import { db } from '$lib/firebase/config';
import { doc, getDoc, updateDoc, increment, addDoc, collection, serverTimestamp } from 'firebase/firestore';
import { PRACTICE_SESSION_COST } from '$lib/constants/app_constants';
import { t } from '$lib/utils/i18n';

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
     * Optionally locks in Parc Fermé constraints for dry sessions.
     * @param teamId - The team document ID.
     * @param driverId - The driver document ID.
     * @param fields - Flat map of Firestore field paths to values (e.g. weekStatus.driverSetups.X.Y).
     * @param setParcFerme - If true, also locks qualifyingParcFerme for this driver.
     */
    async saveQualyResult(teamId: string, driverId: string, fields: Record<string, any>, setParcFerme: boolean): Promise<void> {
        const teamRef = doc(db, 'teams', teamId);
        await updateDoc(teamRef, fields);
        if (setParcFerme) {
            await updateDoc(teamRef, {
                [`weekStatus.driverSetups.${driverId}.qualifyingParcFerme`]: true,
            });
        }
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
     */
    async saveRaceSetup(teamId: string, driverId: string, strategy: any): Promise<void> {
        const teamRef = doc(db, 'teams', teamId);
        await updateDoc(teamRef, {
            [`weekStatus.driverSetups.${driverId}.race`]: { ...strategy },
        });
    }
}

export const carSetupService = new CarSetupService();
