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
    PARTS_REPAIR_HQ_CAP_MULTIPLIER_STEP,
    PARTS_TIER_THRESHOLDS,
    GARAGE_REPAIR_MAX_TABLE,
    PARTS_REPAIR_COOLDOWN_ROUNDS,
} from '$lib/constants/app_constants';
import type { ConditionTier, Part, Team } from '$lib/types';

export class PartsWearService {
    /**
     * Returns the maximum condition a repair can restore a part to,
     * based on the team's Garage facility level (1–5).
     * Table: L1=65%, L2=75%, L3=85%, L4=95%, L5=100%.
     *
     * @param teamData - Raw Firestore team document data
     * @returns Target condition (65–100) based on garage level
     */
    getGarageRepairTarget(teamData: Record<string, unknown>): number {
        const facilities = (teamData['facilities'] as Record<string, { level?: number }>) ?? {};
        let garageLevel = facilities['garage']?.level ?? 1;
        garageLevel = Math.min(Math.max(garageLevel, 1), 5);
        return GARAGE_REPAIR_MAX_TABLE[garageLevel] ?? 65;
    }

    /**
     * Returns the effective per-round repair budget cap, scaled by garage (Engineering) level.
     * Formula: base × (1 + (garageLevel - 1) × 0.5).
     * L1=$150k, L2=$225k, L3=$300k, L4=$375k, L5=$450k.
     *
     * @param teamData - Raw Firestore team document data (or Team object)
     */
    getRepairCap(teamData: Record<string, unknown> | Team): number {
        const facilities = ((teamData as Record<string, unknown>)['facilities'] as Record<string, { level?: number }>) ?? {};
        let garageLevel = facilities['garage']?.level ?? 1;
        garageLevel = Math.min(Math.max(garageLevel, 1), 5);
        return PARTS_REPAIR_BUDGET_CAP_PER_ROUND * (1 + (garageLevel - 1) * PARTS_REPAIR_HQ_CAP_MULTIPLIER_STEP);
    }

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
     * Atomically repairs a car part.
     * - Target condition determined by Garage facility level (65–100%).
     * - Budget cap scales with HQ level; doubled on the final round of the season.
     * - Sets a cooldown of PARTS_REPAIR_COOLDOWN_ROUNDS after repair.
     * - Deducts repairCost from budget and increments weekStatus.repairSpentThisRound.
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

            const teamData = teamDoc.data();
            const budget: number = teamData.budget ?? 0;
            const weekStatus: Record<string, unknown> = teamData.weekStatus ?? {};
            const repairSpent: number = (weekStatus['repairSpentThisRound'] as number) ?? 0;
            const isLastRound: boolean = (weekStatus['isLastRound'] as boolean) ?? false;

            const targetCondition = this.getGarageRepairTarget(teamData);
            let effectiveCap = this.getRepairCap(teamData);
            if (isLastRound) effectiveCap *= 2;

            if (budget < repairCost) throw new Error('INSUFFICIENT_BUDGET');
            if (repairSpent + repairCost > effectiveCap) throw new Error('REPAIR_BUDGET_EXCEEDED');

            transaction.update(teamRef, {
                budget: budget - repairCost,
                'weekStatus.repairSpentThisRound': repairSpent + repairCost,
            });
            transaction.update(partRef, {
                condition: targetCondition,
                maxCondition: targetCondition,
                repairCooldownRoundsLeft: PARTS_REPAIR_COOLDOWN_ROUNDS,
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
    /**
     * Returns remaining repair budget for the current round.
     * Cap is dynamic: scales with HQ level and doubles on the final round.
     *
     * @param team - The current team object
     */
    getRemainingRepairBudget(team: Team): number {
        const spent: number = (team.weekStatus?.['repairSpentThisRound'] as number) ?? 0;
        const isLastRound: boolean = (team.weekStatus?.['isLastRound'] as boolean) ?? false;
        let cap = this.getRepairCap(team as unknown as Record<string, unknown>);
        if (isLastRound) cap *= 2;
        return cap - spent;
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
