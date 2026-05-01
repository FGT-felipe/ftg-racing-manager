"use strict";
/**
 * Season-end processing: prize distribution, career history, season closure.
 * Pure helpers at the top (zero Firebase calls, fully unit-testable).
 * runSeasonEndProcessing() at the bottom orchestrates all Firestore writes.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.DRIVERS_CHAMPION_MARKET_VALUE_BOOST = exports.DRIVERS_CHAMPION_TEAM_BONUS = void 0;
exports.getSeasonPrizeForPosition = getSeasonPrizeForPosition;
exports.rankTeamsByPoints = rankTeamsByPoints;
exports.findDriversChampion = findDriversChampion;
exports.buildSeasonHistoryEntry = buildSeasonHistoryEntry;
exports.buildCareerHistoryEntry = buildCareerHistoryEntry;
exports.runSeasonEndProcessing = runSeasonEndProcessing;
const logger = __importStar(require("firebase-functions/logger"));
const admin_1 = require("../../shared/admin");
const notifications_1 = require("../../shared/notifications");
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
function buildSeasonHistoryEntry(teamData, sId, position, year) {
    return {
        seasonId: sId,
        year,
        constructorsPosition: position,
        points: teamData["seasonPoints"] || 0,
        races: teamData["seasonRaces"] || 0,
        wins: teamData["seasonWins"] || 0,
        podiums: teamData["seasonPodiums"] || 0,
        isConstructorsChampion: position === 1,
        poles: teamData["seasonPoles"] || 0,
        teamName: teamData["name"] || "",
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
function buildCareerHistoryEntry(driverData, teamName, year, isChampion) {
    return {
        year,
        teamName,
        series: "FTG World Championship",
        races: driverData["seasonRaces"] || 0,
        wins: driverData["seasonWins"] || 0,
        podiums: driverData["seasonPodiums"] || 0,
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
async function runSeasonEndProcessing(sId, _season) {
    // Idempotency guard — prevent double-execution if postRaceProcessing fires twice
    const sDocSnap = await admin_1.db.collection("seasons").doc(sId).get();
    if (sDocSnap.exists && sDocSnap.data()["status"] === "ended") {
        logger.warn(`[runSeasonEndProcessing] Season ${sId} already ended, skipping.`);
        return;
    }
    const uSnap = await admin_1.db.collection("universe").doc("game_universe_v1").get();
    if (!uSnap.exists) {
        logger.error("[runSeasonEndProcessing] universe document not found");
        return;
    }
    const universeLeagues = uSnap.data()["leagues"] ?? [];
    const year = new Date().getFullYear();
    for (const league of universeLeagues) {
        const leagueTeamIds = (league["teams"] ?? [])
            .map((t) => t["id"])
            .filter(Boolean);
        if (leagueTeamIds.length === 0)
            continue;
        // Fetch all team docs for this league
        const teamDocs = await Promise.all(leagueTeamIds.map((tid) => admin_1.db.collection("teams").doc(tid).get()));
        const validTeamDocs = teamDocs.filter((d) => d.exists);
        // Build standings and rank
        const teamStandings = validTeamDocs.map((d) => {
            const data = d.data();
            return {
                id: d.id,
                seasonPoints: data["seasonPoints"] || 0,
            };
        });
        const ranked = rankTeamsByPoints(teamStandings);
        const batch = admin_1.db.batch();
        // ── Constructor prizes + season history ───────────────────────────────────
        for (const rankedTeam of ranked) {
            const tDoc = validTeamDocs.find((d) => d.id === rankedTeam.id);
            if (!tDoc)
                continue;
            const tData = tDoc.data();
            const tRef = admin_1.db.collection("teams").doc(rankedTeam.id);
            const prize = getSeasonPrizeForPosition(rankedTeam.position);
            const historyEntry = buildSeasonHistoryEntry(tData, sId, rankedTeam.position, year);
            const teamUpdate = {
                seasonHistory: admin_1.admin.firestore.FieldValue.arrayUnion(historyEntry),
            };
            if (prize > 0) {
                teamUpdate["budget"] = admin_1.admin.firestore.FieldValue.increment(prize);
            }
            batch.update(tRef, teamUpdate);
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
        const allLeagueDrivers = [];
        for (const tDoc of validTeamDocs) {
            const tData = tDoc.data();
            const teamName = tData["name"] || "";
            const driversSnap = await admin_1.db.collection("drivers").where("teamId", "==", tDoc.id).get();
            driversSnap.docs.forEach((d) => {
                allLeagueDrivers.push({ docId: d.id, data: d.data(), teamName });
            });
        }
        const driverStandings = allLeagueDrivers.map(({ docId, data }) => ({
            id: docId,
            teamId: data["teamId"] || "",
            seasonPoints: data["seasonPoints"] || 0,
            seasonWins: data["seasonWins"] || 0,
            seasonPodiums: data["seasonPodiums"] || 0,
        }));
        const champion = findDriversChampion(driverStandings);
        if (champion) {
            const champTeamRef = admin_1.db.collection("teams").doc(champion.teamId);
            batch.update(champTeamRef, {
                budget: admin_1.admin.firestore.FieldValue.increment(constants_1.DRIVERS_CHAMPION_TEAM_BONUS),
            });
            const champTxRef = champTeamRef.collection("transactions").doc();
            batch.set(champTxRef, {
                id: champTxRef.id,
                description: "Season Prize — Drivers Championship Bonus",
                amount: constants_1.DRIVERS_CHAMPION_TEAM_BONUS,
                date: new Date().toISOString(),
                type: "PRIZE",
            });
            // Market value boost for the champion driver
            const champDriver = allLeagueDrivers.find((d) => d.docId === champion.id);
            if (champDriver) {
                const mv = champDriver.data["marketValue"] || 0;
                const newMv = Math.round(mv * constants_1.DRIVERS_CHAMPION_MARKET_VALUE_BOOST);
                batch.update(admin_1.db.collection("drivers").doc(champion.id), {
                    marketValue: newMv,
                });
            }
        }
        // ── Driver career totals + careerHistory ──────────────────────────────────
        for (const { docId, data, teamName } of allLeagueDrivers) {
            const dRef = admin_1.db.collection("drivers").doc(docId);
            const isChampion = champion?.id === docId;
            const careerEntry = buildCareerHistoryEntry(data, teamName, year, isChampion);
            const driverUpdate = {
                races: admin_1.admin.firestore.FieldValue.increment(data["seasonRaces"] || 0),
                wins: admin_1.admin.firestore.FieldValue.increment(data["seasonWins"] || 0),
                podiums: admin_1.admin.firestore.FieldValue.increment(data["seasonPodiums"] || 0),
                careerHistory: admin_1.admin.firestore.FieldValue.arrayUnion(careerEntry),
            };
            if (isChampion) {
                driverUpdate["championships"] = admin_1.admin.firestore.FieldValue.increment(1);
            }
            batch.update(dRef, driverUpdate);
        }
        // ── Season status ─────────────────────────────────────────────────────────
        batch.update(admin_1.db.collection("seasons").doc(sId), {
            status: "ended",
        });
        await batch.commit();
        // ── Office notifications (after batch — addOfficeNews has its own write) ──
        for (const rankedTeam of ranked) {
            const tDoc = validTeamDocs.find((d) => d.id === rankedTeam.id);
            if (!tDoc)
                continue;
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
                const champName = champEntry?.data["name"] || "Your driver";
                message += ` ${champName} is the Drivers Champion! A $${constants_1.DRIVERS_CHAMPION_TEAM_BONUS.toLocaleString()} bonus has been awarded to the team.`;
            }
            await (0, notifications_1.addOfficeNews)(rankedTeam.id, {
                title: "Season Ended — Final Results",
                message,
                type: rankedTeam.position <= 3 ? "SUCCESS" : "INFO",
            });
        }
        logger.info(`[runSeasonEndProcessing] League processed. Season ${sId} ended.`);
    }
}
