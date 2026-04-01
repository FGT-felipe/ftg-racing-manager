import { db } from '$lib/firebase/config';
import {
    doc,
    updateDoc,
    runTransaction,
    increment,
    collection,
    Timestamp,
} from 'firebase/firestore';
import { type Driver } from '$lib/types';
import { driverRepository } from '$lib/repositories/driver.repository';
import { teamRepository } from '$lib/repositories/team.repository';
import { calculateDriverMarketValue } from '$lib/utils/driver';
import {
    TRANSFER_MARKET_LISTING_FEE_RATE,
    DRIVER_RENEWAL_FEE_RATE,
    DISMISS_MORALE_PENALTY,
    MORALE_DEFAULT,
    MORALE_EVENT_TRANSFER_LISTED,
    PSYCHOLOGIST_UPGRADE_COSTS,
} from '$lib/constants/economics';
import { transferMarketService } from '$lib/services/transfer_market.svelte';

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

    /**
     * Removes a driver from the transfer market.
     * The original 10% listing fee is NOT refunded.
     * Throws if there is an active bid on the driver (auction must run to completion).
     *
     * @param teamId - The team that listed the driver
     * @param driver - The driver to delist
     */
    async cancelListing(teamId: string, driver: Driver) {
        if ((driver.currentHighestBid ?? 0) > 0) {
            throw new Error('Cannot cancel listing with active bids');
        }

        const driverRef = driverRepository.docRef(driver.id);

        await runTransaction(db, async (transaction) => {
            const driverDoc = await transaction.get(driverRef);
            if (!driverDoc.exists()) throw new Error('Driver not found');

            transaction.update(driverRef, {
                isTransferListed: false,
                transferListedAt: null,
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

            const driverDoc = await transaction.get(driverRef);
            if (!driverDoc.exists()) throw new Error('Driver not found');
            const currentMorale = driverDoc.data().stats?.morale ?? MORALE_DEFAULT;

            transaction.update(driverRef, {
                isTransferListed: true,
                transferListedAt: Timestamp.now(),
                marketValue,
                'stats.morale': Math.max(0, currentMorale + MORALE_EVENT_TRANSFER_LISTED),
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
     * Stores the result of a post-bid transfer contract negotiation and delegates
     * the actual team transfer to the Cloud Function resolver (T-028 flow).
     *
     * On acceptance: saves accepted contract terms to the driver's pendingContracts map.
     *   The resolver picks these up at auction expiry and executes the transfer.
     *
     * On rejection: blacklists the buyer team on the driver so they cannot bid again,
     *   and applies morale penalties.
     *
     * @param driver             - The driver being negotiated for (still on market)
     * @param params.accepted    - Whether personal terms were agreed
     * @param params.salary      - Agreed annual salary (if accepted)
     * @param params.years       - Contract duration in seasons (if accepted)
     * @param params.moraleChange - Cumulative morale adjustment from failed attempts (≤0)
     * @param params.role        - Agreed team role: 'main' | 'secondary' | 'equal'
     * @param params.replacedDriverId - Driver being displaced from the roster slot
     * @param params.buyerTeamId - The team that placed the bid
     * @param params.bidAmount   - The bid amount placed
     */
    async finalizeTransferAcquisition(driver: Driver, params: {
        accepted: boolean;
        salary?: number;
        years?: number;
        moraleChange: number;
        role?: 'main' | 'secondary' | 'equal';
        replacedDriverId?: string;
        buyerTeamId: string;
        bidAmount: number;
    }) {
        const { accepted, salary, years, moraleChange, role, replacedDriverId, buyerTeamId, bidAmount } = params;

        if (accepted && salary && years && role && replacedDriverId) {
            // Store contract terms — resolver executes the actual transfer at auction end
            await transferMarketService.submitContractAccepted(driver.id, buyerTeamId, {
                bidAmount,
                role,
                replacedDriverId,
                salary,
                years,
            });
        } else {
            // Negotiations failed — blacklist team, apply morale penalty to driver
            await transferMarketService.submitContractRejected(
                driver.id,
                buyerTeamId,
                bidAmount,
                moraleChange
            );
        }
    }
    /**
     * Applies a morale delta to a driver, clamping the result to [0, 100].
     * Used by practice service and any other non-transactional morale events.
     *
     * @param driverId - Target driver
     * @param delta - Points to add (negative = penalty)
     */
    async applyMoraleEvent(driverId: string, delta: number): Promise<void> {
        const driverRef = driverRepository.docRef(driverId);
        await runTransaction(db, async (transaction) => {
            const driverDoc = await transaction.get(driverRef);
            if (!driverDoc.exists()) return;
            const current = driverDoc.data().stats?.morale ?? MORALE_DEFAULT;
            const next = Math.max(0, Math.min(100, current + delta));
            transaction.update(driverRef, { 'stats.morale': next });
        });
    }

    /**
     * Performs a manual psychologist morale boost session for the assigned driver.
     * Can only be used once per week (gated by psychologistSessionDoneThisWeek).
     *
     * @param teamId - The team
     * @param driverId - Target driver
     * @param bonusPoints - Morale points to add (from PSYCHOLOGIST_BONUS_BY_LEVEL)
     */
    async boostMoralePsychologist(teamId: string, driverId: string, bonusPoints: number): Promise<void> {
        const driverRef = driverRepository.docRef(driverId);
        const teamRef = teamRepository.docRef(teamId);

        await runTransaction(db, async (transaction) => {
            const driverDoc = await transaction.get(driverRef);
            if (!driverDoc.exists()) return;
            const current = driverDoc.data().stats?.morale ?? MORALE_DEFAULT;
            transaction.update(driverRef, {
                'stats.morale': Math.min(100, current + bonusPoints),
            });
            transaction.update(teamRef, {
                'weekStatus.psychologistSessionDoneThisWeek': true,
            });
        });
    }

    /**
     * Assigns the psychologist to a specific driver for weekly automatic morale processing.
     *
     * @param teamId - The team
     * @param params.assignedToId - Driver ID to assign
     */
    async savePsychologistAssignment(teamId: string, params: { assignedToId: string }): Promise<void> {
        const teamRef = teamRepository.docRef(teamId);
        await updateDoc(teamRef, {
            'weekStatus.psychologistAssignedTo': params.assignedToId,
        });
    }

    /**
     * Upgrades or downgrades the psychologist level.
     * Upgrade deducts cost from budget and locks further changes for the week.
     * Downgrade is free but also locks changes for the week.
     *
     * @param teamId - The team
     * @param newLevel - Target level (1–5)
     * @param cost - Upgrade cost in USD (0 for downgrade)
     * @param isUpgrade - true = upgrade, false = downgrade
     */
    async changePsychologistLevel(teamId: string, newLevel: number, cost: number, isUpgrade: boolean): Promise<void> {
        const teamRef = teamRepository.docRef(teamId);
        await runTransaction(db, async (transaction) => {
            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) return;

            if (isUpgrade) {
                const budget = teamDoc.data().budget || 0;
                if (budget < cost) throw new Error('Insufficient budget');
                transaction.update(teamRef, {
                    budget: increment(-cost),
                    'weekStatus.psychologistLevel': newLevel,
                    'weekStatus.psychologistUpgradedThisWeek': true,
                });
                const txRef = doc(collection(teamRef, 'transactions'));
                transaction.set(txRef, {
                    id: txRef.id,
                    description: `Staff Upgrade: HR Manager / Psychologist (Lvl ${newLevel})`,
                    amount: -cost,
                    date: new Date().toISOString(),
                    type: 'OTHER',
                });
            } else {
                transaction.update(teamRef, {
                    'weekStatus.psychologistLevel': newLevel,
                    'weekStatus.psychologistUpgradedThisWeek': true,
                });
            }
        });
    }
}

export const staffService = new StaffService();
