/**
 * Season-end pure helpers: prize lookup, standings sort, champion detection.
 * Zero Firebase calls — all functions are deterministic and testable in isolation.
 */

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
