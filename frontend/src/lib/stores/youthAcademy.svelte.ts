import { db } from '$lib/firebase/config';
import {
    doc,
    collection,
    onSnapshot,
    query,
    orderBy,
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
import type { YoungDriver } from '$lib/types';

export function createYouthAcademyStore() {
    let config = $state<any>(null);
    let candidates = $state<YoungDriver[]>([]);
    let selectedDrivers = $state<YoungDriver[]>([]);
    let loading = $state(true);

    function init() {
        $effect(() => {
            const teamId = teamStore.value.team?.id;
            if (!teamId || !browser) return;

            loading = true;

            // Stream config
            const configRef = doc(db, 'teams', teamId, 'academy', 'config');
            const unsubscribeConfig = onSnapshot(configRef, (snapshot) => {
                if (snapshot.exists()) {
                    config = snapshot.data();
                } else {
                    config = null;
                }
                loading = false;
            });

            // Stream candidates
            const candidatesRef = collection(db, 'teams', teamId, 'academy', 'config', 'candidates');
            const unsubscribeCandidates = onSnapshot(candidatesRef, (snapshot) => {
                candidates = snapshot.docs.map(doc => ({
                    id: doc.id,
                    ...doc.data()
                } as YoungDriver));
            });

            // Stream selected
            const selectedRef = collection(db, 'teams', teamId, 'academy', 'config', 'selected');
            const unsubscribeSelected = onSnapshot(selectedRef, (snapshot) => {
                selectedDrivers = snapshot.docs.map(doc => ({
                    id: doc.id,
                    ...doc.data()
                } as YoungDriver));
            });

            return () => {
                unsubscribeConfig();
                unsubscribeCandidates();
                unsubscribeSelected();
            };
        });
    }

    return {
        get config() { return config; },
        get candidates() { return candidates; },
        get selectedDrivers() { return selectedDrivers; },
        get loading() { return loading; },
        init,

        async purchaseAcademy(country: { code: string, name: string, flagEmoji: string }) {
            const teamId = teamStore.value.team?.id;
            if (!teamId) return;

            const purchasePrice = 100000;
            const role = managerStore.profile?.role;

            const teamRef = doc(db, 'teams', teamId);
            const configRef = doc(db, 'teams', teamId, 'academy', 'config');

            await runTransaction(db, async (transaction) => {
                const teamSnap = await transaction.get(teamRef);
                if (!teamSnap.exists()) throw new Error("Team not found");

                const data = teamSnap.data();
                if (!data || (data.budget ?? 0) < purchasePrice) throw new Error("Insufficient budget");
                const budget = data.budget ?? 0;

                let maxSlots = 4;
                if (role === 'bureaucrat') maxSlots += 2;

                transaction.set(configRef, {
                    countryCode: country.code,
                    countryName: country.name,
                    countryFlag: country.flagEmoji,
                    academyLevel: 1,
                    maxSlots,
                    scoutsUsedThisSeason: 0,
                    createdAt: serverTimestamp()
                });

                transaction.update(teamRef, {
                    budget: budget - purchasePrice,
                    [`facilities.youthAcademy`]: {
                        type: 'youthAcademy',
                        level: 1,
                        isLocked: false,
                        maintenanceCost: 5000
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
            if (!teamId || !config) return;

            const currentLevel = config.academyLevel;
            if (currentLevel >= 5) throw new Error("Maximum level reached");

            const upgradePrice = 1000000 * currentLevel;
            const role = managerStore.profile?.role;
            const finalPrice = (role === 'businessAdmin' || role === 'bureaucrat') ? upgradePrice * 0.9 : upgradePrice;

            const teamRef = doc(db, 'teams', teamId);
            const configRef = doc(db, 'teams', teamId, 'academy', 'config');

            await runTransaction(db, async (transaction) => {
                const teamSnap = await transaction.get(teamRef);
                const data = teamSnap.data();
                if (!data || (data.budget ?? 0) < finalPrice) throw new Error("Insufficient budget");
                const budget = data.budget ?? 0;

                const newLevel = currentLevel + 1;
                let maxSlots = 4 + (newLevel - 1);
                if (role === 'bureaucrat') maxSlots += (newLevel * 2);

                transaction.update(configRef, {
                    academyLevel: newLevel,
                    maxSlots,
                    lastUpgradeAt: serverTimestamp()
                });

                transaction.update(teamRef, {
                    budget: budget - finalPrice,
                    [`facilities.youthAcademy.level`]: newLevel,
                    [`facilities.youthAcademy.maintenanceCost`]: 5000 * newLevel
                });
            });

            notificationStore.addNotification({
                title: "Academy Upgraded",
                message: `Youth Academy is now Level ${currentLevel + 1}.`,
                type: "SUCCESS"
            });
        },

        async selectCandidate(candidateId: string) {
            const teamId = teamStore.value.team?.id;
            if (!teamId || !config) return;

            const candidate = candidates.find(c => c.id === candidateId);
            if (!candidate) throw new Error("Candidate not found");

            if (selectedDrivers.length >= config.maxSlots) {
                throw new Error("Academy roster is full");
            }

            const teamRef = doc(db, 'teams', teamId);
            const candidateRef = doc(db, 'teams', teamId, 'academy', 'config', 'candidates', candidateId);
            const selectedRef = doc(db, 'teams', teamId, 'academy', 'config', 'selected', candidateId);
            const configRef = doc(db, 'teams', teamId, 'academy', 'config');

            await runTransaction(db, async (transaction) => {
                const teamSnap = await transaction.get(teamRef);
                const data = teamSnap.data();
                if (!data || (data.budget ?? 0) < (candidate.salary ?? 0)) throw new Error("Insufficient budget for signing bonus");
                const budget = data.budget ?? 0;

                transaction.set(selectedRef, {
                    ...candidate,
                    status: 'selected',
                    selectedAt: serverTimestamp()
                });
                transaction.delete(candidateRef);
                transaction.update(teamRef, { budget: budget - candidate.salary });
                transaction.update(configRef, { scoutsUsedThisSeason: increment(1) });
            });

            notificationStore.addNotification({
                title: "Driver Signed",
                message: `${candidate.name} joined the academy.`,
                type: "SUCCESS"
            });
        },

        async dismissCandidate(candidateId: string) {
            const teamId = teamStore.value.team?.id;
            if (!teamId) return;

            const candidateRef = doc(db, 'teams', teamId, 'academy', 'config', 'candidates', candidateId);
            const configRef = doc(db, 'teams', teamId, 'academy', 'config');

            await runTransaction(db, async (transaction) => {
                transaction.delete(candidateRef);
                transaction.update(configRef, { scoutsUsedThisSeason: increment(1) });
            });
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
                // Unmark all others
                const otherPromoted = selectedDrivers.find(d => d.isMarkedForPromotion && d.id !== driverId);
                if (otherPromoted) {
                    await updateDoc(doc(db, 'teams', teamId, 'academy', 'config', 'selected', otherPromoted.id), {
                        isMarkedForPromotion: false
                    });
                }
            }

            await updateDoc(driverRef, { isMarkedForPromotion: isMarked });
        }
    };
}

export const youthAcademyStore = createYouthAcademyStore();
