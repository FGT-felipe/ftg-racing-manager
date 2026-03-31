"use strict";
/**
 * Qualifying orchestrator — reads from / writes to Firestore.
 * Calls simulateLap() from sim-engine for the actual physics.
 *
 * Faithfully extracted from runQualifyingLogic() in functions/index.js
 * (lines 866–1177) plus the forceQualy onCall handler.
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
exports.forceQualy = exports.scheduledQualifying = void 0;
exports.runQualifyingLogic = runQualifyingLogic;
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
// ─── Core logic ───────────────────────────────────────────────────────────────
/**
 * Runs the qualifying simulation for all leagues.
 * Writes qualyGrid and qualifyingResults to the Race document.
 *
 * Guard: skips leagues where qualyGrid.length > 0 already exists.
 * This prevents double-processing (the exact fix for the R2 bug).
 */
async function runQualifyingLogic() {
    logger.info("=== QUALIFYING START ===");
    try {
        const uDoc = await admin_1.db.collection("universe").doc("game_universe_v1").get();
        if (!uDoc.exists) {
            logger.error("Universe not found");
            return;
        }
        const leagues = Object.values(uDoc.data().leagues ?? {});
        let leagueIdx = 0;
        for (const league of leagues) {
            try {
                // Staggered: 15s between leagues (prevents timeout while giving DB a breather)
                if (leagueIdx > 0)
                    await (0, utils_1.sleep)(15 * 1000);
                leagueIdx++;
                // --- Self-healing season lookup ---
                let sId = league["currentSeasonId"];
                let sDoc = sId ? await admin_1.db.collection("seasons").doc(sId).get() : null;
                if (!sDoc || !sDoc.exists) {
                    logger.info(`Season ${sId ?? "N/A"} not found for ${league["name"]}, falling back to latest season...`);
                    const fallback = await admin_1.db.collection("seasons").orderBy("startDate", "desc").limit(1).get();
                    if (fallback.empty) {
                        logger.info(`Skip league ${league["name"]}: No seasons exist at all`);
                        continue;
                    }
                    sDoc = fallback.docs[0];
                    sId = sDoc.id;
                    logger.info(`Using fallback season: ${sId}`);
                }
                const season = sDoc.data();
                const raceEvent = (season["calendar"] ?? [])
                    .find((r) => !r["isCompleted"]);
                if (!raceEvent) {
                    logger.info(`Skip league ${league["name"]}: No pending races in calendar`);
                    continue;
                }
                const circuit = (0, circuits_1.getCircuit)(raceEvent["circuitId"]);
                const raceDocId = `${sId}_${raceEvent["id"]}`;
                const rRef = admin_1.db.collection("races").doc(raceDocId);
                const rSnap = await rRef.get();
                // ⚠️  CRITICAL GUARD: must check .length > 0, not just existence.
                // An empty array [] is truthy in JS — this was the R2 bug.
                if (rSnap.exists && rSnap.data()?.["qualyGrid"]?.length > 0) {
                    logger.info(`Qualy already done: ${raceDocId}`);
                    continue;
                }
                logger.info(`Qualy: ${league["name"]} - ${raceEvent["trackName"]}`);
                // Gather all team IDs
                const teamIds = [];
                const leagueTeams = league["teams"];
                if (leagueTeams && leagueTeams.length > 0) {
                    teamIds.push(...leagueTeams.map((t) => t.id ?? t));
                }
                else {
                    const divisions = league["divisions"] ?? [];
                    divisions.forEach((d) => { if (d.teamIds)
                        teamIds.push(...d.teamIds); });
                }
                if (!teamIds.length) {
                    logger.info(`Skip league ${league["name"]}: No teams found`);
                    continue;
                }
                const teamDocs = await (0, firestore_1.fetchTeams)(teamIds);
                // Build manager roles map
                const managerRoles = {};
                for (const tDoc of teamDocs) {
                    const t = tDoc.data();
                    if (t["managerId"]) {
                        const mgrDoc = await admin_1.db.collection("managers").doc(t["managerId"]).get();
                        if (mgrDoc.exists) {
                            managerRoles[t["id"]] = mgrDoc.data()["role"] ?? "";
                        }
                    }
                }
                const statsBatch = admin_1.db.batch();
                const qualyResults = [];
                for (const tDoc of teamDocs) {
                    const team = tDoc.data();
                    const dSnap = await admin_1.db.collection("drivers").where("teamId", "==", team["id"]).get();
                    for (let di = 0; di < dSnap.docs.length; di++) {
                        const dDoc = dSnap.docs[di];
                        const driver = { ...dDoc.data(), id: dDoc.id, carIndex: di };
                        let finalLapTime = 0.0;
                        let isCrashed = false;
                        let tyreCompound = "medium";
                        let setupSubmitted = false;
                        let setup = { ...constants_1.DEFAULT_SETUP };
                        const ws = team["weekStatus"] ?? {};
                        const ds = (ws["driverSetups"] ?? {})[driver["id"]];
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
                        }
                        else if (sent && ds?.["qualifying"]) {
                            setup = { ...constants_1.DEFAULT_SETUP, ...ds["qualifying"] };
                            setupSubmitted = true;
                        }
                        if (driver["isTransferListed"]) {
                            const ySnap = await admin_1.db.collection("teams").doc(team["id"])
                                .collection("academy").doc("config")
                                .collection("selected").limit(1).get();
                            if (!ySnap.empty) {
                                const yData = ySnap.docs[0].data();
                                driver["name"] = yData["name"] + " (Academy)";
                                const base = yData["baseSkill"] || 50;
                                driver["stats"] = {
                                    braking: base, cornering: base, smoothness: base,
                                    overtaking: base, consistency: base, adaptability: base,
                                    focus: base, feedback: base, fitness: 100, morale: 100, marketability: 30,
                                };
                            }
                            else {
                                driver["stats"] = { braking: 1, cornering: 1, smoothness: 1, overtaking: 1, consistency: 1, adaptability: 1, focus: 1, feedback: 1, fitness: 1 };
                                isCrashed = true;
                            }
                            setup = { ...constants_1.DEFAULT_SETUP, frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50, qualifyingStyle: "normal" };
                            setupSubmitted = true;
                        }
                        if (!driver["isTransferListed"] && !team["isBot"] && ds && ds["qualifyingBestTime"] && ds["qualifyingBestTime"] > 0) {
                            finalLapTime = ds["qualifyingBestTime"];
                            isCrashed = ds["qualifyingDnf"] || false;
                            tyreCompound = ds["qualifyingBestCompound"] || setup["tyreCompound"] || "medium";
                        }
                        else {
                            const cs = (team["carStats"]?.[String(di)]) ?? {};
                            const res = (0, sim_engine_1.simulateLap)({
                                circuit,
                                carStats: cs,
                                driverStats: driver["stats"] ?? {},
                                setup,
                                style: setup["qualifyingStyle"] || "normal",
                                teamRole: managerRoles[team["id"]] ?? "",
                                weather: raceEvent["weatherQualifying"],
                                specialty: driver["specialty"],
                                isQualifying: true,
                            });
                            finalLapTime = res.lapTime;
                            // Ex-Engineer: +5% qualy success (5% faster lap)
                            if (!res.isCrashed && managerRoles[team["id"]] === "engineer") {
                                finalLapTime *= 0.95;
                            }
                            isCrashed = res.isCrashed;
                            tyreCompound = setup["tyreCompound"] || "medium";
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
                        const driverStats = driver["stats"] ?? {};
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
                        statsBatch.update(admin_1.db.collection("drivers").doc(driver["id"]), {
                            "stats.fitness": newFitness,
                            "stats.morale": newMorale,
                            updatedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
                        });
                    }
                }
                await statsBatch.commit();
                // Sort grid
                qualyResults.sort((a, b) => a["lapTime"] - b["lapTime"]);
                if (qualyResults.length) {
                    const poleTime = qualyResults[0]["lapTime"];
                    qualyResults.forEach((r, i) => {
                        r["position"] = i + 1;
                        r["gap"] = r["lapTime"] - poleTime;
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
                    updatedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
                }, { merge: true });
                // T-020: Immutable backup — qualifying_results collection
                // SCOPE: Append-only. No pipeline or admin tool deletes or updates this collection.
                //        If qualifying is re-run via emergency scripts, this write safely overwrites
                //        the previous entry with the corrected grid.
                const qrRef = admin_1.db.collection("qualifying_results").doc(`${sId}_${raceEvent["id"]}`);
                await qrRef.set({
                    seasonId: sId,
                    raceEventId: raceEvent["id"],
                    trackName: raceEvent["trackName"],
                    circuitId: raceEvent["circuitId"],
                    qualyGrid: qualyResults,
                    createdAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
                });
                logger.info(`[qualifying_results] Backup written for ${sId}_${raceEvent["id"]} (${qualyResults.length} entries)`);
                // Update pole stats
                const pole = qualyResults.find((r) => !r["isCrashed"]);
                if (pole) {
                    const inc = admin_1.admin.firestore.FieldValue.increment(1);
                    await admin_1.db.collection("drivers").doc(pole["driverId"]).update({ poles: inc });
                    await admin_1.db.collection("teams").doc(pole["teamId"]).update({ poles: inc });
                }
                // Qualy prize money (P1: 50k, P2: 30k, P3: 15k)
                const batchQ = admin_1.db.batch();
                for (let i = 0; i < Math.min(3, qualyResults.length); i++) {
                    const result = qualyResults[i];
                    if (result["isCrashed"])
                        continue;
                    const prizeAmount = constants_1.QUALY_PRIZES[i];
                    if (!prizeAmount)
                        continue;
                    const teamRefPz = admin_1.db.collection("teams").doc(result["teamId"]);
                    batchQ.update(teamRefPz, { budget: admin_1.admin.firestore.FieldValue.increment(prizeAmount) });
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
                const teamGroups = {};
                qualyResults.forEach((r) => {
                    const tid = r["teamId"];
                    if (!teamGroups[tid])
                        teamGroups[tid] = [];
                    teamGroups[tid].push(r);
                });
                for (const [tid, drivers] of Object.entries(teamGroups)) {
                    const lines = drivers
                        .map((d) => `${d["driverName"]}: ${d["isCrashed"] ? "DNF (Crash)" : `P${d["position"]}`}`)
                        .join("\n");
                    await (0, notifications_1.addOfficeNews)(tid, {
                        title: "Qualifying Results",
                        message: lines,
                        type: "QUALIFYING_RESULT",
                    });
                }
                logger.info(`Qualy complete: ${raceDocId}`);
            }
            catch (eLeague) {
                logger.error(`Error processing qualifying for league ${league["name"] ?? "unknown"}`, eLeague);
            }
        }
    }
    catch (err) {
        logger.error("Error in runQualifyingLogic", err);
    }
}
// ─── Scheduled export ─────────────────────────────────────────────────────────
/** Scheduled qualifying trigger — Saturday 15:00 COT. */
exports.scheduledQualifying = (0, scheduler_1.onSchedule)({
    schedule: "0 15 * * 6",
    timeZone: "America/Bogota",
    memory: "512MiB",
    timeoutSeconds: 540,
}, async () => {
    await runQualifyingLogic();
});
/** onCall handler to force qualifying manually (requires auth). */
exports.forceQualy = (0, https_1.onCall)({
    cors: true,
    memory: "512MiB",
    timeoutSeconds: 300,
}, async (request) => {
    try {
        if (!request.auth)
            throw new Error("Unauthorized");
        await runQualifyingLogic();
        return { success: true, message: "Qualifying forced successfully!" };
    }
    catch (e) {
        logger.error("Error forcing qualy", e);
        return { success: false, error: String(e) };
    }
});
