import { db, functions } from '$lib/firebase/config';
import { httpsCallable } from 'firebase/functions';
import { doc, getDoc, updateDoc, onSnapshot, collection, query, where, getDocs, orderBy, limit, documentId } from 'firebase/firestore';
import type { Driver } from '$lib/types';
import { MAX_PRACTICE_LAPS_PER_DRIVER } from '$lib/constants/app_constants';

export function createRaceService() {
    return {
        /**
         * Simulates a single practice lap strictly on the client side.
         * Used only for practice telemetry feedback in the UI.
         */
        simulatePracticeRun(
            driver: any,
            setup: any,
            circuit: any,
            carStats: any = { aero: 1, powertrain: 1, chassis: 1 },
            weather: string = "Sunny",
            managerRole: string = ""
        ): { lapTime: number, isCrashed: boolean, driverFeedback: string[], tyreFeedback: string[], setupConfidence: number } {
            const ideal = circuit.idealSetup;
            const s = carStats;
            
            // Manager: Ex-Driver (+5 feedback bonus)
            const baseFeedback = driver.stats?.feedback || 50;
            const effectiveFeedback = managerRole === 'ex_driver' ? baseFeedback + 5 : baseFeedback;

            // Manager: Engineer (-10% tyre wear penalty reduction - reflected in feedback quality)
            // (Tyre wear isn't directly simulated here but we can add feedback)
            const tyreWearPenaltyMod = managerRole === 'engineer' ? 0.9 : 1.0;

            // Setup penalty
            const clamp = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi);
            const aB = 1.0 - (clamp(s.aero || 1, 1, 20) / 40.0);
            const pB = 1.0 - (clamp(s.powertrain || 1, 1, 20) / 40.0);
            const cB = 1.0 - (clamp(s.chassis || 1, 1, 20) / 40.0);

            let penalty = 0;
            const driverFeedback: string[] = [];
            const tyreFeedback: string[] = [];
            const feedbackStat = effectiveFeedback / 100.0; // Standardize to 0-1 for logic below

            const gap = (a: number, b: number) => Math.abs(a - b);
            
            // Helper to add feedback with quality check (matching PracticeService)
            const addFeedback = (specific: string, vague: string, g: number) => {
                const threshold = 12 - (feedbackStat * 10); 
                if (Math.abs(g) > threshold) {
                    if (feedbackStat > 0.75) {
                        driverFeedback.push(specific);
                    } else if (feedbackStat > 0.4) {
                        driverFeedback.push(Math.random() > 0.5 ? specific : vague);
                    } else {
                        driverFeedback.push(vague);
                    }
                }
            };

            const g1 = setup.frontWing - ideal.frontWing;
            penalty += (Math.abs(g1) <= 3 ? 0 : Math.abs(g1) - 3) * 0.03 * aB;
            addFeedback(
                g1 > 0 ? "The front end is way too sharp, I'm fighting oversteer." : "The car is lazy on entry, we have too much understeer.",
                "The front balance doesn't feel right, I can't hit the apex.",
                g1
            );
            
            const g2 = setup.rearWing - ideal.rearWing;
            penalty += (Math.abs(g2) <= 3 ? 0 : Math.abs(g2) - 3) * 0.03 * aB;
            addFeedback(
                g2 > 0 ? "We're slow on the straights, feels like we have a parachute." : "The rear is very nervous. I can't put the power down.",
                "The rear of the car is giving me zero confidence.",
                g2
            );
            
            const g3 = setup.suspension - ideal.suspension;
            penalty += (Math.abs(g3) <= 3 ? 0 : Math.abs(g3) - 3) * 0.02 * cB;
            addFeedback(
                g3 > 0 ? "The car is too stiff, it's bouncing like crazy." : "The suspension feels like jelly, too much roll.",
                "The car's handling over the bumps is very poor.",
                g3
            );
            
            const g4 = setup.gearRatio - ideal.gearRatio;
            penalty += (Math.abs(g4) <= 3 ? 0 : Math.abs(g4) - 3) * 0.025 * pB;
            addFeedback(
                g4 > 0 ? "Gears are too short, hitting the limiter too early." : "Gears are too long, acceleration is non-existent.",
                "The engine mapping doesn't match the track layout.",
                g4
            );

            // Car Config 
            const aV = clamp(s.aero || 1, 1, 20);
            const pV = clamp(s.powertrain || 1, 1, 20);
            const cV = clamp(s.chassis || 1, 1, 20);
            
            const w = aV * (circuit.aeroWeight || 0.33) + 
                      pV * (circuit.powertrainWeight || 0.34) + 
                      cV * (circuit.chassisWeight || 0.33);
            const carFactor = 1.0 - ((w / 20.0) * 0.25);

            // Driver Math
            const ds = driver.stats || {};
            const brk = (ds.braking || 50) / 100.0;
            const crn = (ds.cornering || 50) / 100.0;
            const foc = (ds.focus || 50) / 100.0;
            let df = 1.0 - (brk * 0.02 + crn * 0.025 + (foc - 0.5) * 0.01);

            const isWet = String(weather).toLowerCase().includes("rain") || String(weather).toLowerCase().includes("wet");
            if (isWet) {
                // Base wet surface penalty: sessions in rain are always slower
                penalty += 1.5;

                if (ds.traits && ds.traits.includes("rainMaster")) {
                    df -= 0.015; // Increased bonus for Rain Masters
                }
                if (setup.tyreCompound !== "wet") {
                    penalty += 5.0;
                    tyreFeedback.push("Zero grip! Need wets!");
                } else {
                    penalty -= 0.3; 
                    tyreFeedback.push("Wets are working well.");
                }
            } else if (setup.tyreCompound === "wet") {
                penalty += 3.0; 
                tyreFeedback.push("Wets are overheating on this dry track.");
            }

            // Style modifier
            const st = setup.qualifyingStyle || "normal";
            let sBonus = 0; 
            let accProb = 0.001;

            if (st === "mostRisky") {
                sBonus = 0.04; accProb = 0.003;
            } else if (st === "offensive") {
                sBonus = 0.02; accProb = 0.0015;
            } else if (st === "defensive") {
                sBonus = -0.01; accProb = 0.0005;
            }
            df -= sBonus;

            const crashed = Math.random() < accProb;

            let lap = circuit.baseLapTime * carFactor * df + penalty;
            lap += (Math.random() - 0.5) * 0.8;

            // Final confidence calculation
            const totalGap = Math.abs(g1) + Math.abs(g2) + Math.abs(g3) + Math.abs(g4);
            const confidence = Math.max(0, Math.min(1, 1.0 - (totalGap / 100.0)));

            return { 
                lapTime: crashed ? 999.0 : lap, 
                isCrashed: crashed,
                driverFeedback,
                tyreFeedback,
                setupConfidence: confidence
            };
        },

         /**
         * Fetches other competitor run times from the same league to display as a benchmark.
         * Useful for the GaragePanel.
         */
        async getCompetitorPracticeTimes(sessionId: string, teamIds?: string[], teamNames?: Record<string, string>): Promise<Array<{teamName: string, driverName: string, time: number | null, tyre: string | null, totalLaps: number, driverId: string}>> {
            try {
                console.debug(`[RaceService] getCompetitorPracticeTimes: Redesigned Fetch with Fallback. Session: ${sessionId}`);
                
                if (!teamIds || teamIds.length === 0) {
                    console.warn('[RaceService] getCompetitorPracticeTimes: Aborting. No teamIds provided.');
                    return [];
                }

                // 1. Fetch ALL drivers in the league
                console.debug(`[RaceService] Fetching all drivers for ${teamIds.length} teams.`);
                const driversQ = query(
                    collection(db, 'drivers'),
                    where('teamId', 'in', teamIds)
                );
                const driversSnap = await getDocs(driversQ);
                console.debug(`[RaceService] Drivers found: ${driversSnap.size}`);

                // 2. Fetch ALL teams in the league (for fallback data)
                console.debug(`[RaceService] Fetching all teams for fallback data.`);
                const teamsQ = query(
                    collection(db, 'teams'),
                    where(documentId(), 'in', teamIds)
                );
                const teamsSnap = await getDocs(teamsQ);
                const teamsMap = new Map<string, any>();
                teamsSnap.forEach(tDoc => teamsMap.set(tDoc.id, tDoc.data()));

                // 3. Fetch central practice session data
                const sessionRef = doc(db, 'practice_sessions', sessionId);
                const sessionSnap = await getDoc(sessionRef);
                const sessionData = sessionSnap.exists() ? sessionSnap.data() : { driverResults: {} };
                const driverResults = sessionData.driverResults || {};

                const competitors: Array<{teamName: string, driverName: string, time: number | null, tyre: string | null, totalLaps: number, driverId: string}> = [];

                // 4. Merge data
                driversSnap.forEach(driverDoc => {
                    const dId = driverDoc.id;
                    const d = driverDoc.data();
                    const teamData = teamsMap.get(d.teamId);
                    
                    // Priority 1: Central session data (practice_sessions/{sessionId})
                    // Priority 2: Team weekStatus fallback — only when the stored
                    //   practice.sessionId matches the current session. Without this
                    //   gate, R(N-1) best lap times bleed into R(N) standings because
                    //   driverSetups is not cleared between rounds.
                    const centralResult = driverResults[dId] || {};
                    const rawPracticeData = teamData?.weekStatus?.driverSetups?.[dId]?.practice || {};
                    const teamPracticeData = rawPracticeData.sessionId === sessionId ? rawPracticeData : {};

                    const bestTime = centralResult.bestLapTime || teamPracticeData.bestLapTime || null;
                    const bestTyre = centralResult.bestLapTyre || teamPracticeData.bestLapTyre || null;
                    const laps = Math.max(centralResult.laps || 0, teamPracticeData.laps || 0);

                    competitors.push({
                        teamName: teamNames?.[d.teamId] || d.teamName || teamData?.name || `Team ${d.teamId.substring(0, 5)}`,
                        driverName: d.name || 'Unknown Driver',
                        driverId: dId,
                        time: bestTime,
                        tyre: bestTyre,
                        totalLaps: laps
                    });
                });

                console.debug(`[RaceService] Map complete. Total participants: ${competitors.length}`);

                // Sort: Drivers with times first (by time), then drivers without times alphabetically
                competitors.sort((a, b) => {
                    if (a.time === null && b.time === null) return a.driverName.localeCompare(b.driverName);
                    if (a.time === null) return 1;
                    if (b.time === null) return -1;
                    return a.time - b.time;
                });
                
                return competitors;

            } catch (e) {
                console.error("Failed to fetch competitor times", e);
                return [];
            }
        },

        /**
         * Fetches other competitor qualifying times from the same league to display as a benchmark.
         */
        async getCompetitorQualifyingTimes(sessionId: string, teamIds?: string[], teamNames?: Record<string, string>): Promise<Array<{teamName: string, driverName: string, time: number | null, tyre: string | null, totalLaps: number, driverId: string, gender: string}>> {
            try {
                console.debug(`[RaceService] getCompetitorQualifyingTimes. Session: ${sessionId}`);
                
                if (!teamIds || teamIds.length === 0) {
                    console.warn('[RaceService] getCompetitorQualifyingTimes: Aborting. No teamIds provided.');
                    return [];
                }

                // 1. Fetch ALL drivers in the league
                const driversQ = query(
                    collection(db, 'drivers'),
                    where('teamId', 'in', teamIds)
                );
                const driversSnap = await getDocs(driversQ);

                // 2. Fetch ALL teams in the league (for fallback/direct data)
                const teamsQ = query(
                    collection(db, 'teams'),
                    where(documentId(), 'in', teamIds)
                );
                const teamsSnap = await getDocs(teamsQ);
                const teamsMap = new Map<string, any>();
                teamsSnap.forEach(tDoc => teamsMap.set(tDoc.id, tDoc.data()));

                const competitors: Array<{teamName: string, driverName: string, time: number | null, tyre: string | null, totalLaps: number, driverId: string, gender: string}> = [];

                // 3. Merge data using team weekStatus (where qualy data is stored).
                // Gate by practice.sessionId: qualifying fields share the same
                // driverSetups record and are not cleared between rounds, so
                // R(N-1) qualifying times would leak into R(N) standings.
                driversSnap.forEach(driverDoc => {
                    const dId = driverDoc.id;
                    const d = driverDoc.data();
                    const teamData = teamsMap.get(d.teamId);

                    const rawDs = teamData?.weekStatus?.driverSetups?.[dId] || {};
                    const isCurrentSession = rawDs.practice?.sessionId === sessionId;
                    const qualyData = isCurrentSession ? rawDs : {};

                    const bestTime = qualyData.qualifyingBestTime || null;
                    const bestTyre = qualyData.qualifyingBestCompound || null;
                    const laps = qualyData.qualifyingLaps || 0;

                    competitors.push({
                        teamName: teamNames?.[d.teamId] || d.teamName || teamData?.name || `Team ${d.teamId.substring(0, 5)}`,
                        driverName: d.name || 'Unknown Driver',
                        driverId: dId,
                        time: bestTime === 0 ? null : bestTime,
                        tyre: bestTyre,
                        totalLaps: laps,
                        gender: d.gender || 'male'
                    });
                });

                // Sort: Drivers with times first (by time), then drivers without times alphabetically
                competitors.sort((a, b) => {
                    if (a.time === null && b.time === null) return a.driverName.localeCompare(b.driverName);
                    if (a.time === null) return 1;
                    if (b.time === null) return -1;
                    return a.time - b.time;
                });
                
                return competitors;

            } catch (e) {
                console.error("Failed to fetch competitor qualy times", e);
                return [];
            }
        },

        /**
         * Wrappers for Cloud Functions manual execution.
         * Mainly used by Administrators if they want to force a simulation.
         */
        async forceQualifying(): Promise<any> {
            try {
                const forceQualyCallable = httpsCallable(functions, 'forceQualy');
                const result = await forceQualyCallable();
                return result.data;
            } catch (error) {
                console.error("Error forcing qualifying:", error);
                throw error;
            }
        },

        async forceRace(): Promise<any> {
            try {
                const forceRaceCallable = httpsCallable(functions, 'forceRace');
                const result = await forceRaceCallable();
                return result.data;
            } catch (error) {
                console.error("Error forcing race:", error);
                throw error;
            }
        },

        /**
         * Fetches the qualifying results for a given race document.
         * @param raceDocId - Combined ID in the format `{seasonId}_{eventId}` (e.g. "S1_r3").
         * @returns Array of qualifying result rows, or empty array if not yet available.
         */
        async getQualyResults(raceDocId: string): Promise<any[]> {
            try {
                const snap = await getDoc(doc(db, 'races', raceDocId));
                if (!snap.exists()) return [];
                return snap.data().qualifyingResults || [];
            } catch (e) {
                console.error('[RaceService:getQualyResults] Failed to fetch:', e);
                return [];
            }
        },

        /**
         * Fetches the full race document data (results, positions, times, DNFs).
         * @param raceDocId - Combined ID in the format `{seasonId}_{eventId}`.
         * @returns Race document data, or null if not found.
         */
        async getRaceData(raceDocId: string): Promise<any | null> {
            try {
                const snap = await getDoc(doc(db, 'races', raceDocId));
                if (!snap.exists()) return null;
                return snap.data();
            } catch (e) {
                console.error('[RaceService:getRaceData] Failed to fetch:', e);
                return null;
            }
        },

        /**
         * Fetches a race document by season and round, with automatic fallback
         * for season ID mismatches (e.g. after fix_season_refs.js updates
         * activeSeasonId while historical race docs remain under the old ID prefix).
         *
         * Strategy:
         *  1. Try the canonical {seasonId}_{roundId} direct path.
         *  2. If not found, query the races collection by the raceEventId field.
         *     The qualifying CF always writes raceEventId to every race doc,
         *     so this finds the document regardless of the season ID prefix used.
         *
         * @param seasonId - Current canonical season ID from seasonStore.
         * @param roundId  - Round event ID, e.g. 'r4'.
         * @returns Race document data, or null if not found in either path.
         */
        async getRaceDataByRound(seasonId: string, roundId: string): Promise<any | null> {
            // Primary path — fast, no query cost
            const primary = await this.getRaceData(`${seasonId}_${roundId}`);
            if (primary) return primary;

            // Fallback: query races by raceEventId field.
            // Handles the case where the season ID in the document prefix differs
            // from the current activeSeasonId (e.g. after fix_season_refs ran mid-season).
            // raceEventId is a single-field equality query — no composite index required.
            try {
                const raceSnap = await getDocs(
                    query(
                        collection(db, 'races'),
                        where('raceEventId', '==', roundId),
                        limit(1)
                    )
                );
                if (raceSnap.empty) return null;
                return raceSnap.docs[0].data();
            } catch (e) {
                console.error('[RaceService:getRaceDataByRound] Fallback query failed:', e);
                return null;
            }
        },

        /**
         * Derives a driver's season stats (races, wins, podiums, poles) from the
         * actual race documents for each completed round, then patches the driver
         * doc in Firestore if any value differs from what is currently stored.
         *
         * This is the authoritative source: counters on the driver doc can drift
         * (e.g. seasonPoles was never written for R1–R4), so this computation
         * self-heals on the first modal open and keeps data consistent going forward.
         *
         * @param driverId         - The driver document ID.
         * @param seasonId         - Current canonical season ID from seasonStore.
         * @param completedRoundIds - e.g. ['r1','r2','r3','r4'] from season.calendar.
         * @param currentStats     - Current values on the driver doc (to skip the
         *                           patch write if already correct).
         * @returns Accurate season stats object.
         */
        async syncDriverSeasonStats(
            driverId: string,
            seasonId: string,
            completedRoundIds: string[],
            currentStats: { seasonRaces: number; seasonWins: number; seasonPodiums: number; seasonPoles: number }
        ): Promise<{ seasonRaces: number; seasonWins: number; seasonPodiums: number; seasonPoles: number }> {
            let seasonRaces = 0;
            let seasonWins = 0;
            let seasonPodiums = 0;
            let seasonPoles = 0;

            for (const roundId of completedRoundIds) {
                const data = await this.getRaceDataByRound(seasonId, roundId);
                if (!data) continue;

                // Race results — finalPositions maps driverId → finishing position
                const finalPositions = data.finalPositions || {};
                if (driverId in finalPositions) {
                    const pos = parseInt(String(finalPositions[driverId]));
                    seasonRaces++;
                    if (pos === 1) seasonWins++;
                    if (pos <= 3) seasonPodiums++;
                }

                // Qualifying — pole is the first non-crashed entry in the grid
                const qualyGrid: any[] = data.qualifyingResults?.length > 0
                    ? data.qualifyingResults
                    : (data.qualyGrid || []);
                const pole = qualyGrid.find((q: any) => !q.isCrashed);
                if (pole?.driverId === driverId) seasonPoles++;
            }

            const computed = { seasonRaces, seasonWins, seasonPodiums, seasonPoles };

            // Patch driver doc only if any value differs — avoids unnecessary writes
            const needsPatch =
                computed.seasonRaces  !== currentStats.seasonRaces  ||
                computed.seasonWins   !== currentStats.seasonWins   ||
                computed.seasonPodiums !== currentStats.seasonPodiums ||
                computed.seasonPoles  !== currentStats.seasonPoles;

            if (needsPatch) {
                try {
                    await updateDoc(doc(db, 'drivers', driverId), computed);
                } catch (e) {
                    console.error('[RaceService:syncDriverSeasonStats] Patch write failed:', e);
                }
            }

            return computed;
        },

        /**
         * Opens a real-time subscription to a race document.
         * Intended for live race tracking. The component is responsible for
         * calling the returned unsubscribe function on unmount.
         * @param raceDocId - Combined ID in the format `{seasonId}_{eventId}`.
         * @param callback - Called with race data whenever the document changes.
         * @returns Unsubscribe function to call on component destroy.
         */
        subscribeToRace(raceDocId: string, callback: (data: any | null) => void): () => void {
            const raceRef = doc(db, 'races', raceDocId);
            return onSnapshot(
                raceRef,
                (snap) => {
                    callback(snap.exists() ? snap.data() : null);
                },
                (err) => {
                    console.error('[RaceService:subscribeToRace] Snapshot error:', err);
                    callback(null);
                }
            );
        }
    };
}

export const raceService = createRaceService();
