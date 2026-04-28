import { db } from '$lib/firebase/config';
import {
    doc,
    getDoc,
    setDoc,
    runTransaction,
    collection,
    serverTimestamp,
} from 'firebase/firestore';
import { teamRepository } from '$lib/repositories/team.repository';
import {
    PARTS_ENGINE_REPAIR_COST_FLAT,
    PARTS_REPAIR_BUDGET_CAP_PER_ROUND,
    PARTS_TIER_THRESHOLDS,
} from '$lib/constants/app_constants';
import type { ConditionTier, Part, Team } from '$lib/types';

export class PartsWearService {
    /**
     * Creates the parts/engine document for a car if it doesn't exist yet.
     * Safe to call on every page load — no-ops when the doc already exists.
     *
     * @param teamId - The team owning the car
     * @param carIndex - Car slot index (0 = Car A, 1 = Car B)
     */
    async seedEngineIfMissing(teamId: string, carIndex: number): Promise<void> {
        const partRef = doc(db, 'teams', teamId, 'cars', String(carIndex), 'parts', 'engine');
        const snap = await getDoc(partRef);
        if (snap.exists()) return;
        await setDoc(partRef, {
            partType: 'engine',
            condition: 100,
            level: 1,
            updatedAt: serverTimestamp(),
        });
    }

    /**
     * Atomically repairs a car part to its maxCondition.
     * Enforces per-round repair budget cap (`PARTS_REPAIR_BUDGET_CAP_PER_ROUND`).
     * Deducts repairCost from team budget and increments weekStatus.repairSpentThisRound.
     * Rolls back atomically if budget or cap is insufficient.
     *
     * @param teamId - The team owning the car
     * @param carIndex - Car slot index (0 = Car A)
     * @param partType - Firestore document ID of the part (e.g. 'engine', 'brakes')
     * @param repairCost - Cost of this repair (defaults to PARTS_ENGINE_REPAIR_COST_FLAT)
     * @throws Error('INSUFFICIENT_BUDGET') when team budget < repairCost
     * @throws Error('REPAIR_BUDGET_EXCEEDED') when per-round cap would be exceeded
     */
    async repairPart(
        teamId: string,
        carIndex: number,
        partType: string,
        repairCost: number = PARTS_ENGINE_REPAIR_COST_FLAT,
    ): Promise<void> {
        const teamRef = teamRepository.docRef(teamId);
        const partRef = doc(db, 'teams', teamId, 'cars', String(carIndex), 'parts', partType);

        await runTransaction(db, async (transaction) => {
            const [teamDoc, partDoc] = await Promise.all([
                transaction.get(teamRef),
                transaction.get(partRef),
            ]);

            if (!teamDoc.exists()) throw new Error('Team not found');
            if (!partDoc.exists()) throw new Error('Part not found');

            const budget: number = teamDoc.data().budget ?? 0;
            const weekStatus: Record<string, unknown> = teamDoc.data().weekStatus ?? {};
            const repairSpent: number = (weekStatus['repairSpentThisRound'] as number) ?? 0;
            const targetCondition: number = (partDoc.data().maxCondition as number) ?? 100;

            if (budget < repairCost) throw new Error('INSUFFICIENT_BUDGET');
            if (repairSpent + repairCost > PARTS_REPAIR_BUDGET_CAP_PER_ROUND) {
                throw new Error('REPAIR_BUDGET_EXCEEDED');
            }

            transaction.update(teamRef, {
                budget: budget - repairCost,
                'weekStatus.repairSpentThisRound': repairSpent + repairCost,
            });
            transaction.update(partRef, {
                condition: targetCondition,
                updatedAt: serverTimestamp(),
            });

            const txRef = doc(collection(teamRef, 'transactions'));
            transaction.set(txRef, {
                id: txRef.id,
                description: `Part Repair: ${partType} (Car ${carIndex})`,
                amount: -repairCost,
                date: new Date().toISOString(),
                type: 'OTHER',
            });
        });
    }

    /**
     * Returns the repair target condition for a part (its maxCondition, not always 100).
     * Use this to display the post-repair condition in UI.
     *
     * @param part - The part to inspect
     * @returns Target condition after a full repair
     */
    repairTarget(part: Part): number {
        return part.maxCondition;
    }

    /**
     * Returns remaining repair budget for the current round.
     * Reads repairSpentThisRound from weekStatus (reset each round by processPostRace).
     *
     * @param team - The current team object
     * @returns Remaining budget available for repairs this round
     */
    getRemainingRepairBudget(team: Team): number {
        const spent: number = (team.weekStatus?.['repairSpentThisRound'] as number) ?? 0;
        return PARTS_REPAIR_BUDGET_CAP_PER_ROUND - spent;
    }

    /**
     * Returns the visual condition tier for a given condition value.
     * green ≥80 / yellow 50–79 / orange 30–49 / red <30
     *
     * @param condition - Part condition value (0–100)
     * @returns ConditionTier string
     */
    getConditionTier(condition: number): ConditionTier {
        if (condition >= PARTS_TIER_THRESHOLDS.yellow) return 'green';
        if (condition >= PARTS_TIER_THRESHOLDS.orange) return 'yellow';
        if (condition >= PARTS_TIER_THRESHOLDS.red) return 'orange';
        return 'red';
    }
}

export const partsWearService = new PartsWearService();
