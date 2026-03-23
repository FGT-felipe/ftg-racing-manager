"use strict";
/**
 * Admin utility Cloud Functions.
 * Extracted from functions/index.js (lines 2466–2695).
 *
 * These are privileged onCall functions used for data repair and maintenance.
 * All require Firebase Auth unless they use invoker: "public" (legacy admin tooling).
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
exports.restoreDriversHistory = exports.forceFixGBA = exports.megaFixDebriefs = void 0;
const logger = __importStar(require("firebase-functions/logger"));
const https_1 = require("firebase-functions/v2/https");
const admin_1 = require("../../shared/admin");
const notifications_1 = require("../../shared/notifications");
const post_race_1 = require("../economy/post-race");
// ─── megaFixDebriefs ──────────────────────────────────────────────────────────
/**
 * Regenerates race debriefs for every team across all leagues.
 * Uses the last completed race in each league's current season.
 *
 * @returns Object with { success, updated } count.
 */
exports.megaFixDebriefs = (0, https_1.onCall)({
    cors: true,
    invoker: "public",
    memory: "1GiB",
    timeoutSeconds: 540,
}, async () => {
    logger.info("=== MEGA FIX DEBRIEFS START ===");
    try {
        const leaguesSnap = await admin_1.db.collection("leagues").get();
        let totalUpdated = 0;
        // Fetch all drivers once to avoid per-loop Firestore reads
        const dSnap = await admin_1.db.collection("drivers").get();
        const driversMap = {};
        dSnap.forEach((doc) => {
            driversMap[doc.id] = { ...doc.data(), id: doc.id };
        });
        for (const lDoc of leaguesSnap.docs) {
            const league = lDoc.data();
            const sId = league["currentSeasonId"];
            if (!sId)
                continue;
            const sDoc = await admin_1.db.collection("seasons").doc(sId).get();
            if (!sDoc.exists)
                continue;
            const season = sDoc.data();
            // Find last completed race
            let rIdx = -1;
            const calendar = season["calendar"] ?? [];
            for (let i = calendar.length - 1; i >= 0; i--) {
                if (calendar[i]["isCompleted"]) {
                    rIdx = i;
                    break;
                }
            }
            if (rIdx === -1) {
                logger.info(`League ${lDoc.id} has no completed races.`);
                continue;
            }
            const rEvent = calendar[rIdx];
            const raceDocId = `${sId}_${rEvent["id"]}`;
            const rSnap = await admin_1.db.collection("races").doc(raceDocId).get();
            if (!rSnap.exists) {
                logger.warn(`No race doc for ${raceDocId}`);
                continue;
            }
            const rData = rSnap.data();
            // Group drivers by team
            const teamGrp = {};
            Object.values(driversMap).forEach((d) => {
                const tid = d["teamId"];
                if (!teamGrp[tid])
                    teamGrp[tid] = [];
                teamGrp[tid].push(d);
            });
            for (const tid of Object.keys(teamGrp)) {
                await (0, post_race_1.generateTeamDebrief)(tid, teamGrp[tid], rData, rEvent);
                totalUpdated++;
            }
        }
        logger.info(`=== MEGA FIX COMPLETED: ${totalUpdated} updated ===`);
        return { success: true, updated: totalUpdated };
    }
    catch (err) {
        logger.error("MegaFix failed", err);
        return { success: false, error: err.message };
    }
});
// ─── forceFixGBA ──────────────────────────────────────────────────────────────
/**
 * Regenerates the race debrief specifically for the GBA Racing team.
 * One-off repair tool kept for operational emergencies.
 */
exports.forceFixGBA = (0, https_1.onCall)({
    cors: true,
    invoker: "public",
    timeoutSeconds: 120,
}, async () => {
    logger.info("=== FORCE FIX GBA START ===");
    try {
        const teamSnap = await admin_1.db.collection("teams").where("name", "==", "GBA Racing").get();
        if (teamSnap.empty)
            return { success: false, error: "GBA Racing not found" };
        const teamDoc = teamSnap.docs[0];
        const tid = teamDoc.id;
        const teamData = teamDoc.data();
        const lId = teamData["leagueId"];
        if (!lId)
            return { success: false, error: "League not found for GBA" };
        const lDoc = await admin_1.db.collection("leagues").doc(lId).get();
        if (!lDoc.exists)
            return { success: false, error: "League doc not found" };
        const sId = (lDoc.data()["currentSeasonId"]);
        if (!sId)
            return { success: false, error: "Current season not found" };
        const sDoc = await admin_1.db.collection("seasons").doc(sId).get();
        if (!sDoc.exists)
            return { success: false, error: "Season doc not found" };
        const season = sDoc.data();
        let rIdx = -1;
        const calendar = season["calendar"] ?? [];
        for (let i = calendar.length - 1; i >= 0; i--) {
            if (calendar[i]["isCompleted"]) {
                rIdx = i;
                break;
            }
        }
        if (rIdx === -1)
            return { success: false, error: "No completed races in this season" };
        const rEvent = calendar[rIdx];
        const raceDocId = `${sId}_${rEvent["id"]}`;
        const rSnap = await admin_1.db.collection("races").doc(raceDocId).get();
        if (!rSnap.exists)
            return { success: false, error: `Race doc ${raceDocId} not found` };
        const rData = rSnap.data();
        const results = rData["results"];
        if (!results || !results["finalPositions"]) {
            return { success: false, error: "No positions in race results" };
        }
        const dSnap = await admin_1.db.collection("drivers").where("teamId", "==", tid).get();
        const drivers = dSnap.docs.map((d) => ({ ...d.data(), id: d.id }));
        const lines = drivers.map((d) => {
            const pos = results["finalPositions"][d["id"]];
            const isDnf = (results["dnfs"] ?? []).includes(d["id"]);
            return `${d["name"]}: ${isDnf ? "DNF" : "P" + pos}`;
        }).join("\n");
        const debrief = `Analysis forced for GBA: Reviewing telemetry from ${rEvent["trackName"]}. Highlights: ${lines}`;
        await teamDoc.ref.update({ lastRaceDebrief: debrief, lastRaceResult: lines });
        await (0, notifications_1.addOfficeNews)(tid, {
            title: `Race Summary: ${rEvent["trackName"]}`,
            message: `${lines}\n\nANALYSIS:\n${debrief}`,
            type: "RACE_RESULT",
        });
        return { success: true, tid };
    }
    catch (err) {
        logger.error("forceFixGBA failed", err);
        return { success: false, error: err.message };
    }
});
// ─── restoreDriversHistory ────────────────────────────────────────────────────
/**
 * Generates synthetic career history (2020–2025) for all active drivers.
 * History is generated based on driver age and potential rating.
 *
 * @returns Object with { success, count } of drivers updated.
 */
exports.restoreDriversHistory = (0, https_1.onCall)({
    cors: true,
    invoker: "public",
    memory: "512MiB",
    timeoutSeconds: 540,
}, async (request) => {
    logger.info("restoreDriversHistory triggered", {
        auth: request.auth ? request.auth.uid : null,
    });
    try {
        const driversSnap = await admin_1.db.collection("drivers").get();
        const teamsSnap = await admin_1.db.collection("teams").get();
        const teamsMap = {};
        teamsSnap.docs.forEach((d) => {
            teamsMap[d.id] = d.data()["name"] || "Unknown Team";
        });
        const batch = admin_1.db.batch();
        let count = 0;
        for (const dDoc of driversSnap.docs) {
            const data = dDoc.data();
            const isActive = data["teamId"] != null || data["isTransferListed"] === true;
            if (!isActive)
                continue;
            const age = data["age"] || 25;
            const potential = data["potential"] || 3;
            const teamN = teamsMap[data["teamId"]] || "Independent";
            const wRB = potential * 0.04;
            const pRB = potential * 0.10;
            const careerHistory = [];
            let tR = 0;
            let tW = 0;
            let tP = 0;
            let tC = 0;
            for (let y = 2025; y >= 2020; y--) {
                const yearsAgo = 2026 - y;
                const ageAtYear = age - yearsAgo;
                if (ageAtYear < 18)
                    continue;
                let pF = 1.0;
                if (ageAtYear < 23)
                    pF = 0.7 + Math.random() * 0.2;
                else if (ageAtYear < 27)
                    pF = 0.9 + Math.random() * 0.2;
                else if (ageAtYear <= 32)
                    pF = 1.1 + Math.random() * 0.3;
                else if (ageAtYear <= 36)
                    pF = 0.8 + Math.random() * 0.2;
                else
                    pF = 0.5 + Math.random() * 0.3;
                const sR = 9 + Math.floor(Math.random() * 2);
                let yW = Math.floor(sR * wRB * pF * (0.8 + Math.random() * 0.4));
                let yP = Math.floor(sR * pRB * pF * (0.8 + Math.random() * 0.4));
                if (yW > sR)
                    yW = sR;
                if (yP > sR)
                    yP = sR;
                if (yP < yW)
                    yP = yW;
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
                tR += sR;
                tW += yW;
                tP += yP;
                if (isC)
                    tC++;
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
        await batch.commit();
        return { success: true, count };
    }
    catch (err) {
        logger.error("restoreDriversHistory failed", err);
        return { success: false, error: err.message };
    }
});
