/**
 * Race orchestrator — reads from / writes to Firestore.
 * Calls simulateRace() from sim-engine for the actual physics.
 *
 * Faithfully extracted from runRaceLogic() in functions/index.js
 * (lines 1223–1748) plus the forceRace onCall handler.
 * postRaceProcessing is extracted separately in domains/economy/post-race.ts.
 */

import * as logger from "firebase-functions/logger";
import { onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { db, admin } from "../../shared/admin";
import { getCircuit } from "../../config/circuits";
import { DEFAULT_SETUP, POINT_SYSTEM, getRacePrize } from "../../config/constants";
import { fetchTeams } from "../../shared/firestore";
import { addOfficeNews } from "../../shared/notifications";
import { sleep } from "../../shared/utils";
import { simulateRace } from "./sim-engine";

// ─── Core logic ───────────────────────────────────────────────────────────────

/**
 * Runs the full race simulation for all leagues.
 * Reads qualyGrid from the Race document, runs simulateRace(), and writes
 * finalPositions, stats, prize money, and debrief back to Firestore.
 *
 * Sets postRaceProcessingAt = now + 1h to trigger postRaceProcessing.
 */
export async function runRaceLogic(): Promise<void> {
  try {
    const uDoc = await db.collection("universe").doc("game_universe_v1").get();
    if (!uDoc.exists) return;
    const leagues = Object.values((uDoc.data() as Record<string, unknown>).leagues as Record<string, unknown> ?? {});

    let leagueIdx = 0;
    for (const league of leagues as Record<string, unknown>[]) {
      try {
        if (leagueIdx > 0) await sleep(15 * 1000);
        leagueIdx++;

        // --- Self-healing season lookup ---
        let sId = league["currentSeasonId"] as string | undefined;
        let sDoc = sId ? await db.collection("seasons").doc(sId).get() : null;

        if (!sDoc || !sDoc.exists) {
          logger.info(`Race: Season ${sId ?? "N/A"} not found, falling back...`);
          const fallback = await db.collection("seasons").orderBy("startDate", "desc").limit(1).get();
          if (fallback.empty) continue;
          sDoc = fallback.docs[0];
          sId = sDoc.id;
          logger.info(`Race: Using fallback season: ${sId}`);
        }
        const season = sDoc.data() as Record<string, unknown>;

        const calendar = season["calendar"] as Record<string, unknown>[] ?? [];
        const rIdx = calendar.findIndex((r) => !r["isCompleted"]);
        if (rIdx === -1) continue;
        const rEvent = calendar[rIdx];

        const raceDocId = `${sId}_${rEvent["id"]}`;
        const rSnap = await db.collection("races").doc(raceDocId).get();

        if (!rSnap.exists || !(rSnap.data()?.["qualyGrid"] as unknown[])?.length) {
          logger.warn(`No qualy grid: ${raceDocId}`);
          continue;
        }
        const rData = rSnap.data() as Record<string, unknown>;
        if (rData["isFinished"]) continue;

        const circuit = getCircuit(rEvent["circuitId"] as string);
        logger.info(`Race: ${league["name"]} - ${rEvent["trackName"]}`);

        // Build maps
        const grid = rData["qualyGrid"] as Record<string, unknown>[];
        const teamIds = [...new Set(grid.map((g) => g["teamId"] as string))];
        const teamDocs = await fetchTeams(teamIds);
        const teamsMap: Record<string, Record<string, unknown>> = {};
        teamDocs.forEach((td) => { teamsMap[(td.data() as Record<string, unknown>)["id"] as string] = td.data() as Record<string, unknown>; });

        const driversMap: Record<string, Record<string, unknown>> = {};
        const setupsMap: Record<string, Record<string, unknown>> = {};

        for (let gi = 0; gi < grid.length; gi++) {
          const g = grid[gi];
          const dDoc = await db.collection("drivers").doc(g["driverId"] as string).get();
          if (!dDoc.exists) continue;
          const dData: Record<string, unknown> = { ...dDoc.data() as Record<string, unknown>, id: g["driverId"] };
          dData["carIndex"] = gi % 2;
          driversMap[g["driverId"] as string] = dData;

          const team = teamsMap[g["teamId"] as string] ?? {};
          let su: Record<string, unknown> = { ...DEFAULT_SETUP };

          if (team["isBot"]) {
            const ideal = circuit.idealSetup;
            su["frontWing"] = ideal.frontWing + Math.floor(Math.random() * 10) - 5;
            su["rearWing"] = ideal.rearWing + Math.floor(Math.random() * 10) - 5;
            su["suspension"] = ideal.suspension + Math.floor(Math.random() * 10) - 5;
            su["gearRatio"] = ideal.gearRatio + Math.floor(Math.random() * 10) - 5;
            su["initialFuel"] = 80 + Math.floor(Math.random() * 20);
            su["pitStops"] = ["hard", "medium"];
            su["pitStopFuel"] = [60, 40];
            su["raceStyle"] = "normal";
          } else {
            const ws = (team["weekStatus"] as Record<string, unknown>) ?? {};
            const ds = ((ws["driverSetups"] as Record<string, unknown>) ?? {})[g["driverId"] as string] as Record<string, unknown> | undefined;
            if (ds && (ds["isSetupSent"] || ds["raceSubmitted"]) && ds["race"]) {
              su = { ...DEFAULT_SETUP, ...(ds["race"] as Record<string, unknown>) };
            }
          }

          if (dData["isTransferListed"]) {
            const ySnap = await db.collection("teams").doc(team["id"] as string)
              .collection("academy").doc("config")
              .collection("selected").limit(1).get();
            if (!ySnap.empty) {
              const yData = ySnap.docs[0].data() as Record<string, unknown>;
              dData["name"] = (yData["name"] as string) + " (Academy)";
              const base = (yData["baseSkill"] as number) || 50;
              dData["stats"] = {
                braking: base, cornering: base, smoothness: base,
                overtaking: base, consistency: base, adaptability: base,
                focus: base, feedback: base, fitness: 100, morale: 100, marketability: 30,
              };
            } else {
              dData["stats"] = { braking: 1, cornering: 1, smoothness: 1, overtaking: 1, consistency: 1, adaptability: 1, focus: 1, feedback: 1, fitness: 1 };
            }
            su = { ...DEFAULT_SETUP, frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50, raceStyle: "defensive", pitStops: ["hard"], pitStopFuel: [50] };
          }

          su["tyreCompound"] = g["tyreCompound"] ?? "medium";
          if (dData["isTransferListed"]) su["tyreCompound"] = "hard";
          setupsMap[g["driverId"] as string] = su;
        }

        // Build manager roles map
        const managerRoles: Record<string, string> = {};
        for (const tid of teamIds) {
          const t = teamsMap[tid];
          if (t?.["managerId"]) {
            const mgrDoc = await db.collection("managers").doc(t["managerId"] as string).get();
            if (mgrDoc.exists) {
              managerRoles[tid] = (mgrDoc.data() as Record<string, unknown>)["role"] as string ?? "";
            }
          }
        }

        // Run full race (pure function)
        const raceRes = simulateRace({
          circuit,
          grid: grid as unknown as Parameters<typeof simulateRace>[0]["grid"],
          teamsMap: teamsMap as unknown as Parameters<typeof simulateRace>[0]["teamsMap"],
          driversMap: driversMap as unknown as Parameters<typeof simulateRace>[0]["driversMap"],
          setupsMap,
          managerRoles,
          raceEvent: rEvent as unknown as Parameters<typeof simulateRace>[0]["raceEvent"],
        });

        // Calculate live duration for frontend playback
        const validQualyTimes = grid.filter((g) => (g["lapTime"] as number) > 0 && (g["lapTime"] as number) < 900);
        const avgQualyTime = validQualyTimes.length > 0
          ? validQualyTimes.reduce((s, g) => s + (g["lapTime"] as number), 0) / validQualyTimes.length
          : circuit.baseLapTime;
        let liveDurationSec = avgQualyTime * (circuit.laps ?? 50);
        if (isNaN(liveDurationSec) || liveDurationSec <= 0) {
          liveDurationSec = circuit.baseLapTime * (circuit.laps ?? 50);
        }

        // Save race results
        const raceRef = db.collection("races").doc(raceDocId);
        await raceRef.update({
          status: "completed",
          isFinished: true,
          finalPositions: raceRes.finalPositions,
          totalTimes: raceRes.totalTimes,
          dnfs: raceRes.dnfs,
          fast_lap_time: raceRes.fast_lap_time,
          fast_lap_driver: raceRes.fast_lap_driver,
          countryCode: circuit.countryCode ?? "",
          liveDurationSeconds: liveDurationSec,
          updateIntervalSeconds: 120,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Save lap-by-lap data in subcollection (every 5th lap + last)
        const lapBatch = db.batch();
        const liveColl = raceRef.collection("laps");
        for (let i = 0; i < raceRes.raceLog.length; i++) {
          if (i % 5 === 0 || i === raceRes.raceLog.length - 1) {
            lapBatch.set(liveColl.doc(String(raceRes.raceLog[i].lap)), raceRes.raceLog[i]);
          }
        }
        await lapBatch.commit();

        // Lock teams for post-race processing
        for (const tid of teamIds) {
          await db.collection("teams").doc(tid).update({ "weekStatus.isLockedForProcessing": true });
        }

        // --- POINTS & STATS ---
        const sorted = Object.keys(raceRes.finalPositions)
          .sort((a, b) => raceRes.finalPositions[a] - raceRes.finalPositions[b]);

        const teamPointsAccum: Record<string, number> = {};
        const teamPrizeAccum: Record<string, number> = {};
        const statsBatch = db.batch();

        for (let i = 0; i < sorted.length; i++) {
          const did = sorted[i];
          const isDnf = raceRes.dnfs.includes(did);
          const inc = admin.firestore.FieldValue.increment;
          const dRef = db.collection("drivers").doc(did);
          const dData = driversMap[did];
          if (!dData) continue;

          const pts = i < POINT_SYSTEM.length ? POINT_SYSTEM[i] : 0;
          const isWin = i === 0;
          const isPodium = i < 3;

          const du: Record<string, unknown> = { races: inc(1), seasonRaces: inc(1) };
          if (pts > 0) { du["points"] = inc(pts); du["seasonPoints"] = inc(pts); }
          if (isWin) { du["wins"] = inc(1); du["seasonWins"] = inc(1); }
          if (isPodium) { du["podiums"] = inc(1); du["seasonPodiums"] = inc(1); }

          let mDelta = -5; let fDelta = -0.01;
          if (isDnf) { mDelta = -15; fDelta = -0.1; }
          else if (isWin) { mDelta = 10; fDelta = 0.1; }
          else if (isPodium) { mDelta = 7; fDelta = 0.05; }
          else if (pts > 0) { mDelta = 3; fDelta = 0.02; }

          const mRoleForStats = dData["teamId"] ? (managerRoles[dData["teamId"] as string] ?? "") : "";
          if (mRoleForStats === "ex_driver") mDelta += 10;

          const curStats = (dData["stats"] as Record<string, number>) ?? {};
          const newMorale = Math.min(100, Math.max(0, (curStats["morale"] ?? 50) + mDelta));
          const newForm = Math.min(10, Math.max(1, ((dData["form"] as number) ?? 5.0) + fDelta));
          du["stats.morale"] = newMorale;
          du["form"] = newForm;

          const cForm = (dData["championshipForm"] as Record<string, unknown>[]) ?? [];
          cForm.unshift({ event: rEvent["trackName"], pos: isDnf ? "DNF" : `P${i + 1}`, pts, date: new Date().toISOString() });
          if (cForm.length > 10) cForm.pop();
          du["championshipForm"] = cForm;

          statsBatch.update(dRef, du as FirebaseFirestore.UpdateData<object>);

          const tid = dData["teamId"] as string;
          teamPointsAccum[tid] = (teamPointsAccum[tid] ?? 0) + pts;
          teamPrizeAccum[tid] = (teamPrizeAccum[tid] ?? 0) + (isDnf ? 25_000 : getRacePrize(i));
        }

        // Team stats and prize money
        for (const tid of teamIds) {
          const ep = teamPointsAccum[tid] ?? 0;
          const earnings = teamPrizeAccum[tid] ?? 0;
          const inc = admin.firestore.FieldValue.increment;
          const tRef = db.collection("teams").doc(tid);

          const tu: Record<string, unknown> = { budget: inc(earnings), races: inc(1), seasonRaces: inc(1) };
          if (ep > 0) { tu["points"] = inc(ep); tu["seasonPoints"] = inc(ep); }

          let teamWon = false; let teamPod = 0;
          for (let i = 0; i < sorted.length; i++) {
            const d = driversMap[sorted[i]];
            if (d?.["teamId"] === tid) {
              if (i === 0 && !raceRes.dnfs.includes(sorted[i])) teamWon = true;
              if (i < 3 && !raceRes.dnfs.includes(sorted[i])) teamPod++;
            }
          }
          if (teamWon) { tu["wins"] = inc(1); tu["seasonWins"] = inc(1); }
          if (teamPod > 0) { tu["podiums"] = inc(teamPod); tu["seasonPodiums"] = inc(teamPod); }

          statsBatch.update(tRef, tu as FirebaseFirestore.UpdateData<object>);

          if (earnings > 0) {
            const txRefR = tRef.collection("transactions").doc();
            statsBatch.set(txRefR, {
              id: txRefR.id,
              description: `Race Prize Money (${rEvent["trackName"]})`,
              amount: earnings,
              date: new Date().toISOString(),
              type: "REWARD",
            });
          }
        }

        // Update season calendar
        const updCal = [...calendar];
        updCal[rIdx] = { ...updCal[rIdx], isCompleted: true };
        statsBatch.update(db.collection("seasons").doc(sId as string), { calendar: updCal });
        await statsBatch.commit();

        // Office news + debrief per team
        const teamGrp: Record<string, { id: string; name: string; pos: string; posInt: number; pts: number; isDnf: boolean }[]> = {};
        sorted.forEach((did, i) => {
          const d = driversMap[did];
          if (!d) return;
          const isDnf = raceRes.dnfs.includes(did);
          if (!teamGrp[d["teamId"] as string]) teamGrp[d["teamId"] as string] = [];
          teamGrp[d["teamId"] as string].push({
            id: did,
            name: d["name"] as string,
            pos: isDnf ? "DNF" : `P${i + 1}`,
            posInt: i + 1,
            pts: !isDnf && i < POINT_SYSTEM.length ? POINT_SYSTEM[i] : 0,
            isDnf,
          });
        });

        for (const tid of teamIds) {
          const drivers = teamGrp[tid] ?? [];
          if (!drivers.length) continue;
          const earn = teamPrizeAccum[tid] ?? 0;
          const lines = drivers.map((d) => `${d.name}: ${d.pos} (+${d.pts} pts)`).join("\n");

          let debrief = "";
          const p1 = drivers[0]; const p2 = drivers[1];
          if (p1 && p2) {
            const avgPos = (p1.isDnf ? 20 : p1.posInt) + (p2.isDnf ? 20 : p2.posInt);
            if (avgPos <= 10) debrief = "Excellent weekend! Both drivers brought home solid points. The strategy was spot on.";
            else if (p1.isDnf || p2.isDnf) debrief = "A tough one. Any DNF really hurts our championship chances. We need to look at reliability and driver focus.";
            else if (avgPos >= 30) debrief = "Disappointing result. We are severely lacking pace. You should check if the car updates are being effective or if the drivers need more training.";
            else debrief = "A mediocre performance. We finished roughly where we expected, but to move up the grid we need more aggressive car development.";

            const su1 = setupsMap[p1.id] ?? DEFAULT_SETUP;
            const ideal = circuit.idealSetup;
            const setupGap = Math.abs((su1["frontWing"] as number ?? 50) - ideal.frontWing) +
              Math.abs((su1["suspension"] as number ?? 50) - ideal.suspension);
            if (setupGap > 20) debrief += "\n\nNote: The drivers complained about the car's balance. It seems our current Setup is quite far from the track's ideal requirements.";
            else if (setupGap < 5) debrief += "\n\nNote: The setup was very close to perfect! The drivers felt confident in the corners.";
          }

          await db.collection("teams").doc(tid).update({ lastRaceDebrief: debrief, lastRaceResult: lines });
          await addOfficeNews(tid, {
            title: `Race Summary: ${rEvent["trackName"]}`,
            message: `${lines}\n\nANALYSIS:\n${debrief}\n\nPrize: $${earn.toLocaleString()}`,
            type: "RACE_RESULT",
          });
        }

        // Schedule post-race processing (1h later)
        await raceRef.update({
          postRaceProcessingAt: new Date(Date.now() + 60 * 60 * 1000),
          postRaceProcessed: false,
        });

        logger.info(`Race complete: ${raceDocId}`);
      } catch (eLeague) {
        logger.error(`Error processing race for league ${(league as Record<string, unknown>)["name"] ?? "unknown"}`, eLeague);
      }
    }
  } catch (err) {
    logger.error("Error in runRaceLogic", err);
  }
}

// ─── Scheduled export ─────────────────────────────────────────────────────────

/** Scheduled race trigger — Sunday 14:00 COT. */
export const scheduledRace = onSchedule({
  schedule: "0 14 * * 0",
  timeZone: "America/Bogota",
  memory: "1GiB",
  timeoutSeconds: 540,
}, async () => {
  logger.info("=== RACE START ===");
  await runRaceLogic();
});

/** onCall handler to force a race manually (requires auth). */
export const forceRace = onCall({
  cors: true,
  memory: "1GiB",
  timeoutSeconds: 540,
}, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthorized");
    await runRaceLogic();
    return { success: true, message: "Race forced successfully!" };
  } catch (e) {
    logger.error("Error forcing race", e);
    return { success: false, error: String(e) };
  }
});
