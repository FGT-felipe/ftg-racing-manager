/**
 * Hourly maintenance checker.
 *
 * Runs every hour and resolves any pending async state that may have been
 * left incomplete by other operations (transfers, manual fixes, admin ops).
 *
 * Current responsibilities:
 *  1. Full universe sync — keeps standings fresh regardless of what changed.
 *
 * Extensible: add new checks here as new async flows are introduced (e.g.
 * pendingNegotiation timeouts when T-028 is implemented).
 */

import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { db } from "../shared/admin";

// ─── Universe sync ────────────────────────────────────────────────────────────

/**
 * Rebuilds universe/game_universe_v1 from live collections.
 * Updates driver teamId, stats, and adds any driver not yet tracked.
 * Mirrors the logic in scripts/emergency/sync_universe.js.
 */
export async function runUniverseSync(): Promise<void> {
  logger.info("[Checker:runUniverseSync] Starting universe sync...");

  const uRef = db.collection("universe").doc("game_universe_v1");
  const uDoc = await uRef.get();
  if (!uDoc.exists) {
    logger.warn("[Checker:runUniverseSync] Universe doc not found — skipping.");
    return;
  }

  const leagues: any[] = uDoc.data()!.leagues || [];

  // Load all real drivers once
  const allDriversSnap = await db.collection("drivers").get();
  const realDrivers: Record<string, any> = {};
  for (const d of allDriversSnap.docs) {
    realDrivers[d.id] = { id: d.id, ...d.data() };
  }

  for (let li = 0; li < leagues.length; li++) {
    const leagueTeamIds = new Set<string>(
      (leagues[li].teams || []).map((t: any) => t.id as string)
    );

    // Update existing driver entries
    for (let di = 0; di < (leagues[li].drivers || []).length; di++) {
      const real = realDrivers[leagues[li].drivers[di].id];
      if (!real) continue;

      leagues[li].drivers[di].teamId          = real.teamId || "";
      leagues[li].drivers[di].gender          = real.gender || "male";
      leagues[li].drivers[di].countryCode     = real.countryCode || "";
      leagues[li].drivers[di].points          = real.points || 0;
      leagues[li].drivers[di].seasonPoints    = real.seasonPoints || 0;
      leagues[li].drivers[di].wins            = real.wins || 0;
      leagues[li].drivers[di].seasonWins      = real.seasonWins || 0;
      leagues[li].drivers[di].podiums         = real.podiums || 0;
      leagues[li].drivers[di].seasonPodiums   = real.seasonPodiums || 0;
      leagues[li].drivers[di].races           = real.races || 0;
      leagues[li].drivers[di].seasonRaces     = real.seasonRaces || 0;
      leagues[li].drivers[di].championships   = real.championships || 0;
      leagues[li].drivers[di].championshipForm = real.championshipForm || [];
      leagues[li].drivers[di].careerHistory   = real.careerHistory || [];
    }

    // Add drivers assigned to this league's teams but not yet tracked
    const knownIds = new Set<string>(
      (leagues[li].drivers || []).map((d: any) => d.id as string)
    );
    for (const real of Object.values(realDrivers)) {
      if (!real.teamId || !leagueTeamIds.has(real.teamId)) continue;
      if (knownIds.has(real.id)) continue;

      logger.info(`[Checker:runUniverseSync] Adding missing driver to universe: ${real.name}`);
      leagues[li].drivers.push({
        id:               real.id,
        name:             real.name,
        teamId:           real.teamId,
        gender:           real.gender || "male",
        countryCode:      real.countryCode || "",
        points:           real.points || 0,
        seasonPoints:     real.seasonPoints || 0,
        wins:             real.wins || 0,
        seasonWins:       real.seasonWins || 0,
        podiums:          real.podiums || 0,
        seasonPodiums:    real.seasonPodiums || 0,
        races:            real.races || 0,
        seasonRaces:      real.seasonRaces || 0,
        championships:    real.championships || 0,
        championshipForm: real.championshipForm || [],
        careerHistory:    real.careerHistory || [],
      });
    }

    // Sync team stats and names
    for (let ti = 0; ti < (leagues[li].teams || []).length; ti++) {
      const tDoc = await db.collection("teams").doc(leagues[li].teams[ti].id).get();
      if (!tDoc.exists) continue;
      const real = tDoc.data()!;

      leagues[li].teams[ti].points        = real.points || 0;
      leagues[li].teams[ti].seasonPoints  = real.seasonPoints || 0;
      leagues[li].teams[ti].wins          = real.wins || 0;
      leagues[li].teams[ti].seasonWins    = real.seasonWins || 0;
      leagues[li].teams[ti].podiums       = real.podiums || 0;
      leagues[li].teams[ti].seasonPodiums = real.seasonPodiums || 0;
      leagues[li].teams[ti].races         = real.races || 0;
      leagues[li].teams[ti].seasonRaces   = real.seasonRaces || 0;
      if (real.name) leagues[li].teams[ti].name = real.name;
    }
  }

  // Sync activeSeasonId from ftg_world
  const masterLeague = await db.collection("leagues").doc("ftg_world").get();
  const updatePayload: any = { leagues };
  if (masterLeague.exists) {
    const sid = masterLeague.data()!.currentSeasonId;
    if (sid) updatePayload.activeSeasonId = sid;
  }

  await uRef.update(updatePayload);
  logger.info("[Checker:runUniverseSync] Universe sync complete.");
}

// ─── Scheduled export ─────────────────────────────────────────────────────────

/**
 * Hourly maintenance checker.
 * Keeps universe standings fresh and handles any pending async state.
 * Schedule: every hour at :30 (offset from transfer resolver at :00).
 */
export const scheduledHourlyMaintenance = onSchedule({
  schedule: "30 * * * *",
  timeZone: "America/Bogota",
  memory: "512MiB",
  timeoutSeconds: 300,
}, async () => {
  await runUniverseSync();
});
