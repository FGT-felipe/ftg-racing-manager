"use strict";
/**
 * Post-race processing orchestrator — reads from / writes to Firestore.
 * Extracted from postRaceProcessing onSchedule in functions/index.js (lines 1764–2282).
 *
 * Runs every 30 minutes. Finds races with isFinished=true, postRaceProcessed=false,
 * and postRaceProcessingAt <= now. For each race:
 *   1. Evaluates sponsor objectives and credits payouts.
 *   2. Charges HQ maintenance, driver salaries, fitness trainer.
 *   3. Processes academy XP growth and season-end promotions.
 *   4. Resets weekStatus.
 *   5. Upgrades AI car stats (30% chance per stat).
 *   6. Marks race as postRaceProcessed=true.
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
exports.postRaceProcessing = void 0;
exports.runPostRaceProcessing = runPostRaceProcessing;
exports.syncUniverseStats = syncUniverseStats;
exports.generateTeamDebrief = generateTeamDebrief;
const logger = __importStar(require("firebase-functions/logger"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin_1 = require("../../shared/admin");
const circuits_1 = require("../../config/circuits");
const constants_1 = require("../../config/constants");
const notifications_1 = require("../../shared/notifications");
const sponsors_1 = require("./sponsors");
const salaries_1 = require("./salaries");
// ─── Core logic ───────────────────────────────────────────────────────────────
/**
 * Processes a single race document's post-race economy:
 * sponsor payouts, salaries, academy XP, budget update, AI upgrades.
 *
 * Separated from the scheduler to allow direct invocation in tests/emergency scripts.
 */
async function runPostRaceProcessing() {
    try {
        const now = new Date();
        const racesSnap = await admin_1.db
            .collection("races")
            .where("isFinished", "==", true)
            .where("postRaceProcessed", "==", false)
            .get();
        for (const rDoc of racesSnap.docs) {
            const rd = rDoc.data();
            const pAt = rd["postRaceProcessingAt"];
            if (!pAt)
                continue;
            const procTime = pAt.toDate
                ? pAt.toDate()
                : new Date(pAt);
            if (now < procTime)
                continue;
            logger.info(`Post-race processing: ${rDoc.id}`);
            // SCOPE: All teams that participated in this race, derived directly from qualyGrid
            // (qualyGrid.teamId is authoritative — avoids broken driver-lookup chain when finalPositions is incomplete)
            const qualyGrid = rd["qualyGrid"] ?? [];
            const teamIdsSet = new Set(qualyGrid.map((g) => g["teamId"]).filter(Boolean));
            const sId = rd["seasonId"] || rDoc.id.split("_")[0];
            const eId = rd["eventId"] || rDoc.id.split("_")[1];
            const sDoc = await admin_1.db.collection("seasons").doc(sId).get();
            const season = sDoc.exists ? sDoc.data() : null;
            const rEvent = season
                ? (season["calendar"] ?? []).find((e) => e["id"] === eId) ?? null
                : null;
            // Build manager roles map for role-based economic modifiers
            const managerRoles = {};
            for (const tid of teamIdsSet) {
                const tmDoc = await admin_1.db.collection("teams").doc(tid).get();
                if (tmDoc.exists) {
                    const tmData = tmDoc.data();
                    if (tmData["managerId"]) {
                        const mgrDoc = await admin_1.db.collection("managers").doc(tmData["managerId"]).get();
                        if (mgrDoc.exists) {
                            managerRoles[tid] = mgrDoc.data()["role"] ?? "";
                        }
                    }
                }
            }
            for (const tid of teamIdsSet) {
                const tDoc = await admin_1.db.collection("teams").doc(tid).get();
                if (!tDoc.exists)
                    continue;
                const tRef = admin_1.db.collection("teams").doc(tid);
                const teamData = tDoc.data();
                const batch = admin_1.db.batch();
                const nowIso = admin_1.admin.firestore.FieldValue.serverTimestamp();
                // --- Generate race debrief ---
                const driversSnap = await admin_1.db.collection("drivers").where("teamId", "==", tid).get();
                const drivers = driversSnap.docs.map((doc) => ({ ...doc.data(), id: doc.id }));
                if (rEvent) {
                    await generateTeamDebrief(tid, drivers, rd, rEvent);
                }
                const curWs = teamData["weekStatus"] ?? {};
                let cooldown = curWs["upgradeCooldownWeeksLeft"] || 0;
                if (cooldown > 0)
                    cooldown--;
                let weeklyIncome = 0;
                let weeklyExpense = 0;
                // ── 1. Sponsor payouts & contract decrement ──────────────────────────
                const sponsors = teamData["sponsors"] ?? {};
                const updatedSponsors = {};
                const teamDriverIds = drivers.map((d) => d["id"]);
                for (const [slot, contract] of Object.entries(sponsors)) {
                    if (contract["racesRemaining"] > 0) {
                        weeklyIncome += contract["weeklyBasePayment"] || 0;
                        // Evaluate performance bonus
                        const objMet = (0, sponsors_1.evaluateObjective)(contract, rd, teamDriverIds);
                        if (objMet) {
                            const bonus = contract["objectiveBonus"] ||
                                constants_1.FALLBACK_BONUSES[contract["sponsorId"]] ||
                                0;
                            if (bonus > 0) {
                                weeklyIncome += bonus;
                                const bonusTxRef = tRef.collection("transactions").doc();
                                batch.set(bonusTxRef, {
                                    id: bonusTxRef.id,
                                    description: `Sponsor Objective Met: ${contract["sponsorName"]} (${slot})`,
                                    amount: bonus,
                                    date: nowIso,
                                    type: "SPONSOR",
                                });
                                await (0, notifications_1.addOfficeNews)(tid, {
                                    title: "Sponsor Objective Met!",
                                    message: `Congratulations! We met the ${contract["sponsorName"]} objective: "${contract["objectiveDescription"]}". A bonus of $${bonus.toLocaleString()} has been awarded.`,
                                    type: "SUCCESS",
                                });
                            }
                        }
                        contract["racesRemaining"];
                        const newRemaining = contract["racesRemaining"] - 1;
                        if (newRemaining > 0) {
                            updatedSponsors[slot] = { ...contract, racesRemaining: newRemaining };
                        }
                        else {
                            await (0, notifications_1.addOfficeNews)(tid, {
                                title: "Sponsor Contract Expired",
                                message: `The contract with ${contract["sponsorName"]} for the ${slot} slot has expired.`,
                                type: "INFO",
                            });
                        }
                    }
                }
                // ── 2. HQ maintenance ────────────────────────────────────────────────
                const facilities = teamData["facilities"] ?? {};
                const maintenanceCost = (0, salaries_1.calculateTotalFacilityMaintenance)(facilities);
                weeklyExpense += maintenanceCost;
                // ── 3. Driver salaries ───────────────────────────────────────────────
                let salaryCost = 0;
                const driverSalSnap = await admin_1.db.collection("drivers").where("teamId", "==", tid).get();
                const mRoleForEco = managerRoles[tid] ?? "";
                driverSalSnap.forEach((doc) => {
                    const d = doc.data();
                    salaryCost += (0, salaries_1.calculateWeeklyDriverSalary)(d, mRoleForEco);
                });
                weeklyExpense += salaryCost;
                // ── 3.5 Fitness trainer salary ───────────────────────────────────────
                const trainerLevel = curWs["fitnessTrainerLevel"] || 1;
                const trainerSalary = (0, salaries_1.calculateFitnessTrainerCost)(trainerLevel);
                if (trainerSalary > 0) {
                    weeklyExpense += trainerSalary;
                }
                // ── 4. Academy processing ────────────────────────────────────────────
                const academyConfigDoc = await admin_1.db
                    .collection("teams").doc(tid)
                    .collection("academy").doc("config").get();
                if (academyConfigDoc.exists) {
                    const ac = academyConfigDoc.data();
                    const academyLevel = ac["academyLevel"] || 1;
                    const countryCode = ac["countryCode"] || "GB";
                    const mRole = managerRoles[tid] ?? "";
                    await refreshAcademyCandidates(tid, academyLevel, countryCode, mRole);
                    const selectedRef = admin_1.db
                        .collection("teams").doc(tid)
                        .collection("academy").doc("config")
                        .collection("selected");
                    const selectedSnap = await selectedRef.get();
                    const batchA = admin_1.db.batch();
                    selectedSnap.docs.forEach((sDoc) => {
                        const yDriver = sDoc.data();
                        const weeklyAcademyCost = 10_000;
                        weeklyExpense += weeklyAcademyCost;
                        // Apply XP from weekly karting simulation
                        let curWeekly = yDriver["weeklyGrowth"] || 0;
                        const growthPot = yDriver["growthPotential"] || 5;
                        const levelBonus = (academyLevel - 1) * 8;
                        let xpGain = Math.floor(Math.random() * (growthPot * 15)) + 40 + levelBonus;
                        // Lead Engineer: -5% driver XP gain
                        if (mRole === "engineer") {
                            xpGain = Math.floor(xpGain * 0.95);
                        }
                        curWeekly += xpGain;
                        let applyBaseGrowth = false;
                        const statDiffs = {};
                        let eventMsg = "";
                        if (curWeekly >= 500) {
                            curWeekly -= 500;
                            applyBaseGrowth = true;
                        }
                        const updates = {
                            weeklyGrowth: curWeekly,
                            weeklyStatDiffs: {},
                            weeklyEventMessage: "",
                        };
                        if (applyBaseGrowth) {
                            updates["baseSkill"] = (yDriver["baseSkill"] || 10) + 1;
                            updates["growthPotential"] = Math.max((yDriver["growthPotential"] || 5) - 1, 1);
                            const statsObj = yDriver["stats"] || {
                                cornering: 6, braking: 6, consistency: 6, smoothness: 6,
                                adaptability: 6, overtaking: 6, focus: 6, fitness: 6,
                            };
                            const keys = Object.keys(statsObj);
                            const boostedStat = keys[Math.floor(Math.random() * keys.length)];
                            statsObj[boostedStat] = (statsObj[boostedStat] || 0) + 1;
                            statDiffs[boostedStat] = 1;
                            const positiveEvents = {
                                adaptability: [`${yDriver["name"]} amazed the engineers with their pace in the rain.`, `${yDriver["name"]} quickly adapted to a drastic change in the weather.`],
                                cornering: [`${yDriver["name"]} spent extra hours perfecting their line through curves.`, `${yDriver["name"]} demonstrated impeccable cornering in the simulator.`],
                                smoothness: [`${yDriver["name"]} showed great finesse with the tires.`, `${yDriver["name"]} remarkably improved their driving fluidness.`],
                                braking: [`${yDriver["name"]} showed great skill and confidence in braking late.`, `${yDriver["name"]} adjusted their braking technique to gain time.`],
                                overtaking: [`${yDriver["name"]} performed brilliant overtaking maneuvers in their last race.`, `${yDriver["name"]} showed perfect calculated aggressiveness for passing.`],
                                consistency: [`${yDriver["name"]} remained unshakable under pressure, maintaining constant lap times.`, `${yDriver["name"]} did not make a single mistake throughout the testing week.`],
                                focus: [`${yDriver["name"]} was extremely concentrated, ignoring external distractions.`, `${yDriver["name"]} perfectly read the team's signals during the session.`],
                                fitness: [`${yDriver["name"]} passed all physical tests with the best score in the group.`, `${yDriver["name"]} showed superior physical endurance in long runs.`],
                            };
                            const pool = positiveEvents[boostedStat] ?? ["Continued their steady progression in the program."];
                            eventMsg = pool[Math.floor(Math.random() * pool.length)];
                            updates["stats"] = statsObj;
                        }
                        else {
                            // Occasional small negative event if no growth happened
                            if (Math.random() < 0.15) {
                                const negativeEvents = [
                                    { msg: `${yDriver["name"]} was distracted by personal matters and their focus dropped.`, stat: "focus", diff: -1 },
                                    { msg: `${yDriver["name"]} missed physical training sessions.`, stat: "fitness", diff: -1 },
                                    { msg: `${yDriver["name"]} suffered a minor incident, losing confidence in braking.`, stat: "braking", diff: -1 },
                                ];
                                const neg = negativeEvents[Math.floor(Math.random() * negativeEvents.length)];
                                eventMsg = neg.msg;
                                statDiffs[neg.stat] = neg.diff;
                                const statsObj = yDriver["stats"] ?? {};
                                if (statsObj[neg.stat] !== undefined) {
                                    statsObj[neg.stat] = Math.max(1, statsObj[neg.stat] + neg.diff);
                                }
                                updates["stats"] = statsObj;
                            }
                        }
                        // "Take Action" event trigger
                        if (!yDriver["pendingAction"] && Math.random() < 0.2) {
                            updates["pendingAction"] = true;
                            updates["pendingActionType"] = ["SPONSOR_SHOOT", "TECHNICAL_TEST", "MENTOR_REQUEST"][Math.floor(Math.random() * 3)];
                        }
                        // Specialization trigger — only for trainees the player has committed to.
                        // Requires: no existing specialty, isMarkedForPromotion === true (strict), baseSkill >= 8.
                        // Strict === true so missing/undefined/false never trips the trigger (T-033).
                        // Priority order is fixed: first match wins. A trainee with multiple
                        // stats >= 11 will receive the highest-priority specialty.
                        if (!yDriver["specialty"] &&
                            yDriver["isMarkedForPromotion"] === true &&
                            yDriver["baseSkill"] >= constants_1.SPECIALTY_BASESKILL_THRESHOLD) {
                            const s = yDriver["stats"] ?? {};
                            if (s["adaptability"] >= constants_1.SPECIALTY_STAT_THRESHOLD)
                                updates["specialty"] = "Rainmaster";
                            else if (s["smoothness"] >= constants_1.SPECIALTY_STAT_THRESHOLD)
                                updates["specialty"] = "Tyre Whisperer";
                            else if (s["braking"] >= constants_1.SPECIALTY_STAT_THRESHOLD)
                                updates["specialty"] = "Late Braker";
                            else if (s["overtaking"] >= constants_1.SPECIALTY_STAT_THRESHOLD)
                                updates["specialty"] = "Defensive Minister";
                            else if (s["cornering"] >= constants_1.SPECIALTY_STAT_THRESHOLD)
                                updates["specialty"] = "Apex Hunter";
                            else if (s["consistency"] >= constants_1.SPECIALTY_STAT_THRESHOLD)
                                updates["specialty"] = "Iron Nerve";
                            else if (s["focus"] >= constants_1.SPECIALTY_STAT_THRESHOLD)
                                updates["specialty"] = "Qualy Ace";
                            else if (s["fitness"] >= constants_1.SPECIALTY_STAT_THRESHOLD)
                                updates["specialty"] = "Iron Wall";
                        }
                        updates["weeklyStatDiffs"] = statDiffs;
                        updates["weeklyEventMessage"] = eventMsg;
                        batchA.update(sDoc.ref, updates);
                    });
                    // Academy trainee weekly wages
                    const traineeWages = selectedSnap.size * constants_1.ACADEMY_TRAINEE_WEEKLY_COST;
                    if (traineeWages > 0) {
                        const wageTx = tRef.collection("transactions").doc();
                        batchA.set(wageTx, {
                            id: wageTx.id,
                            description: `Academy: Weekly wages for ${selectedSnap.size} trainees`,
                            amount: -traineeWages,
                            date: new Date().toISOString(),
                            type: "ACADEMY",
                        });
                    }
                    if (selectedSnap.size > 0) {
                        await batchA.commit();
                    }
                    // Season-end promotion logic
                    if (season) {
                        const remainingRaces = (season["calendar"] ?? []).filter((r) => !r["isCompleted"]);
                        if (remainingRaces.length === 0) {
                            const marked = selectedSnap.docs.find((d) => d.data()["isMarkedForPromotion"] === true);
                            if (marked) {
                                const yData = marked.data();
                                const newDriverId = `driver_promoted_${yData["id"]}`;
                                const newDriverRef = admin_1.db.collection("drivers").doc(newDriverId);
                                const currentYear = new Date().getFullYear();
                                const historyCount = Math.min(6, (yData["age"] || 18) - 18);
                                const driverHistory = [];
                                for (let i = 1; i <= historyCount; i++) {
                                    driverHistory.push({
                                        year: currentYear - i,
                                        teamName: "Independent",
                                        series: "Formula FTG",
                                        races: 22,
                                        wins: Math.floor(Math.random() * (yData["potential"] > 3 ? 5 : 2)),
                                        podiums: Math.floor(Math.random() * (yData["potential"] > 3 ? 8 : 4)),
                                        isChampion: (yData["potential"] >= 5 && Math.random() > 0.8),
                                    });
                                }
                                await newDriverRef.set({
                                    id: newDriverId,
                                    teamId: tid,
                                    name: yData["name"],
                                    age: yData["age"],
                                    gender: yData["gender"],
                                    nationality: yData["nationality"],
                                    portraitUrl: yData["portraitUrl"],
                                    salary: yData["salary"] || 520_000,
                                    contractYearsRemaining: 1,
                                    role: "Reserve",
                                    specialty: yData["specialty"] || null,
                                    stats: yData["stats"],
                                    history: driverHistory,
                                    isAcademyGraduate: true,
                                    createdAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
                                });
                                // Reset academy for new season
                                const academyConfigRef = admin_1.db
                                    .collection("teams").doc(tid)
                                    .collection("academy").doc("config");
                                const resetBatch = admin_1.db.batch();
                                selectedSnap.forEach((d) => resetBatch.delete(d.ref));
                                resetBatch.update(academyConfigRef, { scoutsUsedThisSeason: 0 });
                                // Unlock upgrade so managers can upgrade again in the new season
                                resetBatch.update(tRef, { "facilities.youthAcademy.isLocked": false });
                                await resetBatch.commit();
                                await (0, notifications_1.addOfficeNews)(tid, {
                                    title: "Youth Academy Reset",
                                    message: "The season has ended. Your academy candidates and trainees have been reset for the new season.",
                                    type: "INFO",
                                });
                            }
                        }
                    }
                }
                // ── 5. Update budget and write transactions ───────────────────────────
                const currentBudget = teamData["budget"] || 0;
                const newBudget = currentBudget + weeklyIncome - weeklyExpense;
                // Dot-notation update preserves fields added by future versions (e.g. morale/psychologist fields)
                // A full weekStatus object replacement would silently wipe any field not listed here.
                batch.update(tRef, {
                    "weekStatus.practiceCompleted": false,
                    "weekStatus.strategySet": false,
                    "weekStatus.sponsorReviewed": false,
                    "weekStatus.hasUpgradedThisWeek": false,
                    "weekStatus.upgradesThisWeek": 0,
                    "weekStatus.upgradeCooldownWeeksLeft": cooldown,
                    "weekStatus.isLockedForProcessing": false,
                    "weekStatus.fitnessTrainerUpgradedThisWeek": false,
                    "weekStatus.fitnessTrainerTrainedThisWeek": false,
                    "weekStatus.psychologistUpgradedThisWeek": false,
                    "weekStatus.psychologistSessionDoneThisWeek": false,
                    // T-004: reset academy trainee practice slot each round
                    "weekStatus.traineePracticeUsed": null,
                    // v1.7.4: clear all driver setups between rounds — root cause of the
                    // v1.7.x session-gate cascade. Without this, practice/qualifying/race
                    // data from R(N) leaks into R(N+1) and every frontend component must
                    // independently gate by sessionId. See postmortem_v17_session_gate_cascade.md.
                    "weekStatus.driverSetups": {},
                    // v1.7.5: globalStatus persisted between rounds and overrode the time-based
                    // status derivation in the racing page, hiding the trainee practice button.
                    // Delete forces the page to fall back to timeService.currentStatus.
                    "weekStatus.globalStatus": admin_1.admin.firestore.FieldValue.delete(),
                    // v1.7.5: practicePaid persisted between rounds, granting free practice sessions
                    // at the start of the new round without charging the $10k fee.
                    "weekStatus.practicePaid": admin_1.admin.firestore.FieldValue.delete(),
                    sponsors: updatedSponsors,
                    budget: newBudget,
                });
                if (weeklyIncome > 0) {
                    const incTx = tRef.collection("transactions").doc();
                    batch.set(incTx, {
                        id: incTx.id,
                        description: "Weekly Sponsor Income",
                        amount: weeklyIncome,
                        date: nowIso,
                        type: "SPONSOR",
                    });
                }
                if (maintenanceCost > 0) {
                    const maintTx = tRef.collection("transactions").doc();
                    batch.set(maintTx, {
                        id: maintTx.id,
                        description: "Facility Maintenance",
                        amount: -maintenanceCost,
                        date: nowIso,
                        type: "MAINTENANCE",
                    });
                }
                if (salaryCost > 0) {
                    const salaryTx = tRef.collection("transactions").doc();
                    batch.set(salaryTx, {
                        id: salaryTx.id,
                        description: "Driver Salaries",
                        amount: -salaryCost,
                        date: nowIso,
                        type: "SALARY",
                    });
                }
                if (trainerSalary > 0) {
                    const trainerTx = tRef.collection("transactions").doc();
                    batch.set(trainerTx, {
                        id: trainerTx.id,
                        description: `Staff: Fitness Trainer Salary (Lvl ${trainerLevel})`,
                        amount: -trainerSalary,
                        date: nowIso,
                        type: "SALARY",
                    });
                }
                await batch.commit();
            }
            // ── Season-end: prize distribution + career history ───────────────────
            if (season) {
                const remainingAfterThis = (season["calendar"] ?? []).filter((r) => !r["isCompleted"]);
                if (remainingAfterThis.length === 0) {
                    await runSeasonEndProcessing(sId, season);
                }
            }
            // ── AI team car upgrades (30% chance per stat) ────────────────────────
            for (const tid of teamIdsSet) {
                const tDoc = await admin_1.db.collection("teams").doc(tid).get();
                if (!tDoc.exists)
                    continue;
                const team = tDoc.data();
                if (!team["isBot"])
                    continue;
                const cs = { ...team["carStats"] ?? {} };
                let upgraded = false;
                for (const key of ["0", "1"]) {
                    const st = { ...(cs[key] ?? {}) };
                    if (Math.random() < 0.3) {
                        st["aero"] = (st["aero"] || 1) + 1;
                        upgraded = true;
                    }
                    if (Math.random() < 0.3) {
                        st["powertrain"] = (st["powertrain"] || 1) + 1;
                        upgraded = true;
                    }
                    if (Math.random() < 0.3) {
                        st["chassis"] = (st["chassis"] || 1) + 1;
                        upgraded = true;
                    }
                    cs[key] = st;
                }
                if (upgraded) {
                    await admin_1.db.collection("teams").doc(tid).update({ carStats: cs });
                }
            }
            // Mark race as processed
            await rDoc.ref.update({
                postRaceProcessed: true,
                processedAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            });
            // Sync universe standings so /season/standings reflects live data
            await syncUniverseStats();
            logger.info(`Post-race done: ${rDoc.id}`);
        }
    }
    catch (err) {
        logger.error("Error in postRaceProcessing", err);
    }
}
// ─── Season-end processing ────────────────────────────────────────────────────
/**
 * Distributes end-of-season prizes and updates career histories for all leagues.
 * Called once after the last race of the season is processed.
 * Execution order (per AC #10): prizes → career history → seasons.status = "ended".
 *
 * @param {string} sId - Season document ID.
 * @param {Object} season - Season document data (calendar, standings).
 */
async function runSeasonEndProcessing(sId, season) {
    try {
        logger.info(`[SeasonEnd] Starting end-of-season processing for season ${sId}`);
        const uDoc = await admin_1.db.collection("universe").doc("game_universe_v1").get();
        if (!uDoc.exists) {
            logger.warn("[SeasonEnd] universe document not found, skipping season-end processing");
            return;
        }
        const leagues = uDoc.data()["leagues"] ?? [];
        const currentYear = new Date().getFullYear();
        for (const league of leagues) {
            const leagueTeamRefs = (league["teams"] ?? []).map((t) => t["id"]).filter(Boolean);
            if (leagueTeamRefs.length === 0)
                continue;
            // ── 1. Read all teams and rank by seasonPoints ────────────────────────
            const teamDocs = await Promise.all(leagueTeamRefs.map((id) => admin_1.db.collection("teams").doc(id).get()));
            const teamStandings = teamDocs
                .filter((d) => d.exists)
                .map((d) => ({ id: d.id, ref: d.ref, data: d.data() }));
            // Sort descending by seasonPoints; stable on equal points (Array.sort is stable in V8)
            teamStandings.sort((a, b) => (b.data["seasonPoints"] || 0) - (a.data["seasonPoints"] || 0));
            const isConstructorsChampionTeamId = teamStandings.length > 0 ? teamStandings[0].id : null;
            // ── 2. Distribute constructors prizes ─────────────────────────────────
            for (let i = 0; i < teamStandings.length; i++) {
                const pos = i + 1; // 1-based
                const prize = constants_1.SEASON_PRIZE_TABLE[i] ?? 0;
                if (prize <= 0)
                    continue;
                const { id: tid, ref: tRef, data: tData } = teamStandings[i];
                const nowIso = new Date().toISOString();
                const prizeBatch = admin_1.db.batch();
                prizeBatch.update(tRef, { budget: (tData["budget"] || 0) + prize });
                const txRef = tRef.collection("transactions").doc();
                prizeBatch.set(txRef, {
                    id: txRef.id,
                    description: `Season Prize — Constructor Championship P${pos}`,
                    amount: prize,
                    date: nowIso,
                    type: "PRIZE",
                });
                await prizeBatch.commit();
                // Refresh budget in local cache for accurate subsequent reads
                teamStandings[i].data = { ...tData, budget: (tData["budget"] || 0) + prize };
            }
            logger.info(`[SeasonEnd] Constructors prizes distributed for ${teamStandings.length} teams`);
            // ── 3. Identify drivers champion ──────────────────────────────────────
            const leagueDriverIds = (league["drivers"] ?? []).map((d) => d["id"]).filter(Boolean);
            let driversChampion = null;
            if (leagueDriverIds.length > 0) {
                const driverDocs = await Promise.all(leagueDriverIds.map((id) => admin_1.db.collection("drivers").doc(id).get()));
                const activeDrivers = driverDocs
                    .filter((d) => d.exists && (d.data()["seasonRaces"] || 0) > 0)
                    .map((d) => ({ id: d.id, ref: d.ref, data: d.data() }));
                // Sort: seasonPoints desc → seasonWins desc → seasonPodiums desc → id asc
                activeDrivers.sort((a, b) => {
                    const pts = (b.data["seasonPoints"] || 0) - (a.data["seasonPoints"] || 0);
                    if (pts !== 0)
                        return pts;
                    const wins = (b.data["seasonWins"] || 0) - (a.data["seasonWins"] || 0);
                    if (wins !== 0)
                        return wins;
                    const pods = (b.data["seasonPodiums"] || 0) - (a.data["seasonPodiums"] || 0);
                    if (pods !== 0)
                        return pods;
                    return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
                });
                driversChampion = activeDrivers.length > 0 ? activeDrivers[0] : null;
                // ── 4. Distribute drivers champion bonuses ────────────────────────
                if (driversChampion) {
                    const champTeamId = driversChampion.data["teamId"];
                    const champTeamDoc = await admin_1.db.collection("teams").doc(champTeamId).get();
                    if (champTeamDoc.exists) {
                        const champTeamData = champTeamDoc.data();
                        const nowIso = new Date().toISOString();
                        const champBatch = admin_1.db.batch();
                        // Team bonus
                        champBatch.update(champTeamDoc.ref, {
                            budget: (champTeamData["budget"] || 0) + constants_1.DRIVERS_CHAMPION_TEAM_BONUS,
                        });
                        const champTxRef = champTeamDoc.ref.collection("transactions").doc();
                        champBatch.set(champTxRef, {
                            id: champTxRef.id,
                            description: `Season Prize — Drivers Championship Bonus (${driversChampion.data["name"] ?? driversChampion.id})`,
                            amount: constants_1.DRIVERS_CHAMPION_TEAM_BONUS,
                            date: nowIso,
                            type: "PRIZE",
                        });
                        // Driver market value boost
                        const currentMarketValue = driversChampion.data["marketValue"] || 0;
                        const newMarketValue = Math.round(currentMarketValue * constants_1.DRIVERS_CHAMPION_MARKET_VALUE_BOOST);
                        champBatch.update(driversChampion.ref, { marketValue: newMarketValue });
                        await champBatch.commit();
                        logger.info(`[SeasonEnd] Drivers champion bonus paid to team ${champTeamId}; driver ${driversChampion.id} marketValue ${currentMarketValue} → ${newMarketValue}`);
                    }
                    // Office notifications
                    await (0, notifications_1.addOfficeNews)(champTeamId, {
                        title: "🏆 Drivers Championship Bonus!",
                        message: `${driversChampion.data["name"] ?? "Your driver"} won the Drivers Championship! Your team receives a $${constants_1.DRIVERS_CHAMPION_TEAM_BONUS.toLocaleString()} bonus.`,
                        type: "SUCCESS",
                    });
                }
                // ── 5. Update driver career histories ─────────────────────────────
                for (const { id: dId, ref: dRef, data: dData } of activeDrivers) {
                    const isChampion = driversChampion ? dId === driversChampion.id : false;
                    const teamEntry = teamStandings.find((t) => t.id === dData["teamId"]);
                    const teamName = teamEntry ? (teamEntry.data["name"] ?? "") : (dData["teamName"] ?? "");
                    const historyEntry = {
                        year: currentYear,
                        teamName,
                        series: "FTG World Championship",
                        races: dData["seasonRaces"] || 0,
                        wins: dData["seasonWins"] || 0,
                        podiums: dData["seasonPodiums"] || 0,
                        isChampion,
                    };
                    const careerUpdate = {
                        careerHistory: admin_1.admin.firestore.FieldValue.arrayUnion(historyEntry),
                        races: (dData["races"] || 0) + (dData["seasonRaces"] || 0),
                        wins: (dData["wins"] || 0) + (dData["seasonWins"] || 0),
                        podiums: (dData["podiums"] || 0) + (dData["seasonPodiums"] || 0),
                    };
                    if (isChampion) {
                        careerUpdate["championships"] = (dData["championships"] || 0) + 1;
                    }
                    await dRef.update(careerUpdate);
                }
                logger.info(`[SeasonEnd] Career history updated for ${activeDrivers.length} drivers`);
            }
            // ── 6. Update team season histories ───────────────────────────────────
            for (let i = 0; i < teamStandings.length; i++) {
                const pos = i + 1;
                const { id: tid, ref: tRef, data: tData } = teamStandings[i];
                const isConstructorsChampion = tid === isConstructorsChampionTeamId;
                const seasonHistoryEntry = {
                    seasonId: sId,
                    year: currentYear,
                    constructorsPosition: pos,
                    points: tData["seasonPoints"] || 0,
                    races: tData["seasonRaces"] || 0,
                    wins: tData["seasonWins"] || 0,
                    podiums: tData["seasonPodiums"] || 0,
                    isConstructorsChampion,
                };
                await tRef.update({
                    seasonHistory: admin_1.admin.firestore.FieldValue.arrayUnion(seasonHistoryEntry),
                });
                // Send season-end office notification
                const prize = constants_1.SEASON_PRIZE_TABLE[i] ?? 0;
                const champMsg = isConstructorsChampion
                    ? " 🏆 You are the Constructors Champions!"
                    : "";
                const driversChampMsg = driversChampion && driversChampion.data["teamId"] === tid
                    ? ` Your driver ${driversChampion.data["name"] ?? ""} won the Drivers Championship (+$${constants_1.DRIVERS_CHAMPION_TEAM_BONUS.toLocaleString()} bonus).`
                    : "";
                await (0, notifications_1.addOfficeNews)(tid, {
                    title: `Season Over — P${pos} Constructors`,
                    message: `The season has ended. You finished P${pos} in the Constructors Championship and received $${prize.toLocaleString()} in prize money.${champMsg}${driversChampMsg}`,
                    type: isConstructorsChampion ? "SUCCESS" : "INFO",
                });
            }
            logger.info(`[SeasonEnd] Season history updated for ${teamStandings.length} teams`);
        }
        // ── 7. Mark season as ended ───────────────────────────────────────────────
        await admin_1.db.collection("seasons").doc(sId).update({ status: "ended" });
        logger.info(`[SeasonEnd] Season ${sId} status set to "ended". Season-end processing complete.`);
    }
    catch (err) {
        logger.error("[SeasonEnd] Error in runSeasonEndProcessing", err);
        // Non-fatal: do not re-throw — postRaceProcessing must still complete
    }
}
// ─── Universe sync ────────────────────────────────────────────────────────────
/**
 * Syncs live driver/team stats into the denormalized universe document.
 * Called automatically at the end of postRaceProcessing so /season/standings
 * always reflects fresh data after an automated race weekend.
 */
async function syncUniverseStats() {
    const uRef = admin_1.db.collection("universe").doc("game_universe_v1");
    const uDoc = await uRef.get();
    if (!uDoc.exists) {
        logger.warn("[syncUniverseStats] universe document not found, skipping sync");
        return;
    }
    const leagues = uDoc.data()["leagues"];
    for (const league of leagues) {
        const drivers = league["drivers"] ?? [];
        for (const d of drivers) {
            const dDoc = await admin_1.db.collection("drivers").doc(d["id"]).get();
            if (!dDoc.exists)
                continue;
            const r = dDoc.data();
            d["points"] = r["points"] || 0;
            d["seasonPoints"] = r["seasonPoints"] || 0;
            d["wins"] = r["wins"] || 0;
            d["seasonWins"] = r["seasonWins"] || 0;
            d["podiums"] = r["podiums"] || 0;
            d["seasonPodiums"] = r["seasonPodiums"] || 0;
            d["races"] = r["races"] || 0;
            d["seasonRaces"] = r["seasonRaces"] || 0;
            d["championships"] = r["championships"] || 0;
            d["championshipForm"] = r["championshipForm"] || [];
            d["careerHistory"] = r["careerHistory"] || [];
        }
        const teams = league["teams"] ?? [];
        for (const t of teams) {
            const tDoc = await admin_1.db.collection("teams").doc(t["id"]).get();
            if (!tDoc.exists)
                continue;
            const r = tDoc.data();
            t["points"] = r["points"] || 0;
            t["seasonPoints"] = r["seasonPoints"] || 0;
            t["wins"] = r["wins"] || 0;
            t["seasonWins"] = r["seasonWins"] || 0;
            t["podiums"] = r["podiums"] || 0;
            t["seasonPodiums"] = r["seasonPodiums"] || 0;
            t["races"] = r["races"] || 0;
            t["seasonRaces"] = r["seasonRaces"] || 0;
            if (r["name"])
                t["name"] = r["name"];
        }
    }
    // Sync activeSeasonId: prefer ftg_world league's currentSeasonId;
    // if not set, preserve whatever is already in the universe doc.
    let activeSeasonId = uDoc.data()["activeSeasonId"];
    const masterLeagueDoc = await admin_1.db.collection("leagues").doc("ftg_world").get();
    if (masterLeagueDoc.exists) {
        const fromLeague = masterLeagueDoc.data()["currentSeasonId"];
        if (fromLeague)
            activeSeasonId = fromLeague;
    }
    const updatePayload = { leagues };
    if (activeSeasonId)
        updatePayload["activeSeasonId"] = activeSeasonId;
    await uRef.update(updatePayload);
    logger.info("[syncUniverseStats] Universe standings synced", { activeSeasonId });
}
// ─── Helpers (exported for use by admin tools) ───────────────────────────────
/**
 * Generates and saves a race debrief for a team.
 * Mirrors generateTeamDebrief() from functions/index.js (lines 214–278).
 *
 * @param tid Team ID.
 * @param drivers Array of driver documents for this team.
 * @param rData Race document data.
 * @param rEvent Race event from season calendar.
 */
async function generateTeamDebrief(tid, drivers, rData, rEvent) {
    if (!drivers || drivers.length === 0)
        return;
    const dnfs = rData["dnfs"] ?? [];
    const setupsMap = rData["setups"] ?? {};
    const circuit = (0, circuits_1.getCircuit)(rEvent["circuitId"]);
    const positions = rData["finalPositions"] ?? {};
    const teamResults = drivers.map((d) => {
        const posInt = positions[d["id"]];
        const isDnf = dnfs.includes(d["id"]);
        return {
            id: d["id"],
            name: d["name"],
            pos: isDnf ? "DNF" : `P${posInt}`,
            posInt: posInt || 21,
            pts: !isDnf && (posInt - 1) < constants_1.POINT_SYSTEM.length ? constants_1.POINT_SYSTEM[posInt - 1] : 0,
            isDnf,
        };
    }).sort((a, b) => a.posInt - b.posInt);
    const lines = teamResults.map((d) => `${d.name}: ${d.pos} (+${d.pts} pts)`).join("\n");
    let debrief = "";
    const p1 = teamResults[0];
    const p2 = teamResults[1];
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
    else if (p1) {
        debrief = `${p1.name}: ${p1.pos}. We need both cars on track to maximize results.`;
    }
    else {
        debrief = "No analysis available for this team.";
    }
    await admin_1.db.collection("teams").doc(tid).set({ lastRaceDebrief: debrief, lastRaceResult: lines }, { merge: true });
    await admin_1.db.collection("teams").doc(tid).collection("news").add({
        title: `Race Summary: ${rEvent["trackName"]}`,
        message: `${lines}\n\nANALYSIS:\n${debrief}`,
        type: "RACE_RESULT",
        timestamp: admin_1.admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
    });
}
/**
 * Refreshes the academy candidate pool for a team.
 * Mirrors refreshAcademyCandidates() from functions/index.js (lines 799–860).
 *
 * @param teamId Team ID.
 * @param academyLevel Current academy upgrade level (1–5).
 * @param countryCode Team's country code for nationality-biased scouting.
 * @param teamRole Manager role (e.g., "bureaucrat" gets extra targets).
 */
async function refreshAcademyCandidates(teamId, academyLevel, countryCode, teamRole) {
    const configRef = admin_1.db
        .collection("teams").doc(teamId)
        .collection("academy").doc("config");
    const configSnap = await configRef.get();
    const config = configSnap.exists ? configSnap.data() : {};
    const candidatesRef = configRef.collection("candidates");
    const candidatesSnap = await candidatesRef.get();
    let scoutsUsed = config["scoutsUsedThisSeason"] || 0;
    const maxScouts = 20 + (academyLevel - 1) * 5;
    let males = 0;
    let females = 0;
    const now = new Date();
    const batch = admin_1.db.batch();
    candidatesSnap.docs.forEach((doc) => {
        const data = doc.data();
        const rawExp = data["expiresAt"];
        const exp = rawExp
            ? (rawExp.toDate
                ? rawExp.toDate()
                : new Date(rawExp))
            : null;
        if (exp && exp < now) {
            batch.delete(doc.ref);
            scoutsUsed++;
        }
        else {
            if (data["gender"] === "M")
                males++;
            if (data["gender"] === "F")
                females++;
        }
    });
    let maleTarget = 1;
    let femaleTarget = 1;
    if (teamRole === "bureaucrat") {
        maleTarget = 2;
        femaleTarget = 2;
    }
    // Import generateAcademyCandidate lazily to avoid circular deps at module init
    const { generateAcademyCandidate } = await Promise.resolve().then(() => __importStar(require("../academy/candidate-factory")));
    if (males < maleTarget && scoutsUsed < maxScouts) {
        for (let i = 0; i < maleTarget - males; i++) {
            if (scoutsUsed >= maxScouts)
                break;
            const newM = generateAcademyCandidate(academyLevel, countryCode, "M");
            batch.set(candidatesRef.doc(newM.id), newM);
            scoutsUsed++;
        }
    }
    if (females < femaleTarget && scoutsUsed < maxScouts) {
        for (let i = 0; i < femaleTarget - females; i++) {
            if (scoutsUsed >= maxScouts)
                break;
            const newF = generateAcademyCandidate(academyLevel, countryCode, "F");
            batch.set(candidatesRef.doc(newF.id), newF);
            scoutsUsed++;
        }
    }
    batch.update(configRef, { scoutsUsedThisSeason: scoutsUsed });
    await batch.commit();
}
// ─── Scheduled export ─────────────────────────────────────────────────────────
/** Post-race processing trigger — every 30 minutes. */
exports.postRaceProcessing = (0, scheduler_1.onSchedule)({
    schedule: "*/30 * * * *",
    timeZone: "America/Bogota",
    memory: "512MiB",
    timeoutSeconds: 300,
}, async () => {
    await runPostRaceProcessing();
});
