import { db } from '$lib/firebase/config';
import {
    doc,
    updateDoc,
    getDoc,
    runTransaction,
    increment,
    collection,
    query,
    where,
    getDocs
} from 'firebase/firestore';
import { type Driver } from '$lib/types';

export class StaffService {
    async getTeamDrivers(teamId: string): Promise<Driver[]> {
        const q = query(collection(db, 'drivers'), where('teamId', '==', teamId));
        const snapshot = await getDocs(q);
        return snapshot.docs.map(d => ({ id: d.id, ...d.data() } as Driver));
    }

    async saveFitnessAssignment(teamId: string, trainerData: any) {
        const teamRef = doc(db, 'teams', teamId);
        await updateDoc(teamRef, {
            'weekStatus.fitnessTrainerAssignedTo': trainerData.assignedToId
        });
    }

    async upgradeTrainer(teamId: string, currentLevel: number, cost: number) {
        const teamRef = doc(db, 'teams', teamId);
        await runTransaction(db, async (transaction) => {
            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) return;

            const budget = teamDoc.data().budget || 0;
            if (budget < cost) throw new Error("Insufficient budget");

            transaction.update(teamRef, {
                budget: increment(-cost),
                'weekStatus.fitnessTrainerLevel': currentLevel + 1,
                'weekStatus.fitnessTrainerUpgradedThisWeek': true
            });

            const txRef = doc(collection(teamRef, 'transactions'));
            transaction.set(txRef, {
                id: txRef.id,
                description: `Staff Upgrade: Fitness Trainer (Lvl ${currentLevel + 1})`,
                amount: -cost,
                date: new Date().toISOString(),
                type: 'OTHER'
            });
        });
    }

    async trainPilot(teamId: string, pilotId: string, bonus: number) {
        const pilotRef = doc(db, 'drivers', pilotId);
        const teamRef = doc(db, 'teams', teamId);

        await runTransaction(db, async (transaction) => {
            const pilotDoc = await transaction.get(pilotRef);
            if (!pilotDoc.exists()) return;

            const stats = { ...(pilotDoc.data().stats || {}) };
            const currentFit = stats.fitness || 50;
            stats.fitness = Math.min(100, currentFit + bonus);

            transaction.update(pilotRef, { stats });
            transaction.update(teamRef, {
                'weekStatus.fitnessTrainerTrainedThisWeek': true
            });
        });
    }
}

export const staffService = new StaffService();
