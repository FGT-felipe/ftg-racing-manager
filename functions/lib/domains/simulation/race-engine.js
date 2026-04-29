"use strict";
/**
 * Race orchestrator — reads from / writes to Firestore.
 * Calls simulateRace() from sim-engine for the actual physics.
 *
 * Faithfully extracted from runRaceLogic() in functions/index.js
 * (lines 1223–1748) plus the forceRace onCall handler.
 * postRaceProcessing is extracted separately in domains/economy/post-race.ts.
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
exports.forceRace = exports.scheduledRace = void 0;
exports.runRaceLogic = runRaceLogic;
const logger = __importStar(require("firebase-functions/logger"));
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin_1 = require("../../shared/admin");
const circuits_1 = require("../../config/circuits");
const constants_1 = require("../../config/constants");
const firestore_1 = require("../../shared/firestore");
const notifications_1 = require("../../shared/notifications");
const utils_1 = require("../../shared/utils");
const sim_engine_1 = require("./sim-engine");
const wear_1 = require("./wear");
// ─── Core logic ───────────────────────────────────────────────────────────────
/**
 * Runs the full race simulation for all leagues.
 * Reads qualyGrid from the Race document, runs simulateRace(), and writes
 * finalPositions, stats, prize money, and debrief back to Firestore.
 *
 * Sets postRaceProcessingAt = now + 1h to trigger postRaceProcessing.
 */
async function runRaceLogic() {
    const raceStartTime = Date.now(); // T-007 S1: simRuntimeMs baseline (AC#10)
    // T-007 S2: Read parts_wear config once. Falls back to code defaults on failure — never blocks.
    // STRICT-MODE: declared before try/catch (CLAUDE.md §5.1)
    let partsWearConfig = wear_1.PARTS_WEAR_CONFIG_DEFAULTS;
    try {
        const cfgDoc = await admin_1.db.collection("universe").doc("game_universe_v1").get();
        const cfgData = cfgDoc.data()?.["config"];
        if (cfgData?.["parts_wear"]) {
            partsWearConfig = cfgData["parts_wear"];
        }
    }
    catch (eCfg) {
        logger.warn("[runRaceLogic] parts_wear config read failed, using defaults", eCfg);
    }
    try {
        const uDoc = await admin_1.db.collection("universe").doc("game_universe_v1").get();
        if (!uDoc.exists)
            return;
        const leagues = Object.values(uDoc.data().leagues ?? {});
        let leagueIdx = 0;
        for (const league of leagues) {
            try {
                if (leagueIdx > 0)
                    await (0, utils_1.sleep)(15 * 1000);
                leagueIdx++;
                // --- Self-healing season lookup ---
                let sId = league["currentSeasonId"];
                let sDoc = sId ? await admin_1.db.collection("seasons").doc(sId).get() : null;
                if (!sDoc || !sDoc.exists) {
                    logger.info(`Race: Season ${sId ?? "N/A"} not found, falling back...`);
                    const fallback = await admin_1.db.collection("seasons").orderBy("startDate", "desc").limit(1).get();
                    if (fallback.empty)
                        continue;
                    sDoc = fallback.docs[0];
                    sId = sDoc.id;
                    logger.info(`Race: Using fallback season: ${sId}`);
                }
                const season = sDoc.data();
                const calendar = season["calendar"] ?? [];
                const rIdx = calendar.findIndex((r) => !r["isCompleted"]);
                if (rIdx === -1)
                    continue;
                const rEvent = calendar[rIdx];
                const raceDocId = `${sId}_${rEvent["id"]}`;
                const rSnap = await admin_1.db.collection("races").doc(raceDocId).get();
                if (!rSnap.exists || !rSnap.data()?.["qualyGrid"]?.length) {
                    logger.warn(`No qualy grid: ${raceDocId}`);
                    continue;
                }
                const rData = rSnap.data();
                if (rData["isFinished"])
                    continue;
                const circuit = (0, circuits_1.getCircuit)(rEvent["circuitId"]);
                logger.info(`Race: ${league["name"]} - ${rEvent["trackName"]}`);
                // Build maps
                const grid = rData["qualyGrid"];
                const teamIds = [...new Set(grid.map((g) => g["teamId"]))];
                const teamDocs = await (0, firestore_1.fetchTeams)(teamIds);
                const teamsMap = {};
                teamDocs.forEach((td) => { teamsMap[td.data()["id"]] = td.data(); });
                const driversMap = {};
                const setupsMap = {};
                for (let gi = 0; gi < grid.length; gi++) {
                    const g = grid[gi];
                    const dDoc = await admin_1.db.collection("drivers").doc(g["driverId"]).get();
                    if (!dDoc.exists)
                        continue;
                    const dData = { ...dDoc.data(), id: g["driverId"] };
                    dData["carIndex"] = gi % 2;
                    driversMap[g["driverId"]] = dData;
                    const team = teamsMap[g["teamId"]] ?? {};
                    let su = { ...constants_1.DEFAULT_SETUP };
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
                    }
                    else {
                        const ws = team["weekStatus"] ?? {};
                        const ds = (ws["driverSetups"] ?? {})[g["driverId"]];
                        if (ds && (ds["isSetupSent"] || ds["raceSubmitted"]) && ds["race"]) {
                            su = { ...constants_1.DEFAULT_SETUP, ...ds["race"] };
                        }
                    }
                    if (dData["isTransferListed"]) {
                        const ySnap = await admin_1.db.collection("teams").doc(team["id"])
                            .collection("academy").doc("config")
                            .collection("selected").limit(1).get();
                        if (!ySnap.empty) {
                            const yData = ySnap.docs[0].data();
                            dData["name"] = yData["name"] + " (Academy)";
                            const base = yData["baseSkill"] || 50;
                            dData["stats"] = {
                                braking: base, cornering: base, smoothness: base,
                                overtaking: base, consistency: base, adaptability: base,
                                focus: base, feedback: base, fitness: 100, morale: 100, marketability: 30,
                            };
                        }
                        else {
                            dData["stats"] = { braking: 1, cornering: 1, smoothness: 1, overtaking: 1, consistency: 1, adaptability: 1, focus: 1, feedback: 1, fitness: 1 };
                        }
                        su = { ...constants_1.DEFAULT_SETUP, frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50, raceStyle: "defensive", pitStops: ["hard"], pitStopFuel: [50] };
                    }
                    su["tyreCompound"] = g["tyreCompound"] ?? "medium";
                    if (dData["isTransferListed"])
                        su["tyreCompound"] = "hard";
                    setupsMap[g["driverId"]] = su;
                }
                // Build manager roles map
                const managerRoles = {};
                for (const tid of teamIds) {
                    const t = teamsMap[tid];
                    if (t?.["managerId"]) {
                        const mgrDoc = await admin_1.db.collection("managers").doc(t["managerId"]).get();
                        if (mgrDoc.exists) {
                            managerRoles[tid] = mgrDoc.data()["role"] ?? "";
                        }
                    }
                }
                // T-007 S2: Pre-load all 6 parts for every team+carIndex combo.
                // Key format: `${teamId}_${carIndex}`. Missing docs silently default to empty.
                // STRICT-MODE: all variables declared before conditionals (CLAUDE.md §5.1)
                const allPartsMap = {};
                const engineConditionsMap = {}; // kept for backward compat with simulateRace
                const ALL_PART_TYPES_LOCAL = ["engine", "gearbox", "brakes", "frontWing", "rearWing", "suspension"];
                for (const driverId of Object.keys(driversMap)) {
                    const dData = driversMap[driverId];
                    const tid = dData["teamId"];
                    let carIdx = 0;
                    if (typeof dData["carIndex"] === "number")
                        carIdx = dData["carIndex"];
                    const mapKey = `${tid}_${carIdx}`;
                    if (allPartsMap[mapKey])
                        continue; // already loaded for this car
                    allPartsMap[mapKey] = {};
                    try {
                        const partsSnap = await admin_1.db
                            .collection("teams").doc(tid)
                            .collection("cars").doc(String(carIdx))
                            .collection("parts")
                            .get();
                        for (const pDoc of partsSnap.docs) {
                            if (!ALL_PART_TYPES_LOCAL.includes(pDoc.id))
                                continue;
                            const pd = pDoc.data();
                            allPartsMap[mapKey][pDoc.id] = {
                                condition: pd["condition"] ?? 100,
                                maxCondition: pd["maxCondition"] ?? 100,
                                level: pd["level"] ?? 1,
                            };
                        }
                        // Keep engineConditionsMap in sync for simulateRace backward compat
                        if (allPartsMap[mapKey]["engine"] !== undefined) {
                            engineConditionsMap[tid] = allPartsMap[mapKey]["engine"].condition;
                        }
                    }
                    catch (eParts) {
                        logger.warn(`[runRaceLogic] parts read failed for team ${tid} car ${carIdx}, defaulting to empty`, eParts);
                    }
                }
                // T-007 S2: flatten PartState → condition number for sim-engine (pure, no Firestore types)
                const allPartsConditionsMap = {};
                for (const [key, parts] of Object.entries(allPartsMap)) {
                    allPartsConditionsMap[key] = {};
                    for (const [partType, partState] of Object.entries(parts)) {
                        allPartsConditionsMap[key][partType] = partState.condition;
                    }
                }
                // Run full race (pure function)
                const raceRes = (0, sim_engine_1.simulateRace)({
                    circuit,
                    grid: grid,
                    teamsMap: teamsMap,
                    driversMap: driversMap,
                    setupsMap,
                    managerRoles,
                    engineConditionsMap,
                    raceEvent: rEvent,
                    allPartsConditionsMap,
                    failureCurve: partsWearConfig.failureCurve,
                });
                // Calculate live duration for frontend playback
                const validQualyTimes = grid.filter((g) => g["lapTime"] > 0 && g["lapTime"] < 900);
                const avgQualyTime = validQualyTimes.length > 0
                    ? validQualyTimes.reduce((s, g) => s + g["lapTime"], 0) / validQualyTimes.length
                    : circuit.baseLapTime;
                let liveDurationSec = avgQualyTime * (circuit.laps ?? 50);
                if (isNaN(liveDurationSec) || liveDurationSec <= 0) {
                    liveDurationSec = circuit.baseLapTime * (circuit.laps ?? 50);
                }
                // Save race results
                const raceRef = admin_1.db.collection("races").doc(raceDocId);
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
                    completedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
                    simRuntimeMs: Date.now() - raceStartTime, // T-007 S1: AC#10
                });
                // Save lap-by-lap data in subcollection (every 5th lap + last)
                const lapBatch = admin_1.db.batch();
                const liveColl = raceRef.collection("laps");
                for (let i = 0; i < raceRes.raceLog.length; i++) {
                    if (i % 5 === 0 || i === raceRes.raceLog.length - 1) {
                        lapBatch.set(liveColl.doc(String(raceRes.raceLog[i].lap)), raceRes.raceLog[i]);
                    }
                }
                await lapBatch.commit();
                // Lock teams for post-race processing
                for (const tid of teamIds) {
                    await admin_1.db.collection("teams").doc(tid).update({ "weekStatus.isLockedForProcessing": true });
                }
                // --- POINTS & STATS ---
                const sorted = Object.keys(raceRes.finalPositions)
                    .sort((a, b) => raceRes.finalPositions[a] - raceRes.finalPositions[b]);
                const teamPointsAccum = {};
                const teamPrizeAccum = {};
                const statsBatch = admin_1.db.batch();
                for (let i = 0; i < sorted.length; i++) {
                    const did = sorted[i];
                    const isDnf = raceRes.dnfs.includes(did);
                    const inc = admin_1.admin.firestore.FieldValue.increment;
                    const dRef = admin_1.db.collection("drivers").doc(did);
                    const dData = driversMap[did];
                    if (!dData)
                        continue;
                    const pts = i < constants_1.POINT_SYSTEM.length ? constants_1.POINT_SYSTEM[i] : 0;
                    const isWin = i === 0;
                    const isPodium = i < 3;
                    const du = { races: inc(1), seasonRaces: inc(1) };
                    if (pts > 0) {
                        du["points"] = inc(pts);
                        du["seasonPoints"] = inc(pts);
                    }
                    if (isWin) {
                        du["wins"] = inc(1);
                        du["seasonWins"] = inc(1);
                    }
                    if (isPodium) {
                        du["podiums"] = inc(1);
                        du["seasonPodiums"] = inc(1);
                    }
                    let mDelta = -5;
                    let fDelta = -0.01;
                    if (isDnf) {
                        mDelta = -15;
                        fDelta = -0.1;
                    }
                    else if (isWin) {
                        mDelta = 10;
                        fDelta = 0.1;
                    }
                    else if (isPodium) {
                        mDelta = 7;
                        fDelta = 0.05;
                    }
                    else if (pts > 0) {
                        mDelta = 3;
                        fDelta = 0.02;
                    }
                    const mRoleForStats = dData["teamId"] ? (managerRoles[dData["teamId"]] ?? "") : "";
                    if (mRoleForStats === "ex_driver")
                        mDelta += 10;
                    const curStats = dData["stats"] ?? {};
                    const newMorale = Math.min(100, Math.max(0, (curStats["morale"] ?? 50) + mDelta));
                    const newForm = Math.min(10, Math.max(1, (dData["form"] ?? 5.0) + fDelta));
                    du["stats.morale"] = newMorale;
                    du["form"] = newForm;
                    const cForm = dData["championshipForm"] ?? [];
                    cForm.unshift({ event: rEvent["trackName"], pos: isDnf ? "DNF" : `P${i + 1}`, pts, date: new Date().toISOString() });
                    if (cForm.length > 10)
                        cForm.pop();
                    du["championshipForm"] = cForm;
                    statsBatch.update(dRef, du);
                    const tid = dData["teamId"];
                    teamPointsAccum[tid] = (teamPointsAccum[tid] ?? 0) + pts;
                    teamPrizeAccum[tid] = (teamPrizeAccum[tid] ?? 0) + (isDnf ? 25_000 : (0, constants_1.getRacePrize)(i));
                }
                // Team stats and prize money
                for (const tid of teamIds) {
                    const ep = teamPointsAccum[tid] ?? 0;
                    const earnings = teamPrizeAccum[tid] ?? 0;
                    const inc = admin_1.admin.firestore.FieldValue.increment;
                    const tRef = admin_1.db.collection("teams").doc(tid);
                    const tu = { budget: inc(earnings), races: inc(1), seasonRaces: inc(1) };
                    if (ep > 0) {
                        tu["points"] = inc(ep);
                        tu["seasonPoints"] = inc(ep);
                    }
                    let teamWon = false;
                    let teamPod = 0;
                    for (let i = 0; i < sorted.length; i++) {
                        const d = driversMap[sorted[i]];
                        if (d?.["teamId"] === tid) {
                            if (i === 0 && !raceRes.dnfs.includes(sorted[i]))
                                teamWon = true;
                            if (i < 3 && !raceRes.dnfs.includes(sorted[i]))
                                teamPod++;
                        }
                    }
                    if (teamWon) {
                        tu["wins"] = inc(1);
                        tu["seasonWins"] = inc(1);
                    }
                    if (teamPod > 0) {
                        tu["podiums"] = inc(teamPod);
                        tu["seasonPodiums"] = inc(teamPod);
                    }
                    statsBatch.update(tRef, tu);
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
                statsBatch.update(admin_1.db.collection("seasons").doc(sId), { calendar: updCal });
                await statsBatch.commit();
                // T-124 S3.2: Append seasonForm entry — constructors standing after this round
                try {
                    const round = rIdx + 1;
                    const postSeasonPts = {};
                    for (const tid of teamIds) {
                        const preRacePts = teamsMap[tid]?.["seasonPoints"] ?? 0;
                        postSeasonPts[tid] = preRacePts + (teamPointsAccum[tid] ?? 0);
                    }
                    const ranked = [...teamIds].sort((a, b) => (postSeasonPts[b] ?? 0) - (postSeasonPts[a] ?? 0));
                    const formBatch = admin_1.db.batch();
                    for (let pos = 0; pos < ranked.length; pos++) {
                        const tid = ranked[pos];
                        const existing = teamsMap[tid]?.["seasonForm"] ?? [];
                        const filtered = existing.filter((e) => e["round"] !== round);
                        filtered.push({ round, trackName: rEvent["trackName"], position: pos + 1, pts: teamPointsAccum[tid] ?? 0 });
                        filtered.sort((a, b) => a["round"] - b["round"]);
                        formBatch.update(admin_1.db.collection("teams").doc(tid), { seasonForm: filtered });
                    }
                    await formBatch.commit();
                }
                catch (e) {
                    functions_1.logger.error("seasonForm append failed (non-critical):", e);
                }
                // T-007 S2: Apply wear deltas per driver/car after stats are committed (AC#7, AC#9, AC#13)
                // Wrapped in try/catch — wear failure NEVER corrupts race results
                for (const driverId of Object.keys(driversMap)) {
                    const dData = driversMap[driverId];
                    const tid = dData["teamId"];
                    let carIdx = 0;
                    if (typeof dData["carIndex"] === "number")
                        carIdx = dData["carIndex"];
                    const mapKey = `${tid}_${carIdx}`;
                    const partsMap = allPartsMap[mapKey] ?? {};
                    const raceStyle = setupsMap[driverId]?.["raceStyle"] ?? "normal";
                    const hadIncident = raceRes.dnfs.includes(driverId);
                    const weatherRace = rEvent["weatherRace"] ?? "dry";
                    try {
                        await (0, wear_1.applyWearDelta)(tid, carIdx, sId, rEvent["id"], partsMap, {
                            circuitId: rEvent["circuitId"],
                            raceStyle,
                            weather: weatherRace,
                            config: partsWearConfig,
                        }, hadIncident);
                    }
                    catch (eWear) {
                        logger.error(`[runRaceLogic:wear-apply] failed for team ${tid} car ${carIdx}`, eWear);
                    }
                }
                // Office news + debrief per team
                const teamGrp = {};
                sorted.forEach((did, i) => {
                    const d = driversMap[did];
                    if (!d)
                        return;
                    const isDnf = raceRes.dnfs.includes(did);
                    if (!teamGrp[d["teamId"]])
                        teamGrp[d["teamId"]] = [];
                    teamGrp[d["teamId"]].push({
                        id: did,
                        name: d["name"],
                        pos: isDnf ? "DNF" : `P${i + 1}`,
                        posInt: i + 1,
                        pts: !isDnf && i < constants_1.POINT_SYSTEM.length ? constants_1.POINT_SYSTEM[i] : 0,
                        isDnf,
                    });
                });
                for (const tid of teamIds) {
                    const drivers = teamGrp[tid] ?? [];
                    if (!drivers.length)
                        continue;
                    const earn = teamPrizeAccum[tid] ?? 0;
                    const lines = drivers.map((d) => `${d.name}: ${d.pos} (+${d.pts} pts)`).join("\n");
                    let debrief = "";
                    const p1 = drivers[0];
                    const p2 = drivers[1];
                    if (p1 && p2) {
                        const avgPos = (p1.isDnf ? 20 : p1.posInt) + (p2.isDnf ? 20 : p2.posInt);
                        if (avgPos <= 10)
                            debrief = "Excellent weekend! Both drivers brought home solid points. The strategy was spot on.";
                        else if (p1.isDnf || p2.isDnf)
                            debrief = "A tough one. Any DNF really hurts our championship chances. We need to look at reliability and driver focus.";
                        else if (avgPos >= 30)
                            debrief = "Disappointing result. We are severely lacking pace. You should check if the car updates are being effective or if the drivers need more training.";
                        else
                            debrief = "A mediocre performance. We finished roughly where we expected, but to move up the grid we need more aggressive car development.";
                        const su1 = setupsMap[p1.id] ?? constants_1.DEFAULT_SETUP;
                        const ideal = circuit.idealSetup;
                        const setupGap = Math.abs((su1["frontWing"] ?? 50) - ideal.frontWing) +
                            Math.abs((su1["suspension"] ?? 50) - ideal.suspension);
                        if (setupGap > 20)
                            debrief += "\n\nNote: The drivers complained about the car's balance. It seems our current Setup is quite far from the track's ideal requirements.";
                        else if (setupGap < 5)
                            debrief += "\n\nNote: The setup was very close to perfect! The drivers felt confident in the corners.";
                    }
                    await admin_1.db.collection("teams").doc(tid).update({ lastRaceDebrief: debrief, lastRaceResult: lines });
                    await (0, notifications_1.addOfficeNews)(tid, {
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
            }
            catch (eLeague) {
                logger.error(`Error processing race for league ${league["name"] ?? "unknown"}`, eLeague);
            }
        }
    }
    catch (err) {
        logger.error("Error in runRaceLogic", err);
    }
}
// ─── Scheduled export ─────────────────────────────────────────────────────────
/** Scheduled race trigger — Sunday 14:00 COT. */
exports.scheduledRace = (0, scheduler_1.onSchedule)({
    schedule: "0 14 * * 0",
    timeZone: "America/Bogota",
    memory: "1GiB",
    timeoutSeconds: 540,
}, async () => {
    logger.info("=== RACE START ===");
    await runRaceLogic();
});
/** onCall handler to force a race manually (requires auth). */
exports.forceRace = (0, https_1.onCall)({
    cors: true,
    memory: "1GiB",
    timeoutSeconds: 540,
}, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthorized");
        await runRaceLogic();
        return { success: true, message: "Race forced successfully!" };
    }
    catch (e) {
        logger.error("Error forcing race", e);
        return { success: false, error: String(e) };
    }
});
