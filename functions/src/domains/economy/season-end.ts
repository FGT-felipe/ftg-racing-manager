/**
 * Season-end processing: prize distribution, career history, season closure.
 * Pure helpers at the top (zero Firebase calls, fully unit-testable).
 * runSeasonEndProcessing() at the bottom orchestrates all Firestore writes.
 */

import * as logger from "firebase-functions/logger";
import { db, admin } from "../../shared/admin";
import { addOfficeNews } from "../../shared/notifications";
import {
  SEASON_PRIZE_TABLE,
  DRIVERS_CHAMPION_TEAM_BONUS,
  DRIVERS_CHAMPION_MARKET_VALUE_BOOST,
} from "../../config/constants";

export { DRIVERS_CHAMPION_TEAM_BONUS, DRIVERS_CHAMPION_MARKET_VALUE_BOOST };

// ─── Types ────────────────────────────────────────────────────────────────────

export interface TeamStanding {
  id: string;
  seasonPoints: number;
  /** Populated by rankTeamsByPoints — 1-based. */
  position?: number;
}

export interface DriverStanding {
  id: string;
  teamId: string;
  seasonPoints: number;
  seasonWins: number;
  seasonPodiums: number;
}

/** One entry appended to teams/{id}.seasonHistory[] per completed season. */
export interface SeasonHistoryEntry {
  seasonId: string;
  year: number;
  constructorsPosition: number;
  points: number;
  races: number;
  wins: number;
  podiums: number;
  isConstructorsChampion: boolean;
  poles: number;
  teamName: string;
}

/** One entry appended to drivers/{id}.careerHistory[] per completed season. */
export interface CareerHistoryEntry {
  year: number;
  teamName: string;
  series: string;
  races: number;
  wins: number;
  podiums: number;
  isChampion: boolean;
}

// ─── Prize lookup ─────────────────────────────────────────────────────────────

/**
 * Returns the end-of-season constructors prize for a 1-based championship position.
 * All 10 positions (P1–P10) return a non-zero amount.
 * Any position outside the table (P11+, P0) returns 0.
 */
export function getSeasonPrizeForPosition(position: number): number {
  if (position < 1 || position > SEASON_PRIZE_TABLE.length) return 0;
  return SEASON_PRIZE_TABLE[position - 1];
}

// ─── Standings sort ───────────────────────────────────────────────────────────

/**
 * Sorts teams by seasonPoints descending and attaches a 1-based position.
 * Stable sort: equal points preserve original array order (earlier index wins).
 * Returns a new array — does not mutate the input.
 */
export function rankTeamsByPoints(teams: TeamStanding[]): (TeamStanding & { position: number })[] {
  return [...teams]
    .sort((a, b) => b.seasonPoints - a.seasonPoints)
    .map((team, idx) => ({ ...team, position: idx + 1 }));
}

// ─── Drivers champion detection ───────────────────────────────────────────────

/**
 * Identifies the Drivers Championship winner from an array of driver standings.
 * Tie-break hierarchy (all deterministic):
 *   1. Most seasonPoints
 *   2. Most seasonWins
 *   3. Most seasonPodiums
 *   4. Lexicographic driverId (ascending — "driver_a" beats "driver_b")
 * Returns null for an empty array.
 */
export function findDriversChampion(drivers: DriverStanding[]): DriverStanding | null {
  if (drivers.length === 0) return null;
  return [...drivers].sort((a, b) => {
    if (b.seasonPoints !== a.seasonPoints) return b.seasonPoints - a.seasonPoints;
    if (b.seasonWins    !== a.seasonWins)  return b.seasonWins    - a.seasonWins;
    if (b.seasonPodiums !== a.seasonPodiums) return b.seasonPodiums - a.seasonPodiums;
    return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
  })[0];
}

// ─── Pure builder helpers ─────────────────────────────────────────────────────

/**
 * Builds a SeasonHistoryEntry from raw team document data.
 * Pure — no Firebase calls. Used by runSeasonEndProcessing and unit tests.
 *
 * @param teamData Raw team Firestore document data.
 * @param sId Season ID (e.g. "S1").
 * @param position 1-based constructors championship position.
 * @param year Calendar year of the season end.
 */
export function buildSeasonHistoryEntry(
  teamData: Record<string, unknown>,
  sId: string,
  position: number,
  year: number,
): SeasonHistoryEntry {
  return {
    seasonId: sId,
    year,
    constructorsPosition: position,
    points: (teamData["seasonPoints"] as number) || 0,
    races: (teamData["seasonRaces"] as number) || 0,
    wins: (teamData["seasonWins"] as number) || 0,
    podiums: (teamData["seasonPodiums"] as number) || 0,
    isConstructorsChampion: position === 1,
    poles: (teamData["seasonPoles"] as number) || 0,
    teamName: (teamData["name"] as string) || "",
  };
}

/**
 * Builds a CareerHistoryEntry from raw driver document data.
 * Pure — no Firebase calls. Used by runSeasonEndProcessing and unit tests.
 *
 * @param driverData Raw driver Firestore document data.
 * @param teamName Team display name at time of season end.
 * @param year Calendar year of the season end.
 * @param isChampion True only for the drivers championship winner.
 */
export function buildCareerHistoryEntry(
  driverData: Record<string, unknown>,
  teamName: string,
  year: number,
  isChampion: boolean,
): CareerHistoryEntry {
  return {
    year,
    teamName,
    series: "FTG World Championship",
    races: (driverData["seasonRaces"] as number) || 0,
    wins: (driverData["seasonWins"] as number) || 0,
    podiums: (driverData["seasonPodiums"] as number) || 0,
    isChampion,
  };
}

// ─── Season-end orchestrator ──────────────────────────────────────────────────

/**
 * Runs all end-of-season processing for the given season:
 *   1. Distributes constructor championship prizes.
 *   2. Identifies and rewards the drivers champion.
 *   3. Updates driver career totals and appends careerHistory entries.
 *   4. Appends SeasonHistoryEntry (with poles + teamName) to each team.
 *   5. Sends office news notification to each team.
 *   6. Sets seasons/{sId}.status = "ended".
 *
 * Called non-fatally from runPostRaceProcessing when the final race of the season
 * is processed (all calendar entries isCompleted === true).
 * Idempotent: skips silently if seasons/{sId}.status is already "ended".
 *
 * @param sId Season document ID (e.g. "S1").
 * @param _season Raw season document data (unused — reserved for future use).
 */
export async function runSeasonEndProcessing(
  sId: string,
  _season: Record<string, unknown>,
): Promise<void> {
  // Idempotency guard — prevent double-execution if postRaceProcessing fires twice
  const sDocSnap = await db.collection("seasons").doc(sId).get();
  if (sDocSnap.exists && (sDocSnap.data() as Record<string, unknown>)["status"] === "ended") {
    logger.warn(`[runSeasonEndProcessing] Season ${sId} already ended, skipping.`);
    return;
  }

  const uSnap = await db.collection("universe").doc("game_universe_v1").get();
  if (!uSnap.exists) {
    logger.error("[runSeasonEndProcessing] universe document not found");
    return;
  }
  const universeLeagues = (
    (uSnap.data() as Record<string, unknown>)["leagues"] as Array<Record<string, unknown>>
  ) ?? [];

  const year = new Date().getFullYear();

  for (const league of universeLeagues) {
    const leagueTeamIds = (
      (league["teams"] as Array<Record<string, unknown>>) ?? []
    )
      .map((t) => t["id"] as string)
      .filter(Boolean);

    if (leagueTeamIds.length === 0) continue;

    // Fetch all team docs for this league
    const teamDocs = await Promise.all(
      leagueTeamIds.map((tid) => db.collection("teams").doc(tid).get()),
    );
    const validTeamDocs = teamDocs.filter((d) => d.exists);

    // Build standings and rank
    const teamStandings: TeamStanding[] = validTeamDocs.map((d) => {
      const data = d.data() as Record<string, unknown>;
      return {
        id: d.id,
        seasonPoints: (data["seasonPoints"] as number) || 0,
      };
    });
    const ranked = rankTeamsByPoints(teamStandings);

    const batch = db.batch();

    // ── Constructor prizes + season history ───────────────────────────────────
    for (const rankedTeam of ranked) {
      const tDoc = validTeamDocs.find((d) => d.id === rankedTeam.id);
      if (!tDoc) continue;
      const tData = tDoc.data() as Record<string, unknown>;
      const tRef = db.collection("teams").doc(rankedTeam.id);

      const prize = getSeasonPrizeForPosition(rankedTeam.position);
      const historyEntry = buildSeasonHistoryEntry(tData, sId, rankedTeam.position, year);

      const teamUpdate: Record<string, unknown> = {
        seasonHistory: admin.firestore.FieldValue.arrayUnion(historyEntry),
      };
      if (prize > 0) {
        teamUpdate["budget"] = admin.firestore.FieldValue.increment(prize);
      }
      batch.update(tRef, teamUpdate as FirebaseFirestore.UpdateData<object>);

      if (prize > 0) {
        const txRef = tRef.collection("transactions").doc();
        batch.set(txRef, {
          id: txRef.id,
          description: `Season Prize — Constructor Championship P${rankedTeam.position}`,
          amount: prize,
          date: new Date().toISOString(),
          type: "PRIZE",
        });
      }
    }

    // ── Drivers champion detection and rewards ────────────────────────────────
    // Fetch all drivers that belong to this league's teams
    const allLeagueDrivers: Array<{
      docId: string;
      data: Record<string, unknown>;
      teamName: string;
    }> = [];

    for (const tDoc of validTeamDocs) {
      const tData = tDoc.data() as Record<string, unknown>;
      const teamName = (tData["name"] as string) || "";
      const driversSnap = await db.collection("drivers").where("teamId", "==", tDoc.id).get();
      driversSnap.docs.forEach((d) => {
        allLeagueDrivers.push({ docId: d.id, data: d.data() as Record<string, unknown>, teamName });
      });
    }

    const driverStandings: DriverStanding[] = allLeagueDrivers.map(({ docId, data }) => ({
      id: docId,
      teamId: (data["teamId"] as string) || "",
      seasonPoints: (data["seasonPoints"] as number) || 0,
      seasonWins: (data["seasonWins"] as number) || 0,
      seasonPodiums: (data["seasonPodiums"] as number) || 0,
    }));

    const champion = findDriversChampion(driverStandings);

    if (champion) {
      const champTeamRef = db.collection("teams").doc(champion.teamId);
      batch.update(champTeamRef, {
        budget: admin.firestore.FieldValue.increment(DRIVERS_CHAMPION_TEAM_BONUS),
      } as FirebaseFirestore.UpdateData<object>);

      const champTxRef = champTeamRef.collection("transactions").doc();
      batch.set(champTxRef, {
        id: champTxRef.id,
        description: "Season Prize — Drivers Championship Bonus",
        amount: DRIVERS_CHAMPION_TEAM_BONUS,
        date: new Date().toISOString(),
        type: "PRIZE",
      });

      // Market value boost for the champion driver
      const champDriver = allLeagueDrivers.find((d) => d.docId === champion.id);
      if (champDriver) {
        const mv = (champDriver.data["marketValue"] as number) || 0;
        const newMv = Math.round(mv * DRIVERS_CHAMPION_MARKET_VALUE_BOOST);
        batch.update(db.collection("drivers").doc(champion.id), {
          marketValue: newMv,
        } as FirebaseFirestore.UpdateData<object>);
      }
    }

    // ── Driver career totals + careerHistory ──────────────────────────────────
    for (const { docId, data, teamName } of allLeagueDrivers) {
      const dRef = db.collection("drivers").doc(docId);
      const isChampion = champion?.id === docId;
      const careerEntry = buildCareerHistoryEntry(data, teamName, year, isChampion);

      const driverUpdate: Record<string, unknown> = {
        races: admin.firestore.FieldValue.increment((data["seasonRaces"] as number) || 0),
        wins: admin.firestore.FieldValue.increment((data["seasonWins"] as number) || 0),
        podiums: admin.firestore.FieldValue.increment((data["seasonPodiums"] as number) || 0),
        careerHistory: admin.firestore.FieldValue.arrayUnion(careerEntry),
      };
      if (isChampion) {
        driverUpdate["championships"] = admin.firestore.FieldValue.increment(1);
      }
      batch.update(dRef, driverUpdate as FirebaseFirestore.UpdateData<object>);
    }

    // ── Season status ─────────────────────────────────────────────────────────
    batch.update(db.collection("seasons").doc(sId), {
      status: "ended",
    } as FirebaseFirestore.UpdateData<object>);

    await batch.commit();

    // ── Office notifications (after batch — addOfficeNews has its own write) ──
    for (const rankedTeam of ranked) {
      const tDoc = validTeamDocs.find((d) => d.id === rankedTeam.id);
      if (!tDoc) continue;

      const prize = getSeasonPrizeForPosition(rankedTeam.position);
      const hasChampionDriver = champion?.teamId === rankedTeam.id;

      let message = `The season has ended. You finished P${rankedTeam.position} in the Constructors Championship.`;
      if (prize > 0) {
        message += ` Season prize: $${prize.toLocaleString()}.`;
      }
      if (rankedTeam.position === 1) {
        message += " Congratulations — you are the Constructors Champions!";
      }
      if (hasChampionDriver && champion) {
        const champEntry = allLeagueDrivers.find((d) => d.docId === champion.id);
        const champName = (champEntry?.data["name"] as string) || "Your driver";
        message += ` ${champName} is the Drivers Champion! A $${DRIVERS_CHAMPION_TEAM_BONUS.toLocaleString()} bonus has been awarded to the team.`;
      }

      await addOfficeNews(rankedTeam.id, {
        title: "Season Ended — Final Results",
        message,
        type: rankedTeam.position <= 3 ? "SUCCESS" : "INFO",
      });
    }

    logger.info(`[runSeasonEndProcessing] League processed. Season ${sId} ended.`);
  }
}
