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

import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { db, admin } from "../../shared/admin";
import { getCircuit } from "../../config/circuits";
import {
  FALLBACK_BONUSES,
  DEFAULT_SETUP,
  POINT_SYSTEM,
  ACADEMY_TRAINEE_WEEKLY_COST,
  SPECIALTY_BASESKILL_THRESHOLD,
  SPECIALTY_STAT_THRESHOLD,
} from "../../config/constants";
import { addOfficeNews } from "../../shared/notifications";
import { evaluateObjective } from "./sponsors";
import {
  calculateWeeklyDriverSalary,
  calculateFitnessTrainerCost,
  calculateTotalFacilityMaintenance,
} from "./salaries";

// ─── Core logic ───────────────────────────────────────────────────────────────

/**
 * Processes a single race document's post-race economy:
 * sponsor payouts, salaries, academy XP, budget update, AI upgrades.
 *
 * Separated from the scheduler to allow direct invocation in tests/emergency scripts.
 */
export async function runPostRaceProcessing(): Promise<void> {
  try {
    const now = new Date();
    const racesSnap = await db
      .collection("races")
      .where("isFinished", "==", true)
      .where("postRaceProcessed", "==", false)
      .get();

    for (const rDoc of racesSnap.docs) {
      const rd = rDoc.data() as Record<string, unknown>;
      const pAt = rd["postRaceProcessingAt"];
      if (!pAt) continue;

      const procTime = (pAt as { toDate?: () => Date }).toDate
        ? (pAt as { toDate: () => Date }).toDate()
        : new Date(pAt as string);
      if (now < procTime) continue;

      logger.info(`Post-race processing: ${rDoc.id}`);

      // Collect all team IDs from drivers in this race
      const driverIds = Object.keys((rd["finalPositions"] as Record<string, number>) ?? {});
      const teamIdsSet = new Set<string>();
      for (const did of driverIds) {
        const dDoc = await db.collection("drivers").doc(did).get();
        if (dDoc.exists) {
          teamIdsSet.add((dDoc.data() as Record<string, unknown>)["teamId"] as string);
        }
      }

      const sId = (rd["seasonId"] as string) || rDoc.id.split("_")[0];
      const eId = (rd["eventId"] as string) || rDoc.id.split("_")[1];
      const sDoc = await db.collection("seasons").doc(sId).get();
      const season = sDoc.exists ? (sDoc.data() as Record<string, unknown>) : null;
      const rEvent = season
        ? ((season["calendar"] as Record<string, unknown>[]) ?? []).find((e) => e["id"] === eId) ?? null
        : null;

      // Build manager roles map for role-based economic modifiers
      const managerRoles: Record<string, string> = {};
      for (const tid of teamIdsSet) {
        const tmDoc = await db.collection("teams").doc(tid).get();
        if (tmDoc.exists) {
          const tmData = tmDoc.data() as Record<string, unknown>;
          if (tmData["managerId"]) {
            const mgrDoc = await db.collection("managers").doc(tmData["managerId"] as string).get();
            if (mgrDoc.exists) {
              managerRoles[tid] = ((mgrDoc.data() as Record<string, unknown>)["role"] as string) ?? "";
            }
          }
        }
      }

      for (const tid of teamIdsSet) {
        const tDoc = await db.collection("teams").doc(tid).get();
        if (!tDoc.exists) continue;
        const tRef = db.collection("teams").doc(tid);
        const teamData = tDoc.data() as Record<string, unknown>;
        const batch = db.batch();
        const nowIso = admin.firestore.FieldValue.serverTimestamp();

        // --- Generate race debrief ---
        const driversSnap = await db.collection("drivers").where("teamId", "==", tid).get();
        const drivers = driversSnap.docs.map((doc) => ({ ...(doc.data() as Record<string, unknown>), id: doc.id }));
        if (rEvent) {
          await generateTeamDebrief(tid, drivers, rd, rEvent);
        }

        const curWs = (teamData["weekStatus"] as Record<string, unknown>) ?? {};
        let cooldown = (curWs["upgradeCooldownWeeksLeft"] as number) || 0;
        if (cooldown > 0) cooldown--;

        let weeklyIncome = 0;
        let weeklyExpense = 0;

        // ── 1. Sponsor payouts & contract decrement ──────────────────────────
        const sponsors = (teamData["sponsors"] as Record<string, Record<string, unknown>>) ?? {};
        const updatedSponsors: Record<string, unknown> = {};
        const teamDriverIds = drivers.map((d) => d["id"] as string);

        for (const [slot, contract] of Object.entries(sponsors)) {
          if ((contract["racesRemaining"] as number) > 0) {
            weeklyIncome += (contract["weeklyBasePayment"] as number) || 0;

            // Evaluate performance bonus
            const objMet = evaluateObjective(
              contract as unknown as import("../../shared/types").SponsorContract,
              rd as unknown as import("../../shared/types").RaceData,
              teamDriverIds,
            );
            if (objMet) {
              const bonus =
                (contract["objectiveBonus"] as number) ||
                FALLBACK_BONUSES[contract["sponsorId"] as string] ||
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
                await addOfficeNews(tid, {
                  title: "Sponsor Objective Met!",
                  message: `Congratulations! We met the ${contract["sponsorName"]} objective: "${contract["objectiveDescription"]}". A bonus of $${(bonus as number).toLocaleString()} has been awarded.`,
                  type: "SUCCESS",
                });
              }
            }

            (contract["racesRemaining"] as number);
            const newRemaining = (contract["racesRemaining"] as number) - 1;

            if (newRemaining > 0) {
              updatedSponsors[slot] = { ...contract, racesRemaining: newRemaining };
            } else {
              await addOfficeNews(tid, {
                title: "Sponsor Contract Expired",
                message: `The contract with ${contract["sponsorName"]} for the ${slot} slot has expired.`,
                type: "INFO",
              });
            }
          }
        }

        // ── 2. HQ maintenance ────────────────────────────────────────────────
        const facilities = (teamData["facilities"] as Record<string, { level?: number }>) ?? {};
        const maintenanceCost = calculateTotalFacilityMaintenance(
          facilities as Record<string, import("../../shared/types").Facility>,
        );
        weeklyExpense += maintenanceCost;

        // ── 3. Driver salaries ───────────────────────────────────────────────
        let salaryCost = 0;
        const driverSalSnap = await db.collection("drivers").where("teamId", "==", tid).get();
        const mRoleForEco = managerRoles[tid] ?? "";
        driverSalSnap.forEach((doc) => {
          const d = doc.data() as import("../../shared/types").Driver;
          salaryCost += calculateWeeklyDriverSalary(d, mRoleForEco);
        });
        weeklyExpense += salaryCost;

        // ── 3.5 Fitness trainer salary ───────────────────────────────────────
        const trainerLevel = (curWs["fitnessTrainerLevel"] as number) || 1;
        const trainerSalary = calculateFitnessTrainerCost(trainerLevel);
        if (trainerSalary > 0) {
          weeklyExpense += trainerSalary;
        }

        // ── 4. Academy processing ────────────────────────────────────────────
        const academyConfigDoc = await db
          .collection("teams").doc(tid)
          .collection("academy").doc("config").get();

        if (academyConfigDoc.exists) {
          const ac = academyConfigDoc.data() as Record<string, unknown>;
          const academyLevel = (ac["academyLevel"] as number) || 1;
          const countryCode = (ac["countryCode"] as string) || "GB";
          const mRole = managerRoles[tid] ?? "";

          await refreshAcademyCandidates(tid, academyLevel, countryCode, mRole);

          const selectedRef = db
            .collection("teams").doc(tid)
            .collection("academy").doc("config")
            .collection("selected");
          const selectedSnap = await selectedRef.get();

          const batchA = db.batch();
          selectedSnap.docs.forEach((sDoc) => {
            const yDriver = sDoc.data() as Record<string, unknown>;
            const weeklyAcademyCost = 10_000;
            weeklyExpense += weeklyAcademyCost;

            // Apply XP from weekly karting simulation
            let curWeekly = (yDriver["weeklyGrowth"] as number) || 0;
            const growthPot = (yDriver["growthPotential"] as number) || 5;
            const levelBonus = (academyLevel - 1) * 8;
            let xpGain = Math.floor(Math.random() * (growthPot * 15)) + 40 + levelBonus;

            // Lead Engineer: -5% driver XP gain
            if (mRole === "engineer") {
              xpGain = Math.floor(xpGain * 0.95);
            }
            curWeekly += xpGain;

            let applyBaseGrowth = false;
            const statDiffs: Record<string, number> = {};
            let eventMsg = "";

            if (curWeekly >= 500) {
              curWeekly -= 500;
              applyBaseGrowth = true;
            }

            const updates: Record<string, unknown> = {
              weeklyGrowth: curWeekly,
              weeklyStatDiffs: {},
              weeklyEventMessage: "",
            };

            if (applyBaseGrowth) {
              updates["baseSkill"] = ((yDriver["baseSkill"] as number) || 10) + 1;
              updates["growthPotential"] = Math.max(((yDriver["growthPotential"] as number) || 5) - 1, 1);

              const statsObj = (yDriver["stats"] as Record<string, number>) || {
                cornering: 6, braking: 6, consistency: 6, smoothness: 6,
                adaptability: 6, overtaking: 6, focus: 6, fitness: 6,
              };
              const keys = Object.keys(statsObj);
              const boostedStat = keys[Math.floor(Math.random() * keys.length)];
              statsObj[boostedStat] = (statsObj[boostedStat] || 0) + 1;
              statDiffs[boostedStat] = 1;

              const positiveEvents: Record<string, string[]> = {
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
            } else {
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
                const statsObj = (yDriver["stats"] as Record<string, number>) ?? {};
                if (statsObj[neg.stat] !== undefined) {
                  statsObj[neg.stat] = Math.max(1, statsObj[neg.stat] + neg.diff);
                }
                updates["stats"] = statsObj;
              }
            }

            // "Take Action" event trigger
            if (!yDriver["pendingAction"] && Math.random() < 0.2) {
              updates["pendingAction"] = true;
              updates["pendingActionType"] = ["SPONSOR_SHOOT", "TECHNICAL_TEST", "MENTOR_REQUEST"][
                Math.floor(Math.random() * 3)
              ];
            }

            // Specialization trigger (baseSkill >= 8 required)
            // Priority order is fixed: first match wins. A trainee with multiple
            // stats >= 11 will receive the highest-priority specialty.
            if (!yDriver["specialty"] && (yDriver["baseSkill"] as number) >= SPECIALTY_BASESKILL_THRESHOLD) {
              const s = (yDriver["stats"] as Record<string, number>) ?? {};
              if (s["adaptability"] >= SPECIALTY_STAT_THRESHOLD) updates["specialty"] = "Rainmaster";
              else if (s["smoothness"] >= SPECIALTY_STAT_THRESHOLD) updates["specialty"] = "Tyre Whisperer";
              else if (s["braking"] >= SPECIALTY_STAT_THRESHOLD) updates["specialty"] = "Late Braker";
              else if (s["overtaking"] >= SPECIALTY_STAT_THRESHOLD) updates["specialty"] = "Defensive Minister";
              else if (s["cornering"] >= SPECIALTY_STAT_THRESHOLD) updates["specialty"] = "Apex Hunter";
              else if (s["consistency"] >= SPECIALTY_STAT_THRESHOLD) updates["specialty"] = "Iron Nerve";
              else if (s["focus"] >= SPECIALTY_STAT_THRESHOLD) updates["specialty"] = "Qualy Ace";
              else if (s["fitness"] >= SPECIALTY_STAT_THRESHOLD) updates["specialty"] = "Iron Wall";
            }

            updates["weeklyStatDiffs"] = statDiffs;
            updates["weeklyEventMessage"] = eventMsg;

            batchA.update(sDoc.ref, updates as FirebaseFirestore.UpdateData<object>);
          });

          // Academy trainee weekly wages
          const traineeWages = selectedSnap.size * ACADEMY_TRAINEE_WEEKLY_COST;
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
            const remainingRaces = ((season["calendar"] as Record<string, unknown>[]) ?? []).filter(
              (r) => !r["isCompleted"],
            );
            if (remainingRaces.length === 0) {
              const marked = selectedSnap.docs.find((d) => d.data()["isMarkedForPromotion"] === true);
              if (marked) {
                const yData = marked.data() as Record<string, unknown>;
                const newDriverId = `driver_promoted_${yData["id"]}`;
                const newDriverRef = db.collection("drivers").doc(newDriverId);
                const currentYear = new Date().getFullYear();
                const historyCount = Math.min(6, ((yData["age"] as number) || 18) - 18);
                const driverHistory = [];
                for (let i = 1; i <= historyCount; i++) {
                  driverHistory.push({
                    year: currentYear - i,
                    teamName: "Independent",
                    series: "Formula FTG",
                    races: 22,
                    wins: Math.floor(Math.random() * ((yData["potential"] as number) > 3 ? 5 : 2)),
                    podiums: Math.floor(Math.random() * ((yData["potential"] as number) > 3 ? 8 : 4)),
                    isChampion: ((yData["potential"] as number) >= 5 && Math.random() > 0.8),
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
                  salary: (yData["salary"] as number) || 520_000,
                  contractYearsRemaining: 1,
                  role: "Reserve",
                  specialty: yData["specialty"] || null,
                  stats: yData["stats"],
                  history: driverHistory,
                  isAcademyGraduate: true,
                  createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });

                // Reset academy for new season
                const academyConfigRef = db
                  .collection("teams").doc(tid)
                  .collection("academy").doc("config");
                const resetBatch = db.batch();
                selectedSnap.forEach((d) => resetBatch.delete(d.ref));
                resetBatch.update(academyConfigRef, { scoutsUsedThisSeason: 0 });
                await resetBatch.commit();

                await addOfficeNews(tid, {
                  title: "Youth Academy Reset",
                  message:
                    "The season has ended. Your academy candidates and trainees have been reset for the new season.",
                  type: "INFO",
                });
              }
            }
          }
        }

        // ── 5. Update budget and write transactions ───────────────────────────
        const currentBudget = (teamData["budget"] as number) || 0;
        const newBudget = currentBudget + weeklyIncome - weeklyExpense;

        batch.update(tRef, {
          weekStatus: {
            practiceCompleted: false,
            strategySet: false,
            sponsorReviewed: false,
            hasUpgradedThisWeek: false,
            upgradesThisWeek: 0,
            upgradeCooldownWeeksLeft: cooldown,
            isLockedForProcessing: false,
            fitnessTrainerUpgradedThisWeek: false,
            fitnessTrainerTrainedThisWeek: false,
          },
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

      // ── AI team car upgrades (30% chance per stat) ────────────────────────
      for (const tid of teamIdsSet) {
        const tDoc = await db.collection("teams").doc(tid).get();
        if (!tDoc.exists) continue;
        const team = tDoc.data() as Record<string, unknown>;
        if (!team["isBot"]) continue;

        const cs = { ...(team["carStats"] as Record<string, Record<string, number>>) ?? {} };
        let upgraded = false;
        for (const key of ["0", "1"]) {
          const st = { ...(cs[key] ?? {}) };
          if (Math.random() < 0.3) { st["aero"] = (st["aero"] || 1) + 1; upgraded = true; }
          if (Math.random() < 0.3) { st["powertrain"] = (st["powertrain"] || 1) + 1; upgraded = true; }
          if (Math.random() < 0.3) { st["chassis"] = (st["chassis"] || 1) + 1; upgraded = true; }
          cs[key] = st;
        }
        if (upgraded) {
          await db.collection("teams").doc(tid).update({ carStats: cs });
        }
      }

      // Mark race as processed
      await rDoc.ref.update({
        postRaceProcessed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Post-race done: ${rDoc.id}`);
    }
  } catch (err) {
    logger.error("Error in postRaceProcessing", err);
  }
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
export async function generateTeamDebrief(
  tid: string,
  drivers: Record<string, unknown>[],
  rData: Record<string, unknown>,
  rEvent: Record<string, unknown>,
): Promise<void> {
  if (!drivers || drivers.length === 0) return;

  const dnfs = (rData["dnfs"] as string[]) ?? [];
  const setupsMap = (rData["setups"] as Record<string, Record<string, unknown>>) ?? {};
  const circuit = getCircuit(rEvent["circuitId"] as string);
  const positions = (rData["finalPositions"] as Record<string, number>) ?? {};

  const teamResults = drivers.map((d) => {
    const posInt = positions[d["id"] as string];
    const isDnf = dnfs.includes(d["id"] as string);
    return {
      id: d["id"] as string,
      name: d["name"] as string,
      pos: isDnf ? "DNF" : `P${posInt}`,
      posInt: posInt || 21,
      pts: !isDnf && (posInt - 1) < POINT_SYSTEM.length ? POINT_SYSTEM[posInt - 1] : 0,
      isDnf,
    };
  }).sort((a, b) => a.posInt - b.posInt);

  const lines = teamResults.map((d) => `${d.name}: ${d.pos} (+${d.pts} pts)`).join("\n");
  let debrief = "";
  const p1 = teamResults[0];
  const p2 = teamResults[1];

  if (p1 && p2) {
    const avgPos = (p1.isDnf ? 20 : p1.posInt) + (p2.isDnf ? 20 : p2.posInt);
    if (avgPos <= 10) debrief = "Excellent weekend! Both drivers brought home solid points. The strategy was spot on.";
    else if (p1.isDnf || p2.isDnf) debrief = "A tough one. Any DNF really hurts our championship chances. We need to look at reliability and driver focus.";
    else if (avgPos >= 30) debrief = "Disappointing result. We are severely lacking pace. You should check if the car updates are being effective or if the drivers need more training.";
    else debrief = "A mediocre performance. We finished roughly where we expected, but to move up the grid we need more aggressive car development.";

    const su1 = setupsMap[p1.id] ?? DEFAULT_SETUP;
    const ideal = circuit.idealSetup;
    const setupGap =
      Math.abs(((su1["frontWing"] as number) ?? 50) - ideal.frontWing) +
      Math.abs(((su1["suspension"] as number) ?? 50) - ideal.suspension);
    if (setupGap > 20) debrief += "\n\nNote: The drivers complained about the car's balance. It seems our current Setup is quite far from the track's ideal requirements.";
    else if (setupGap < 5) debrief += "\n\nNote: The setup was very close to perfect! The drivers felt confident in the corners.";
  } else if (p1) {
    debrief = `${p1.name}: ${p1.pos}. We need both cars on track to maximize results.`;
  } else {
    debrief = "No analysis available for this team.";
  }

  await db.collection("teams").doc(tid).set(
    { lastRaceDebrief: debrief, lastRaceResult: lines },
    { merge: true },
  );

  await db.collection("teams").doc(tid).collection("news").add({
    title: `Race Summary: ${rEvent["trackName"]}`,
    message: `${lines}\n\nANALYSIS:\n${debrief}`,
    type: "RACE_RESULT",
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
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
async function refreshAcademyCandidates(
  teamId: string,
  academyLevel: number,
  countryCode: string,
  teamRole: string,
): Promise<void> {
  const configRef = db
    .collection("teams").doc(teamId)
    .collection("academy").doc("config");
  const configSnap = await configRef.get();
  const config = configSnap.exists ? (configSnap.data() as Record<string, unknown>) : {};

  const candidatesRef = configRef.collection("candidates");
  const candidatesSnap = await candidatesRef.get();

  let scoutsUsed = (config["scoutsUsedThisSeason"] as number) || 0;
  const maxScouts = 20 + (academyLevel - 1) * 5;

  let males = 0;
  let females = 0;
  const now = new Date();

  const batch = db.batch();

  candidatesSnap.docs.forEach((doc) => {
    const data = doc.data() as Record<string, unknown>;
    const rawExp = data["expiresAt"];
    const exp = rawExp
      ? ((rawExp as { toDate?: () => Date }).toDate
        ? (rawExp as { toDate: () => Date }).toDate()
        : new Date(rawExp as string))
      : null;

    if (exp && exp < now) {
      batch.delete(doc.ref);
      scoutsUsed++;
    } else {
      if (data["gender"] === "M") males++;
      if (data["gender"] === "F") females++;
    }
  });

  let maleTarget = 1;
  let femaleTarget = 1;
  if (teamRole === "bureaucrat") {
    maleTarget = 2;
    femaleTarget = 2;
  }

  // Import generateAcademyCandidate lazily to avoid circular deps at module init
  const { generateAcademyCandidate } = await import("../academy/candidate-factory");

  if (males < maleTarget && scoutsUsed < maxScouts) {
    for (let i = 0; i < maleTarget - males; i++) {
      if (scoutsUsed >= maxScouts) break;
      const newM = generateAcademyCandidate(academyLevel, countryCode, "M");
      batch.set(candidatesRef.doc(newM.id), newM);
      scoutsUsed++;
    }
  }
  if (females < femaleTarget && scoutsUsed < maxScouts) {
    for (let i = 0; i < femaleTarget - females; i++) {
      if (scoutsUsed >= maxScouts) break;
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
export const postRaceProcessing = onSchedule({
  schedule: "*/30 * * * *",
  timeZone: "America/Bogota",
  memory: "512MiB",
  timeoutSeconds: 300,
}, async () => {
  await runPostRaceProcessing();
});
