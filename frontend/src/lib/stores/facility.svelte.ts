import { db } from '$lib/firebase/config';
import { teamStore } from '$lib/stores/team.svelte';
import { authStore } from '$lib/stores/auth.svelte';
import { managerStore } from '$lib/stores/manager.svelte';
import { notificationStore } from '$lib/stores/notifications.svelte';
import { seasonStore } from '$lib/stores/season.svelte';
import { FacilityType, type Facility } from '$lib/types';
import { doc, collection, runTransaction, serverTimestamp } from 'firebase/firestore';
import {
    FACILITY_UPGRADE_COSTS,
    FACILITY_MAINTENANCE_COST_PER_LEVEL,
    FACILITY_ROLE_DISCOUNT,
    FACILITY_MAX_LEVEL,
    YOUTH_ACADEMY_UPGRADE_COST_PER_LEVEL,
} from '$lib/constants/economics';

export function createFacilityStore() {
    const defaultFacilities: Record<string, Facility> = {
        [FacilityType.teamOffice]: { type: FacilityType.teamOffice, level: 1, isLocked: false, maintenanceCost: FACILITY_MAINTENANCE_COST_PER_LEVEL },
        [FacilityType.garage]: { type: FacilityType.garage, level: 1, isLocked: false, maintenanceCost: FACILITY_MAINTENANCE_COST_PER_LEVEL },
        [FacilityType.youthAcademy]: { type: FacilityType.youthAcademy, level: 0, isLocked: false, maintenanceCost: 0 },
        [FacilityType.pressRoom]: { type: FacilityType.pressRoom, level: 0, isLocked: false, maintenanceCost: 0 },
        [FacilityType.scoutingOffice]: { type: FacilityType.scoutingOffice, level: 0, isLocked: false, maintenanceCost: 0 },
        [FacilityType.racingSimulator]: { type: FacilityType.racingSimulator, level: 0, isLocked: false, maintenanceCost: 0 },
        [FacilityType.gym]: { type: FacilityType.gym, level: 0, isLocked: false, maintenanceCost: 0 },
        [FacilityType.rdOffice]: { type: FacilityType.rdOffice, level: 0, isLocked: false, maintenanceCost: 0 },
        [FacilityType.carMuseum]: { type: FacilityType.carMuseum, level: 0, isLocked: false, maintenanceCost: 0 }
    };

    return {
        get facilities() {
            const team = teamStore.value.team;
            if (!team) return defaultFacilities;

            // Merge defaults with team data to ensure all slots are visible
            const merged = { ...defaultFacilities };
            if (team.facilities) {
                for (const [key, facility] of Object.entries(team.facilities)) {
                    merged[key] = facility;
                }
            }
            return merged;
        },

        get currentSeasonId(): string | null {
            return seasonStore.value.season?.id ?? teamStore.value.team?.currentSeasonId ?? null;
        },

        /**
         * Returns true if the facility can be upgraded this season.
         * A facility is blocked if it is already at max level or was already upgraded in the current season.
         */
        canUpgradeFacility(type: FacilityType): boolean {
            const facility = this.facilities[type];
            if (!facility || facility.level >= FACILITY_MAX_LEVEL) return false;
            const seasonId = this.currentSeasonId;
            if (!seasonId) return true; // season not loaded yet — optimistic
            return facility.lastUpgradeSeasonId !== seasonId;
        },

        getUpgradePrice(type: FacilityType, currentLevel: number): number {
            if (currentLevel >= FACILITY_MAX_LEVEL) return 0;

            // Youth Academy overrides base price when upgrading (level > 0).
            if (type === FacilityType.youthAcademy && currentLevel > 0) {
                return YOUTH_ACADEMY_UPGRADE_COST_PER_LEVEL * currentLevel;
            }

            return FACILITY_UPGRADE_COSTS[currentLevel] ?? 0;
        },

        getMaintenanceCost(level: number): number {
            return level * FACILITY_MAINTENANCE_COST_PER_LEVEL;
        },

        async upgradeFacility(type: FacilityType) {
            const team = teamStore.value.team;
            if (!team) throw new Error("No team active");

            const seasonId = seasonStore.value.season?.id ?? team.currentSeasonId ?? null;
            const profile = managerStore.profile;
            const facility = this.facilities[type];

            if (facility.level >= FACILITY_MAX_LEVEL) {
                throw new Error("Maximum level reached");
            }

            if (seasonId && facility.lastUpgradeSeasonId === seasonId) {
                throw new Error("Already upgraded this season");
            }

            let price = this.getUpgradePrice(type, facility.level);

            // Apply discounts based on role
            if (profile?.role === 'business' || profile?.role === 'bureaucrat') {
                price = Math.round(price * FACILITY_ROLE_DISCOUNT);
            }

            if (team.budget < price) {
                throw new Error(`Insufficient budget. Need $${(price / 1000000).toFixed(1)}M`);
            }

            const teamRef = doc(db, 'teams', team.id);

            await runTransaction(db, async (transaction) => {
                const teamDoc = await transaction.get(teamRef);
                if (!teamDoc.exists()) throw new Error("Team not found");

                const teamData = teamDoc.data();
                const currentBudget = teamData.budget;

                if (currentBudget < price) throw new Error("Insufficient budget");

                // Re-check season limit inside transaction (authoritative)
                const resolvedSeasonId = teamData.currentSeasonId ?? seasonId;
                const facilityInDoc = teamData.facilities?.[type];
                if (resolvedSeasonId && facilityInDoc?.lastUpgradeSeasonId === resolvedSeasonId) {
                    throw new Error("Already upgraded this season");
                }

                const nextLevel = facility.level + 1;
                const updatedFacility: Facility = {
                    ...facility,
                    level: nextLevel,
                    maintenanceCost: this.getMaintenanceCost(nextLevel),
                    lastUpgradeSeasonId: resolvedSeasonId
                };

                // Update team budget and facility
                transaction.update(teamRef, {
                    'budget': currentBudget - price,
                    [`facilities.${type}`]: updatedFacility
                });

                // Add transaction history
                const transRef = doc(collection(db, 'teams', team.id, 'transactions'));
                transaction.set(transRef, {
                    id: transRef.id,
                    description: `Upgraded ${type} to level ${nextLevel}`,
                    amount: -price,
                    date: new Date().toISOString(),
                    type: 'UPGRADE'
                });
            });

            // Success notification
            await notificationStore.addNotification({
                title: "Facility Upgraded",
                message: `${type} has been upgraded to level ${facility.level + 1}.`,
                type: 'SUCCESS',
                actionRoute: '/facilities'
            });
        }
    };
}

export const facilityStore = createFacilityStore();
