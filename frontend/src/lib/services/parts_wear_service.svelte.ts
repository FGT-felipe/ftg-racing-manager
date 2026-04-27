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
    PARTS_TIER_THRESHOLDS,
} from '$lib/constants/app_constants';
import type { ConditionTier } from '$lib/types';

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
     * Atomically repairs a car part to 100% condition.
     * Deducts PARTS_ENGINE_REPAIR_COST_FLAT from team budget and writes a
     * transaction entry. Rolls back if budget is insufficient.
     *
     * @param teamId - The team owning the car
     * @param carIndex - Car slot index (0 = Car A)
     * @param partId - Firestore document ID of the part (e.g. 'engine')
     * @throws Error with message 'INSUFFICIENT_BUDGET' when budget < repair cost
     */
    async repairPart(teamId: string, carIndex: number, partId: string): Promise<void> {
        const teamRef = teamRepository.docRef(teamId);
        const partRef = doc(db, 'teams', teamId, 'cars', String(carIndex), 'parts', partId);

        await runTransaction(db, async (transaction) => {
            const [teamDoc, partDoc] = await Promise.all([
                transaction.get(teamRef),
                transaction.get(partRef),
            ]);

            if (!teamDoc.exists()) throw new Error('Team not found');
            if (!partDoc.exists()) throw new Error('Part not found');

            const budget: number = teamDoc.data().budget ?? 0;
            const cost = PARTS_ENGINE_REPAIR_COST_FLAT;

            if (budget < cost) throw new Error('INSUFFICIENT_BUDGET');

            transaction.update(teamRef, { budget: budget - cost });
            transaction.update(partRef, {
                condition: 100,
                updatedAt: serverTimestamp(),
            });

            const txRef = doc(collection(teamRef, 'transactions'));
            transaction.set(txRef, {
                id: txRef.id,
                description: `Part Repair: ${partId} (Car ${carIndex})`,
                amount: -cost,
                date: new Date().toISOString(),
                type: 'OTHER',
            });
        });
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
