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
import {
    ACADEMY_PURCHASE_COST,
    ACADEMY_MAINTENANCE_COST,
    ACADEMY_TRAINEE_WEEKLY_SALARY,
    ACADEMY_UPGRADE_COST_MULTIPLIER,
    ACADEMY_INTENSIVE_TRAINING_COST,
    FACILITY_ROLE_DISCOUNT,
} from '$lib/constants/economics';
import { getFlagEmoji } from '$lib/utils/country';
import { academyService } from '$lib/services/academy.svelte';

export function createYouthAcademyStore() {
    let config = $state<any>(null);
    let candidates = $state<YoungDriver[]>([]);
    let selectedDrivers = $state<YoungDriver[]>([]);
    let loading = $state(true);
    let initializedTeamId: string | null = null;

    let unsubscribeConfig: (() => void) | null = null;
    let unsubscribeCandidates: (() => void) | null = null;
    let unsubscribeSelected: (() => void) | null = null;

    function init(teamId: string | null) {
        if (!teamId || !browser) {
            loading = false;
            return;
        }

        if (initializedTeamId === teamId) return;

        console.debug(`📡 YouthAcademyStore: Initializing for Team ${teamId}`);
        clear();

        initializedTeamId = teamId;
        loading = true;

        // Stream config
        const configRef = doc(db, 'teams', teamId, 'academy', 'config');
        unsubscribeConfig = onSnapshot(configRef, (snapshot) => {
            if (snapshot.exists()) {
                config = snapshot.data();

                // Self-heal: if the academy has been upgraded (level > 1) but
                // lastUpgradeSeasonId is null due to a prior bug in upgradeAcademy(),
                // write the current season ID silently so canUpgrade returns correctly.
                const seasonId = seasonStore.value.season?.id ?? null;
                if (seasonId && (config.academyLevel ?? 0) > 1 && !config.lastUpgradeSeasonId) {
                    const teamRef = doc(db, 'teams', teamId);
                    updateDoc(configRef, { lastUpgradeSeasonId: seasonId });
                    updateDoc(teamRef, { 'facilities.youthAcademy.lastUpgradeSeasonId': seasonId });
                    console.debug('[YouthAcademyStore] Repaired null lastUpgradeSeasonId →', seasonId);
                }
            } else {
                config = null;
            }
            loading = false;
            console.debug('✅ YouthAcademyStore: Config loaded');
        });

        // Stream candidates
        const candidatesRef = collection(db, 'teams', teamId, 'academy', 'config', 'candidates');
        unsubscribeCandidates = onSnapshot(candidatesRef, (snapshot) => {
            candidates = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            } as YoungDriver));
        });

        // Stream selected
        const selectedRef = collection(db, 'teams', teamId, 'academy', 'config', 'selected');
        unsubscribeSelected = onSnapshot(selectedRef, (snapshot) => {
            selectedDrivers = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            } as YoungDriver));
        });
    }

    function clear() {
        if (unsubscribeConfig) unsubscribeConfig();
        if (unsubscribeCandidates) unsubscribeCandidates();
        if (unsubscribeSelected) unsubscribeSelected();
        unsubscribeConfig = null;
        unsubscribeCandidates = null;
        unsubscribeSelected = null;
        initializedTeamId = null;
        config = null;
        candidates = [];
        selectedDrivers = [];
        loading = false;
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
        const isLocked = teamStore.value.team?.facilities?.youthAcademy?.isLocked === true;
        return config.academyLevel < 5 && !isLocked;
    });

    return {
        get config() { return config; },
        get candidates() { return candidates; },
        get selectedDrivers() { return selectedDrivers; },
        get loading() { return loading; },
        get maxSlots() { return maxSlots; },
        get scoutingQuota() { return scoutingQuota; },
        get i18n_currentSeasonId() { return seasonStore.value.season?.id || teamStore.value.team?.currentSeasonId || null; },
        get canUpgrade() { return canUpgrade; },
        init,

        async purchaseAcademy(country: { code: string, name: string, flagEmoji?: string }) {
            const teamId = teamStore.value.team?.id;
            const currentSeasonId = seasonStore.value.season?.id || teamStore.value.team?.currentSeasonId || null;

            console.debug('YouthAcademyStore: Attempting purchase...', { teamId, currentSeasonId });

            if (!teamId) throw new Error("Team context missing. Please try again.");

            const purchasePrice = ACADEMY_PURCHASE_COST;
            const teamRef = doc(db, 'teams', teamId);
            const configRef = doc(db, 'teams', teamId, 'academy', 'config');

            await runTransaction(db, async (transaction) => {
                const teamSnap = await transaction.get(teamRef);
                if (!teamSnap.exists()) throw new Error("Team record not found in database.");

                const data = teamSnap.data();
                if (!data || (data.budget ?? 0) < purchasePrice) throw new Error(`Insufficient budget. Required: $10,000. Available: $${((data?.budget ?? 0) / 1000).toFixed(0)}k`);
                const budget = data.budget ?? 0;

                // Read seasonId from the team document (authoritative, avoids store timing issues)
                const resolvedSeasonId = data?.currentSeasonId || currentSeasonId || null;

                transaction.set(configRef, {
                    countryCode: country.code,
                    countryName: country.name,
                    countryFlag: country.flagEmoji || getFlagEmoji(country.code),
                    academyLevel: 1,
                    scoutsUsedThisSeason: 2,
                    lastUpgradeSeasonId: resolvedSeasonId,
                    createdAt: serverTimestamp()
                });

                // Generate initial batch of candidates (Level 1, 1M, 1F)
                const initialCandidates = academyService.generateInitialCandidates(2, country.code, 1);
                initialCandidates.forEach(candidate => {
                    const candidateRef = doc(db, 'teams', teamId, 'academy', 'config', 'candidates', candidate.id);
                    transaction.set(candidateRef, candidate);
                });

                transaction.update(teamRef, {
                    budget: budget - purchasePrice,
                    [`facilities.youthAcademy`]: {
                        type: 'youthAcademy',
                        level: 1,
                        isLocked: false,
                        maintenanceCost: ACADEMY_MAINTENANCE_COST,
                        lastUpgradeSeasonId: resolvedSeasonId
                    }
                });

                // Record transaction
                const txRef = doc(collection(db, 'teams', teamId, 'transactions'));
                transaction.set(txRef, {
                    id: txRef.id,
                    description: `Academy Establishment: ${country.name}`,
                    amount: -purchasePrice,
                    date: new Date().toISOString(),
                    type: 'UPGRADE'
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
            // Read season ID from store before the transaction — this is the authoritative value
            // used by canUpgrade, so it must match exactly what is stored.
            const resolvedSeasonId = seasonStore.value.season?.id ?? null;
            if (!teamId || !config || !resolvedSeasonId) return;

            if (config.academyLevel >= 5) throw new Error("Maximum level reached");
            if (config.lastUpgradeSeasonId === resolvedSeasonId) throw new Error("Already upgraded this season");

            const upgradePrice = ACADEMY_UPGRADE_COST_MULTIPLIER * config.academyLevel;
            const role = managerStore.profile?.role;
            const finalPrice = (role === 'business' || role === 'bureaucrat') ? Math.round(upgradePrice * FACILITY_ROLE_DISCOUNT) : upgradePrice;

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
                    lastUpgradeSeasonId: resolvedSeasonId
                });

                transaction.update(teamRef, {
                    budget: budget - finalPrice,
                    [`facilities.youthAcademy.level`]: newLevel,
                    [`facilities.youthAcademy.lastUpgradeSeasonId`]: resolvedSeasonId,
                    [`facilities.youthAcademy.isLocked`]: true
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
            const configRef = doc(db, 'teams', teamId, 'academy', 'config');
            const candidateRef = doc(db, 'teams', teamId, 'academy', 'config', 'candidates', candidateId);
            const selectedRef = doc(db, 'teams', teamId, 'academy', 'config', 'selected', candidateId);

            await runTransaction(db, async (transaction) => {
                const teamSnap = await transaction.get(teamRef);
                const data = teamSnap.data();
                const salary = candidate.salary ?? ACADEMY_TRAINEE_WEEKLY_SALARY;
                if (!data || (data.budget ?? 0) < salary) throw new Error("Insufficient budget for hiring");
                const budget = data.budget ?? 0;

                transaction.set(selectedRef, {
                    ...candidate,
                    status: 'selected',
                    selectedAt: serverTimestamp()
                });
                transaction.delete(candidateRef);
                transaction.update(configRef, {
                    scoutsUsedThisSeason: increment(1)
                });
                transaction.update(teamRef, { budget: budget - salary });
            });

            // Generate a replacement candidate so the scouting pool stays populated
            const [replacement] = academyService.generateInitialCandidates(1, config.countryCode, config.academyLevel);
            const replacementRef = doc(db, 'teams', teamId, 'academy', 'config', 'candidates', replacement.id);
            await setDoc(replacementRef, replacement);

            notificationStore.addNotification({
                title: "Driver Signed",
                message: `${candidate.name} is now training at the academy.`,
                type: "SUCCESS"
            });
        },

        async solveAcademyAction(driverId: string, decision: 'resolve' | 'dismiss') {
            const teamId = teamStore.value.team?.id;
            if (!teamId) return;

            const driverRef = doc(db, 'teams', teamId, 'academy', 'config', 'selected', driverId);
            const driver = selectedDrivers.find(d => d.id === driverId);
            const type = driver?.pendingActionType || 'GENERAL';

            // INTENSIVE_TRAINING with resolve requires a budget transaction
            if (decision === 'resolve' && type === 'INTENSIVE_TRAINING') {
                const intensiveCost = ACADEMY_INTENSIVE_TRAINING_COST;
                const teamRef = doc(db, 'teams', teamId);
                const allSkills = ['braking', 'cornering', 'smoothness', 'overtaking', 'consistency', 'adaptability', 'focus'] as const;
                const diffs: Record<string, number> = Object.fromEntries(allSkills.map(s => [s, 1]));
                const message = `Intensive training week completed. All skills improved at a cost of $${(intensiveCost / 1000).toFixed(0)}k.`;

                await runTransaction(db, async (transaction) => {
                    const teamSnap = await transaction.get(teamRef);
                    const teamData = teamSnap.data();
                    if (!teamData || (teamData.budget ?? 0) < intensiveCost) {
                        throw new Error(`Insufficient budget for intensive training. Required: $${intensiveCost.toLocaleString()}`);
                    }
                    const budget = teamData.budget ?? 0;

                    const newMin = { ...driver?.statRangeMin };
                    const newMax = { ...driver?.statRangeMax };
                    const statsUpdates: Record<string, any> = {};
                    for (const key of allSkills) {
                        newMin[key] = Math.min(20, Math.max(1, (newMin[key] || 8) + 1));
                        newMax[key] = Math.min(20, Math.max(1, (newMax[key] || 10) + 1));
                        statsUpdates[`stats.${key}`] = increment(1);
                    }

                    transaction.update(driverRef, {
                        pendingAction: false,
                        weeklyEventMessage: message,
                        weeklyStatDiffs: diffs,
                        statRangeMin: newMin,
                        statRangeMax: newMax,
                        ...statsUpdates
                    });

                    transaction.update(teamRef, { budget: budget - intensiveCost });

                    const txRef = doc(collection(db, 'teams', teamId, 'transactions'));
                    transaction.set(txRef, {
                        id: txRef.id,
                        description: `Intensive Training: ${driver?.name || 'Academy Driver'}`,
                        amount: -intensiveCost,
                        date: new Date().toISOString(),
                        type: 'TRAINING'
                    });
                });

                notificationStore.addNotification({
                    title: 'Intensive Training Complete',
                    message: `${driver?.name || 'Driver'}: all skills +1. Cost: $25k.`,
                    type: 'SUCCESS'
                });
                return;
            }

            let message = "The driver successfully completed the requested flow.";
            let diffs: Record<string, number> = {};

            if (decision === 'resolve') {
                switch(type) {
                    case 'SPONSOR_SHOOT':
                        diffs = { focus: -1, adaptability: 1 };
                        message = "The sponsor shoot raised adaptability, but cost some focus.";
                        break;
                    case 'TECHNICAL_TEST':
                        diffs = { cornering: 1, focus: -1 };
                        message = "Intense technical testing improved cornering but left the driver mentally drained.";
                        break;
                    case 'MENTOR_REQUEST':
                        const stats = ['consistency', 'smoothness', 'focus', 'adaptability'];
                        const randomStat = stats[Math.floor(Math.random() * stats.length)];
                        diffs = { [randomStat]: 1 };
                        message = `A mentorship session yielded great improvements in ${randomStat}.`;
                        break;
                    case 'MEDIA_TRAINING':
                        diffs = { focus: 1, adaptability: 1 };
                        message = "Media training improved both focus and adaptability.";
                        break;
                    case 'FITNESS_BOOTCAMP':
                        diffs = { consistency: 2, focus: -1 };
                        message = "The intense bootcamp built physical endurance, improving consistency though the driver is mentally tired.";
                        break;
                    default:
                        // Generic reward based on what the driver needs most? 
                        // For now just focus + another random stat
                        const allStats = ['braking', 'cornering', 'smoothness', 'overtaking', 'consistency', 'adaptability', 'focus'];
                        const secondStat = allStats[Math.floor(Math.random() * allStats.length)];
                        diffs = { focus: 1, [secondStat]: 1 };
                        message = "The driver successfully completed the requested flow and gained valuable experience.";
                }
            } else if (decision === 'dismiss') {
                if (type === 'INTENSIVE_TRAINING') {
                    message = "Intensive training was declined. The driver feels unmotivated.";
                } else {
                    message = "The matter was dismissed. The driver feels ignored.";
                }
                diffs = { focus: -1 };
            }

            const updates: any = {
                pendingAction: false,
                weeklyEventMessage: message,
                weeklyStatDiffs: diffs
            };

            if (driver && Object.keys(diffs).length > 0) {
                const newMin = { ...driver.statRangeMin };
                const newMax = { ...driver.statRangeMax };
                
                for (const [key, value] of Object.entries(diffs)) {
                    const isPercentage = key === 'fitness' || key === 'morale';
                    const maxVal = isPercentage ? 100 : 20;
                    newMin[key] = Math.min(maxVal, Math.max(1, (newMin[key] || (isPercentage ? 70 : 8)) + value));
                    newMax[key] = Math.min(maxVal, Math.max(1, (newMax[key] || (isPercentage ? 80 : 10)) + value));
                    updates[`stats.${key}`] = increment(value);
                }
                updates.statRangeMin = newMin;
                updates.statRangeMax = newMax;
            }

            await updateDoc(driverRef, updates);

            notificationStore.addNotification({
                title: `${driver?.name || 'Driver'} Action`,
                message: message,
                type: "INFO"
            });
        },

        async dismissCandidate(candidateId: string) {
            const teamId = teamStore.value.team?.id;
            if (!teamId || !config) return;
            const candidateRef = doc(db, 'teams', teamId, 'academy', 'config', 'candidates', candidateId);
            await deleteDoc(candidateRef);

            // Generate one replacement candidate to keep the scouting pool populated
            const [replacement] = academyService.generateInitialCandidates(1, config.countryCode, config.academyLevel);
            const replacementRef = doc(db, 'teams', teamId, 'academy', 'config', 'candidates', replacement.id);
            await setDoc(replacementRef, replacement);
        },

        async releaseDriver(driverId: string) {
            const teamId = teamStore.value.team?.id;
            if (!teamId || !config) return;
            const driverRef = doc(db, 'teams', teamId, 'academy', 'config', 'selected', driverId);
            await deleteDoc(driverRef);

            // Return a fresh candidate to the scouting pool
            const [replacement] = academyService.generateInitialCandidates(1, config.countryCode, config.academyLevel);
            const candidateRef = doc(db, 'teams', teamId, 'academy', 'config', 'candidates', replacement.id);
            await setDoc(candidateRef, replacement);

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
