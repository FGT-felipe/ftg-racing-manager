/* eslint-disable max-len */
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10 });

// ─────────────────────────────────────────────
// CIRCUIT PROFILES (mirror of circuit_service.dart)
// ─────────────────────────────────────────────
const CIRCUITS = {
  "mexico": {
    id: "mexico", baseLapTime: 76.0, laps: 71,
    tyreWearMultiplier: 1.1, fuelConsumptionMultiplier: 1.0,
    aeroWeight: 0.4, powertrainWeight: 0.4, chassisWeight: 0.2,
    idealSetup: {
      frontWing: 80, rearWing: 75,
      suspension: 50, gearRatio: 85,
    },
  },
  "vegas": {
    id: "vegas", baseLapTime: 92.0, laps: 50,
    tyreWearMultiplier: 0.8, fuelConsumptionMultiplier: 1.1,
    aeroWeight: 0.2, powertrainWeight: 0.6, chassisWeight: 0.2,
    idealSetup: {
      frontWing: 25, rearWing: 20,
      suspension: 70, gearRatio: 90,
    },
  },
  "interlagos": {
    id: "interlagos", baseLapTime: 70.5, laps: 71,
    tyreWearMultiplier: 1.2, fuelConsumptionMultiplier: 1.2,
    aeroWeight: 0.3, powertrainWeight: 0.3, chassisWeight: 0.4,
    idealSetup: {
      frontWing: 65, rearWing: 60,
      suspension: 45, gearRatio: 55,
    },
  },
  "miami": {
    id: "miami", baseLapTime: 90.0, laps: 57,
    tyreWearMultiplier: 1.0, fuelConsumptionMultiplier: 1.0,
    aeroWeight: 0.4, powertrainWeight: 0.3, chassisWeight: 0.3,
    idealSetup: {
      frontWing: 55, rearWing: 50,
      suspension: 60, gearRatio: 65,
    },
  },
  "san_pablo_street": {
    id: "san_pablo_street", baseLapTime: 82.0, laps: 40,
    tyreWearMultiplier: 1.3, fuelConsumptionMultiplier: 1.3,
    aeroWeight: 0.2, powertrainWeight: 0.2, chassisWeight: 0.6,
    idealSetup: {
      frontWing: 85, rearWing: 80,
      suspension: 30, gearRatio: 35,
    },
  },
  "indianapolis": {
    id: "indianapolis", baseLapTime: 72.0, laps: 73,
    tyreWearMultiplier: 1.1, fuelConsumptionMultiplier: 1.1,
    aeroWeight: 0.3, powertrainWeight: 0.4, chassisWeight: 0.3,
    idealSetup: {
      frontWing: 40, rearWing: 35,
      suspension: 75, gearRatio: 80,
    },
  },
  "montreal": {
    id: "montreal", baseLapTime: 73.0, laps: 70,
    tyreWearMultiplier: 0.9, fuelConsumptionMultiplier: 1.3,
    aeroWeight: 0.2, powertrainWeight: 0.4, chassisWeight: 0.4,
    idealSetup: {
      frontWing: 45, rearWing: 40,
      suspension: 55, gearRatio: 70,
    },
  },
  "texas": {
    id: "texas", baseLapTime: 94.0, laps: 56,
    tyreWearMultiplier: 1.4, fuelConsumptionMultiplier: 1.1,
    aeroWeight: 0.5, powertrainWeight: 0.2, chassisWeight: 0.3,
    idealSetup: {
      frontWing: 75, rearWing: 70,
      suspension: 50, gearRatio: 60,
    },
  },
  "buenos_aires": {
    id: "buenos_aires", baseLapTime: 74.0, laps: 72,
    tyreWearMultiplier: 1.1, fuelConsumptionMultiplier: 1.0,
    aeroWeight: 0.3, powertrainWeight: 0.2, chassisWeight: 0.5,
    idealSetup: {
      frontWing: 65, rearWing: 60,
      suspension: 45, gearRatio: 50,
    },
  },
};

const GENERIC_CIRCUIT = {
  id: "generic", baseLapTime: 85.0, laps: 50,
  tyreWearMultiplier: 1.0, fuelConsumptionMultiplier: 1.0,
  aeroWeight: 0.33, powertrainWeight: 0.34, chassisWeight: 0.33,
  idealSetup: {
    frontWing: 50, rearWing: 50,
    suspension: 50, gearRatio: 50,
  },
};

/**
 * Returns the circuit profile for the given ID.
 * @param {string} circuitId The circuit identifier.
 * @return {Object} The circuit profile.
 */
function getCircuit(circuitId) {
  return CIRCUITS[circuitId] || GENERIC_CIRCUIT;
}

const POINT_SYSTEM = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
const BASE_PRIZE = 250000;
const POINT_VALUE = 150000;

const DEFAULT_SETUP = {
  frontWing: 50, rearWing: 50,
  suspension: 50, gearRatio: 50,
  tyreCompound: "medium",
  qualifyingStyle: "normal",
  raceStyle: "normal",
  initialFuel: 50.0,
  pitStops: ["hard"],
  pitStopStyles: ["normal"],
  pitStopFuel: [50.0],
};

// ─────────────────────────────────────────────
// SIMULATION ENGINE
// ─────────────────────────────────────────────
const SimEngine = {
  /**
   * Simulates a single qualifying or practice lap.
   * @param {Object} p - Parameters.
   * @return {Object} {lapTime, isCrashed}
   */
  simulateLap(p) {
    const { circuit, carStats, driverStats, setup, style } = p;
    const ideal = circuit.idealSetup;
    const s = carStats || { aero: 1, powertrain: 1, chassis: 1 };

    // Setup penalty
    const clamp = (v, lo, hi) => Math.min(Math.max(v, lo), hi);
    const aB = 1.0 - (clamp(s.aero || 1, 1, 20) / 40.0);
    const pB = 1.0 - (clamp(s.powertrain || 1, 1, 20) / 40.0);
    const cB = 1.0 - (clamp(s.chassis || 1, 1, 20) / 40.0);

    let penalty = 0;
    const gap = (a, b) => Math.abs(a - b);
    const g1 = gap(setup.frontWing, ideal.frontWing);
    penalty += (g1 <= 3 ? 0 : g1 - 3) * 0.03 * aB;
    const g2 = gap(setup.rearWing, ideal.rearWing);
    penalty += (g2 <= 3 ? 0 : g2 - 3) * 0.03 * aB;
    const g3 = gap(setup.suspension, ideal.suspension);
    penalty += (g3 <= 3 ? 0 : g3 - 3) * 0.02 * cB;
    const g4 = gap(setup.gearRatio, ideal.gearRatio);
    penalty += (g4 <= 3 ? 0 : g4 - 3) * 0.025 * pB;

    // Car performance
    const aV = clamp(s.aero || 1, 1, 20);
    const pV = clamp(s.powertrain || 1, 1, 20);
    const cV = clamp(s.chassis || 1, 1, 20);
    const w = aV * (circuit.aeroWeight || 0.33) +
      pV * (circuit.powertrainWeight || 0.34) +
      cV * (circuit.chassisWeight || 0.33);
    const carFactor = 1.0 - ((w / 20.0) * 0.25);

    // Driver contribution
    const brk = (driverStats.braking || 50) / 100.0;
    const crn = (driverStats.cornering || 50) / 100.0;
    const foc = (driverStats.focus || 50) / 100.0;
    let df = 1.0 - (brk * 0.02 + crn * 0.025 + (foc - 0.5) * 0.01);

    // Style
    const st = style || "normal";
    let sBonus = 0; let accProb = 0.03;
    if (st === "mostRisky") {
      sBonus = 0.04; accProb = 0.20;
    } else if (st === "offensive") {
      sBonus = 0.02; accProb = 0.10;
    } else if (st === "defensive") {
      sBonus = -0.01; accProb = 0.01;
    }
    df -= sBonus;
    // Ex-Driver: +5% extra crash probability
    const teamRole = p.teamRole || "";
    let extraCrash = 0;
    if (teamRole === "exDriver") extraCrash = 0.05;
    const crashed = Math.random() < (accProb + extraCrash);

    let lap = circuit.baseLapTime * carFactor * df + penalty;
    lap += (Math.random() - 0.5) * 0.8;

    return { lapTime: crashed ? 999.0 : lap, isCrashed: crashed };
  },

  /**
   * Simulates a full race lap by lap.
   * @param {Object} p - Parameters.
   * @return {Object} Full race result.
   */
  simulateRace(p) {
    const { circuit, grid, teamsMap, driversMap, setupsMap, managerRoles } = p;
    const roles = managerRoles || {};
    const totalLaps = circuit.laps;

    // Initialise state
    const order = grid.map((g) => g.driverId);
    const total = {}; const wear = {}; const fuel = {};
    const compound = {}; const style = {};
    const stops = {}; const usedHard = {};
    const dnfs = []; const raceLog = [];

    for (const id of order) {
      const su = setupsMap[id] || DEFAULT_SETUP;
      total[id] = 0; wear[id] = 0;
      fuel[id] = su.initialFuel || 50;
      compound[id] = su.tyreCompound || "medium";
      style[id] = su.raceStyle || "normal";
      stops[id] = 0;
      usedHard[id] = compound[id] === "hard";
    }

    let curOrder = [...order];

    for (let lap = 1; lap <= totalLaps; lap++) {
      const lapTimes = {};
      const lapEvents = [];

      for (const did of curOrder) {
        if (dnfs.includes(did)) continue;

        const driver = driversMap[did];
        const team = teamsMap[driver.teamId];
        const su = setupsMap[did] || DEFAULT_SETUP;
        const idx = driver.carIndex || 0;
        const cs = (team.carStats && team.carStats[String(idx)]) ||
          { aero: 1, powertrain: 1, chassis: 1 };

        const res = this.simulateLap({
          circuit, carStats: cs,
          driverStats: driver.stats || {},
          setup: { ...su, tyreCompound: compound[did] },
          style: style[did],
          teamRole: roles[driver.teamId] || "",
        });

        if (res.isCrashed) {
          dnfs.push(did);
          lapEvents.push({
            lap, driverId: did,
            desc: "CRASH: Retired from race", type: "DNF",
          });
          continue;
        }

        let lt = res.lapTime;

        // ── Manager Role Modifiers ──
        const teamRole = roles[driver.teamId] || "";
        // Ex-Driver: +2% pace (faster = multiply by 0.98)
        if (teamRole === "exDriver") lt *= 0.98;
        // Business Admin: -2% pace (slower = multiply by 1.02)
        if (teamRole === "businessAdmin") lt *= 1.02;

        // Tyre wear penalty
        lt += Math.pow(wear[did] / 100.0, 2) * 8.0;

        // Fuel weight penalty
        lt += (fuel[did] / 100.0) * 1.5;

        // Fuel consumption
        const baseFuelC = 2.5 * (circuit.fuelConsumptionMultiplier || 1);
        let fMod = 1.0;
        let wMod = 1.0;
        if (style[did] === "defensive") {
          fMod = 0.85; wMod = 0.75;
        } else if (style[did] === "offensive") {
          fMod = 1.15; wMod = 1.25;
        } else if (style[did] === "mostRisky") {
          fMod = 1.35; wMod = 1.6;
        }
        fuel[did] -= baseFuelC * fMod;

        if (fuel[did] <= 0) {
          lt += 10.0;
          fuel[did] = 0.5;
          lapEvents.push({
            lap, driverId: did,
            desc: "OUT OF FUEL: Limping to pits",
            type: "INFO",
          });
        }

        // Pit stop logic
        const needsT = wear[did] > 80;
        const needsF = fuel[did] < baseFuelC * 2.5;

        if ((needsT || needsF) && lap < totalLaps) {
          lt += 24.0 + Math.random() * 2.0;
          wear[did] = 0;

          const si = stops[did];
          const pFuels = su.pitStopFuel || [50];
          fuel[did] = si < pFuels.length ? pFuels[si] : 50;

          const plan = su.pitStops || ["hard"];
          const splan = su.pitStopStyles || ["normal"];
          let nc;
          if (si < plan.length) {
            nc = plan[si];
          } else {
            nc = usedHard[did] ?
              (plan.length ? plan[plan.length - 1] : "medium") :
              "hard";
          }
          style[did] = si < splan.length ? splan[si] : "normal";
          compound[did] = nc;
          stops[did] = si + 1;
          if (nc === "hard") usedHard[did] = true;

          lapEvents.push({
            lap, driverId: did,
            desc: `In for a stop! Swapping to ${nc.toUpperCase()}s.`, type: "PIT",
          });
        } else {
          // Tyre wear accumulation
          let cwMod = 1.0;
          if (compound[did] === "soft") cwMod = 1.6;
          else if (compound[did] === "medium") cwMod = 1.1;
          else if (compound[did] === "hard") cwMod = 0.7;

          wear[did] += 4.5 *
            (circuit.tyreWearMultiplier || 1) *
            cwMod * wMod + Math.random();

          // Ex-Engineer: -10% tyre wear
          const teamRoleW = roles[driversMap[did].teamId] || "";
          if (teamRoleW === "exEngineer") {
            wear[did] *= 0.9;
          }
        }

        lapTimes[did] = lt;
        total[did] = (total[did] || 0) + lt;
      }

      // Sort by total time
      const newOrd = [...curOrder];
      newOrd.sort((a, b) => {
        if (dnfs.includes(a)) return 1;
        if (dnfs.includes(b)) return -1;
        return (total[a] || 0) - (total[b] || 0);
      });

      // Detect overtakes
      for (let i = 0; i < newOrd.length; i++) {
        if (dnfs.includes(newOrd[i])) continue;
        const old = curOrder.indexOf(newOrd[i]);
        if (old !== -1 && i < old) {
          let flavor = "Overtake move!";
          if (i + 1 < newOrd.length) {
            const passedId = newOrd[i + 1];
            const passedName = (driversMap[passedId] && driversMap[passedId].name) || "rival";
            const phrases = [
              `Dives down the inside of ${passedName}!`,
              `Moves past ${passedName} for P${i + 1}!`,
              `Great move on ${passedName}!`,
              `Takes P${i + 1} from ${passedName}!`,
            ];
            flavor = phrases[newOrd.length % phrases.length];
          }
          lapEvents.push({
            lap, driverId: newOrd[i],
            desc: flavor, type: "OVERTAKE",
          });
        }
      }
      curOrder = newOrd;

      const pos = {};
      curOrder.forEach((id, i) => pos[id] = i + 1);
      raceLog.push({ lap, lapTimes, positions: pos, tyres: { ...compound }, events: lapEvents });
    }

    // Hard compound penalty (35s)
    for (const did of curOrder) {
      if (!dnfs.includes(did) && !usedHard[did]) {
        total[did] = (total[did] || 0) + 35.0;
        if (raceLog.length) {
          raceLog[raceLog.length - 1].events.push({
            lap: totalLaps, driverId: did,
            desc: "35s PENALTY: Failed to use Hard compound", type: "INFO",
          });
        }
      }
    }

    // Final sort
    curOrder.sort((a, b) => {
      if (dnfs.includes(a)) return 1;
      if (dnfs.includes(b)) return -1;
      return (total[a] || 0) - (total[b] || 0);
    });
    const finalPos = {};
    curOrder.forEach((id, i) => finalPos[id] = i + 1);

    return { raceLog, finalPositions: finalPos, totalTimes: total, dnfs };
  },
};

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────

/**
 * Makes a delay (used for staggering league processing).
 * @param {number} ms milliseconds.
 * @return {Promise} resolves after ms.
 */
function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

/**
 * Sends a Press News notification.
 * @param {string} leagueId League ID.
 * @param {Object} data Notification data.
 * @return {Promise} Firestore write.
 */
async function addPressNews(leagueId, data) {
  return db.collection("leagues").doc(leagueId)
    .collection("press_news").add({
      ...data,
      leagueId,
      isArchived: false,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/**
 * Sends an Office News notification to a specific team.
 * @param {string} teamId Team ID.
 * @param {Object} data Notification data.
 * @return {Promise} Firestore write.
 */
async function addOfficeNews(teamId, data) {
  return db.collection("teams").doc(teamId)
    .collection("notifications").add({
      ...data,
      teamId,
      isRead: false,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/**
 * Fetches teams by IDs (Firestore 'in' limit = 30).
 * @param {Array<string>} teamIds Team IDs.
 * @return {Promise<Array>} Team documents.
 */
async function fetchTeams(teamIds) {
  if (!teamIds.length) return [];
  const chunks = [];
  for (let i = 0; i < teamIds.length; i += 30) {
    chunks.push(teamIds.slice(i, i + 30));
  }
  const docs = [];
  for (const chunk of chunks) {
    const snap = await db.collection("teams")
      .where("id", "in", chunk).get();
    snap.docs.forEach((d) => docs.push(d));
  }
  return docs;
}

// ─────────────────────────────────────────────
// 1. SCHEDULED QUALIFYING (Sat 3:00 PM COT)
// ─────────────────────────────────────────────
exports.scheduledQualifying = onSchedule({
  schedule: "0 15 * * 6",
  timeZone: "America/Bogota",
  memory: "512MiB",
  timeoutSeconds: 300,
}, async () => {
  logger.info("=== QUALIFYING START ===");

  try {
    const uDoc = await db.collection("universe")
      .doc("game_universe_v1").get();
    if (!uDoc.exists) {
      logger.error("Universe not found"); return;
    }
    const leagues = Object.values(
      uDoc.data().activeLeagues || {},
    );

    let leagueIdx = 0;
    for (const league of leagues) {
      // Staggered: 5 min between leagues
      if (leagueIdx > 0) await sleep(5 * 60 * 1000);
      leagueIdx++;

      const sId = league.currentSeasonId;
      if (!sId) continue;

      const sDoc = await db.collection("seasons").doc(sId).get();
      if (!sDoc.exists) continue;
      const season = sDoc.data();

      const raceEvent = (season.calendar || [])
        .find((r) => !r.isCompleted);
      if (!raceEvent) continue;

      const circuit = getCircuit(raceEvent.circuitId);
      const raceDocId = `${sId}_${raceEvent.id}`;
      const rRef = db.collection("races").doc(raceDocId);
      const rSnap = await rRef.get();

      if (rSnap.exists && rSnap.data().qualyGrid) {
        logger.info(`Qualy already done: ${raceDocId}`);
        continue;
      }

      logger.info(`Qualy: ${league.name} - ${raceEvent.trackName}`);

      // Gather all team IDs from divisions
      const teamIds = [];
      (league.divisions || []).forEach((d) => {
        if (d.teamIds) teamIds.push(...d.teamIds);
      });
      if (!teamIds.length) continue;

      const teamDocs = await fetchTeams(teamIds);
      const qualyResults = [];

      // Build manager roles map for qualifying modifiers
      const managerRoles = {};
      for (const tDoc of teamDocs) {
        const t = tDoc.data();
        if (t.managerId) {
          const mgrDoc = await db.collection("managers").doc(t.managerId).get();
          if (mgrDoc.exists) {
            managerRoles[t.id] = mgrDoc.data().role || "";
          }
        }
      }

      for (const tDoc of teamDocs) {
        const team = tDoc.data();
        const dSnap = await db.collection("drivers")
          .where("teamId", "==", team.id).get();

        for (let di = 0; di < dSnap.docs.length; di++) {
          const dDoc = dSnap.docs[di];
          const driver = { ...dDoc.data(), id: dDoc.id, carIndex: di };

          // Resolve setup
          let setup = { ...DEFAULT_SETUP };
          const ws = team.weekStatus || {};
          const ds = (ws.driverSetups || {})[driver.id];
          const sent = ds && ds.isSetupSent;

          if (team.isBot) {
            // AI: near-ideal setup with randomness
            const ideal = circuit.idealSetup;
            setup.frontWing = ideal.frontWing +
              Math.floor(Math.random() * 10) - 5;
            setup.rearWing = ideal.rearWing +
              Math.floor(Math.random() * 10) - 5;
            setup.suspension = ideal.suspension +
              Math.floor(Math.random() * 10) - 5;
            setup.gearRatio = ideal.gearRatio +
              Math.floor(Math.random() * 10) - 5;
            const styles = [
              "normal", "normal", "offensive", "mostRisky",
            ];
            setup.qualifyingStyle = styles[
              Math.floor(Math.random() * styles.length)
            ];
          } else if (sent && ds.qualifying) {
            setup = { ...DEFAULT_SETUP, ...ds.qualifying };
          }
          // else: default 50/50

          const cs = (team.carStats &&
            team.carStats[String(di)]) || {};
          const res = SimEngine.simulateLap({
            circuit, carStats: cs,
            driverStats: driver.stats || {},
            setup,
            style: setup.qualifyingStyle || "normal",
            teamRole: managerRoles[team.id] || "",
          });

          // Ex-Engineer: +5% qualy success (5% faster lap)
          let finalLapTime = res.lapTime;
          if (!res.isCrashed && managerRoles[team.id] === "exEngineer") {
            finalLapTime *= 0.95;
          }

          qualyResults.push({
            driverId: driver.id,
            driverName: driver.name,
            teamName: team.name,
            teamId: team.id,
            lapTime: finalLapTime,
            isCrashed: res.isCrashed,
            tyreCompound: setup.tyreCompound || "medium",
            setupSubmitted: !!sent || team.isBot,
          });
        }
      }

      // Sort grid
      qualyResults.sort((a, b) => a.lapTime - b.lapTime);
      if (qualyResults.length) {
        const poleTime = qualyResults[0].lapTime;
        qualyResults.forEach((r, i) => {
          r.position = i + 1;
          r.gap = r.lapTime - poleTime;
        });
      }

      // Save qualifying grid
      await rRef.set({
        seasonId: sId,
        raceEventId: raceEvent.id,
        trackName: raceEvent.trackName,
        circuitId: raceEvent.circuitId,
        qualyGrid: qualyResults,
        qualifyingResults: qualyResults,
        status: "qualifying",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // Update pole stats
      const pole = qualyResults.find((r) => !r.isCrashed);
      if (pole) {
        const inc = admin.firestore.FieldValue.increment(1);
        await db.collection("drivers")
          .doc(pole.driverId).update({ poles: inc });
        await db.collection("teams")
          .doc(pole.teamId).update({ poles: inc });

        // PRESS NEWS: Pole
        const lId = league.id || "";
        await addPressNews(lId, {
          title: `POLE POSITION: ${raceEvent.trackName.toUpperCase()}`,
          message: `${pole.driverName} (${pole.teamName}) takes POLE!`,
          type: "POLE",
          eventType: "Qualifying",
          pilotName: pole.driverName,
          teamName: pole.teamName,
        });
      }

      // OFFICE NEWS: each team gets qualy report
      const teamGroups = {};
      qualyResults.forEach((r) => {
        if (!teamGroups[r.teamId]) teamGroups[r.teamId] = [];
        teamGroups[r.teamId].push(r);
      });

      for (const [tid, drivers] of Object.entries(teamGroups)) {
        const lines = drivers.map((d) => {
          const status = d.isCrashed ? "DNF (Crash)" :
            `P${d.position}`;
          return `${d.driverName}: ${status}`;
        }).join("\n");

        await addOfficeNews(tid, {
          title: "Qualifying Results",
          message: lines,
          type: "QUALIFYING_RESULT",
          eventType: "Qualifying",
        });
      }

      logger.info(`Qualy complete: ${raceDocId}`);
    }
  } catch (err) {
    logger.error("Error in scheduledQualifying", err);
  }
});

// ─────────────────────────────────────────────
// 2. SCHEDULED RACE (Sun 3:00 PM COT)
// ─────────────────────────────────────────────
exports.scheduledRace = onSchedule({
  schedule: "0 15 * * 0",
  timeZone: "America/Bogota",
  memory: "1GiB",
  timeoutSeconds: 540,
}, async () => {
  logger.info("=== RACE START ===");

  try {
    const uDoc = await db.collection("universe")
      .doc("game_universe_v1").get();
    if (!uDoc.exists) return;
    const leagues = Object.values(
      uDoc.data().activeLeagues || {},
    );

    let leagueIdx = 0;
    for (const league of leagues) {
      if (leagueIdx > 0) await sleep(5 * 60 * 1000);
      leagueIdx++;

      const sId = league.currentSeasonId;
      if (!sId) continue;

      const sDoc = await db.collection("seasons").doc(sId).get();
      if (!sDoc.exists) continue;
      const season = sDoc.data();

      const rIdx = (season.calendar || [])
        .findIndex((r) => !r.isCompleted);
      if (rIdx === -1) continue;
      const rEvent = season.calendar[rIdx];

      const raceDocId = `${sId}_${rEvent.id}`;
      const rSnap = await db.collection("races")
        .doc(raceDocId).get();

      if (!rSnap.exists || !rSnap.data().qualyGrid) {
        logger.warn(`No qualy grid: ${raceDocId}`);
        continue;
      }
      const rData = rSnap.data();
      if (rData.isFinished) continue;

      const circuit = getCircuit(rEvent.circuitId);
      logger.info(`Race: ${league.name} - ${rEvent.trackName}`);

      // Build maps
      const grid = rData.qualyGrid;
      const teamIds = [...new Set(grid.map((g) => g.teamId))];
      const teamDocs = await fetchTeams(teamIds);
      const teamsMap = {};
      teamDocs.forEach((td) => {
        teamsMap[td.data().id] = td.data();
      });

      const driversMap = {};
      const setupsMap = {};

      for (let gi = 0; gi < grid.length; gi++) {
        const g = grid[gi];
        const dDoc = await db.collection("drivers")
          .doc(g.driverId).get();
        if (!dDoc.exists) continue;
        const dData = { ...dDoc.data(), id: g.driverId };
        dData.carIndex = gi % 2; // 0 or 1 per team
        driversMap[g.driverId] = dData;

        // Resolve race setup
        const team = teamsMap[g.teamId] || {};
        let su = { ...DEFAULT_SETUP };

        if (team.isBot) {
          const ideal = circuit.idealSetup;
          su.frontWing = ideal.frontWing +
            Math.floor(Math.random() * 10) - 5;
          su.rearWing = ideal.rearWing +
            Math.floor(Math.random() * 10) - 5;
          su.suspension = ideal.suspension +
            Math.floor(Math.random() * 10) - 5;
          su.gearRatio = ideal.gearRatio +
            Math.floor(Math.random() * 10) - 5;
          su.initialFuel = 80 + Math.floor(Math.random() * 20);
          su.pitStops = ["hard", "medium"];
          su.pitStopFuel = [60, 40];
          su.raceStyle = "normal";
        } else {
          const ws = team.weekStatus || {};
          const ds = (ws.driverSetups || {})[g.driverId];
          if (ds && ds.isSetupSent && ds.race) {
            su = { ...DEFAULT_SETUP, ...ds.race };
          }
        }
        // Override tyreCompound with qualy best
        su.tyreCompound = g.tyreCompound || "medium";
        setupsMap[g.driverId] = su;
      }

      // Build manager roles map (teamId -> role string)
      const managerRoles = {};
      for (const tid of teamIds) {
        const t = teamsMap[tid];
        if (t && t.managerId) {
          const mgrDoc = await db.collection("managers").doc(t.managerId).get();
          if (mgrDoc.exists) {
            managerRoles[tid] = mgrDoc.data().role || "";
          }
        }
      }

      // Run full race
      const result = SimEngine.simulateRace({
        circuit, grid, teamsMap, driversMap, setupsMap, managerRoles,
      });

      // Calculate live duration for frontend
      const avgQualyTime = grid.reduce(
        (s, g) => s + (g.lapTime < 900 ? g.lapTime : 0), 0,
      ) / grid.filter((g) => g.lapTime < 900).length;
      const liveDurationSec = avgQualyTime * circuit.laps;

      // Save race results to Firestore
      const raceRef = db.collection("races").doc(raceDocId);
      await raceRef.update({
        status: "completed",
        isFinished: true,
        finalPositions: result.finalPositions,
        totalTimes: result.totalTimes,
        dnfs: result.dnfs,
        liveDurationSeconds: liveDurationSec,
        updateIntervalSeconds: 120,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Save lap-by-lap data for frontend "live" playback
      // Store in subcollection to avoid document size limits
      const batch = db.batch();
      const liveColl = raceRef.collection("laps");

      // Store every 5th lap + last lap (to keep doc count manageable)
      for (let i = 0; i < result.raceLog.length; i++) {
        const isKeyLap = i % 5 === 0 ||
          i === result.raceLog.length - 1;
        if (isKeyLap) {
          const lapRef = liveColl.doc(String(result.raceLog[i].lap));
          batch.set(lapRef, result.raceLog[i]);
        }
      }
      await batch.commit();

      // Lock teams for processing
      for (const tid of teamIds) {
        await db.collection("teams").doc(tid).update({
          "weekStatus.isLockedForProcessing": true,
        });
      }

      // --- POINTS & STATS ---
      const sorted = Object.keys(result.finalPositions)
        .sort((a, b) => result.finalPositions[a] -
          result.finalPositions[b]);

      const teamPointsAccum = {};
      const statsBatch = db.batch();

      for (let i = 0; i < sorted.length; i++) {
        const did = sorted[i];
        if (result.dnfs.includes(did)) continue;

        const pts = i < POINT_SYSTEM.length ? POINT_SYSTEM[i] : 0;
        const isWin = i === 0;
        const isPodium = i < 3;
        const inc = admin.firestore.FieldValue.increment;

        const dRef = db.collection("drivers").doc(did);
        const du = { races: inc(1), seasonRaces: inc(1) };
        if (pts > 0) {
          du.points = inc(pts);
          du.seasonPoints = inc(pts);
        }
        if (isWin) {
          du.wins = inc(1);
          du.seasonWins = inc(1);
        }
        if (isPodium) {
          du.podiums = inc(1);
          du.seasonPodiums = inc(1);
        }
        statsBatch.update(dRef, du);

        const dData = driversMap[did];
        if (dData) {
          const tid = dData.teamId;
          teamPointsAccum[tid] =
            (teamPointsAccum[tid] || 0) + pts;
        }
      }

      // Team stats and prize money
      for (const tid of teamIds) {
        const ep = teamPointsAccum[tid] || 0;
        const earnings = BASE_PRIZE + ep * POINT_VALUE;
        const inc = admin.firestore.FieldValue.increment;
        const tRef = db.collection("teams").doc(tid);

        const tu = {
          budget: inc(earnings),
          races: inc(1), seasonRaces: inc(1),
        };
        if (ep > 0) {
          tu.points = inc(ep);
          tu.seasonPoints = inc(ep);
        }

        // Check win/podiums for this team
        let teamWon = false;
        let teamPod = 0;
        for (let i = 0; i < sorted.length; i++) {
          const d = driversMap[sorted[i]];
          if (d && d.teamId === tid) {
            if (i === 0 && !result.dnfs.includes(sorted[i])) {
              teamWon = true;
            }
            if (i < 3 && !result.dnfs.includes(sorted[i])) {
              teamPod++;
            }
          }
        }
        if (teamWon) {
          tu.wins = inc(1);
          tu.seasonWins = inc(1);
        }
        if (teamPod > 0) {
          tu.podiums = inc(teamPod);
          tu.seasonPodiums = inc(teamPod);
        }

        statsBatch.update(tRef, tu);
      }

      // Update season calendar
      const updCal = [...season.calendar];
      updCal[rIdx] = { ...updCal[rIdx], isCompleted: true };
      statsBatch.update(
        db.collection("seasons").doc(sId),
        { calendar: updCal },
      );

      await statsBatch.commit();

      // --- NOTIFICATIONS ---
      const lId = league.id || "";
      if (sorted.length && !result.dnfs.includes(sorted[0])) {
        const winDrv = driversMap[sorted[0]];
        const winTeam = teamsMap[winDrv.teamId];
        await addPressNews(lId, {
          title: `RACE WINNER: ${rEvent.trackName.toUpperCase()}`,
          message: `${winDrv.name} (${winTeam.name}) wins!`,
          type: "WINNER",
          eventType: "Race",
          pilotName: winDrv.name,
          teamName: winTeam.name,
        });
      }

      // Office News: each team gets its result
      const teamGrp = {};
      sorted.forEach((did, i) => {
        const d = driversMap[did];
        if (!d) return;
        if (!teamGrp[d.teamId]) teamGrp[d.teamId] = [];
        const isDnf = result.dnfs.includes(did);
        teamGrp[d.teamId].push({
          name: d.name,
          pos: isDnf ? "DNF" : `P${i + 1}`,
          pts: !isDnf && i < POINT_SYSTEM.length ?
            POINT_SYSTEM[i] : 0,
        });
      });

      for (const [tid, drivers] of Object.entries(teamGrp)) {
        const ep = teamPointsAccum[tid] || 0;
        const earn = BASE_PRIZE + ep * POINT_VALUE;
        const lines = drivers.map(
          (d) => `${d.name}: ${d.pos} (+${d.pts} pts)`,
        ).join("\n");
        await addOfficeNews(tid, {
          title: `Race Results: ${rEvent.trackName}`,
          message: `${lines}\nPrize: $${earn.toLocaleString()}`,
          type: "RACE_RESULT",
          eventType: "Race",
        });
      }

      // Schedule post-race processing (1h later)
      // We set a flag; the postRaceProcessing function
      // checks this timestamp
      await raceRef.update({
        postRaceProcessingAt: new Date(
          Date.now() + 60 * 60 * 1000,
        ),
      });

      logger.info(`Race complete: ${raceDocId}`);
    }
  } catch (err) {
    logger.error("Error in scheduledRace", err);
  }
});

// ─────────────────────────────────────────────
// 3. POST-RACE PROCESSING (Every 30 min check)
// ─────────────────────────────────────────────
exports.postRaceProcessing = onSchedule({
  schedule: "*/30 * * * *",
  timeZone: "America/Bogota",
  memory: "512MiB",
  timeoutSeconds: 300,
}, async () => {
  try {
    const now = new Date();
    // Find races that need post-processing
    const racesSnap = await db.collection("races")
      .where("isFinished", "==", true)
      .where("postRaceProcessed", "==", null)
      .get();

    for (const rDoc of racesSnap.docs) {
      const rd = rDoc.data();
      const pAt = rd.postRaceProcessingAt;
      if (!pAt) continue;

      const procTime = pAt.toDate ? pAt.toDate() : new Date(pAt);
      if (now < procTime) continue; // Not time yet

      logger.info(`Post-race processing: ${rDoc.id}`);


      // Get all drivers in this race
      const driverIds = Object.keys(rd.finalPositions || {});
      const teamIdsSet = new Set();

      for (const did of driverIds) {
        const dDoc = await db.collection("drivers")
          .doc(did).get();
        if (dDoc.exists) {
          teamIdsSet.add(dDoc.data().teamId);
        }
      }

      // Reset weekStatus and unlock
      for (const tid of teamIdsSet) {
        // Read current weekStatus to preserve Bureaucrat cooldown
        const tDoc = await db.collection("teams").doc(tid).get();
        const curWs = (tDoc.exists && tDoc.data().weekStatus) || {};
        let cooldown = curWs.upgradeCooldownWeeksLeft || 0;
        if (cooldown > 0) cooldown--; // Decrement each week

        await db.collection("teams").doc(tid).update({
          "weekStatus": {
            practiceCompleted: false,
            strategySet: false,
            sponsorReviewed: false,
            hasUpgradedThisWeek: false,
            upgradesThisWeek: 0,
            upgradeCooldownWeeksLeft: cooldown,
            isLockedForProcessing: false,
          },
        });
      }

      // AI team upgrades (30% chance per stat)
      for (const tid of teamIdsSet) {
        const tDoc = await db.collection("teams")
          .doc(tid).get();
        if (!tDoc.exists) continue;
        const team = tDoc.data();
        if (!team.isBot) continue;

        const cs = { ...(team.carStats || {}) };
        let upgraded = false;
        for (const key of ["0", "1"]) {
          const st = { ...(cs[key] || {}) };
          if (Math.random() < 0.3) {
            st.aero = (st.aero || 1) + 1;
            upgraded = true;
          }
          if (Math.random() < 0.3) {
            st.powertrain = (st.powertrain || 1) + 1;
            upgraded = true;
          }
          if (Math.random() < 0.3) {
            st.chassis = (st.chassis || 1) + 1;
            upgraded = true;
          }
          cs[key] = st;
        }
        if (upgraded) {
          await db.collection("teams").doc(tid)
            .update({ carStats: cs });
        }
      }

      // Mark as processed
      await rDoc.ref.update({
        postRaceProcessed: true,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`Post-race done: ${rDoc.id}`);
    }
  } catch (err) {
    logger.error("Error in postRaceProcessing", err);
  }
});
