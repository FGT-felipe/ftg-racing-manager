import { db } from '$lib/firebase/config';
import {
    doc,
    updateDoc,
    runTransaction,
    increment,
    collection,
} from 'firebase/firestore';
import { type Driver } from '$lib/types';
import { driverRepository } from '$lib/repositories/driver.repository';
import { teamRepository } from '$lib/repositories/team.repository';

export class StaffService {
    async getTeamDrivers(teamId: string): Promise<Driver[]> {
        return driverRepository.getTeamDrivers(teamId);
    }

    async saveFitnessAssignment(teamId: string, trainerData: any) {
        const teamRef = teamRepository.docRef(teamId);
        await updateDoc(teamRef, {
            'weekStatus.fitnessTrainerAssignedTo': trainerData.assignedToId
        });
    }

    async changeTrainerLevel(teamId: string, newLevel: number, cost: number, isUpgrade: boolean) {
        const teamRef = teamRepository.docRef(teamId);
        await runTransaction(db, async (transaction) => {
            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) return;

            if (isUpgrade) {
                const budget = teamDoc.data().budget || 0;
                if (budget < cost) throw new Error("Insufficient budget");

                transaction.update(teamRef, {
                    budget: increment(-cost),
                    'weekStatus.fitnessTrainerLevel': newLevel,
                    'weekStatus.fitnessTrainerUpgradedThisWeek': true
                });
            } else {
                transaction.update(teamRef, {
                    'weekStatus.fitnessTrainerLevel': newLevel,
                    'weekStatus.fitnessTrainerUpgradedThisWeek': true
                });
            }

            if (isUpgrade) {
                const txRef = doc(collection(teamRef, 'transactions'));
                transaction.set(txRef, {
                    id: txRef.id,
                    description: `Staff Upgrade: Fitness Trainer (Lvl ${newLevel})`,
                    amount: -cost,
                    date: new Date().toISOString(),
                    type: 'OTHER'
                });
            }
        });
    }

    async trainPilot(teamId: string, pilotId: string, bonus: number) {
        const pilotRef = driverRepository.docRef(pilotId);
        const teamRef = teamRepository.docRef(teamId);

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
        const driverRef = driverRepository.docRef(driver.id);
        const teamRef = teamRepository.docRef(teamId);

        const marketValue = driver.salary * 12;
        const releaseFee = Math.round(marketValue * 0.10);

        await runTransaction(db, async (transaction) => {
            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) return;

            const budget = teamDoc.data().budget || 0;
            if (budget < releaseFee) throw new Error("Insufficient budget for release fee");

            transaction.update(teamRef, {
                budget: increment(-releaseFee)
            });

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
        const driverRef = driverRepository.docRef(driver.id);
        const teamRef = teamRepository.docRef(teamId);

        const marketValue = driver.salary * 12;
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
        const driverRef = driverRepository.docRef(driverId);
        const teamRef = teamRepository.docRef(teamId);

        await runTransaction(db, async (transaction) => {
            const driverDoc = await transaction.get(driverRef);
            if (!driverDoc.exists()) throw new Error("Driver not found");

            const driverData = driverDoc.data() as Driver;
            const endDateStr = driverData.contract?.endDate;
            const currentContractEnd = endDateStr ? new Date(endDateStr) : new Date();
            const newContractEnd = new Date(currentContractEnd.setFullYear(currentContractEnd.getFullYear() + years));

            const renewalCost = Math.round(driverData.salary * 12 * years * 0.10);

            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) throw new Error("Team not found");

            const budget = teamDoc.data().budget || 0;
            if (budget < renewalCost) throw new Error("Insufficient budget for contract renewal");

            transaction.update(teamRef, {
                budget: increment(-renewalCost)
            });

            transaction.update(driverRef, {
                'contract.endDate': newContractEnd.toISOString(),
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
