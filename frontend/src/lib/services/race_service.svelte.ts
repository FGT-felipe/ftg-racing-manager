import { db, functions } from '$lib/firebase/config';
import { httpsCallable } from 'firebase/functions';
import { doc, getDoc, collection, query, where, getDocs, orderBy, limit, documentId } from 'firebase/firestore';
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
            weather: string = "Sunny"
        ): { lapTime: number, isCrashed: boolean } {
            const ideal = circuit.idealSetup;
            const s = carStats;

            // Setup penalty
            const clamp = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi);
            const aB = 1.0 - (clamp(s.aero || 1, 1, 20) / 40.0);
            const pB = 1.0 - (clamp(s.powertrain || 1, 1, 20) / 40.0);
            const cB = 1.0 - (clamp(s.chassis || 1, 1, 20) / 40.0);

            let penalty = 0;
            const gap = (a: number, b: number) => Math.abs(a - b);
            
            const g1 = gap(setup.frontWing, ideal.frontWing);
            penalty += (g1 <= 3 ? 0 : g1 - 3) * 0.03 * aB;
            
            const g2 = gap(setup.rearWing, ideal.rearWing);
            penalty += (g2 <= 3 ? 0 : g2 - 3) * 0.03 * aB;
            
            const g3 = gap(setup.suspension, ideal.suspension);
            penalty += (g3 <= 3 ? 0 : g3 - 3) * 0.02 * cB;
            
            const g4 = gap(setup.gearRatio, ideal.gearRatio);
            penalty += (g4 <= 3 ? 0 : g4 - 3) * 0.025 * pB;

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
                if (ds.traits && ds.traits.includes("rainMaster")) {
                    df -= 0.01;
                }
                if (setup.tyreCompound !== "wet") {
                    penalty += 5.0;
                } else {
                    penalty -= 0.3; 
                }
            } else if (setup.tyreCompound === "wet") {
                penalty += 3.0; 
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

            return { lapTime: crashed ? 999.0 : lap, isCrashed: crashed };
        },

         /**
         * Fetches other competitor run times from the same league to display as a benchmark.
         * Useful for the GaragePanel.
         */
        async getCompetitorPracticeTimes(sessionId: string, teamIds?: string[], teamNames?: Record<string, string>): Promise<Array<{teamName: string, driverName: string, time: number | null, tyre: string | null, totalLaps: number, driverId: string}>> {
            try {
                console.log(`[RaceService] getCompetitorPracticeTimes: Redesigned Fetch with Fallback. Session: ${sessionId}`);
                
                if (!teamIds || teamIds.length === 0) {
                    console.warn('[RaceService] getCompetitorPracticeTimes: Aborting. No teamIds provided.');
                    return [];
                }

                // 1. Fetch ALL drivers in the league
                console.log(`[RaceService] Fetching all drivers for ${teamIds.length} teams.`);
                const driversQ = query(
                    collection(db, 'drivers'),
                    where('teamId', 'in', teamIds)
                );
                const driversSnap = await getDocs(driversQ);
                console.log(`[RaceService] Drivers found: ${driversSnap.size}`);

                // 2. Fetch ALL teams in the league (for fallback data)
                console.log(`[RaceService] Fetching all teams for fallback data.`);
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
                    
                    // Priority 1: Central session data
                    // Priority 2: Team-specific weekStatus data (fallback)
                    const centralResult = driverResults[dId] || {};
                    const teamPracticeData = teamData?.weekStatus?.driverSetups?.[dId]?.practice || {};

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

                console.log(`[RaceService] Map complete. Total participants: ${competitors.length}`);

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
        }
    };
}

export const raceService = createRaceService();
