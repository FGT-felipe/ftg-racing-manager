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
    limit,
    deleteField,
    increment,
} from 'firebase/firestore';
import {
    BUDGET_REBALANCE_THRESHOLD_HIGH,
    BUDGET_REBALANCE_THRESHOLD_LOW,
    BUDGET_REBALANCE_REDUCTION_RATE,
    QUALY_ENTRY_FEE,
} from '$lib/constants/economics';

/**
 * Result returned by any admin dry-run operation.
 * When dryRun=true, no writes are committed — only this summary is returned.
 */
export interface AdminPreflightResult {
    /** Full Firestore paths of documents that would be written/updated, e.g. "teams/abc123" */
    affectedDocIds: string[];
    /** Human-readable aggregate, e.g. "8 teams · 14 drivers · 2 race docs" */
    summary: string;
}

export const adminService = {
    /**
     * DANGEROUS: Port of DatabaseSeeder.nukeAndReseed
     * Wipes historical data and resets the universe.
     *
     * @deprecated No longer exposed in the admin UI. Kept as emergency reference only.
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
            console.error('[AdminService:nukeAndReseed] Failed:', e.message || 'Unknown error');
            throw e;
        }
    },

    /**
     * Port of MaintenanceService.fixRaceCalendars
     * Synchronizes calendars with the absolute truth from ftg_world.
     *
     * SCOPE: Uncompleted calendar entries (isCompleted=false) in target seasons only.
     * Does NOT touch completed race entries.
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
            console.error('[AdminService:fixRaceCalendars] Failed:', e.message || 'Unknown error');
            throw e;
        }
    },

    /**
     * Port of FinanceService.applyGreatRebalanceTax
     *
     * SCOPE: All team documents (human + bot). Adjusts budget to configured thresholds,
     * clears all sponsor slots, and resets sponsorNegotiations. Irreversible for sponsors.
     *
     * @param dryRun - If true, performs all reads and returns preflight summary without writing.
     */
    async applyGreatRebalanceTax(dryRun = false): Promise<true | AdminPreflightResult> {
        try {
            const teamsSnap = await getDocs(collection(db, 'teams'));
            let batch = writeBatch(db);
            let opCount = 0;

            const affectedDocIds: string[] = [];

            for (const tDoc of teamsSnap.docs) {
                const teamData = tDoc.data();
                const currentBudget = teamData.budget || 0;
                let newBudget = currentBudget;

                if (currentBudget > BUDGET_REBALANCE_THRESHOLD_HIGH) {
                    newBudget = BUDGET_REBALANCE_THRESHOLD_HIGH + Math.floor((currentBudget - BUDGET_REBALANCE_THRESHOLD_HIGH) * BUDGET_REBALANCE_REDUCTION_RATE);
                } else if (currentBudget < BUDGET_REBALANCE_THRESHOLD_LOW) {
                    newBudget = BUDGET_REBALANCE_THRESHOLD_LOW;
                }

                affectedDocIds.push(`teams/${tDoc.id}`);

                if (!dryRun) {
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
            }

            if (dryRun) {
                return {
                    affectedDocIds,
                    summary: `${affectedDocIds.length} teams`
                };
            }

            if (opCount > 0) await batch.commit();
            return true;
        } catch (e: any) {
            console.error('[AdminService:applyGreatRebalanceTax] Failed:', e.message || 'Unknown error');
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
     * Emergency recovery tool after a qualifying data corruption incident.
     * Resets all qualifying fields for every human (non-bot) team's drivers,
     * refunds the QUALY_ENTRY_FEE per affected driver, and clears the qualyGrid
     * from all unfinished race documents so Force Qualifying can regenerate a clean grid.
     *
     * SCOPE: Human teams (isBot=false) that have drivers with qualifyingAttempts > 0.
     *        Race documents where isFinished !== true AND qualyGrid.length > 0.
     *        Completed races (isFinished=true) are NEVER touched — they are permanent records.
     *
     * @param dryRun - If true, performs all reads and returns preflight summary without writing.
     * @returns Preflight summary (dryRun=true) or operation counts (dryRun=false).
     */
    async resetQualifyingSession(dryRun = false): Promise<{ teamsFixed: number; driversFixed: number } | AdminPreflightResult> {
        try {
            const teamsSnap = await getDocs(collection(db, 'teams'));

            // --- Step 1: Identify human teams with active qualifying data ---
            let teamsBatch = writeBatch(db);
            let batchOps = 0;
            let teamsFixed = 0;
            let driversFixed = 0;

            const affectedTeamIds: string[] = [];
            const affectedRaceIds: string[] = [];

            for (const tDoc of teamsSnap.docs) {
                const teamData = tDoc.data();
                if (teamData.isBot) continue;

                const driverSetups: Record<string, any> = teamData.weekStatus?.driverSetups ?? {};
                const updates: Record<string, any> = {};
                let affectedDrivers = 0;

                for (const [driverId, ds] of Object.entries(driverSetups)) {
                    const setup = ds as any;
                    if (!setup.qualifyingAttempts || setup.qualifyingAttempts === 0) continue;

                    const path = `weekStatus.driverSetups.${driverId}`;
                    updates[`${path}.qualifyingAttempts`]    = deleteField();
                    updates[`${path}.qualifyingBestTime`]    = deleteField();
                    updates[`${path}.qualifyingBestCompound`] = deleteField();
                    updates[`${path}.qualifyingDnf`]         = deleteField();
                    updates[`${path}.qualifyingParcFerme`]   = deleteField();
                    updates[`${path}.qualifying`]            = deleteField();
                    updates[`${path}.isSetupSent`]           = deleteField();
                    updates[`${path}.lastQualyResult`]       = deleteField();
                    updates[`${path}.qualifyingLaps`]        = deleteField();
                    affectedDrivers++;
                }

                if (affectedDrivers > 0) {
                    affectedTeamIds.push(`teams/${tDoc.id}`);

                    if (!dryRun) {
                        updates['budget'] = increment(QUALY_ENTRY_FEE * affectedDrivers);
                        teamsBatch.update(tDoc.ref, updates);
                        batchOps++;
                        teamsFixed++;
                        driversFixed += affectedDrivers;

                        if (batchOps >= 400) {
                            await teamsBatch.commit();
                            teamsBatch = writeBatch(db);
                            batchOps = 0;
                        }
                    } else {
                        teamsFixed++;
                        driversFixed += affectedDrivers;
                    }
                }
            }
            if (!dryRun && batchOps > 0) await teamsBatch.commit();

            // --- Step 2: Identify unfinished race documents with a qualifying grid ---
            // SCOPE: Only unfinished races (isFinished !== true). Completed races are permanent records.
            const racesSnap = await getDocs(collection(db, 'races'));
            let racesBatch = writeBatch(db);
            let racesOps = 0;

            for (const rDoc of racesSnap.docs) {
                const rData = rDoc.data();
                // Skip any race that has already finished — those are historical records
                if (rData?.isFinished === true) continue;
                const grid = rData?.qualyGrid;
                if (!grid || grid.length === 0) continue;

                affectedRaceIds.push(`races/${rDoc.id}`);

                if (!dryRun) {
                    racesBatch.update(rDoc.ref, { qualyGrid: [], qualifyingResults: [] });
                    racesOps++;

                    if (racesOps >= 400) {
                        await racesBatch.commit();
                        racesBatch = writeBatch(db);
                        racesOps = 0;
                    }
                }
            }
            if (!dryRun && racesOps > 0) await racesBatch.commit();

            if (dryRun) {
                const affectedDocIds = [...affectedTeamIds, ...affectedRaceIds];
                const summary = `${affectedTeamIds.length} teams · ${driversFixed} drivers · ${affectedRaceIds.length} race docs`;
                return { affectedDocIds, summary };
            }

            console.log(`[AdminService:resetQualifyingSession] Reset ${driversFixed} drivers across ${teamsFixed} teams. Cleared ${racesOps} race documents.`);
            return { teamsFixed, driversFixed };
        } catch (e: any) {
            console.error('[AdminService:resetQualifyingSession] Failed:', e.message || e);
            throw e;
        }
    },

    /**
     * Recovery tool for teams that purchased an academy but have no candidates.
     *
     * SCOPE: Teams where facilities.youthAcademy.level > 0 AND selected sub-collection is empty.
     *        Only fixes academies with zero active trainees — existing trainee progress is protected.
     *
     * @param dryRun - If true, performs all reads and returns preflight summary without writing.
     */
    async fixBrokenAcademies(dryRun = false): Promise<{ count: number; teams: string[] } | AdminPreflightResult> {
        try {
            const { academyService } = await import('./academy.svelte');
            const teamsSnap = await getDocs(collection(db, 'teams'));
            let fixedCount = 0;
            let fixedTeamIds: string[] = [];

            for (const tDoc of teamsSnap.docs) {
                const teamData = tDoc.data();
                const academy = teamData.facilities?.youthAcademy;

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
                        const needsFix = candSnap.empty || candSnap.size !== 2 || !configSnap.exists();

                        if (needsFix) {
                            fixedTeamIds.push(`teams/${teamId}`);

                            if (!dryRun) {
                                const countryCode = configSnap.exists() ? configSnap.data().countryCode : 'ES';
                                const countryName = configSnap.exists() ? configSnap.data().countryName : 'Spain';
                                const countryFlag = configSnap.exists() ? configSnap.data().countryFlag : '🇪🇸';

                                const batch = writeBatch(db);

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

                                candSnap.docs.forEach(d => batch.delete(d.ref));

                                const newCandidates = academyService.generateInitialCandidates(2, configSnap.exists() ? configSnap.data().countryCode : 'ES', academy.level || 1);
                                newCandidates.forEach(c => {
                                    const cRef = doc(candidatesRef, c.id);
                                    batch.set(cRef, c);
                                });

                                await batch.commit();
                                console.debug(`[AdminService:fixBrokenAcademies] Fixed academy for team ${teamId}`);
                            }
                            fixedCount++;
                        }
                    }
                }
            }

            if (dryRun) {
                return {
                    affectedDocIds: fixedTeamIds,
                    summary: `${fixedTeamIds.length} teams`
                };
            }

            console.log(`[AdminService:fixBrokenAcademies] Finished. Total fixed: ${fixedCount}`, fixedTeamIds);
            return { count: fixedCount, teams: fixedTeamIds };
        } catch (e: any) {
            console.error('[AdminService:fixBrokenAcademies] Failed:', e.message || 'Unknown error');
            throw e;
        }
    }
};
