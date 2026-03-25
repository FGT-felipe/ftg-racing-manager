import { db } from '$lib/firebase/config';
import { teamStore } from '$lib/stores/team.svelte';
import { managerStore } from '$lib/stores/manager.svelte';
import { notificationStore } from '$lib/stores/notifications.svelte';
import { doc, runTransaction, collection } from 'firebase/firestore';
import { CAR_UPGRADE_BASE_COST, CAR_PART_MAX_LEVEL, BUREAUCRAT_UPGRADE_COOLDOWN_WEEKS } from '$lib/constants/economics';

export function createCarStore() {
    return {
        get carStats() {
            const team = teamStore.value.team;
            if (!team) return {};
            return team.carStats || {
                '0': { aero: 1, powertrain: 1, chassis: 1, reliability: 1 },
                '1': { aero: 1, powertrain: 1, chassis: 1, reliability: 1 }
            };
        },

        getUpgradeCost(currentLevel: number): number {
            const profile = managerStore.profile;
            // Fibonacci sequence for multiplier: 1, 1, 2, 3, 5, 8, 13, 21...
            if (currentLevel <= 2) {
                const base = CAR_UPGRADE_BASE_COST;
                return profile?.role === 'engineer' ? base * 2 : base;
            }

            let a = 1;
            let b = 1;
            for (let i = 2; i < currentLevel; i++) {
                const temp = a + b;
                a = b;
                b = temp;
            }

            const base = b * CAR_UPGRADE_BASE_COST;
            return profile?.role === 'engineer' ? base * 2 : base;
        },

        async upgradePart(carIndex: number, partKey: string) {
            const team = teamStore.value.team;
            if (!team) throw new Error("No team active");

            const profile = managerStore.profile;
            const currentStats = this.carStats[carIndex.toString()] || {};
            const currentLevel = currentStats[partKey] || 1;

            if (currentLevel >= CAR_PART_MAX_LEVEL) {
                throw new Error(`Part is already at maximum level (${CAR_PART_MAX_LEVEL})`);
            }

            const cost = this.getUpgradeCost(currentLevel);

            if (team.budget < cost) {
                throw new Error(`Insufficient funds. Need $${(cost / 1000).toFixed(0)}k`);
            }

            const teamRef = doc(db, 'teams', team.id);

            await runTransaction(db, async (transaction) => {
                const teamDoc = await transaction.get(teamRef);
                if (!teamDoc.exists()) throw new Error("Team not found");

                const data = teamDoc.data();
                const budget = data.budget;
                const weekStatus = { ...(data.weekStatus || {}) };
                const upgradeCount = weekStatus.upgradesThisWeek || 0;
                const cooldownLeft = weekStatus.upgradeCooldownWeeksLeft || 0;

                // Bureaucrat cooldown check
                if (profile?.role === 'bureaucrat' && cooldownLeft > 0) {
                    throw new Error(`Bureaucrat cooldown: ${cooldownLeft} week(s) remaining.`);
                }

                // Upgrade limit check
                const maxUpgrades = profile?.role === 'engineer' ? 2 : 1;
                if (upgradeCount >= maxUpgrades) {
                    throw new Error(`Upgrade limit reached (${maxUpgrades} per week).`);
                }

                if (budget < cost) throw new Error("Insufficient funds");

                // Prepare new car stats
                const newCarStats = { ...(data.carStats || {}) };
                const targetCarStats = { ...(newCarStats[carIndex.toString()] || { aero: 1, powertrain: 1, chassis: 1, reliability: 1 }) };

                const newLevel = (targetCarStats[partKey] || 1) + 1;
                targetCarStats[partKey] = newLevel;
                newCarStats[carIndex.toString()] = targetCarStats;

                // Update week status
                weekStatus.upgradesThisWeek = upgradeCount + 1;
                if (profile?.role === 'bureaucrat') {
                    weekStatus.upgradeCooldownWeeksLeft = BUREAUCRAT_UPGRADE_COOLDOWN_WEEKS;
                }

                transaction.update(teamRef, {
                    budget: budget - cost,
                    carStats: newCarStats,
                    weekStatus: weekStatus
                });

                // Record transaction
                const transRef = doc(collection(teamRef, 'transactions'));
                const carLabel = carIndex === 0 ? "Car A" : "Car B";
                transaction.set(transRef, {
                    id: transRef.id,
                    description: `Upgrade ${partKey} to LVL ${newLevel} (${carLabel})`,
                    amount: -cost,
                    date: new Date().toISOString(),
                    type: 'UPGRADE'
                });
            });

            // Success notification
            await notificationStore.addNotification({
                title: "Car Updated",
                message: `Upgraded ${partKey} to LVL ${currentLevel + 1} on ${carIndex === 0 ? 'Car A' : 'Car B'}.`,
                type: 'SUCCESS',
                actionRoute: '/management/engineering'
            });
        }
    };
}

export const carStore = createCarStore();
