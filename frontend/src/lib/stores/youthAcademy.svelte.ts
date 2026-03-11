import { db } from '$lib/firebase/config';
import {
    doc,
    collection,
    onSnapshot,
    runTransaction,
    serverTimestamp,
    deleteDoc,
    setDoc,
    updateDoc,
    increment
} from 'firebase/firestore';
import { browser } from '$app/environment';
import { teamStore } from './team.svelte';
import { managerStore } from './manager.svelte';
import { notificationStore } from './notifications.svelte';
import { seasonStore } from './season.svelte';
import { driverStore } from './driver.svelte';
import type { YoungDriver } from '$lib/types';
import { untrack } from 'svelte';

export function createYouthAcademyStore() {
    let config = $state<any>(null);
    let candidates = $state<YoungDriver[]>([]);
    let selectedDrivers = $state<YoungDriver[]>([]);
    let loading = $state(true);
    let initializedTeamId: string | null = null;

    function init() {
        // Use an effect that tracks the teamId specifically
        $effect(() => {
            const teamId = teamStore.value.team?.id;

            // Only proceed if we have a valid teamId and we are in the browser
            if (!teamId || !browser) {
                untrack(() => { loading = false; });
                return;
            }

            // Guard against re-initializing for the same team
            if (untrack(() => initializedTeamId === teamId)) return;

            console.log(`📡 YouthAcademyStore: Initializing for Team ${teamId}`);

            untrack(() => {
                initializedTeamId = teamId;
                loading = true;
            });

            // Stream config
            const configRef = doc(db, 'teams', teamId, 'academy', 'config');
            const unsubscribeConfig = onSnapshot(configRef, (snapshot) => {
                untrack(() => {
                    if (snapshot.exists()) {
                        config = snapshot.data();
                    } else {
                        config = null;
                    }
                    loading = false;
                    console.log('✅ YouthAcademyStore: Config loaded');
                });
            });

            // Stream candidates
            const candidatesRef = collection(db, 'teams', teamId, 'academy', 'config', 'candidates');
            const unsubscribeCandidates = onSnapshot(candidatesRef, (snapshot) => {
                untrack(() => {
                    candidates = snapshot.docs.map(doc => ({
                        id: doc.id,
                        ...doc.data()
                    } as YoungDriver));
                });
            });

            // Stream selected
            const selectedRef = collection(db, 'teams', teamId, 'academy', 'config', 'selected');
            const unsubscribeSelected = onSnapshot(selectedRef, (snapshot) => {
                untrack(() => {
                    selectedDrivers = snapshot.docs.map(doc => ({
                        id: doc.id,
                        ...doc.data()
                    } as YoungDriver));
                });
            });

            return () => {
                console.log(`🧹 YouthAcademyStore: Cleaning up for Team ${teamId}`);
                unsubscribeConfig();
                unsubscribeCandidates();
                unsubscribeSelected();
                untrack(() => { initializedTeamId = null; });
            };
        });
    }

    // Dynamic Getters for product rules
    const maxSlots = $derived.by(() => {
        if (!config) return 0;
        const level = config.academyLevel || 1;
        const base = 4 + (level - 1);
        const bonus = (managerStore.profile?.role === 'bureaucrat') ? (level * 2) : 0;
        return base + bonus;
    });

    const scoutingQuota = $derived.by(() => {
        if (!config) return 0;
        return 20 + (config.academyLevel - 1) * 5;
    });

    const canUpgrade = $derived.by(() => {
        if (!config || !seasonStore.value.season) return false;
        return config.academyLevel < 5 && config.lastUpgradeSeasonId !== seasonStore.value.season.id;
    });

    return {
        get config() { return config; },
        get candidates() { return candidates; },
        get selectedDrivers() { return selectedDrivers; },
        get loading() { return loading; },
        get maxSlots() { return maxSlots; },
        get scoutingQuota() { return scoutingQuota; },
        get canUpgrade() { return canUpgrade; },
        init,

        async purchaseAcademy(country: { code: string, name: string, flagEmoji: string }) {
            const teamId = teamStore.value.team?.id;
            const currentSeasonId = seasonStore.value.season?.id || teamStore.value.team?.currentSeasonId || null;

            console.log('YouthAcademyStore: Attempting purchase...', { teamId, currentSeasonId });

            if (!teamId) throw new Error("Team context missing. Please try again.");

            const purchasePrice = 10000;
            const teamRef = doc(db, 'teams', teamId);
            const configRef = doc(db, 'teams', teamId, 'academy', 'config');

            await runTransaction(db, async (transaction) => {
                const teamSnap = await transaction.get(teamRef);
                if (!teamSnap.exists()) throw new Error("Team record not found in database.");

                const data = teamSnap.data();
                if (!data || (data.budget ?? 0) < purchasePrice) throw new Error(`Insufficient budget. Required: $10,000. Available: $${((data?.budget ?? 0) / 1000).toFixed(0)}k`);
                const budget = data.budget ?? 0;

                transaction.set(configRef, {
                    countryCode: country.code,
                    countryName: country.name,
                    countryFlag: country.flagEmoji,
                    academyLevel: 1,
                    scoutsUsedThisSeason: 2, // Initial generation count
                    lastUpgradeSeasonId: currentSeasonId,
                    createdAt: serverTimestamp()
                });

                transaction.update(teamRef, {
                    budget: budget - purchasePrice,
                    [`facilities.youthAcademy`]: {
                        type: 'youthAcademy',
                        level: 1,
                        isLocked: false,
                        maintenanceCost: 15000,
                        lastUpgradeSeasonId: currentSeasonId
                    }
                });
            });

            notificationStore.addNotification({
                title: "Academy Built",
                message: `Youth Academy established in ${country.name}.`,
                type: "SUCCESS"
            });
        },

        async upgradeAcademy() {
            const teamId = teamStore.value.team?.id;
            const currentSeasonId = seasonStore.value.season?.id || teamStore.value.team?.currentSeasonId || null;
            if (!teamId || !config) return;

            if (config.academyLevel >= 5) throw new Error("Maximum level reached");
            if (currentSeasonId && config.lastUpgradeSeasonId === currentSeasonId) throw new Error("Already upgraded this season");

            const upgradePrice = 1000000 * config.academyLevel;
            const role = managerStore.profile?.role;
            const finalPrice = (role === 'businessAdmin' || role === 'bureaucrat') ? Math.round(upgradePrice * 0.9) : upgradePrice;

            const teamRef = doc(db, 'teams', teamId);
            const configRef = doc(db, 'teams', teamId, 'academy', 'config');

            await runTransaction(db, async (transaction) => {
                const teamSnap = await transaction.get(teamRef);
                const data = teamSnap.data();
                if (!data || (data.budget ?? 0) < finalPrice) throw new Error("Insufficient budget");
                const budget = data.budget ?? 0;

                const newLevel = config.academyLevel + 1;

                transaction.update(configRef, {
                    academyLevel: newLevel,
                    lastUpgradeSeasonId: currentSeasonId
                });

                transaction.update(teamRef, {
                    budget: budget - finalPrice,
                    [`facilities.youthAcademy.level`]: newLevel,
                    [`facilities.youthAcademy.lastUpgradeSeasonId`]: currentSeasonId
                });
            });

            notificationStore.addNotification({
                title: "Academy Upgraded",
                message: `Youth Academy improved to Level ${config.academyLevel + 1}.`,
                type: "SUCCESS"
            });
        },

        async selectCandidate(candidateId: string) {
            const teamId = teamStore.value.team?.id;
            if (!teamId || !config) return;

            const candidate = candidates.find(c => c.id === candidateId);
            if (!candidate) throw new Error("Candidate not found");

            if (selectedDrivers.length >= maxSlots) {
                throw new Error("Academy roster is full");
            }

            const teamRef = doc(db, 'teams', teamId);
            const candidateRef = doc(db, 'teams', teamId, 'academy', 'config', 'candidates', candidateId);
            const selectedRef = doc(db, 'teams', teamId, 'academy', 'config', 'selected', candidateId);

            await runTransaction(db, async (transaction) => {
                const teamSnap = await transaction.get(teamRef);
                const data = teamSnap.data();
                const salary = candidate.salary ?? 10000;
                if (!data || (data.budget ?? 0) < salary) throw new Error("Insufficient budget for hiring");
                const budget = data.budget ?? 0;

                transaction.set(selectedRef, {
                    ...candidate,
                    status: 'selected',
                    selectedAt: serverTimestamp()
                });
                transaction.delete(candidateRef);
                transaction.update(config, {
                    scoutsUsedThisSeason: increment(1)
                });
                transaction.update(teamRef, { budget: budget - salary });
            });

            notificationStore.addNotification({
                title: "Driver Signed",
                message: `${candidate.name} is now training at the academy.`,
                type: "SUCCESS"
            });
        },

        async solveAcademyAction(driverId: string, decision: string) {
            const teamId = teamStore.value.team?.id;
            if (!teamId) return;

            const driverRef = doc(db, 'teams', teamId, 'academy', 'config', 'selected', driverId);

            await updateDoc(driverRef, {
                pendingAction: false,
                weeklyEventMessage: `Resolved: ${decision}`
            });

            notificationStore.addNotification({
                title: "Decision Made",
                message: "Your choice has been recorded.",
                type: "INFO"
            });
        },

        async dismissCandidate(candidateId: string) {
            const teamId = teamStore.value.team?.id;
            if (!teamId) return;
            const candidateRef = doc(db, 'teams', teamId, 'academy', 'config', 'candidates', candidateId);
            await deleteDoc(candidateRef);
        },

        async releaseDriver(driverId: string) {
            const teamId = teamStore.value.team?.id;
            if (!teamId) return;
            const driverRef = doc(db, 'teams', teamId, 'academy', 'config', 'selected', driverId);
            await deleteDoc(driverRef);

            notificationStore.addNotification({
                title: "Driver Released",
                message: "Driver removed from the academy program.",
                type: "INFO"
            });
        },

        async togglePromotion(driverId: string, isMarked: boolean) {
            const teamId = teamStore.value.team?.id;
            if (!teamId) return;

            const driverRef = doc(db, 'teams', teamId, 'academy', 'config', 'selected', driverId);

            if (isMarked) {
                const coreDriversCount = driverStore.drivers.length;
                if (coreDriversCount >= 5) {
                    throw new Error("Team roster is full (Max 5 drivers). Cannot promote more.");
                }

                for (const d of selectedDrivers) {
                    if (d.isMarkedForPromotion && d.id !== driverId) {
                        await updateDoc(doc(db, 'teams', teamId, 'academy', 'config', 'selected', d.id), {
                            isMarkedForPromotion: false
                        });
                    }
                }
            }

            await updateDoc(driverRef, { isMarkedForPromotion: isMarked });
        }
    };
}

export const youthAcademyStore = createYouthAcademyStore();
