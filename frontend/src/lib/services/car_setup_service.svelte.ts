import { db } from '$lib/firebase/config';
import { doc, getDoc, updateDoc, increment, addDoc, collection, serverTimestamp, arrayUnion } from 'firebase/firestore';
import { PRACTICE_SESSION_COST } from '$lib/constants/app_constants';
import { t } from '$lib/utils/i18n';

export interface QualyRunRecord {
    attempt: number;
    lapTime: number;
    tyreCompound: string;
    setupConfidence: number;
    setupUsed: Record<string, any>;
    isCrashed: boolean;
}

/**
 * Service for all car setup and race weekend Firestore writes.
 * Components must not call doc(), updateDoc(), or addDoc() directly —
 * all setup persistence goes through this service.
 */
export class CarSetupService {
    /**
     * Pays the one-time practice entry fee for a driver and logs the transaction.
     * Only called when the driver has not yet paid for the current weekend.
     * @param teamId - The team document ID.
     * @param currentBudget - Current team budget (used for direct assignment, not increment).
     * @param driverId - The driver document ID.
     * @param driverName - Driver name used in the transaction description.
     */
    async payPracticeFee(teamId: string, currentBudget: number, driverId: string, driverName: string): Promise<void> {
        const teamRef = doc(db, 'teams', teamId);
        const txRef = collection(db, 'teams', teamId, 'transactions');
        await updateDoc(teamRef, {
            budget: currentBudget - PRACTICE_SESSION_COST,
            [`weekStatus.practicePaid.${driverId}`]: true,
        });
        await addDoc(txRef, {
            description: t('practice_fee_description', { name: driverName }),
            amount: -PRACTICE_SESSION_COST,
            date: serverTimestamp(),
            type: 'PRACTICE',
        });
    }

    /**
     * Saves the full practice run history array for a driver to the team document.
     * Overwrites the existing practiceRuns array.
     * @param teamId - The team document ID.
     * @param driverId - The driver document ID.
     * @param runs - Updated array of practice run records.
     */
    async savePracticeRuns(teamId: string, driverId: string, runs: any[]): Promise<void> {
        const teamRef = doc(db, 'teams', teamId);
        await updateDoc(teamRef, {
            [`weekStatus.driverSetups.${driverId}.practiceRuns`]: runs,
        });
    }

    /**
     * Charges the qualifying session entry fee via an atomic increment.
     * Only called on the first qualifying attempt of a driver.
     * @param teamId - The team document ID.
     * @param cost - Fee amount to deduct from budget.
     */
    async chargeQualyFee(teamId: string, cost: number): Promise<void> {
        const teamRef = doc(db, 'teams', teamId);
        await updateDoc(teamRef, { budget: increment(-cost) });
    }

    /**
     * Applies a fitness penalty to a driver's stats after a qualifying session.
     * @param driverId - The driver document ID.
     * @param newFitness - Calculated fitness value after penalty (clamped 0–100).
     */
    async applyFitnessPenalty(driverId: string, newFitness: number): Promise<void> {
        const driverRef = doc(db, 'drivers', driverId);
        await updateDoc(driverRef, { 'stats.fitness': newFitness });
    }

    /**
     * Saves a qualifying attempt result (clean lap or DNF/crash) to the team document.
     * Appends the run to the qualifyingRuns array. Optionally locks Parc Fermé.
     *
     * IMPORTANT: `driverSetups` is not cleared between race weekends by post-race
     * processing, so `qualifyingRuns` from R(N-1) persists into R(N). When this is
     * the first attempt of a fresh race weekend (`isFreshSession`), we OVERWRITE the
     * array with `[run]` instead of appending, otherwise stale runs leak into the
     * next round's UI. Subsequent attempts in the same session append.
     *
     * @param teamId - The team document ID.
     * @param driverId - The driver document ID.
     * @param fields - Flat map of Firestore field paths to values.
     * @param setParcFerme - If true, also locks qualifyingParcFerme for this driver.
     * @param run - Run record to append to (or seed) qualifyingRuns[].
     * @param isFreshSession - When true, overwrite the runs array instead of appending.
     */
    async saveQualyResult(
        teamId: string,
        driverId: string,
        fields: Record<string, any>,
        setParcFerme: boolean,
        run: QualyRunRecord,
        isFreshSession: boolean = false,
    ): Promise<void> {
        const teamRef = doc(db, 'teams', teamId);
        await updateDoc(teamRef, {
            ...fields,
            [`weekStatus.driverSetups.${driverId}.qualifyingRuns`]: isFreshSession
                ? [run]
                : arrayUnion(run),
        });
        if (setParcFerme) {
            await updateDoc(teamRef, {
                [`weekStatus.driverSetups.${driverId}.qualifyingParcFerme`]: true,
            });
        }
    }

    /**
     * Confirms a specific qualifying run as the race setup, locking Parc Fermé to that run's
     * mechanical values and tyre compound. Called when the manager clicks "→ Race Setup".
     * @param teamId - The team document ID.
     * @param driverId - The driver document ID.
     * @param run - The qualifying run whose setup to use for the race.
     * @param isWetSession - If true, no Parc Fermé lock applies (free compound choice).
     */
    async confirmQualySetup(
        teamId: string,
        driverId: string,
        run: QualyRunRecord,
        isWetSession: boolean
    ): Promise<void> {
        const teamRef = doc(db, 'teams', teamId);
        await updateDoc(teamRef, {
            [`weekStatus.driverSetups.${driverId}.qualifying`]: run.setupUsed,
            [`weekStatus.driverSetups.${driverId}.qualifyingBestCompound`]: run.tyreCompound,
            [`weekStatus.driverSetups.${driverId}.qualifyingConfirmedAttempt`]: run.attempt,
            [`weekStatus.driverSetups.${driverId}.qualifyingParcFerme`]: !isWetSession && !run.isCrashed,
        });
    }

    /**
     * Reads the qualifying grid from a race document.
     * Used by the Race Setup tab to enforce Parc Fermé tyre constraints.
     * @param raceDocId - Combined ID in the format `{seasonId}_{eventId}`.
     * @returns Array of qualifying rows with driverId and tyreCompound, or empty array.
     */
    async getQualyGrid(raceDocId: string): Promise<Array<{ driverId: string; tyreCompound: string }>> {
        try {
            const snap = await getDoc(doc(db, 'races', raceDocId));
            if (!snap.exists()) return [];
            const data = snap.data();
            const grid = data.qualifyingResults || data.qualyGrid || [];
            return Array.isArray(grid)
                ? grid.filter((row: any) => row.driverId && row.tyreCompound)
                : [];
        } catch (e) {
            console.error('[CarSetupService:getQualyGrid] Failed to fetch:', e);
            return [];
        }
    }

    /**
     * Writes a new budget value directly to the team document.
     * NOTE: This is a non-atomic write. Prefer chargeQualyFee (increment) for
     * concurrent-safe deductions. Used here to mirror pre-existing practice logic.
     * @param teamId - The team document ID.
     * @param newBudget - The new budget value to write.
     */
    async deductTeamBudget(teamId: string, newBudget: number): Promise<void> {
        const teamRef = doc(db, 'teams', teamId);
        await updateDoc(teamRef, { budget: newBudget });
    }

    /**
     * Saves the race strategy for a driver to the team document.
     * @param teamId - The team document ID.
     * @param driverId - The driver document ID.
     * @param strategy - The CarSetup object to persist as the race strategy.
     * @param sessionId - Current race-weekend session id (`${seasonId}_${raceEventId}`).
     *        Stamped as `raceSessionId` sibling so the dashboard checklist can
     *        distinguish R(N) leftovers from R(N+1) submissions. Post-race
     *        processing does not clear driverSetups, so without this tag a
     *        stale `race` object from the previous round would mark the
     *        checklist 100% complete.
     */
    async saveRaceSetup(teamId: string, driverId: string, strategy: any, sessionId: string | null = null): Promise<void> {
        const teamRef = doc(db, 'teams', teamId);
        const updates: Record<string, unknown> = {
            [`weekStatus.driverSetups.${driverId}.race`]: { ...strategy },
        };
        if (sessionId) {
            updates[`weekStatus.driverSetups.${driverId}.raceSessionId`] = sessionId;
        }
        await updateDoc(teamRef, updates);
    }
}

export const carSetupService = new CarSetupService();
