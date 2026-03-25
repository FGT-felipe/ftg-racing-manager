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
import { calculateDriverMarketValue } from '$lib/utils/driver';
import {
    TRANSFER_MARKET_LISTING_FEE_RATE,
    DRIVER_RENEWAL_FEE_RATE,
    DISMISS_MORALE_PENALTY,
} from '$lib/constants/economics';

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

    /**
     * Dismisses a driver from the team.
     * Fee = driver's full annual salary (paid as severance).
     * The driver becomes a free agent: marketValue resets to annual salary, morale -20.
     *
     * @param teamId - The team performing the dismissal
     * @param driver - The driver being dismissed
     */
    async dismissDriver(teamId: string, driver: Driver) {
        const driverRef = driverRepository.docRef(driver.id);
        const teamRef = teamRepository.docRef(teamId);

        const dismissFee = driver.salary; // Full annual salary as severance

        await runTransaction(db, async (transaction) => {
            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) return;

            const driverDoc = await transaction.get(driverRef);
            if (!driverDoc.exists()) return;

            const budget = teamDoc.data().budget || 0;
            if (budget < dismissFee) throw new Error("Insufficient budget for dismissal fee");

            const currentMorale = driverDoc.data().stats?.morale ?? 50;

            transaction.update(teamRef, {
                budget: increment(-dismissFee)
            });

            transaction.update(driverRef, {
                teamId: null,
                carIndex: -1,
                role: 'Unassigned',
                marketValue: driver.salary, // Reset to annual salary post-dismissal
                'stats.morale': Math.max(0, currentMorale - DISMISS_MORALE_PENALTY),
            });

            const txRef = doc(collection(teamRef, 'transactions'));
            transaction.set(txRef, {
                id: txRef.id,
                description: `Driver Dismissed: ${driver.name}`,
                amount: -dismissFee,
                date: new Date().toISOString(),
                type: 'OTHER'
            });
        });
    }

    async listDriverOnMarket(teamId: string, driver: Driver) {
        const driverRef = driverRepository.docRef(driver.id);
        const teamRef = teamRepository.docRef(teamId);

        const marketValue = calculateDriverMarketValue(driver);
        const listingFee = Math.round(marketValue * TRANSFER_MARKET_LISTING_FEE_RATE);

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
                marketValue
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

    /**
     * Finalises a negotiated contract renewal for a main driver.
     * Called only when the manager has successfully reached an agreement.
     *
     * @param teamId - The team performing the renewal
     * @param driver - The driver whose contract is being renewed
     * @param params.years - Contract duration in seasons (1–3)
     * @param params.salary - Agreed annual salary (post-negotiation)
     * @param params.moraleChange - Cumulative morale adjustment from failed attempts (≤0)
     */
    async negotiateRenewal(teamId: string, driver: Driver, params: {
        years: number;
        salary: number;
        moraleChange: number;
    }) {
        const driverRef = driverRepository.docRef(driver.id);
        const teamRef = teamRepository.docRef(teamId);
        const { years, salary, moraleChange } = params;

        await runTransaction(db, async (transaction) => {
            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) throw new Error("Team not found");

            const driverDoc = await transaction.get(driverRef);
            if (!driverDoc.exists()) throw new Error("Driver not found");

            // salary is annual; fee = 10% of total annual contract value
            const renewalFee = Math.round(salary * years * DRIVER_RENEWAL_FEE_RATE);
            const budget = teamDoc.data().budget || 0;
            if (budget < renewalFee) throw new Error("Insufficient budget for contract renewal");

            const driverUpdates: Record<string, any> = {
                salary,
                contractYearsRemaining: years,
            };
            if (moraleChange !== 0) {
                const currentMorale = driverDoc.data().stats?.morale ?? 50;
                driverUpdates['stats.morale'] = Math.max(0, Math.min(100, currentMorale + moraleChange));
            }

            transaction.update(teamRef, { budget: increment(-renewalFee) });
            transaction.update(driverRef, driverUpdates);

            const txRef = doc(collection(teamRef, 'transactions'));
            transaction.set(txRef, {
                id: txRef.id,
                description: `Contract Renewal: ${driver.name} (${years} yr${years > 1 ? 's' : ''} @ $${salary.toLocaleString()}/yr)`,
                amount: -renewalFee,
                date: new Date().toISOString(),
                type: 'OTHER',
            });
        });
    }

    /**
     * Applies morale penalties after failed negotiations (driver walked away, manager abandoned).
     * Called when negotiations collapse without a deal.
     */
    async applyNegotiationFailPenalty(driver: Driver, moraleChange: number) {
        if (moraleChange === 0) return;
        const driverRef = driverRepository.docRef(driver.id);
        const currentMorale = driver.stats?.morale ?? 50;
        await updateDoc(driverRef, {
            'stats.morale': Math.max(0, Math.min(100, currentMorale + moraleChange)),
        });
    }

    /**
     * Finalizes a post-bid transfer negotiation.
     * Called after the buyer won an auction and has agreed (or failed) on personal terms.
     *
     * On acceptance: driver transferred to buyer team with agreed salary/years.
     * On rejection: driver returned to original team. Bid amount is NOT refunded.
     *
     * @param driver - The driver in pendingNegotiation state
     * @param params.accepted - Whether personal terms were agreed
     * @param params.salary - Agreed annual salary (if accepted)
     * @param params.years - Contract duration in seasons (if accepted)
     * @param params.moraleChange - Cumulative morale adjustment from failed attempts
     */
    async finalizeTransferAcquisition(driver: Driver, params: {
        accepted: boolean;
        salary?: number;
        years?: number;
        moraleChange: number;
    }) {
        const driverRef = driverRepository.docRef(driver.id);
        const { accepted, salary, years, moraleChange } = params;
        const buyerTeamId = driver.pendingBuyerTeamId;
        const originalTeamId = driver.pendingOriginalTeamId;

        if (!buyerTeamId) throw new Error('No pending buyer for this driver');

        await runTransaction(db, async (transaction) => {
            const driverDoc = await transaction.get(driverRef);
            if (!driverDoc.exists()) throw new Error('Driver not found');

            const pendingNeg = driverDoc.data().pendingNegotiation;
            if (!pendingNeg) throw new Error('No pending negotiation for this driver');

            const clearPendingFields = {
                pendingNegotiation: false,
                pendingBuyerTeamId: null,
                pendingBidAmount: null,
                pendingOriginalTeamId: null,
            };

            if (accepted && salary && years) {
                // Transfer the driver to the buyer team
                const driverUpdates: Record<string, any> = {
                    ...clearPendingFields,
                    teamId: buyerTeamId,
                    salary,
                    contractYearsRemaining: years,
                    role: 'Reserve', // Joins as Reserve — manager reassigns later
                    carIndex: -1,
                };
                if (moraleChange !== 0) {
                    const currentMorale = driverDoc.data().stats?.morale ?? 50;
                    driverUpdates['stats.morale'] = Math.max(0, Math.min(100, currentMorale + moraleChange));
                }

                transaction.update(driverRef, driverUpdates);

                // Log acquisition transaction for buyer
                const buyerTeamRef = teamRepository.docRef(buyerTeamId);
                const txRef = doc(collection(buyerTeamRef, 'transactions'));
                transaction.set(txRef, {
                    id: txRef.id,
                    description: `Transfer Acquisition: ${driver.name} (${years} yr${years > 1 ? 's' : ''} @ $${salary.toLocaleString()}/yr)`,
                    amount: 0, // Transfer fee already deducted by resolver
                    date: new Date().toISOString(),
                    type: 'OTHER',
                });
            } else {
                // Negotiations failed — return driver to original team, bid amount already lost
                const driverUpdates: Record<string, any> = {
                    ...clearPendingFields,
                    teamId: originalTeamId || null,
                };
                if (moraleChange !== 0) {
                    const currentMorale = driverDoc.data().stats?.morale ?? 50;
                    driverUpdates['stats.morale'] = Math.max(0, Math.min(100, currentMorale + moraleChange));
                }
                transaction.update(driverRef, driverUpdates);
            }
        });
    }
}

export const staffService = new StaffService();
