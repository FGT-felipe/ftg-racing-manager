"use strict";
/**
 * Season-end pure helpers: prize lookup, standings sort, champion detection.
 * Zero Firebase calls — all functions are deterministic and testable in isolation.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.DRIVERS_CHAMPION_MARKET_VALUE_BOOST = exports.DRIVERS_CHAMPION_TEAM_BONUS = void 0;
exports.getSeasonPrizeForPosition = getSeasonPrizeForPosition;
exports.rankTeamsByPoints = rankTeamsByPoints;
exports.findDriversChampion = findDriversChampion;
const constants_1 = require("../../config/constants");
Object.defineProperty(exports, "DRIVERS_CHAMPION_TEAM_BONUS", { enumerable: true, get: function () { return constants_1.DRIVERS_CHAMPION_TEAM_BONUS; } });
Object.defineProperty(exports, "DRIVERS_CHAMPION_MARKET_VALUE_BOOST", { enumerable: true, get: function () { return constants_1.DRIVERS_CHAMPION_MARKET_VALUE_BOOST; } });
// ─── Prize lookup ─────────────────────────────────────────────────────────────
/**
 * Returns the end-of-season constructors prize for a 1-based championship position.
 * All 10 positions (P1–P10) return a non-zero amount.
 * Any position outside the table (P11+, P0) returns 0.
 */
function getSeasonPrizeForPosition(position) {
    if (position < 1 || position > constants_1.SEASON_PRIZE_TABLE.length)
        return 0;
    return constants_1.SEASON_PRIZE_TABLE[position - 1];
}
// ─── Standings sort ───────────────────────────────────────────────────────────
/**
 * Sorts teams by seasonPoints descending and attaches a 1-based position.
 * Stable sort: equal points preserve original array order (earlier index wins).
 * Returns a new array — does not mutate the input.
 */
function rankTeamsByPoints(teams) {
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
function findDriversChampion(drivers) {
    if (drivers.length === 0)
        return null;
    return [...drivers].sort((a, b) => {
        if (b.seasonPoints !== a.seasonPoints)
            return b.seasonPoints - a.seasonPoints;
        if (b.seasonWins !== a.seasonWins)
            return b.seasonWins - a.seasonWins;
        if (b.seasonPodiums !== a.seasonPodiums)
            return b.seasonPodiums - a.seasonPodiums;
        return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
    })[0];
}
