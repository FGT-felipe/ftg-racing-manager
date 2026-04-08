/**
 * Admin utility Cloud Functions.
 * Extracted from functions/index.js (lines 2466–2695).
 *
 * These are privileged onCall functions used for data repair and maintenance.
 * All require Firebase Auth unless they use invoker: "public" (legacy admin tooling).
 */

import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db, admin } from "../../shared/admin";
import { addOfficeNews } from "../../shared/notifications";
import { generateTeamDebrief, syncUniverseStats } from "../economy/post-race";

// ─── megaFixDebriefs ──────────────────────────────────────────────────────────

/**
 * Regenerates race debriefs for every team across all leagues.
 * Uses the last completed race in each league's current season.
 *
 * @returns Object with { success, updated } count.
 */
export const megaFixDebriefs = onCall({
  cors: true,
  enforceAppCheck: true,  // Uncomment after enabling App Check in Firebase Console
  memory: "1GiB",
  timeoutSeconds: 540,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const isDryRun = !!(request.data as Record<string, unknown>)?.["dryRun"];
  logger.info("=== MEGA FIX DEBRIEFS START ===", { uid: request.auth.uid, dryRun: isDryRun });
  try {
    const leaguesSnap = await db.collection("leagues").get();
    let totalUpdated = 0;
    const affectedDocIds: string[] = [];

    // Fetch all drivers once to avoid per-loop Firestore reads
    const dSnap = await db.collection("drivers").get();
    const driversMap: Record<string, Record<string, unknown>> = {};
    dSnap.forEach((doc) => {
      driversMap[doc.id] = { ...(doc.data() as Record<string, unknown>), id: doc.id };
    });

    // Group drivers by team once
    const teamGrp: Record<string, Record<string, unknown>[]> = {};
    Object.values(driversMap).forEach((d) => {
      const tid = d["teamId"] as string;
      if (!tid) return;
      if (!teamGrp[tid]) teamGrp[tid] = [];
      teamGrp[tid].push(d);
    });

    for (const lDoc of leaguesSnap.docs) {
      const league = lDoc.data() as Record<string, unknown>;
      const sId = league["currentSeasonId"] as string | undefined;
      if (!sId) continue;

      const sDoc = await db.collection("seasons").doc(sId).get();
      if (!sDoc.exists) continue;
      const season = sDoc.data() as Record<string, unknown>;

      // Find last completed race
      let rIdx = -1;
      const calendar = (season["calendar"] as Record<string, unknown>[]) ?? [];
      for (let i = calendar.length - 1; i >= 0; i--) {
        if (calendar[i]["isCompleted"]) { rIdx = i; break; }
      }
      if (rIdx === -1) {
        logger.info(`League ${lDoc.id} has no completed races.`);
        continue;
      }

      const rEvent = calendar[rIdx];
      const raceDocId = `${sId}_${rEvent["id"]}`;
      const rSnap = await db.collection("races").doc(raceDocId).get();
      if (!rSnap.exists) {
        logger.warn(`No race doc for ${raceDocId}`);
        continue;
      }

      const rData = rSnap.data() as Record<string, unknown>;

      for (const tid of Object.keys(teamGrp)) {
        if (isDryRun) {
          affectedDocIds.push(`teams/${tid}`);
        } else {
          await generateTeamDebrief(tid, teamGrp[tid], rData, rEvent);
        }
        totalUpdated++;
      }
    }

    if (isDryRun) {
      return {
        dryRun: true,
        affectedDocIds,
        summary: `${affectedDocIds.length} teams across ${leaguesSnap.size} leagues`,
      };
    }

    logger.info(`=== MEGA FIX COMPLETED: ${totalUpdated} updated ===`);
    return { success: true, updated: totalUpdated };
  } catch (err) {
    logger.error("MegaFix failed", err);
    return { success: false, error: (err as Error).message };
  }
});

// ─── forceFixGBA ──────────────────────────────────────────────────────────────

/**
 * Regenerates the race debrief specifically for the GBA Racing team.
 * One-off repair tool kept for operational emergencies.
 */
export const forceFixGBA = onCall({
  cors: true,
  enforceAppCheck: true,  // Uncomment after enabling App Check in Firebase Console
  timeoutSeconds: 120,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  logger.info("=== FORCE FIX GBA START ===", { uid: request.auth.uid });
  try {
    const teamSnap = await db.collection("teams").where("name", "==", "GBA Racing").get();
    if (teamSnap.empty) return { success: false, error: "GBA Racing not found" };

    const teamDoc = teamSnap.docs[0];
    const tid = teamDoc.id;
    const teamData = teamDoc.data() as Record<string, unknown>;
    const lId = teamData["leagueId"] as string | undefined;
    if (!lId) return { success: false, error: "League not found for GBA" };

    const lDoc = await db.collection("leagues").doc(lId).get();
    if (!lDoc.exists) return { success: false, error: "League doc not found" };
    const sId = ((lDoc.data() as Record<string, unknown>)["currentSeasonId"]) as string | undefined;
    if (!sId) return { success: false, error: "Current season not found" };

    const sDoc = await db.collection("seasons").doc(sId).get();
    if (!sDoc.exists) return { success: false, error: "Season doc not found" };
    const season = sDoc.data() as Record<string, unknown>;

    let rIdx = -1;
    const calendar = (season["calendar"] as Record<string, unknown>[]) ?? [];
    for (let i = calendar.length - 1; i >= 0; i--) {
      if (calendar[i]["isCompleted"]) { rIdx = i; break; }
    }
    if (rIdx === -1) return { success: false, error: "No completed races in this season" };

    const rEvent = calendar[rIdx];
    const raceDocId = `${sId}_${rEvent["id"]}`;
    const rSnap = await db.collection("races").doc(raceDocId).get();
    if (!rSnap.exists) return { success: false, error: `Race doc ${raceDocId} not found` };

    const rData = rSnap.data() as Record<string, unknown>;
    const results = rData["results"] as Record<string, unknown> | undefined;
    if (!results || !results["finalPositions"]) {
      return { success: false, error: "No positions in race results" };
    }

    const dSnap = await db.collection("drivers").where("teamId", "==", tid).get();
    const drivers = dSnap.docs.map((d) => ({ ...(d.data() as Record<string, unknown>), id: d.id } as Record<string, unknown>));

    const lines = drivers.map((d) => {
      const pos = (results["finalPositions"] as Record<string, number>)[d["id"] as string];
      const isDnf = ((results["dnfs"] as string[]) ?? []).includes(d["id"] as string);
      return `${d["name"]}: ${isDnf ? "DNF" : "P" + pos}`;
    }).join("\n");

    const debrief = `Analysis forced for GBA: Reviewing telemetry from ${rEvent["trackName"]}. Highlights: ${lines}`;

    await teamDoc.ref.update({ lastRaceDebrief: debrief, lastRaceResult: lines });
    await addOfficeNews(tid, {
      title: `Race Summary: ${rEvent["trackName"]}`,
      message: `${lines}\n\nANALYSIS:\n${debrief}`,
      type: "RACE_RESULT",
    });

    return { success: true, tid };
  } catch (err) {
    logger.error("forceFixGBA failed", err);
    return { success: false, error: (err as Error).message };
  }
});

// ─── restoreDriversHistory ────────────────────────────────────────────────────

/**
 * Generates synthetic career history (2020–2025) for all active drivers.
 * History is generated based on driver age and potential rating.
 *
 * @returns Object with { success, count } of drivers updated.
 */
// ─── syncUniverseCallable ─────────────────────────────────────────────────────

/**
 * Syncs the denormalized universe standings document with live data.
 * Reads seasonPoints, wins, podiums, races from teams/ and drivers/ collections
 * and writes them into universe/game_universe_v1.
 *
 * Use from the admin panel when standings appear stale after a race weekend.
 * SCOPE: universe/game_universe_v1 only — no operational collections are modified.
 */
export const syncUniverseCallable = onCall({
  cors: true,
  enforceAppCheck: true,
  timeoutSeconds: 120,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  logger.info("[syncUniverseCallable] Triggered by admin.", { uid: request.auth.uid });
  try {
    await syncUniverseStats();
    return { success: true };
  } catch (err) {
    logger.error("[syncUniverseCallable] Failed:", err);
    throw new HttpsError("internal", (err as Error).message);
  }
});

export const restoreDriversHistory = onCall({
  cors: true,
  enforceAppCheck: true,  // Uncomment after enabling App Check in Firebase Console
  memory: "512MiB",
  timeoutSeconds: 540,
}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentication required.");
  }
  const isDryRun = !!(request.data as Record<string, unknown>)?.["dryRun"];
  logger.info("restoreDriversHistory triggered", { uid: request.auth.uid, dryRun: isDryRun });
  try {
    const driversSnap = await db.collection("drivers").get();
    const teamsSnap = await db.collection("teams").get();
    const teamsMap: Record<string, string> = {};
    teamsSnap.docs.forEach((d) => {
      teamsMap[d.id] = ((d.data() as Record<string, unknown>)["name"] as string) || "Unknown Team";
    });

    const batch = db.batch();
    let count = 0;
    const affectedDocIds: string[] = [];

    for (const dDoc of driversSnap.docs) {
      const data = dDoc.data() as Record<string, unknown>;
      const isActive = data["teamId"] != null || data["isTransferListed"] === true;
      if (!isActive) continue;

      affectedDocIds.push(`drivers/${dDoc.id}`);

      if (isDryRun) {
        count++;
        continue;
      }

      const age = (data["age"] as number) || 25;
      const potential = (data["potential"] as number) || 3;
      const teamN = teamsMap[data["teamId"] as string] || "Independent";

      const wRB = potential * 0.04;
      const pRB = potential * 0.10;
      const careerHistory: Record<string, unknown>[] = [];
      let tR = 0; let tW = 0; let tP = 0; let tC = 0;

      for (let y = 2025; y >= 2020; y--) {
        const yearsAgo = 2026 - y;
        const ageAtYear = age - yearsAgo;
        if (ageAtYear < 18) continue;

        let pF = 1.0;
        if (ageAtYear < 23) pF = 0.7 + Math.random() * 0.2;
        else if (ageAtYear < 27) pF = 0.9 + Math.random() * 0.2;
        else if (ageAtYear <= 32) pF = 1.1 + Math.random() * 0.3;
        else if (ageAtYear <= 36) pF = 0.8 + Math.random() * 0.2;
        else pF = 0.5 + Math.random() * 0.3;

        const sR = 9 + Math.floor(Math.random() * 2);
        let yW = Math.floor(sR * wRB * pF * (0.8 + Math.random() * 0.4));
        let yP = Math.floor(sR * pRB * pF * (0.8 + Math.random() * 0.4));
        if (yW > sR) yW = sR;
        if (yP > sR) yP = sR;
        if (yP < yW) yP = yW;

        const isC = yW >= 5 && Math.random() > 0.6;

        careerHistory.push({
          year: y,
          teamName: data["teamId"] ? teamN : "Independiente",
          series: "FTG LEAGUE",
          races: sR,
          wins: yW,
          podiums: yP,
          isChampion: isC,
        });

        tR += sR; tW += yW; tP += yP;
        if (isC) tC++;
      }

      batch.update(dDoc.ref, {
        races: tR,
        wins: tW,
        podiums: tP,
        championships: tC,
        careerHistory,
      });
      count++;
    }

    if (isDryRun) {
      return {
        dryRun: true,
        affectedDocIds,
        summary: `${affectedDocIds.length} active drivers`,
      };
    }

    await batch.commit();
    return { success: true, count };
  } catch (err) {
    logger.error("restoreDriversHistory failed", err);
    return { success: false, error: (err as Error).message };
  }
});
