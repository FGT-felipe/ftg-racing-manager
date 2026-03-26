/**
 * Qualifying orchestrator — reads from / writes to Firestore.
 * Calls simulateLap() from sim-engine for the actual physics.
 *
 * Faithfully extracted from runQualifyingLogic() in functions/index.js
 * (lines 866–1177) plus the forceQualy onCall handler.
 */

import * as logger from "firebase-functions/logger";
import { onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { db, admin } from "../../shared/admin";
import { getCircuit } from "../../config/circuits";
import { DEFAULT_SETUP, QUALY_PRIZES } from "../../config/constants";
import { fetchTeams } from "../../shared/firestore";
import { addOfficeNews } from "../../shared/notifications";
import { sleep } from "../../shared/utils";
import { simulateLap } from "./sim-engine";

// ─── Core logic ───────────────────────────────────────────────────────────────

/**
 * Runs the qualifying simulation for all leagues.
 * Writes qualyGrid and qualifyingResults to the Race document.
 *
 * Guard: skips leagues where qualyGrid.length > 0 already exists.
 * This prevents double-processing (the exact fix for the R2 bug).
 */
export async function runQualifyingLogic(): Promise<void> {
  logger.info("=== QUALIFYING START ===");

  try {
    const uDoc = await db.collection("universe").doc("game_universe_v1").get();
    if (!uDoc.exists) {
      logger.error("Universe not found");
      return;
    }
    const leagues = Object.values((uDoc.data() as Record<string, unknown>).leagues as Record<string, unknown> ?? {});

    let leagueIdx = 0;
    for (const league of leagues as Record<string, unknown>[]) {
      try {
        // Staggered: 15s between leagues (prevents timeout while giving DB a breather)
        if (leagueIdx > 0) await sleep(15 * 1000);
        leagueIdx++;

        // --- Self-healing season lookup ---
        let sId = league["currentSeasonId"] as string | undefined;
        let sDoc = sId ? await db.collection("seasons").doc(sId).get() : null;

        if (!sDoc || !sDoc.exists) {
          logger.info(`Season ${sId ?? "N/A"} not found for ${league["name"]}, falling back to latest season...`);
          const fallback = await db.collection("seasons").orderBy("startDate", "desc").limit(1).get();
          if (fallback.empty) {
            logger.info(`Skip league ${league["name"]}: No seasons exist at all`);
            continue;
          }
          sDoc = fallback.docs[0];
          sId = sDoc.id;
          logger.info(`Using fallback season: ${sId}`);
        }
        const season = sDoc.data() as Record<string, unknown>;

        const raceEvent = (season["calendar"] as Record<string, unknown>[] ?? [])
          .find((r) => !r["isCompleted"]) as Record<string, unknown> | undefined;
        if (!raceEvent) {
          logger.info(`Skip league ${league["name"]}: No pending races in calendar`);
          continue;
        }

        const circuit = getCircuit(raceEvent["circuitId"] as string);
        const raceDocId = `${sId}_${raceEvent["id"]}`;
        const rRef = db.collection("races").doc(raceDocId);
        const rSnap = await rRef.get();

        // ⚠️  CRITICAL GUARD: must check .length > 0, not just existence.
        // An empty array [] is truthy in JS — this was the R2 bug.
        if (rSnap.exists && (rSnap.data()?.["qualyGrid"] as unknown[])?.length > 0) {
          logger.info(`Qualy already done: ${raceDocId}`);
          continue;
        }

        logger.info(`Qualy: ${league["name"]} - ${raceEvent["trackName"]}`);

        // Gather all team IDs
        const teamIds: string[] = [];
        const leagueTeams = league["teams"] as { id?: string }[] | undefined;
        if (leagueTeams && leagueTeams.length > 0) {
          teamIds.push(...leagueTeams.map((t) => t.id ?? (t as unknown as string)));
        } else {
          const divisions = league["divisions"] as { teamIds?: string[] }[] ?? [];
          divisions.forEach((d) => { if (d.teamIds) teamIds.push(...d.teamIds); });
        }
        if (!teamIds.length) {
          logger.info(`Skip league ${league["name"]}: No teams found`);
          continue;
        }

        const teamDocs = await fetchTeams(teamIds);

        // Build manager roles map
        const managerRoles: Record<string, string> = {};
        for (const tDoc of teamDocs) {
          const t = tDoc.data() as Record<string, unknown>;
          if (t["managerId"]) {
            const mgrDoc = await db.collection("managers").doc(t["managerId"] as string).get();
            if (mgrDoc.exists) {
              managerRoles[t["id"] as string] = (mgrDoc.data() as Record<string, unknown>)["role"] as string ?? "";
            }
          }
        }

        const statsBatch = db.batch();
        const qualyResults: Record<string, unknown>[] = [];

        for (const tDoc of teamDocs) {
          const team = tDoc.data() as Record<string, unknown>;
          const dSnap = await db.collection("drivers").where("teamId", "==", team["id"]).get();

          for (let di = 0; di < dSnap.docs.length; di++) {
            const dDoc = dSnap.docs[di];
            const driver: Record<string, unknown> = { ...dDoc.data(), id: dDoc.id, carIndex: di };

            let finalLapTime = 0.0;
            let isCrashed = false;
            let tyreCompound = "medium";
            let setupSubmitted = false;

            let setup: Record<string, unknown> = { ...DEFAULT_SETUP };
            const ws = (team["weekStatus"] as Record<string, unknown>) ?? {};
            const ds = ((ws["driverSetups"] as Record<string, unknown>) ?? {})[driver["id"] as string] as Record<string, unknown> | undefined;
            const sent = ds && ds["isSetupSent"];

            if (team["isBot"]) {
              const ideal = circuit.idealSetup;
              setup["frontWing"] = ideal.frontWing + Math.floor(Math.random() * 10) - 5;
              setup["rearWing"] = ideal.rearWing + Math.floor(Math.random() * 10) - 5;
              setup["suspension"] = ideal.suspension + Math.floor(Math.random() * 10) - 5;
              setup["gearRatio"] = ideal.gearRatio + Math.floor(Math.random() * 10) - 5;
              const styles = ["normal", "normal", "offensive", "mostRisky"];
              setup["qualifyingStyle"] = styles[Math.floor(Math.random() * styles.length)];
              setupSubmitted = true;
            } else if (sent && ds?.["qualifying"]) {
              setup = { ...DEFAULT_SETUP, ...(ds["qualifying"] as Record<string, unknown>) };
              setupSubmitted = true;
            }

            if (driver["isTransferListed"]) {
              const ySnap = await db.collection("teams").doc(team["id"] as string)
                .collection("academy").doc("config")
                .collection("selected").limit(1).get();
              if (!ySnap.empty) {
                const yData = ySnap.docs[0].data() as Record<string, unknown>;
                driver["name"] = (yData["name"] as string) + " (Academy)";
                const base = (yData["baseSkill"] as number) || 50;
                driver["stats"] = {
                  braking: base, cornering: base, smoothness: base,
                  overtaking: base, consistency: base, adaptability: base,
                  focus: base, feedback: base, fitness: 100, morale: 100, marketability: 30,
                };
              } else {
                driver["stats"] = { braking: 1, cornering: 1, smoothness: 1, overtaking: 1, consistency: 1, adaptability: 1, focus: 1, feedback: 1, fitness: 1 };
                isCrashed = true;
              }
              setup = { ...DEFAULT_SETUP, frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50, qualifyingStyle: "normal" };
              setupSubmitted = true;
            }

            if (!driver["isTransferListed"] && !team["isBot"] && ds && ds["qualifyingBestTime"] && (ds["qualifyingBestTime"] as number) > 0) {
              finalLapTime = ds["qualifyingBestTime"] as number;
              isCrashed = (ds["qualifyingDnf"] as boolean) || false;
              tyreCompound = (ds["qualifyingBestCompound"] as string) || (setup["tyreCompound"] as string) || "medium";
            } else {
              const cs = ((team["carStats"] as Record<string, unknown>)?.[String(di)]) as Record<string, number> ?? {};
              const res = simulateLap({
                circuit,
                carStats: cs,
                driverStats: (driver["stats"] as Record<string, number>) ?? {},
                setup,
                style: (setup["qualifyingStyle"] as string) || "normal",
                teamRole: managerRoles[team["id"] as string] ?? "",
                weather: raceEvent["weatherQualifying"] as string,
                specialty: driver["specialty"] as string | undefined,
                isQualifying: true,
              });

              finalLapTime = res.lapTime;
              // Ex-Engineer: +5% qualy success (5% faster lap)
              if (!res.isCrashed && managerRoles[team["id"] as string] === "engineer") {
                finalLapTime *= 0.95;
              }
              isCrashed = res.isCrashed;
              tyreCompound = (setup["tyreCompound"] as string) || "medium";
            }

            qualyResults.push({
              driverId: driver["id"],
              driverName: driver["name"],
              teamName: team["name"],
              teamId: team["id"],
              lapTime: finalLapTime,
              isCrashed,
              tyreCompound,
              setupSubmitted: setupSubmitted || Boolean(team["isBot"]),
            });

            // --- FITNESS & MORALE IMPACT ---
            const driverStats = (driver["stats"] as Record<string, number>) ?? {};
            const currentFitness = driverStats["fitness"] ?? 100;
            const currentMorale = driverStats["morale"] ?? 100;
            const focusStat = Math.min(Math.max(driverStats["focus"] ?? 10, 1), 20);
            let fitnessPenalty = 1.5 + ((20 - focusStat) / 19) * 1.5;
            let moralePenalty = 0;

            if (!team["isBot"] && !sent) {
              fitnessPenalty += 2.0;
              moralePenalty += 2.0;
            }

            const newFitness = Math.max(0, Math.min(100, currentFitness - fitnessPenalty));
            const newMorale = Math.max(0, Math.min(100, currentMorale - moralePenalty));

            statsBatch.update(db.collection("drivers").doc(driver["id"] as string), {
              "stats.fitness": newFitness,
              "stats.morale": newMorale,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }
        }

        await statsBatch.commit();

        // Sort grid
        qualyResults.sort((a, b) => (a["lapTime"] as number) - (b["lapTime"] as number));
        if (qualyResults.length) {
          const poleTime = qualyResults[0]["lapTime"] as number;
          qualyResults.forEach((r, i) => {
            r["position"] = i + 1;
            r["gap"] = (r["lapTime"] as number) - poleTime;
          });
        }

        // Save qualifying grid
        await rRef.set({
          seasonId: sId,
          raceEventId: raceEvent["id"],
          trackName: raceEvent["trackName"],
          circuitId: raceEvent["circuitId"],
          qualyGrid: qualyResults,
          qualifyingResults: qualyResults,
          status: "qualifying",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

        // Update pole stats
        const pole = qualyResults.find((r) => !r["isCrashed"]);
        if (pole) {
          const inc = admin.firestore.FieldValue.increment(1);
          await db.collection("drivers").doc(pole["driverId"] as string).update({ poles: inc });
          await db.collection("teams").doc(pole["teamId"] as string).update({ poles: inc });
        }

        // Qualy prize money (P1: 50k, P2: 30k, P3: 15k)
        const batchQ = db.batch();
        for (let i = 0; i < Math.min(3, qualyResults.length); i++) {
          const result = qualyResults[i];
          if (result["isCrashed"]) continue;
          const prizeAmount = QUALY_PRIZES[i];
          if (!prizeAmount) continue;
          const teamRefPz = db.collection("teams").doc(result["teamId"] as string);
          batchQ.update(teamRefPz, { budget: admin.firestore.FieldValue.increment(prizeAmount) });
          const txRefQ = teamRefPz.collection("transactions").doc();
          batchQ.set(txRefQ, {
            id: txRefQ.id,
            description: `Qualifying P${i + 1} Reward (${result["driverName"]})`,
            amount: prizeAmount,
            date: new Date().toISOString(),
            type: "REWARD",
          });
        }
        await batchQ.commit();

        // Office news per team
        const teamGroups: Record<string, Record<string, unknown>[]> = {};
        qualyResults.forEach((r) => {
          const tid = r["teamId"] as string;
          if (!teamGroups[tid]) teamGroups[tid] = [];
          teamGroups[tid].push(r);
        });

        for (const [tid, drivers] of Object.entries(teamGroups)) {
          const lines = drivers
            .map((d) => `${d["driverName"]}: ${d["isCrashed"] ? "DNF (Crash)" : `P${d["position"]}`}`)
            .join("\n");
          await addOfficeNews(tid, {
            title: "Qualifying Results",
            message: lines,
            type: "QUALIFYING_RESULT",
          });
        }

        logger.info(`Qualy complete: ${raceDocId}`);
      } catch (eLeague) {
        logger.error(`Error processing qualifying for league ${(league as Record<string, unknown>)["name"] ?? "unknown"}`, eLeague);
      }
    }
  } catch (err) {
    logger.error("Error in runQualifyingLogic", err);
  }
}

// ─── Scheduled export ─────────────────────────────────────────────────────────

/** Scheduled qualifying trigger — Saturday 15:00 COT. */
export const scheduledQualifying = onSchedule({
  schedule: "0 15 * * 6",
  timeZone: "America/Bogota",
  memory: "512MiB",
  timeoutSeconds: 540,
}, async () => {
  await runQualifyingLogic();
});

/** onCall handler to force qualifying manually (requires auth). */
export const forceQualy = onCall({
  cors: true,
  memory: "512MiB",
  timeoutSeconds: 300,
}, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthorized");
    await runQualifyingLogic();
    return { success: true, message: "Qualifying forced successfully!" };
  } catch (e) {
    logger.error("Error forcing qualy", e);
    return { success: false, error: String(e) };
  }
});
