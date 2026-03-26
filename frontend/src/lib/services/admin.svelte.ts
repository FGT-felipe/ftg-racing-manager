import { db } from '$lib/firebase/config';
import {
    collection,
    getDocs,
    writeBatch,
    doc,
    deleteDoc,
    query,
    collectionGroup,
    serverTimestamp,
    addDoc,
    setDoc,
    getDoc,
    where,
    updateDoc,
    limit
} from 'firebase/firestore';
import {
    BUDGET_REBALANCE_THRESHOLD_HIGH,
    BUDGET_REBALANCE_THRESHOLD_LOW,
    BUDGET_REBALANCE_REDUCTION_RATE,
} from '$lib/constants/economics';

export const adminService = {
    /**
     * DANGEROUS: Port of DatabaseSeeder.nukeAndReseed
     * Wipes historical data and resets the universe.
     */
    async nukeAndReseed() {
        try {
            // 1. Delete Universe
            await deleteDoc(doc(db, 'universe', 'game_universe_v1'));

            // 2. Clear Collection Groups (Drivers, Press News)
            const collectionGroups = ['drivers', 'press_news'];
            for (const cg of collectionGroups) {
                const snap = await getDocs(query(collectionGroup(db, cg)));
                if (!snap.empty) {
                    const batch = writeBatch(db);
                    snap.docs.forEach(d => batch.delete(d.ref));
                    await batch.commit();
                }
            }

            // 3. Clear Standalone Collections
            const collections = [
                'teams',
                'leagues',
                'seasons',
                'divisions',
                'races',
                'driver_titles',
                'managers'
            ];

            for (const col of collections) {
                const snap = await getDocs(collection(db, col));
                if (!snap.empty) {
                    const batch = writeBatch(db);
                    snap.docs.forEach(d => batch.delete(d.ref));
                    await batch.commit();
                }
            }

            return true;
        } catch (e: any) {
            console.error('Admin operation failed:', e.message || 'Unknown error');
            throw e;
        }
    },

    /**
     * Port of MaintenanceService.fixRaceCalendars
     * Synchronizes calendars with the absolute truth from ftg_world.
     */
    async fixRaceCalendars() {
        const worldSeasonId = '3sh7fStGc55XxwmQHaJu';
        const targetSeasons = {
            'ftg_2th': 'Py9vb4IrLJGZPDCCCUkG',
            'ftg_karting': 'qRM0nhyt95JGXqgxLtnT',
        };

        try {
            const worldDoc = await getDoc(doc(db, 'seasons', worldSeasonId));
            if (!worldDoc.exists()) throw new Error('Reference world season not found');

            const worldData = worldDoc.data();
            const referenceMap = new Map();
            worldData.calendar.forEach((race: any) => {
                referenceMap.set(race.circuitId, race);
            });

            for (const [leagueId, seasonId] of Object.entries(targetSeasons)) {
                const seasonDoc = await getDoc(doc(db, 'seasons', seasonId));
                if (!seasonDoc.exists()) continue;

                const seasonData = seasonDoc.data();
                const calendar = [...seasonData.calendar];
                let changed = false;

                for (let i = 0; i < calendar.length; i++) {
                    const race = calendar[i];
                    if (race.isCompleted) continue;

                    const ref = referenceMap.get(race.circuitId);
                    if (!ref) continue;

                    if (race.totalLaps !== ref.totalLaps ||
                        race.weatherQualifying !== ref.weatherQualifying ||
                        race.weatherRace !== ref.weatherRace) {

                        calendar[i] = {
                            ...race,
                            totalLaps: ref.totalLaps,
                            weatherQualifying: ref.weatherQualifying,
                            weatherRace: ref.weatherRace
                        };
                        changed = true;
                    }
                }

                if (changed) {
                    await updateDoc(doc(db, 'seasons', seasonId), { calendar });
                }
            }
            return true;
        } catch (e: any) {
            console.error('Calendar sync failed:', e.message || 'Unknown error');
            throw e;
        }
    },

    /**
     * Port of FinanceService.applyGreatRebalanceTax
     */
    async applyGreatRebalanceTax() {
        try {
            const teamsSnap = await getDocs(collection(db, 'teams'));
            let batch = writeBatch(db);
            let opCount = 0;

            for (const tDoc of teamsSnap.docs) {
                const teamData = tDoc.data();
                const currentBudget = teamData.budget || 0;
                let newBudget = currentBudget;

                if (currentBudget > BUDGET_REBALANCE_THRESHOLD_HIGH) {
                    newBudget = BUDGET_REBALANCE_THRESHOLD_HIGH + Math.floor((currentBudget - BUDGET_REBALANCE_THRESHOLD_HIGH) * BUDGET_REBALANCE_REDUCTION_RATE);
                } else if (currentBudget < BUDGET_REBALANCE_THRESHOLD_LOW) {
                    newBudget = BUDGET_REBALANCE_THRESHOLD_LOW;
                }

                if (newBudget !== currentBudget) {
                    const txRef = doc(collection(db, 'teams', tDoc.id, 'transactions'));
                    batch.set(txRef, {
                        id: txRef.id,
                        description: 'Great Economic Rebalance 2026',
                        amount: newBudget - currentBudget,
                        date: new Date().toISOString(),
                        type: 'TAX'
                    });
                    opCount++;
                }

                const weekStatus = { ...(teamData.weekStatus || {}) };
                weekStatus.sponsorNegotiations = {};

                batch.update(tDoc.ref, {
                    budget: newBudget,
                    sponsors: {},
                    weekStatus
                });
                opCount++;

                const notifRef = doc(collection(db, 'teams', tDoc.id, 'notifications'));
                batch.set(notifRef, {
                    teamId: tDoc.id,
                    title: 'Economic Rebalance',
                    message: `The Racing Federation has applied an economic rebalance. Your budget is now $${(newBudget / 1000000).toFixed(1)}M. Previous sponsors have been terminated.`,
                    type: 'INFO',
                    timestamp: serverTimestamp()
                });
                opCount++;

                if (opCount >= 450) {
                    await batch.commit();
                    batch = writeBatch(db);
                    opCount = 0;
                }
            }

            if (opCount > 0) await batch.commit();
            return true;
        } catch (e: any) {
            console.error('Rebalance operation failed:', e.message || 'Unknown error');
            throw e;
        }
    },

    /**
     * Enqueues a market driver generation command via Firestore for the CF trigger.
     */
    async generateMarketDrivers() {
        await addDoc(collection(db, 'commands'), {
            type: 'generate_market_drivers',
            timestamp: serverTimestamp(),
            executed: false,
        });
    },

    /**
     * Recovery tool for teams that purchased an academy but have no candidates.
     */
    async fixBrokenAcademies() {
        try {
            const { academyService } = await import('./academy.svelte');
            const teamsSnap = await getDocs(collection(db, 'teams'));
            let fixedCount = 0;
            let fixedTeamIds: string[] = [];

            for (const tDoc of teamsSnap.docs) {
                const teamData = tDoc.data();
                const academy = teamData.facilities?.youthAcademy;

                // If they have an academy level > 0
                if (academy && academy.level > 0) {
                    const teamId = tDoc.id;
                    const candidatesRef = collection(db, 'teams', teamId, 'academy', 'config', 'candidates');
                    const selectedRef = collection(db, 'teams', teamId, 'academy', 'config', 'selected');
                    const configRef = doc(db, 'teams', teamId, 'academy', 'config');
                    
                    const [candSnap, selectedSnap, configSnap] = await Promise.all([
                        getDocs(candidatesRef),
                        getDocs(selectedRef),
                        getDoc(configRef)
                    ]);

                    // SAFETY: Only fix if they have NO selected pilots (trainees)
                    // This protects existing user progress.
                    if (selectedSnap.empty) {
                        const countryCode = configSnap.exists() ? configSnap.data().countryCode : 'ES';
                        const countryName = configSnap.exists() ? configSnap.data().countryName : 'Spain';
                        const countryFlag = configSnap.exists() ? configSnap.data().countryFlag : '🇪🇸';

                        // Check if we need to fix (either empty OR doesn't match the new 1M/1F 2-candidate rule)
                        const needsFix = candSnap.empty || candSnap.size !== 2 || !configSnap.exists();

                        if (needsFix) {
                            const batch = writeBatch(db);

                            // 1. Ensure config document exists
                            if (!configSnap.exists()) {
                                batch.set(configRef, {
                                    countryCode,
                                    countryName,
                                    countryFlag,
                                    academyLevel: academy.level || 1,
                                    scoutsUsedThisSeason: 2,
                                    createdAt: serverTimestamp()
                                });
                            }

                            // 2. Clear all existing candidates
                            candSnap.docs.forEach(d => batch.delete(d.ref));

                            // 3. Generate and set new 1M/1F pair
                            const newCandidates = academyService.generateInitialCandidates(2, countryCode, academy.level || 1);
                            newCandidates.forEach(c => {
                                const cRef = doc(candidatesRef, c.id);
                                batch.set(cRef, c);
                            });

                            await batch.commit();
                            fixedCount++;
                            fixedTeamIds.push(teamId);
                            console.debug(`[AdminService] Fixed/Reset academy for team ${teamId}`);
                        }
                    }
                }
            }

            console.log(`[AdminService] Finished fixing academies. Total fixed: ${fixedCount}`, fixedTeamIds);
            return { count: fixedCount, teams: fixedTeamIds };
        } catch (e: any) {
            console.error('Fix academies operation failed:', e.message || 'Unknown error');
            throw e;
        }
    }
};
