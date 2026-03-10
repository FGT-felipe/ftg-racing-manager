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
    getDocs,
    deleteDoc
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

    async dismissDriver(teamId: string, driver: Driver) {
        const driverRef = doc(db, 'drivers', driver.id);
        const teamRef = doc(db, 'teams', teamId);

        // Calculate 10% fee (port from Flutter)
        const marketValue = driver.salary * 12; // Simple estimation for now
        const releaseFee = Math.round(marketValue * 0.10);

        await runTransaction(db, async (transaction) => {
            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) return;

            const budget = teamDoc.data().budget || 0;
            if (budget < releaseFee) throw new Error("Insufficient budget for release fee");

            transaction.update(teamRef, {
                budget: increment(-releaseFee)
            });

            // According to Flutter code, it deletes the driver or set teamId to null.
            // Let's set teamId to null to keep the record but unassigned.
            transaction.update(driverRef, {
                teamId: null,
                carIndex: -1,
                role: 'Unassigned'
            });

            const txRef = doc(collection(teamRef, 'transactions'));
            transaction.set(txRef, {
                id: txRef.id,
                description: `Driver Released: ${driver.name}`,
                amount: -releaseFee,
                date: new Date().toISOString(),
                type: 'OTHER'
            });
        });
    }

    async listDriverOnMarket(teamId: string, driver: Driver) {
        const driverRef = doc(db, 'drivers', driver.id);
        const teamRef = doc(db, 'teams', teamId);

        const marketValue = driver.salary * 12; // Simple estimation
        const listingFee = Math.round(marketValue * 0.10);

        await runTransaction(db, async (transaction) => {
            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) return;

            const budget = teamDoc.data().budget || 0;
            if (budget < listingFee) throw new Error("Insufficient budget for listing fee");

            transaction.update(teamRef, {
                budget: increment(-listingFee)
            });

            transaction.update(driverRef, {
                isTransferListed: true,
                transferListedAt: new Date().toISOString(),
                priceAtListing: marketValue
            });

            const txRef = doc(collection(teamRef, 'transactions'));
            transaction.set(txRef, {
                id: txRef.id,
                description: `Market Listing Fee: ${driver.name}`,
                amount: -listingFee,
                date: new Date().toISOString(),
                type: 'OTHER'
            });
        });
    }

    async renewContract(teamId: string, driverId: string, years: number) {
        const driverRef = doc(db, 'drivers', driverId);
        const teamRef = doc(db, 'teams', teamId);

        await runTransaction(db, async (transaction) => {
            const driverDoc = await transaction.get(driverRef);
            if (!driverDoc.exists()) throw new Error("Driver not found");

            const driverData = driverDoc.data() as Driver;
            const currentContractEnd = driverData.contractEnd ? new Date(driverData.contractEnd) : new Date();
            const newContractEnd = new Date(currentContractEnd.setFullYear(currentContractEnd.getFullYear() + years));

            // Example renewal cost: 10% of current annual salary per renewed year
            const renewalCost = Math.round(driverData.salary * 12 * years * 0.10);

            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) throw new Error("Team not found");

            const budget = teamDoc.data().budget || 0;
            if (budget < renewalCost) throw new Error("Insufficient budget for contract renewal");

            transaction.update(teamRef, {
                budget: increment(-renewalCost)
            });

            transaction.update(driverRef, {
                contractEnd: newContractEnd.toISOString(),
                // Optionally, update salary or other contract terms here
            });

            const txRef = doc(collection(teamRef, 'transactions'));
            transaction.set(txRef, {
                id: txRef.id,
                description: `Contract Renewal: ${driverData.name} (${years} years)`,
                amount: -renewalCost,
                date: new Date().toISOString(),
                type: 'OTHER'
            });
        });
    }
}

export const staffService = new StaffService();
