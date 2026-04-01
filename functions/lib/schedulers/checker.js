"use strict";
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
exports.scheduledHourlyMaintenance = void 0;
exports.runUniverseSync = runUniverseSync;
const logger = __importStar(require("firebase-functions/logger"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin_1 = require("../shared/admin");
// ─── Universe sync ────────────────────────────────────────────────────────────
/**
 * Rebuilds universe/game_universe_v1 from live collections.
 * Updates driver teamId, stats, and adds any driver not yet tracked.
 * Mirrors the logic in scripts/emergency/sync_universe.js.
 */
async function runUniverseSync() {
    logger.info("[Checker:runUniverseSync] Starting universe sync...");
    const uRef = admin_1.db.collection("universe").doc("game_universe_v1");
    const uDoc = await uRef.get();
    if (!uDoc.exists) {
        logger.warn("[Checker:runUniverseSync] Universe doc not found — skipping.");
        return;
    }
    const leagues = uDoc.data().leagues || [];
    // Load all real drivers once
    const allDriversSnap = await admin_1.db.collection("drivers").get();
    const realDrivers = {};
    for (const d of allDriversSnap.docs) {
        realDrivers[d.id] = { id: d.id, ...d.data() };
    }
    for (let li = 0; li < leagues.length; li++) {
        const leagueTeamIds = new Set((leagues[li].teams || []).map((t) => t.id));
        // Update existing driver entries
        for (let di = 0; di < (leagues[li].drivers || []).length; di++) {
            const real = realDrivers[leagues[li].drivers[di].id];
            if (!real)
                continue;
            leagues[li].drivers[di].teamId = real.teamId || "";
            leagues[li].drivers[di].gender = real.gender || "male";
            leagues[li].drivers[di].countryCode = real.countryCode || "";
            leagues[li].drivers[di].points = real.points || 0;
            leagues[li].drivers[di].seasonPoints = real.seasonPoints || 0;
            leagues[li].drivers[di].wins = real.wins || 0;
            leagues[li].drivers[di].seasonWins = real.seasonWins || 0;
            leagues[li].drivers[di].podiums = real.podiums || 0;
            leagues[li].drivers[di].seasonPodiums = real.seasonPodiums || 0;
            leagues[li].drivers[di].races = real.races || 0;
            leagues[li].drivers[di].seasonRaces = real.seasonRaces || 0;
            leagues[li].drivers[di].championships = real.championships || 0;
            leagues[li].drivers[di].championshipForm = real.championshipForm || [];
            leagues[li].drivers[di].careerHistory = real.careerHistory || [];
        }
        // Add drivers assigned to this league's teams but not yet tracked
        const knownIds = new Set((leagues[li].drivers || []).map((d) => d.id));
        for (const real of Object.values(realDrivers)) {
            if (!real.teamId || !leagueTeamIds.has(real.teamId))
                continue;
            if (knownIds.has(real.id))
                continue;
            logger.info(`[Checker:runUniverseSync] Adding missing driver to universe: ${real.name}`);
            leagues[li].drivers.push({
                id: real.id,
                name: real.name,
                teamId: real.teamId,
                gender: real.gender || "male",
                countryCode: real.countryCode || "",
                points: real.points || 0,
                seasonPoints: real.seasonPoints || 0,
                wins: real.wins || 0,
                seasonWins: real.seasonWins || 0,
                podiums: real.podiums || 0,
                seasonPodiums: real.seasonPodiums || 0,
                races: real.races || 0,
                seasonRaces: real.seasonRaces || 0,
                championships: real.championships || 0,
                championshipForm: real.championshipForm || [],
                careerHistory: real.careerHistory || [],
            });
        }
        // Sync team stats and names
        for (let ti = 0; ti < (leagues[li].teams || []).length; ti++) {
            const tDoc = await admin_1.db.collection("teams").doc(leagues[li].teams[ti].id).get();
            if (!tDoc.exists)
                continue;
            const real = tDoc.data();
            leagues[li].teams[ti].points = real.points || 0;
            leagues[li].teams[ti].seasonPoints = real.seasonPoints || 0;
            leagues[li].teams[ti].wins = real.wins || 0;
            leagues[li].teams[ti].seasonWins = real.seasonWins || 0;
            leagues[li].teams[ti].podiums = real.podiums || 0;
            leagues[li].teams[ti].seasonPodiums = real.seasonPodiums || 0;
            leagues[li].teams[ti].races = real.races || 0;
            leagues[li].teams[ti].seasonRaces = real.seasonRaces || 0;
            if (real.name)
                leagues[li].teams[ti].name = real.name;
        }
    }
    // Sync activeSeasonId from ftg_world
    const masterLeague = await admin_1.db.collection("leagues").doc("ftg_world").get();
    const updatePayload = { leagues };
    if (masterLeague.exists) {
        const sid = masterLeague.data().currentSeasonId;
        if (sid)
            updatePayload.activeSeasonId = sid;
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
exports.scheduledHourlyMaintenance = (0, scheduler_1.onSchedule)({
    schedule: "30 * * * *",
    timeZone: "America/Bogota",
    memory: "512MiB",
    timeoutSeconds: 300,
}, async () => {
    await runUniverseSync();
});
