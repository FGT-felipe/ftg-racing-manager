/* eslint-disable max-len */
// Deployment: 2026-03-30 (hotfix/weekly-update-reliability: team scope via qualyGrid, weekStatus dot-notation, auto universe sync, dynamic year)
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10 });

// ---------------------------------------------------------------------------
// Morale constants (mirrors frontend/src/lib/constants/economics.ts)
// ---------------------------------------------------------------------------
const MORALE_DEFAULT = 70;        // Used when driver.stats.morale is undefined
const MORALE_NEUTRAL = 50;        // Neutral — no laptime effect
const MORALE_LAPTIME_FACTOR = 0.02; // ±1% at morale 0/100 vs neutral 50

const MORALE_EVENT_WIN_RACE         =  15;
const MORALE_EVENT_PODIUM           =   8;  // P2 or P3
const MORALE_EVENT_POLE             =  10;
const MORALE_EVENT_SPONSOR_OBJ      =   8;
const MORALE_EVENT_DNF              = -10;
const MORALE_EVENT_FINISH_LOW       =  -5;  // P10 or lower

const PSYCHOLOGIST_SALARY_BY_LEVEL = [0, 0, 50000, 120000, 250000, 500000];

const FALLBACK_BONUSES = {
  "titans_oil": 250000,
  "global_tech": 200000,
  "zenith_sky": 300000,
  "fast_logistics": 100000,
  "spark_energy": 120000,
  "eco_pulse": 80000,
  "local_drinks": 30000,
  "micro_chips": 40000,
  "nitro_gear": 35000,
};

/**
 * Evaluates if a sponsor objective was met.
 * @param {Object} contract The active contract.
 * @param {Object} raceData The final race document data.
 * @param {Array} teamDrivers The list of team driver IDs.
 * @return {boolean}
 */
function evaluateObjective(contract, raceData, teamDrivers) {
  const desc = (contract.objectiveDescription || "").toLowerCase();
  const finalPositions = raceData.finalPositions || {};
  const dnfs = raceData.dnfs || [];
  const fastLapDriver = raceData.fast_lap_driver;
  const raceCountry = raceData.countryCode || "";
  const sponsorCountry = contract.countryCode || "";

  // Helper to get driver position safely
  const getPos = (id) => (dnfs.includes(id) ? 999 : (finalPositions[id] || 999));

  if (desc.includes("race win")) {
    return teamDrivers.some((id) => getPos(id) === 1);
  }
  if (desc.includes("finish top 3")) {
    return teamDrivers.some((id) => getPos(id) <= 3);
  }
  if (desc.includes("finish top 5")) {
    return teamDrivers.some((id) => getPos(id) <= 5);
  }
  if (desc.includes("finish top 8")) {
    return teamDrivers.some((id) => getPos(id) <= 8);
  }
  if (desc.includes("finish top 10")) {
    return teamDrivers.some((id) => getPos(id) <= 10);
  }
  if (desc.includes("finish top 16")) {
    return teamDrivers.some((id) => getPos(id) <= 16);
  }
  if (desc.includes("double podium")) {
    const podiumDrivers = teamDrivers.filter((id) => getPos(id) <= 3);
    return podiumDrivers.length >= 2;
  }
  if (desc.includes("both in points")) {
    return teamDrivers.every((id) => getPos(id) <= 10);
  }
  if (desc.includes("fastest lap")) {
    return teamDrivers.includes(fastLapDriver);
  }
  if (desc.includes("finish race")) {
    return teamDrivers.some((id) => !dnfs.includes(id));
  }
  if (desc.includes("home race win")) {
    const isHomeRace = raceCountry && sponsorCountry && raceCountry === sponsorCountry;
    if (!isHomeRace) return false;
    return teamDrivers.some((id) => getPos(id) === 1);
  }
  return false;
}


// ─────────────────────────────────────────────
// CIRCUIT PROFILES (mirror of circuit_service.dart)
// ─────────────────────────────────────────────
const CIRCUITS = {
  "mexico": {
    id: "mexico", countryCode: "MX", baseLapTime: 76.0, laps: 71,
    tyreWearMultiplier: 1.1, fuelConsumptionMultiplier: 1.0,
    aeroWeight: 0.4, powertrainWeight: 0.4, chassisWeight: 0.2,
    idealSetup: {
      frontWing: 80, rearWing: 75,
      suspension: 50, gearRatio: 85,
    },
  },
  "vegas": {
    id: "vegas", countryCode: "US", baseLapTime: 92.0, laps: 50,
    tyreWearMultiplier: 0.8, fuelConsumptionMultiplier: 1.1,
    aeroWeight: 0.2, powertrainWeight: 0.6, chassisWeight: 0.2,
    idealSetup: {
      frontWing: 25, rearWing: 20,
      suspension: 70, gearRatio: 90,
    },
  },
  "interlagos": {
    id: "interlagos", countryCode: "BR", baseLapTime: 70.5, laps: 71,
    tyreWearMultiplier: 1.2, fuelConsumptionMultiplier: 1.2,
    aeroWeight: 0.3, powertrainWeight: 0.3, chassisWeight: 0.4,
    idealSetup: {
      frontWing: 65, rearWing: 60,
      suspension: 45, gearRatio: 55,
    },
  },
  "miami": {
    id: "miami", countryCode: "US", baseLapTime: 90.0, laps: 57,
    tyreWearMultiplier: 1.0, fuelConsumptionMultiplier: 1.0,
    aeroWeight: 0.4, powertrainWeight: 0.3, chassisWeight: 0.3,
    idealSetup: {
      frontWing: 55, rearWing: 50,
      suspension: 60, gearRatio: 65,
    },
  },
  "san_pablo_street": {
    id: "san_pablo_street", countryCode: "BR", baseLapTime: 82.0, laps: 40,
    tyreWearMultiplier: 1.3, fuelConsumptionMultiplier: 1.3,
    aeroWeight: 0.2, powertrainWeight: 0.2, chassisWeight: 0.6,
    idealSetup: {
      frontWing: 85, rearWing: 80,
      suspension: 30, gearRatio: 35,
    },
  },
  "indianapolis": {
    id: "indianapolis", countryCode: "US", baseLapTime: 72.0, laps: 73,
    tyreWearMultiplier: 1.1, fuelConsumptionMultiplier: 1.1,
    aeroWeight: 0.3, powertrainWeight: 0.4, chassisWeight: 0.3,
    idealSetup: {
      frontWing: 40, rearWing: 35,
      suspension: 75, gearRatio: 80,
    },
  },
  "montreal": {
    id: "montreal", countryCode: "CA", baseLapTime: 73.0, laps: 70,
    tyreWearMultiplier: 0.9, fuelConsumptionMultiplier: 1.3,
    aeroWeight: 0.2, powertrainWeight: 0.4, chassisWeight: 0.4,
    idealSetup: {
      frontWing: 45, rearWing: 40,
      suspension: 55, gearRatio: 70,
    },
  },
  "texas": {
    id: "texas", countryCode: "US", baseLapTime: 94.0, laps: 56,
    tyreWearMultiplier: 1.4, fuelConsumptionMultiplier: 1.1,
    aeroWeight: 0.5, powertrainWeight: 0.2, chassisWeight: 0.3,
    idealSetup: {
      frontWing: 75, rearWing: 70,
      suspension: 50, gearRatio: 60,
    },
  },
  "buenos_aires": {
    id: "buenos_aires", countryCode: "AR", baseLapTime: 74.0, laps: 72,
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

/**
 * Generates a debrief for a team after a race.
 * @param {string} tid - Team ID.
 * @param {Array} drivers - List of driver objects for the team.
 * @param {Object} rData - Race data.
 * @param {Object} rEvent - Race event from season calendar.
 * @return {Promise<void>}
 */
async function generateTeamDebrief(tid, drivers, rData, rEvent) {
  if (!drivers || drivers.length === 0) return;

  const dnfs = rData.dnfs || (rData.results && rData.results.dnfs) || [];
  const setupsMap = rData.setups || {};
  const circuit = getCircuit(rEvent.circuitId);

  // Reconstruct sorted list if we only have positions map
  const positions = rData.finalPositions || (rData.results && rData.results.finalPositions) || {};

  const teamResults = drivers.map((d) => {
    const posInt = positions[d.id];
    const isDnf = dnfs.includes(d.id);
    return {
      id: d.id,
      name: d.name,
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

    const su1 = setupsMap[p1.id] || DEFAULT_SETUP;
    const ideal = circuit.idealSetup;
    const gap = Math.abs((su1.frontWing || 50) - (ideal.frontWing || 50)) + Math.abs((su1.suspension || 50) - (ideal.suspension || 50));
    if (gap > 20) debrief += "\n\nNote: The drivers complained about the car's balance. It seems our current Setup is quite far from the track's ideal requirements.";
    else if (gap < 5) debrief += "\n\nNote: The setup was very close to perfect! The drivers felt confident in the corners.";
  } else if (p1) {
    debrief = `${p1.name}: ${p1.pos}. We need both cars on track to maximize results.`;
  } else {
    debrief = "No analysis available for this team.";
  }

  // 1. Update Team Document (Main debrief card)
  await db.collection("teams").doc(tid).set({
    lastRaceDebrief: debrief,
    lastRaceResult: lines,
  }, { merge: true });

  // 2. Add News entry (Aligned with UI collection 'news')
  await db.collection("teams").doc(tid).collection("news").add({
    title: `Race Summary: ${rEvent.trackName}`,
    message: `${lines}\n\nANALYSIS:\n${debrief}`,
    type: "RACE_RESULT",
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  });
}

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
    const brk = (driverStats.braking || 10) / 20.0;
    const crn = (driverStats.cornering || 10) / 20.0;
    const foc = (driverStats.focus || 10) / 20.0;
    const adp = (driverStats.adaptability || 10) / 20.0;
    // Morale effect: positive morale > MORALE_NEUTRAL reduces driverFactor (faster), negative increases it (slower)
    const moraleRaw = (driverStats.morale != null ? driverStats.morale : MORALE_DEFAULT);
    const moraleFactor = MORALE_LAPTIME_FACTOR * (moraleRaw - MORALE_NEUTRAL) / 100;
    let df = 1.0 - (brk * 0.02 + crn * 0.025 + (foc - 0.5) * 0.01 + moraleFactor);

    const isWet = (p.weather || "").toLowerCase().includes("rain") || (p.weather || "").toLowerCase().includes("wet");
    if (isWet) {
      if (driverStats.traits && driverStats.traits.includes("rainMaster")) {
        df -= 0.01;
      }
      // General rain penalty if not on wets
      if (setup.tyreCompound !== "wet") {
        penalty += 5.0;
      } else {
        penalty -= 0.3; // Wet tyre bonus in rain
      }
    } else if (setup.tyreCompound === "wet") {
      penalty += 3.0; // Penalty for using wets on dry track
    }

    // Style
    const st = style || "normal";
    let sBonus = 0; let accProb = 0.001;
    if (st === "mostRisky") {
      sBonus = 0.04; accProb = 0.003;
    } else if (st === "offensive") {
      sBonus = 0.02; accProb = 0.0015;
    } else if (st === "defensive") {
      sBonus = -0.01; accProb = 0.0005;
    }
    df -= sBonus;
    // Reliability reduces crash chance
    const rV = clamp(s.reliability || 1, 1, 20);
    accProb *= (1.0 - (rV / 30.0));
    // Ex-Driver: small extra crash probability (+5% relative increase or flat extra)
    const teamRole = p.teamRole || "";
    let extraCrash = 0;
    if (teamRole === "ex_driver") {
      extraCrash = 0.001;
      df -= 0.02; // +2% race pace bonus
    } else if (teamRole === "business") {
      df += 0.02; // -2% race pace penalty
    }

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
    const { circuit, grid, teamsMap, driversMap, setupsMap, managerRoles, raceEvent } = p;
    const roles = managerRoles || {};
    const totalLaps = raceEvent.totalLaps || circuit.laps;
    const isWet = (raceEvent.weatherRace || "").toLowerCase().includes("rain") ||
      (raceEvent.weatherRace || "").toLowerCase().includes("wet");

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
    let fast_lap_time = 999999;
    let fast_lap_driver = "";

    for (let lap = 1; lap <= totalLaps; lap++) {
      const lapTimes = {};
      const lapEvents = [];

      for (const did of curOrder) {
        if (dnfs.includes(did)) continue;

        const driver = driversMap[did];
        const team = driver ? teamsMap[driver.teamId] : null;

        if (!driver || !team) {
          dnfs.push(did);
          lapEvents.push({
            lap, driverId: did,
            desc: "DNS: Driver or team data missing", type: "DNF",
          });
          continue;
        }

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
          weather: raceEvent.weatherRace,
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
          if (teamRoleW === "engineer") {
            wear[did] *= 0.9;
          }
        }

        lapTimes[did] = lt;
        total[did] = (total[did] || 0) + lt;

        if (lt < fast_lap_time) {
          fast_lap_time = lt;
          fast_lap_driver = did;
        }
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

    // Hard compound penalty (35s) - Only if NOT wet
    for (const did of curOrder) {
      if (!dnfs.includes(did) && !usedHard[did] && !isWet) {
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

    return {
      raceLog,
      finalPositions: finalPos,
      totalTimes: total,
      dnfs,
      fast_lap_time,
      fast_lap_driver,
    };
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
/*
async function addPressNews(leagueId, data) {
  return db.collection("leagues").doc(leagueId)
      .collection("press_news").add({
        ...data,
        leagueId,
        isArchived: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
}
*/

/**
 * Sends an Office News notification to a specific team.
 * @param {string} teamId Team ID.
 * @param {Object} data Notification data.
 * @return {Promise} Firestore write.
 */
async function addOfficeNews(teamId, data) {
  const batch = db.batch();
  
  // 1. news collection (for Office facility)
  const newsRef = db.collection("teams").doc(teamId).collection("news").doc();
  batch.set(newsRef, {
    ...data,
    teamId,
    isRead: false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 2. notifications collection (for Dashboard / Store)
  const notifRef = db.collection("teams").doc(teamId).collection("notifications").doc();
  batch.set(notifRef, {
    ...data,
    isRead: false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return batch.commit();
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
// ACADEMY HELPERS
// ─────────────────────────────────────────────

/**
 * Helper to generate a Youth Academy candidate in Node.js
 * Mirrors the logic from YouthAcademyFactory in Flutter.
 * @param {number} academyLevel The current level of the academy (1-5).
 * @param {string} countryCode The country code for the candidate.
 * @param {string} gender The gender ("M" or "F").
 * @return {Object} The generated candidate object.
 */
function generateAcademyCandidate(academyLevel, countryCode, gender) {
  const level = Math.min(Math.max(academyLevel, 1), 5);

  let minCurrentStars; let maxCurrentStars; let minMaxStars; let maxMaxStars;
  switch (level) {
    case 1:
      minCurrentStars = 1.0; maxCurrentStars = 3.0;
      minMaxStars = 2.0; maxMaxStars = 3.5;
      break;
    case 2:
      minCurrentStars = 1.0; maxCurrentStars = 3.5;
      minMaxStars = 2.5; maxMaxStars = 4.0;
      break;
    case 3:
      minCurrentStars = 1.5; maxCurrentStars = 3.5;
      minMaxStars = 3.0; maxMaxStars = 4.5;
      break;
    case 4:
      minCurrentStars = 2.0; maxCurrentStars = 4.0;
      minMaxStars = 3.5; maxMaxStars = 5.0;
      break;
    case 5:
    default:
      minCurrentStars = 2.0; maxCurrentStars = 4.0;
      minMaxStars = 4.0; maxMaxStars = 5.0;
      break;
  }

  const currentStars = minCurrentStars + (Math.random() * (maxCurrentStars - minCurrentStars));
  const actualMinMax = Math.max(currentStars, minMaxStars);
  const maxStars = actualMinMax + (Math.random() * (maxMaxStars - actualMinMax));

  const baseSkill = Math.min(Math.max(Math.round(currentStars * 4), 2), 16);
  const maxSkill = Math.min(Math.max(Math.round(maxStars * 4), baseSkill), 20);
  const growthPotential = maxSkill - baseSkill;

  const statRangeMin = {};
  const statRangeMax = {};
  const ALL_STATS = [
    "cornering", "braking", "consistency", "smoothness",
    "adaptability", "overtaking", "defending", "focus", "fitness",
  ];

  for (const statKey of ALL_STATS) {
    if (statKey === "fitness") {
      // Fitness (Forma) is a 0-100 percentage
      const minVal = 80 + Math.floor(Math.random() * 20);
      const maxVal = 100;
      statRangeMin[statKey] = minVal;
      statRangeMax[statKey] = maxVal;
    } else {
      const variance = Math.floor(Math.random() * 2);
      // Ensure min/max are strictly within 1-20
      const minVal = Math.min(Math.max(Math.round(baseSkill - 1 + variance), 1), 20);
      const maxVal = Math.min(Math.max(Math.round(baseSkill + growthPotential + variance), minVal), 20);
      statRangeMin[statKey] = minVal;
      statRangeMax[statKey] = maxVal;
    }
  }

  // Common names for basic generation
  const mNames = ["John", "David", "Liam", "Carlos", "Mateo", "Luis", "Oliver", "Lucas"];
  const fNames = ["Emma", "Olivia", "Sophia", "Isabella", "Mia", "Ana", "Sofia", "Maria"];
  const lNames = ["Smith", "Garcia", "Silva", "Mueller", "Rossi", "Wang", "Kim", "Olsen", "Santos"];

  const firstPool = gender === "M" ? mNames : fNames;
  const firstName = firstPool[Math.floor(Math.random() * firstPool.length)];
  const lastName = lNames[Math.floor(Math.random() * lNames.length)];
  const fullName = `${firstName} ${lastName}`;

  const timestamp = Date.now();
  const randomSuffix = Math.floor(Math.random() * 999999);
  const id = `young_${countryCode}_${timestamp}_${randomSuffix}`;
  const age = 16 + Math.floor(Math.random() * 4);
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

  return {
    id,
    name: fullName,
    nationality: { code: countryCode, name: countryCode, flagEmoji: "🌎" },
    age,
    baseSkill,
    gender,
    growthPotential,
    portraitUrl: `https://api.dicebear.com/7.x/notionists/png?seed=${id}&gender=${gender === "M" ? "male" : "female"}`,
    status: "candidate",
    expiresAt,
    salary: 10000,
    contractYears: 1,
    statRangeMin,
    statRangeMax,
  };
}

/**
 * Checks a team's academy candidates and generates new ones if needed.
 * @param {string} teamId The ID of the team.
 * @param {number} academyLevel The current level of the academy (1-5).
 * @param {string} countryCode The country code of the team/academy.
 * @param {string} teamRole The manager's role.
 * @return {Promise<void>} Resolves when the batch commit is complete.
 */
async function refreshAcademyCandidates(teamId, academyLevel, countryCode, teamRole = "") {
  const configRef = db.collection("teams").doc(teamId).collection("academy").doc("config");
  const configSnap = await configRef.get();
  const config = configSnap.exists ? configSnap.data() : {};

  const candidatesRef = configRef.collection("candidates");
  const candidatesSnap = await candidatesRef.get();

  let scoutsUsed = config.scoutsUsedThisSeason || 0;
  const maxScouts = 20 + (academyLevel - 1) * 5; // Level 1: 20, Level 5: 40

  let males = 0;
  let females = 0;
  const now = new Date();

  const batch = db.batch();

  candidatesSnap.docs.forEach((doc) => {
    const data = doc.data();
    const exp = data.expiresAt ? (data.expiresAt.toDate ? data.expiresAt.toDate() : new Date(data.expiresAt)) : null;

    // Check if expired
    if (exp && exp < now) {
      batch.delete(doc.ref);
      scoutsUsed++; // Increment quota for expired candidates
    } else {
      if (data.gender === "M") males++;
      if (data.gender === "F") females++;
    }
  });

  // Ensure 1 male, 1 female offering if under quota
  // Bureaucrat: +1 extra youth academy driver per level (conceptually we just allow more scouts/candidates)
  let maleTarget = 1;
  let femaleTarget = 1;
  if (teamRole === "bureaucrat") {
    maleTarget = 2; // For simplicity, we double the base targets if bureaucrat
    femaleTarget = 2;
  }

  if (males < maleTarget && scoutsUsed < maxScouts) {
    for (let i = 0; i < (maleTarget - males); i++) {
        if (scoutsUsed >= maxScouts) break;
        const newM = generateAcademyCandidate(academyLevel, countryCode, "M");
        batch.set(candidatesRef.doc(newM.id), newM);
        scoutsUsed++;
    }
  }
  if (females < femaleTarget && scoutsUsed < maxScouts) {
    for (let i = 0; i < (femaleTarget - females); i++) {
        if (scoutsUsed >= maxScouts) break;
        const newF = generateAcademyCandidate(academyLevel, countryCode, "F");
        batch.set(candidatesRef.doc(newF.id), newF);
        scoutsUsed++;
    }
  }

  // Always update scoutsUsedThisSeason if it changed (increase for expired)
  batch.update(configRef, { scoutsUsedThisSeason: scoutsUsed });

  await batch.commit();
}

// ─────────────────────────────────────────────
// 1. SCHEDULED QUALIFYING (Sat 3:00 PM COT)
// ─────────────────────────────────────────────────────

async function runQualifyingLogic() {
  logger.info("=== QUALIFYING START ===");

  try {
    const uDoc = await db.collection("universe")
      .doc("game_universe_v1").get();
    if (!uDoc.exists) {
      logger.error("Universe not found"); return;
    }
    const leagues = Object.values(
      uDoc.data().leagues || {},
    );

    let leagueIdx = 0;
    for (const league of leagues) {
      try {
        // Staggered: 15s between leagues (prevents timeout while giving DB a breather)
        if (leagueIdx > 0) await sleep(15 * 1000);
        leagueIdx++;

        // --- Self-healing season lookup ---
        let sId = league.currentSeasonId;
        let sDoc = sId ?
          await db.collection("seasons").doc(sId).get() : null;

        if (!sDoc || !sDoc.exists) {
          logger.info(`Season ${sId || "N/A"} not found for ${league.name}, falling back to latest season...`);
          const fallback = await db.collection("seasons")
            .orderBy("startDate", "desc").limit(1).get();
          if (fallback.empty) {
            logger.info(`Skip league ${league.name}: No seasons exist at all`);
            continue;
          }
          sDoc = fallback.docs[0];
          sId = sDoc.id;
          logger.info(`Using fallback season: ${sId}`);
        }
        const season = sDoc.data();

        const raceEvent = (season.calendar || []).find((r) => !r.isCompleted);
        if (!raceEvent) {
          logger.info(`Skip league ${league.name}: No pending races in calendar`);
          continue;
        }

        const circuit = getCircuit(raceEvent.circuitId);
        const raceDocId = `${sId}_${raceEvent.id}`;
        const rRef = db.collection("races").doc(raceDocId);
        const rSnap = await rRef.get();

        if (rSnap.exists && rSnap.data().qualyGrid && rSnap.data().qualyGrid.length > 0) {
          logger.info(`Qualy already done: ${raceDocId}`);
          continue;
        }

        logger.info(`Qualy: ${league.name} - ${raceEvent.trackName}`);

        // Gather all team IDs from teams array (or legacy divisions)
        const teamIds = [];
        if (league.teams && league.teams.length > 0) {
          teamIds.push(...league.teams.map((t) => t.id || t));
        } else {
          (league.divisions || []).forEach((d) => {
            if (d.teamIds) teamIds.push(...d.teamIds);
          });
        }
        if (!teamIds.length) {
          logger.info(`Skip league ${league.name}: No teams found in league.teams or league.divisions`);
          continue;
        }

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

        const statsBatch = db.batch();

        for (const tDoc of teamDocs) {
          const team = tDoc.data();
          const dSnap = await db.collection("drivers")
            .where("teamId", "==", team.id).get();

          for (let di = 0; di < dSnap.docs.length; di++) {
            const dDoc = dSnap.docs[di];
            const driver = { ...dDoc.data(), id: dDoc.id, carIndex: di };

            let finalLapTime = 0.0;
            let isCrashed = false;
            let tyreCompound = "medium";
            let setupSubmitted = false;

            let setup = { ...DEFAULT_SETUP };
            const ws = team.weekStatus || {};
            const ds = (ws.driverSetups || {})[driver.id];
            const sent = ds && ds.isSetupSent;

            if (team.isBot) {
              // AI: near-ideal setup with randomness
              const ideal = circuit.idealSetup;
              setup.frontWing = ideal.frontWing + Math.floor(Math.random() * 10) - 5;
              setup.rearWing = ideal.rearWing + Math.floor(Math.random() * 10) - 5;
              setup.suspension = ideal.suspension + Math.floor(Math.random() * 10) - 5;
              setup.gearRatio = ideal.gearRatio + Math.floor(Math.random() * 10) - 5;
              const styles = ["normal", "normal", "offensive", "mostRisky"];
              setup.qualifyingStyle = styles[Math.floor(Math.random() * styles.length)];
              setupSubmitted = true;
            } else if (sent && ds.qualifying) {
              setup = { ...DEFAULT_SETUP, ...ds.qualifying };
              setupSubmitted = true;
            }

            if (driver.isTransferListed) {
              const ySnap = await db.collection("teams").doc(team.id)
                .collection("academy").doc("config")
                .collection("selected").limit(1).get();
              if (!ySnap.empty) {
                const yData = ySnap.docs[0].data();
                driver.name = yData.name + " (Academy)";
                const base = yData.baseSkill || 50;
                driver.stats = {
                  braking: base, cornering: base, smoothness: base,
                  overtaking: base, consistency: base, adaptability: base,
                  focus: base, feedback: base, fitness: 100,
                  morale: 100, marketability: 30,
                };
              } else {
                // Generic bad
                driver.stats = { braking: 1, cornering: 1, smoothness: 1, overtaking: 1, consistency: 1, adaptability: 1, focus: 1, feedback: 1, fitness: 1 };
                isCrashed = true; // Can't start properly without a driver
              }
              setup = { ...DEFAULT_SETUP, frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50, qualifyingStyle: "normal" };
              setupSubmitted = true;
            }

            if (!driver.isTransferListed && !team.isBot && ds && ds.qualifyingBestTime && ds.qualifyingBestTime > 0) {
              finalLapTime = ds.qualifyingBestTime;
              isCrashed = ds.qualifyingDnf || false;
              tyreCompound = ds.qualifyingBestCompound || setup.tyreCompound || "medium";
            } else {
              const cs = (team.carStats && team.carStats[String(di)]) || {};
              const res = SimEngine.simulateLap({
                circuit, carStats: cs,
                driverStats: driver.stats || {},
                setup,
                style: setup.qualifyingStyle || "normal",
                teamRole: managerRoles[team.id] || "",
                weather: raceEvent.weatherQualifying,
              });

              // Ex-Engineer: +5% qualy success (5% faster lap)
              finalLapTime = res.lapTime;
              if (!res.isCrashed && managerRoles[team.id] === "engineer") {
                finalLapTime *= 0.95;
              }
              isCrashed = res.isCrashed;
              tyreCompound = setup.tyreCompound || "medium";
            }

            qualyResults.push({
              driverId: driver.id,
              driverName: driver.name,
              teamName: team.name,
              teamId: team.id,
              lapTime: finalLapTime,
              isCrashed: isCrashed,
              tyreCompound: tyreCompound,
              setupSubmitted: setupSubmitted || team.isBot,
            });

            // --- FITNESS & MORALE IMPACT ---
            let fitnessPenalty = 0;
            let moralePenalty = 0;
            const currentFitness = driver.stats.fitness || 100;
            const currentMorale = driver.stats.morale || 100;

            // 1. Fitness loss due to qualifying session effort
            const focusStat = Math.min(Math.max(driver.stats.focus || 10, 1), 20);
            fitnessPenalty = 1.5 + ((20 - focusStat) / 19) * 1.5;

            // 2. Extra penalty for Managers who didn't submit a setup (excluding AI)
            if (!team.isBot && !sent) {
              fitnessPenalty += 2.0;
              moralePenalty += 2.0;
            }

            const newFitness = Math.max(0, Math.min(100, currentFitness - fitnessPenalty));
            const newMorale = Math.max(0, Math.min(100, currentMorale - moralePenalty));

            statsBatch.update(db.collection("drivers").doc(driver.id), {
              "stats.fitness": newFitness,
              "stats.morale": newMorale,
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
            // -------------------------------
          }
        }

        await statsBatch.commit();

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

        // T-020: Immutable backup — qualifying_results collection
        // SCOPE: Append-only. No pipeline or admin tool deletes or updates this collection.
        //        If qualifying is re-run via emergency scripts, this write safely overwrites
        //        the previous entry with the corrected grid.
        const qrRef = db.collection("qualifying_results").doc(`${sId}_${raceEvent.id}`);
        await qrRef.set({
          seasonId: sId,
          raceEventId: raceEvent.id,
          trackName: raceEvent.trackName,
          circuitId: raceEvent.circuitId,
          qualyGrid: qualyResults,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        logger.info(`[qualifying_results] Immutable backup written for ${sId}_${raceEvent.id} (${qualyResults.length} entries)`);

        // Update pole stats
        const pole = qualyResults.find((r) => !r.isCrashed);
        if (pole) {
          const inc = admin.firestore.FieldValue.increment(1);
          await db.collection("drivers")
            .doc(pole.driverId).update({ poles: inc });
          await db.collection("teams")
            .doc(pole.teamId).update({ poles: inc });

          // Morale boost for pole sitter
          await db.runTransaction(async (tx) => {
            const poleDriverRef = db.collection("drivers").doc(pole.driverId);
            const poleSnap = await tx.get(poleDriverRef);
            if (poleSnap.exists) {
              const currentMorale = poleSnap.data().stats?.morale != null
                ? poleSnap.data().stats.morale
                : MORALE_DEFAULT;
              const newMorale = Math.min(100, currentMorale + MORALE_EVENT_POLE);
              tx.update(poleDriverRef, { "stats.morale": newMorale });
            }
          });

          /*
          await addPressNews(lId, {
            title: `POLE POSITION: ${raceEvent.trackName.toUpperCase()}`,
            message: `${pole.driverName} (${pole.teamName}) takes POLE!`,
            type: "POLE",
            eventType: "Qualifying",
            pilotName: pole.driverName,
            teamName: pole.teamName,
          });
          */
        }

        // OFFICE NEWS & QUALY PRIZE MONEY: each team gets qualy report
        const teamGroups = {};
        qualyResults.forEach((r) => {
          if (!teamGroups[r.teamId]) teamGroups[r.teamId] = [];
          teamGroups[r.teamId].push(r);
        });

        // Distribute Prize Money for Qualy (P1: 50k, P2: 30k, P3: 15k)
        const qualyPrizes = [50000, 30000, 15000];
        const batchQ = db.batch();

        for (let i = 0; i < Math.min(3, qualyResults.length); i++) {
          const result = qualyResults[i];
          if (result.isCrashed) continue;

          const prizeAmount = qualyPrizes[i];
          if (!prizeAmount) continue;

          const teamRefPz = db.collection("teams").doc(result.teamId);
          batchQ.update(teamRefPz, {
            budget: admin.firestore.FieldValue.increment(prizeAmount)
          });

          const txRefQ = teamRefPz.collection("transactions").doc();
          batchQ.set(txRefQ, {
            id: txRefQ.id,
            description: `Qualifying P${i + 1} Reward (${result.driverName})`,
            amount: prizeAmount,
            date: new Date().toISOString(),
            type: "REWARD"
          });
        }
        await batchQ.commit();

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
            actionRoute: "/race_week/garage",
          });
        }

        logger.info(`Qualy complete: ${raceDocId}`);
      } catch (eLeague) {
        logger.error(`Error processing qualifying for league ${league.name || "unknown"}`, eLeague);
      }
    }
  } catch (err) {
    logger.error("Error in runQualifyingLogic", err);
  }
}

exports.scheduledQualifying = onSchedule({
  schedule: "0 15 * * 6",
  timeZone: "America/Bogota",
  memory: "512MiB",
  timeoutSeconds: 540,
}, async () => {
  await runQualifyingLogic();
});

exports.forceQualy = onCall({
  cors: true,
  memory: "512MiB",
  timeoutSeconds: 300,
}, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthorized");
    await runQualifyingLogic();
    return { success: true, message: "Qualifying forced successfully!" };
  } catch (e) {
    logger.error("Error forcing qualy", e);
    return { success: false, error: e.toString() };
  }
});

exports.forceRace = onCall({
  cors: true,
  memory: "1GiB",
  timeoutSeconds: 540,
}, async (request) => {
  try {
    if (!request.auth) throw new Error("Unauthorized");
    // Special: allow forcing a specific league or all
    await runRaceLogic();
    return { success: true, message: "Race forced successfully!" };
  } catch (e) {
    logger.error("Error forcing race", e);
    return { success: false, error: e.toString() };
  }
});

// ─────────────────────────────────────────────
// 2. SCHEDULED RACE (Sun 3:00 PM COT)
// ─────────────────────────────────────────────

async function runRaceLogic() {
  try {

    const uDoc = await db.collection("universe")
      .doc("game_universe_v1").get();
    if (!uDoc.exists) return;
    const leagues = Object.values(
      uDoc.data().leagues || {},
    );

    let leagueIdx = 0;
    for (const league of leagues) {
      try {
        if (leagueIdx > 0) await sleep(15 * 1000);
        leagueIdx++;

        // --- Self-healing season lookup ---
        let sId = league.currentSeasonId;
        let sDoc = sId ?
          await db.collection("seasons").doc(sId).get() : null;

        if (!sDoc || !sDoc.exists) {
          logger.info(`Race: Season ${sId || "N/A"} not found, falling back...`);
          const fallback = await db.collection("seasons")
            .orderBy("startDate", "desc").limit(1).get();
          if (fallback.empty) continue;
          sDoc = fallback.docs[0];
          sId = sDoc.id;
          logger.info(`Race: Using fallback season: ${sId}`);
        }
        const season = sDoc.data();

        const rIdx = (season.calendar || [])
          .findIndex((r) => !r.isCompleted);
        if (rIdx === -1) continue;
        const rEvent = season.calendar[rIdx];

        const raceDocId = `${sId}_${rEvent.id}`;
        const rSnap = await db.collection("races")
          .doc(raceDocId).get();

        if (!rSnap.exists || !rSnap.data().qualyGrid || rSnap.data().qualyGrid.length === 0) {
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
            if (ds && (ds.isSetupSent || ds.raceSubmitted) && ds.race) {
              su = { ...DEFAULT_SETUP, ...ds.race };
            } else {
              // Missing setup penalty: fallback to generic DEFAULT_SETUP
              // The R1 resimulation used strong fallbacks here to fix a data loss bug.
              // Reverting to DEFAULT_SETUP for future races.
              su = { ...DEFAULT_SETUP };
            }
          }

          if (dData.isTransferListed) {
            const ySnap = await db.collection("teams").doc(team.id)
              .collection("academy").doc("config")
              .collection("selected").limit(1).get();
            if (!ySnap.empty) {
              const yData = ySnap.docs[0].data();
              dData.name = yData.name + " (Academy)";
              const base = yData.baseSkill || 50;
              dData.stats = {
                braking: base, cornering: base, smoothness: base,
                overtaking: base, consistency: base, adaptability: base,
                focus: base, feedback: base, fitness: 100,
                morale: 100, marketability: 30,
              };
            } else {
              dData.stats = { braking: 1, cornering: 1, smoothness: 1, overtaking: 1, consistency: 1, adaptability: 1, focus: 1, feedback: 1, fitness: 1 };
            }
            su = { ...DEFAULT_SETUP, frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50, raceStyle: "defensive", pitStops: ["hard"], pitStopFuel: [50] };
          }

          // Override tyreCompound with qualy best
          su.tyreCompound = g.tyreCompound || "medium";
          if (dData.isTransferListed) su.tyreCompound = "hard";
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
        const raceRes = SimEngine.simulateRace({
          circuit, grid,
          teamsMap,
          driversMap,
          setupsMap,
          managerRoles,
          raceEvent: rEvent,
        });

        // Calculate live duration for frontend
        const validQualyTimes = grid.filter((g) => g.lapTime > 0 && g.lapTime < 900);
        const avgQualyTime = validQualyTimes.length > 0
          ? validQualyTimes.reduce((s, g) => s + g.lapTime, 0) / validQualyTimes.length
          : circuit.baseLapTime || 90; // Fallback to circuit base lap time

        let liveDurationSec = avgQualyTime * (circuit.laps || 50);
        if (isNaN(liveDurationSec) || liveDurationSec <= 0) {
          liveDurationSec = (circuit.baseLapTime || 90) * (circuit.laps || 50);
        }

        // Save race results to Firestore
        const raceRef = db.collection("races").doc(raceDocId);
        await raceRef.update({
          status: "completed",
          isFinished: true,
          finalPositions: raceRes.finalPositions,
          totalTimes: raceRes.totalTimes,
          dnfs: raceRes.dnfs,
          fast_lap_time: raceRes.fast_lap_time,
          fast_lap_driver: raceRes.fast_lap_driver,
          countryCode: circuit.countryCode || "",
          liveDurationSeconds: liveDurationSec,
          updateIntervalSeconds: 120,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Save lap-by-lap data for frontend "live" playback
        // Store in subcollection to avoid document size limits
        const batch = db.batch();
        const liveColl = raceRef.collection("laps");

        // Store every 5th lap + last lap (to keep doc count manageable)
        for (let i = 0; i < raceRes.raceLog.length; i++) {
          const isKeyLap = i % 5 === 0 ||
            i === raceRes.raceLog.length - 1;
          if (isKeyLap) {
            const lapRef = liveColl.doc(String(raceRes.raceLog[i].lap));
            batch.set(lapRef, raceRes.raceLog[i]);
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
        const sorted = Object.keys(raceRes.finalPositions)
          .sort((a, b) => raceRes.finalPositions[a] -
            raceRes.finalPositions[b]);

        const teamPointsAccum = {};
        const teamPrizeAccum = {};
        const statsBatch = db.batch();

        const getRacePrize = (pos) => {
          if (pos === 0) return 500000;
          if (pos === 1) return 350000;
          if (pos === 2) return 250000;
          if (pos >= 3 && pos <= 5) return 150000;
          if (pos >= 6 && pos <= 9) return 100000;
          return 25000;
        };

        for (let i = 0; i < sorted.length; i++) {
          const did = sorted[i];
          const isDnf = raceRes.dnfs.includes(did);
          const inc = admin.firestore.FieldValue.increment;
          const dRef = db.collection("drivers").doc(did);
          const dData = driversMap[did];

          if (!dData) continue;

          const pts = i < POINT_SYSTEM.length ? POINT_SYSTEM[i] : 0;
          const isWin = i === 0;
          const isPodium = i < 3;

          // Stats to update
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

          // Morale & Form Update
          let mDelta = MORALE_EVENT_FINISH_LOW; // Default: P10+ or unscored finish
          let fDelta = -0.01;
          if (isDnf) {
            mDelta = MORALE_EVENT_DNF; fDelta = -0.1;
          } else if (isWin) {
            mDelta = MORALE_EVENT_WIN_RACE; fDelta = 0.1;
          } else if (isPodium) {
            mDelta = MORALE_EVENT_PODIUM; fDelta = 0.05;
          } else if (pts > 0) {
            mDelta = 3; fDelta = 0.02; // Points finish (P4-P9): subtle positive
          }

          const mRoleForStats = dData.teamId ? (managerRoles[dData.teamId] || "") : "";
          if (mRoleForStats === "ex_driver") {
            mDelta += 10; // Ex-Driver manager boosts morale during race
          }

          const curStats = dData.stats || {};
          const currentMorale = curStats.morale != null ? curStats.morale : MORALE_DEFAULT;
          const newMorale = Math.min(100, Math.max(0, currentMorale + mDelta));
          const newForm = Math.min(10, Math.max(1, (dData.form || 5.0) + fDelta));

          du["stats.morale"] = newMorale;
          du.form = newForm;

          // Championship Form (Recent results)
          const cForm = dData.championshipForm || [];
          cForm.unshift({
            event: rEvent.trackName,
            pos: isDnf ? "DNF" : `P${i + 1}`,
            pts: pts,
            date: new Date().toISOString(),
          });
          if (cForm.length > 10) cForm.pop();
          du.championshipForm = cForm;

          statsBatch.update(dRef, du);

          const tid = dData.teamId;
          teamPointsAccum[tid] = (teamPointsAccum[tid] || 0) + pts;
          teamPrizeAccum[tid] = (teamPrizeAccum[tid] || 0) + (isDnf ? 25000 : getRacePrize(i));
        }

        // Team stats and prize money
        for (const tid of teamIds) {
          const ep = teamPointsAccum[tid] || 0;
          const earnings = teamPrizeAccum[tid] || 0;
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
              if (i === 0 && !raceRes.dnfs.includes(sorted[i])) {
                teamWon = true;
              }
              if (i < 3 && !raceRes.dnfs.includes(sorted[i])) {
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

          // Add transaction for race prize money
          if (earnings > 0) {
            const txRefR = tRef.collection("transactions").doc();
            statsBatch.set(txRefR, {
              id: txRefR.id,
              description: `Race Prize Money (${rEvent.trackName})`,
              amount: earnings,
              date: new Date().toISOString(),
              type: "REWARD",
            });
          }
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
        /*
        const lId = league.id || "";
        await addPressNews(lId, {
          title: `RACE WINNER: ${rEvent.trackName.toUpperCase()}`,
          message: `${winDrv.name} (${winTeam.name}) wins!`,
          type: "WINNER",
          eventType: "Race",
          pilotName: winDrv.name,
          teamName: winTeam.name,
        });
        */

        // Office News & Race Debrief: each team gets its result and analysis
        const teamGrp = {};
        sorted.forEach((did, i) => {
          const d = driversMap[did];
          if (!d) return;
          if (!teamGrp[d.teamId]) teamGrp[d.teamId] = [];
          const isDnf = raceRes.dnfs.includes(did);
          teamGrp[d.teamId].push({
            id: did,
            name: d.name,
            pos: isDnf ? "DNF" : `P${i + 1}`,
            posInt: i + 1,
            pts: !isDnf && i < POINT_SYSTEM.length ?
              POINT_SYSTEM[i] : 0,
            isDnf,
          });
        });

        // Generate personalized debriefs for each team
        for (const tid of teamIds) {
          const drivers = teamGrp[tid] || [];
          if (drivers.length === 0) continue;

          const earn = teamPrizeAccum[tid] || 0;
          const lines = drivers.map(
            (d) => `${d.name}: ${d.pos} (+${d.pts} pts)`,
          ).join("\n");

          // Basic analysis for debrief
          let debrief = "";
          const p1 = drivers[0];
          const p2 = drivers[1];

          if (p1 && p2) {
            const avgPos = (p1.isDnf ? 20 : p1.posInt) + (p2.isDnf ? 20 : p2.posInt);
            if (avgPos <= 10) {
              debrief = "Excellent weekend! Both drivers brought home solid points. The strategy was spot on.";
            } else if (p1.isDnf || p2.isDnf) {
              debrief = "A tough one. Any DNF really hurts our championship chances. We need to look at reliability and driver focus.";
            } else if (avgPos >= 30) {
              debrief = "Disappointing result. We are severely lacking pace. You should check if the car updates are being effective or if the drivers need more training.";
            } else {
              debrief = "A mediocre performance. We finished roughly where we expected, but to move up the grid we need more aggressive car development.";
            }

            // Setup feedback
            const su1 = setupsMap[p1.id] || DEFAULT_SETUP;
            const ideal = circuit.idealSetup;
            const gap = Math.abs(su1.frontWing - ideal.frontWing) + Math.abs(su1.suspension - ideal.suspension);
            if (gap > 20) {
              debrief += "\n\nNote: The drivers complained about the car's balance. It seems our current Setup is quite far from the track's ideal requirements.";
            } else if (gap < 5) {
              debrief += "\n\nNote: The setup was very close to perfect! The drivers felt confident in the corners.";
            }
          }

          // Update Team with last debrief
          await db.collection("teams").doc(tid).update({
            lastRaceDebrief: debrief,
            lastRaceResult: lines,
          });

          await addOfficeNews(tid, {
            title: `Race Summary: ${rEvent.trackName}`,
            message: `${lines}\n\nANALYSIS:\n${debrief}\n\nPrize: $${earn.toLocaleString()}`,
            type: "RACE_RESULT",
          });
        }

        // Schedule post-race processing (1h later)
        // We set a flag; the postRaceProcessing function
        // checks this timestamp
        await raceRef.update({
          postRaceProcessingAt: new Date(
            Date.now() + 60 * 60 * 1000,
          ),
          postRaceProcessed: false,
        });

        logger.info(`Race complete: ${raceDocId}`);
      } catch (eLeague) {
        logger.error(`Error processing race for league ${league.name || "unknown"}`, eLeague);
      }
    }

  } catch (err) {
    logger.error("Error in runRaceLogic", err);
  }

  // --- NEW: Sync universe after race logic completes ---
  await syncUniverseGlobal();
}

/**
 * Syncs the global universe document with the real data from driver and team collections.
 * This should be called after any logic that modifies competition points across leagues.
 */
async function syncUniverseGlobal() {
  logger.info("🔄 Syncing universe document with real data from collections...");
  try {
    const uRef = db.collection("universe").doc("game_universe_v1");
    const uDoc = await uRef.get();
    if (!uDoc.exists) {
      logger.warn("Universe document does not exist, skipping sync.");
      return;
    }
    const uData = uDoc.data();
    const leagues = uData.leagues || [];

    for (let li = 0; li < leagues.length; li++) {
      const league = leagues[li];

      if (league.drivers) {
        for (let di = 0; di < league.drivers.length; di++) {
          const uDriver = league.drivers[di];
          const dDoc = await db.collection("drivers").doc(uDriver.id).get();
          if (dDoc.exists) {
            const real = dDoc.data();
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
        }
      }

      if (league.teams) {
        for (let ti = 0; ti < league.teams.length; ti++) {
          const uTeam = league.teams[ti];
          const tDoc = await db.collection("teams").doc(uTeam.id).get();
          if (tDoc.exists) {
            const real = tDoc.data();
            leagues[li].teams[ti].points = real.points || 0;
            leagues[li].teams[ti].seasonPoints = real.seasonPoints || 0;
            leagues[li].teams[ti].wins = real.wins || 0;
            leagues[li].teams[ti].seasonWins = real.seasonWins || 0;
            leagues[li].teams[ti].podiums = real.podiums || 0;
            leagues[li].teams[ti].seasonPodiums = real.seasonPodiums || 0;
            leagues[li].teams[ti].races = real.races || 0;
            leagues[li].teams[ti].seasonRaces = real.seasonRaces || 0;
            if (real.name) leagues[li].teams[ti].name = real.name;
          }
        }
      }
    }

    await uRef.update({ leagues });
    logger.info("✅ Universe synced successfully!");
  } catch (err) {
    logger.error("Error syncing universe:", err);
  }
}

exports.scheduledRace = onSchedule({
  schedule: "0 14 * * 0",
  timeZone: "America/Bogota",
  memory: "1GiB",
  timeoutSeconds: 540,
}, async () => {
  logger.info("=== RACE START ===");
  await runRaceLogic();
});


// ─────────────────────────────────────────────
// HELPER: Sync universe standings document
// Reads live driver/team stats and writes them to universe/game_universe_v1
// so the /season/standings page reflects the latest race results.
// ─────────────────────────────────────────────
async function syncUniverseStats() {
  const uRef = db.collection("universe").doc("game_universe_v1");
  const uDoc = await uRef.get();
  if (!uDoc.exists) {
    logger.warn("[syncUniverseStats] universe document not found, skipping sync");
    return;
  }
  const leagues = uDoc.data().leagues;

  for (let li = 0; li < leagues.length; li++) {
    for (let di = 0; di < leagues[li].drivers.length; di++) {
      const dDoc = await db.collection("drivers").doc(leagues[li].drivers[di].id).get();
      if (!dDoc.exists) continue;
      const r = dDoc.data();
      leagues[li].drivers[di].points = r.points || 0;
      leagues[li].drivers[di].seasonPoints = r.seasonPoints || 0;
      leagues[li].drivers[di].wins = r.wins || 0;
      leagues[li].drivers[di].seasonWins = r.seasonWins || 0;
      leagues[li].drivers[di].podiums = r.podiums || 0;
      leagues[li].drivers[di].seasonPodiums = r.seasonPodiums || 0;
      leagues[li].drivers[di].races = r.races || 0;
      leagues[li].drivers[di].seasonRaces = r.seasonRaces || 0;
      leagues[li].drivers[di].championships = r.championships || 0;
      leagues[li].drivers[di].championshipForm = r.championshipForm || [];
      leagues[li].drivers[di].careerHistory = r.careerHistory || [];
    }
    for (let ti = 0; ti < leagues[li].teams.length; ti++) {
      const tDoc = await db.collection("teams").doc(leagues[li].teams[ti].id).get();
      if (!tDoc.exists) continue;
      const r = tDoc.data();
      leagues[li].teams[ti].points = r.points || 0;
      leagues[li].teams[ti].seasonPoints = r.seasonPoints || 0;
      leagues[li].teams[ti].wins = r.wins || 0;
      leagues[li].teams[ti].seasonWins = r.seasonWins || 0;
      leagues[li].teams[ti].podiums = r.podiums || 0;
      leagues[li].teams[ti].seasonPodiums = r.seasonPodiums || 0;
      leagues[li].teams[ti].races = r.races || 0;
      leagues[li].teams[ti].seasonRaces = r.seasonRaces || 0;
      if (r.name) leagues[li].teams[ti].name = r.name;
    }
  }

  await uRef.update({ leagues });
  logger.info("[syncUniverseStats] Universe standings synced");
}

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
      .where("postRaceProcessed", "==", false)
      .get();

    for (const rDoc of racesSnap.docs) {
      const rd = rDoc.data();
      const pAt = rd.postRaceProcessingAt;
      if (!pAt) continue;

      const procTime = pAt.toDate ? pAt.toDate() : new Date(pAt);
      if (now < procTime) continue; // Not time yet

      logger.info(`Post-race processing: ${rDoc.id}`);


      // SCOPE: All teams that participated in this race, derived directly from qualyGrid
      // (qualyGrid.teamId is authoritative — avoids broken driver-lookup chain that caused R4 economy skip)
      const teamIdsSet = new Set(
        (rd.qualyGrid || []).map((g) => g.teamId).filter(Boolean),
      );

      // Reset weekStatus, unlock, and process WEEKLY ECONOMY
      const sId = rd.seasonId || rDoc.id.split("_")[0];
      const eId = rd.eventId || rDoc.id.split("_")[1];
      const sDoc = await db.collection("seasons").doc(sId).get();
      const season = sDoc.data();
      const rEvent = season ? (season.calendar || []).find((e) => e.id === eId) : null;

      // Build managerRoles map for role-based economic modifiers
      const managerRoles = {};
      for (const tid of teamIdsSet) {
        const tmDoc = await db.collection("teams").doc(tid).get();
        if (tmDoc.exists && tmDoc.data().managerId) {
          const mgrDoc = await db.collection("managers").doc(tmDoc.data().managerId).get();
          if (mgrDoc.exists) {
            managerRoles[tid] = mgrDoc.data().role || "";
          }
        }
      }



      for (const tid of teamIdsSet) {
        // Read current weekStatus to preserve Bureaucrat cooldown
        const tDoc = await db.collection("teams").doc(tid).get();
        if (!tDoc.exists) continue;
        const tRef = db.collection("teams").doc(tid);

        const teamData = tDoc.data();
        const batch = db.batch();
        const nowIso = admin.firestore.FieldValue.serverTimestamp();

        // --- NEW: Generate Race Analysis Debrief ---
        const driversSnap = await db.collection("drivers").where("teamId", "==", tid).get();
        const drivers = driversSnap.docs.map((doc) => ({ ...doc.data(), id: doc.id }));
        if (rEvent) {
          await generateTeamDebrief(tid, drivers, rd, rEvent);
        }
        // -------------------------------------------

        const curWs = teamData.weekStatus || {};
        let cooldown = curWs.upgradeCooldownWeeksLeft || 0;
        if (cooldown > 0) cooldown--; // Decrement each week

        let weeklyIncome = 0;
        let weeklyExpense = 0;

        // 1. Sponsor Payouts & Contract decrement
        const sponsors = teamData.sponsors || {};
        const updatedSponsors = {};
        const teamDriverIds = drivers.map((d) => d.id);

        for (const [slot, contract] of Object.entries(sponsors)) {
          if (contract.racesRemaining > 0) {
            weeklyIncome += contract.weeklyBasePayment || 0;

            // PERFORMANCE BONUS
            if (evaluateObjective(contract, rd, teamDriverIds)) {
              const bonus = contract.objectiveBonus || FALLBACK_BONUSES[contract.sponsorId] || 0;
              if (bonus > 0) {
                weeklyIncome += bonus;
                const bonusTxRef = tRef.collection("transactions").doc();
                batch.set(bonusTxRef, {
                  id: bonusTxRef.id,
                  description: `Sponsor Objective Met: ${contract.sponsorName} (${slot})`,
                  amount: bonus,
                  date: nowIso,
                  type: "SPONSOR",
                });

                await addOfficeNews(tid, {
                  title: "Sponsor Objective Met!",
                  message: `Congratulations! We met the ${contract.sponsorName} objective: "${contract.objectiveDescription}". A bonus of $${bonus.toLocaleString()} has been awarded.`,
                  type: "SUCCESS",
                });

                // Morale boost for all team drivers when a sponsor objective is met
                for (const dId of teamDriverIds) {
                  await db.runTransaction(async (tx) => {
                    const dRef = db.collection("drivers").doc(dId);
                    const dSnap = await tx.get(dRef);
                    if (dSnap.exists) {
                      const curMorale = dSnap.data().stats?.morale != null
                        ? dSnap.data().stats.morale
                        : MORALE_DEFAULT;
                      tx.update(dRef, {
                        "stats.morale": Math.min(100, curMorale + MORALE_EVENT_SPONSOR_OBJ),
                      });
                    }
                  });
                }
              }
            }

            contract.racesRemaining -= 1;

            if (contract.racesRemaining > 0) {
              updatedSponsors[slot] = contract;
            } else {
              // Notification for expired contract
              await addOfficeNews(tid, {
                title: "Sponsor Contract Expired",
                message: `The contract with ${contract.sponsorName} for the ${slot} slot has expired.`,
                type: "INFO",
              });
            }
          }
        }

        // 2. HQ Maintenance
        let maintenanceCost = 0;
        const facilities = teamData.facilities || {};
        for (const facility of Object.values(facilities)) {
          const level = facility.level || 0;
          if (level > 0) {
            maintenanceCost += level * 15000;
          }
        }
        weeklyExpense += maintenanceCost;

        // 3. Driver Salaries
        let salaryCost = 0;
        const dSnap = await db.collection("drivers").where("teamId", "==", tid).get();
        const mRoleForEco = teamData.managerId ? (managerRoles[tid] || "") : "";
        dSnap.forEach((doc) => {
          const d = doc.data();
          let salary = d.salary || 10000; // default $10k
          if (mRoleForEco === "ex_driver") {
            salary *= 1.2; // +20% salary penalty
          }
          salaryCost += Math.round(salary / 52); // weekly wage
        });
        weeklyExpense += salaryCost;

        // 3.5 Fitness Trainer Salary
        const trainerLevel = curWs.fitnessTrainerLevel || 1;
        const trainerSalaries = [0, 0, 50000, 120000, 250000, 500000];
        const trainerSalary = (trainerLevel >= 0 && trainerLevel < trainerSalaries.length) ?
          trainerSalaries[trainerLevel] : 0;

        if (trainerSalary > 0) {
          weeklyExpense += trainerSalary;
        }

        // 3.6 Psychologist (HR Manager) Salary
        const psychLevel = curWs.psychologistLevel || 1;
        const psychSalary = (psychLevel >= 0 && psychLevel < PSYCHOLOGIST_SALARY_BY_LEVEL.length)
          ? PSYCHOLOGIST_SALARY_BY_LEVEL[psychLevel]
          : 0;
        if (psychSalary > 0) {
          weeklyExpense += psychSalary;
        }

        // 4. Academy Processing
        const academyConfigDoc = await db.collection("teams").doc(tid).collection("academy").doc("config").get();
        if (academyConfigDoc.exists) {
          const ac = academyConfigDoc.data();
          const academyLevel = ac.academyLevel || 1;
          const countryCode = ac.countryCode || "GB";
          const mRole = teamData.managerId ? (managerRoles[tid] || "") : "";

          await refreshAcademyCandidates(tid, academyLevel, countryCode, mRole);

          const selectedRef = db.collection("teams").doc(tid).collection("academy").doc("config").collection("selected");
          const selectedSnap = await selectedRef.get();

          const batchA = db.batch();
          selectedSnap.docs.forEach((sDoc) => {
            const yDriver = sDoc.data();
            const weeklyAcademyCost = 10000; // Flat $10,000 per trainee weekly
            weeklyExpense += weeklyAcademyCost;

            // Apply XP from FTG Karting Championship weekly simulation
            let curWeekly = yDriver.weeklyGrowth || 0;
            const growthPot = yDriver.growthPotential || 5;
            // Increased growth rate for better feel + Academy Level Bonus
            const levelBonus = (academyLevel - 1) * 8;
            let xpGain = Math.floor(Math.random() * (growthPot * 15)) + 40 + levelBonus;

            // Lead Engineer: -5% driver XP gain penalty
            if (mRole === "engineer") {
              xpGain = Math.floor(xpGain * 0.95);
            }

            // Promotion focus bonus: +25% XP for the driver marked for promotion
            if (yDriver.isMarkedForPromotion) {
              xpGain = Math.floor(xpGain * 1.25);
            }

            curWeekly += xpGain;

            let applyBaseGrowth = false;
            const statDiffs = {};
            let eventMsg = "";

            if (curWeekly >= 500) { // Slower growth for 1-20 scale
              curWeekly -= 500;
              applyBaseGrowth = true;
            }

            const updates = {
              weeklyGrowth: curWeekly,
              weeklyStatDiffs: {},
              weeklyEventMessage: "",
            };

            if (applyBaseGrowth) {
              updates.baseSkill = (yDriver.baseSkill || 10) + 1;
              updates.growthPotential = Math.max((yDriver.growthPotential || 5) - 1, 1);

              const statsObj = yDriver.stats || {
                cornering: 6, braking: 6, consistency: 6, smoothness: 6,
                adaptability: 6, overtaking: 6, focus: 6, fitness: 6,
              };

              // Select a random stat to boost — exclude fitness (percentual, not a skill)
              const keys = Object.keys(statsObj).filter(k => k !== 'fitness');
              const boostedStat = keys[Math.floor(Math.random() * keys.length)];
              statsObj[boostedStat] += 1;
              statDiffs[boostedStat] = 1;

              // Random Narrative based on the boosted stat
              const positiveEvents = {
                adaptability: [`${yDriver.name} amazed the engineers with their pace in the rain.`, `${yDriver.name} quickly adapted to a drastic change in the weather.`],
                cornering: [`${yDriver.name} spent extra hours perfecting their line through curves.`, `${yDriver.name} demonstrated impeccable cornering in the simulator.`],
                smoothness: [`${yDriver.name} showed great finesse with the tires.`, `${yDriver.name} remarkably improved their driving fluidness.`],
                braking: [`${yDriver.name} showed great skill and confidence in braking late.`, `${yDriver.name} adjusted their braking technique to gain time.`],
                overtaking: [`${yDriver.name} performed brilliant overtaking maneuvers in their last race.`, `${yDriver.name} showed perfect calculated aggressiveness for passing.`],
                consistency: [`${yDriver.name} remained unshakable under pressure, maintaining constant lap times.`, `${yDriver.name} did not make a single mistake throughout the testing week.`],
                focus: [`${yDriver.name} was extremely concentrated, ignoring external distractions.`, `${yDriver.name} perfectly read the team's signals during the session.`],
                fitness: [`${yDriver.name} passed all physical tests with the best score in the group.`, `${yDriver.name} showed superior physical endurance in long runs.`],
              };

              const eventPool = positiveEvents[boostedStat] || ["Continued their steady progression in the program."];
              eventMsg = eventPool[Math.floor(Math.random() * eventPool.length)];

              updates.stats = statsObj;
            } else {
              // Occasional small negative event if no growth happened
              if (Math.random() < 0.15) {
                const negativeEvents = [
                  { msg: `${yDriver.name} was distracted by personal matters and their focus dropped.`, stat: "focus", diff: -1 },
                  { msg: `${yDriver.name} struggled to adapt to recent circuit changes.`, stat: "adaptability", diff: -1 },
                  { msg: `${yDriver.name} suffered a minor incident, losing confidence in braking.`, stat: "braking", diff: -1 },
                ];
                const neg = negativeEvents[Math.floor(Math.random() * negativeEvents.length)];
                eventMsg = neg.msg;
                statDiffs[neg.stat] = neg.diff;

                const statsObj = yDriver.stats || {};
                if (statsObj[neg.stat]) statsObj[neg.stat] = Math.max(1, statsObj[neg.stat] + neg.diff);
                updates.stats = statsObj;
              }
            }

            // Chance for "Take Action" events (Manual Events)
            // INTENSIVE_TRAINING: 6% chance (rare but high impact), regular events: 20% chance
            if (!yDriver.pendingAction) {
              const eventRoll = Math.random();
              if (eventRoll < 0.06) {
                updates.pendingAction = true;
                updates.pendingActionType = "INTENSIVE_TRAINING";
              } else if (eventRoll < 0.26) {
                updates.pendingAction = true;
                updates.pendingActionType = ["SPONSOR_SHOOT", "TECHNICAL_TEST", "MENTOR_REQUEST"][Math.floor(Math.random() * 3)];
              }
            }

            // Specialization Trigger logic
            if (!yDriver.specialty && yDriver.baseSkill >= 8) {
              // If they have a very high specific stat, they might get a specialty
              const s = yDriver.stats || {};
              // Thresholds based on 1-20 scale (11/20 = 55%)
              if (s.adaptability >= 11) updates.specialty = "Rainmaster";
              else if (s.smoothness >= 11) updates.specialty = "Tyre Whisperer";
              else if (s.braking >= 11) updates.specialty = "Late Braker";
              else if (s.overtaking >= 11) updates.specialty = "Defensive Minister";
            }

            updates.weeklyStatDiffs = statDiffs;
            updates.weeklyEventMessage = eventMsg;

            batchA.update(sDoc.ref, updates);
          });

          // Calculate Academy Trainee Wages ($10,000 per trainee)
          const traineeWages = selectedSnap.size * 10000;
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

          // Season End Promotion Logic
          const rd = rDoc.data();
          const sId = rd.seasonId;
          if (sId) {
            const sDoc = await db.collection("seasons").doc(sId).get();
            if (sDoc.exists) {
              const season = sDoc.data();
              const remainingRaces = (season.calendar || []).filter((r) => !r.isCompleted);
              if (remainingRaces.length === 0) {
                // Season Ended! Promote marked driver
                const marked = selectedSnap.docs.find((d) => d.data().isMarkedForPromotion === true);
                if (marked) {
                  const yData = marked.data();
                  const newDriverId = `driver_promoted_${yData.id}`;
                  const newDriverRef = db.collection("drivers").doc(newDriverId);

                  // Create the new driver for the main squad
                  const currentYear = new Date().getFullYear();
                  const teamsSnap = await db.collection("teams").get();
                  const teamsMap = {};
                  teamsSnap.docs.forEach(d => {
                    teamsMap[d.id] = d.data().name;
                  });

                  const driverHistory = [];
                  const historyCount = Math.min(6, (yData.age || 18) - 18); // Max 6 years of history, starting from 18

                  for (let i = 1; i <= historyCount; i++) {
                    const year = currentYear - i;
                    // For academy drivers, their history is always "Independent"
                    const teamN = "Independent";

                    driverHistory.push({
                      year,
                      teamName: teamN,
                      series: "Formula FTG", // Assuming all academy drivers come from this series
                      races: 22, // Standard number of races
                      wins: Math.floor(Math.random() * (yData.potential > 3 ? 5 : 2)),
                      podiums: Math.floor(Math.random() * (yData.potential > 3 ? 8 : 4)),
                      isChampion: (yData.potential >= 5 && Math.random() > 0.8)
                    });
                  }

                  await newDriverRef.set({
                    id: newDriverId,
                    teamId: tid,
                    name: yData.name,
                    age: yData.age,
                    gender: yData.gender,
                    nationality: yData.nationality,
                    portraitUrl: yData.portraitUrl,
                    salary: yData.salary || 520000,
                    contractYearsRemaining: 1,
                    role: "Reserve", // Default to reserve
                    specialty: yData.specialty || null,
                    stats: yData.stats || {},
                    potential: Math.min(5, Math.max(1, Math.round((yData.baseSkill + yData.growthPotential) / 4))),
                    races: 0,
                    wins: 0,
                    podiums: 0,
                    poles: 0,
                    points: 0,
                    seasonPoints: 0,
                    seasonRaces: 0,
                    seasonWins: 0,
                    seasonPodiums: 0,
                    seasonPoles: 0,
                    traits: [],
                    careerHistory: driverHistory,
                    statusTitle: "Rookie" // Default status for promoted academy drivers
                  });

                  await addOfficeNews(tid, {
                    title: "Academy Promotion Successful!",
                    message: `${yData.name} has been promoted to the reserve squad for the next season!`,
                    type: "SUCCESS",
                  });
                }

                // Discard all candidates and selected for the end of season
                const academyConfigRef = db.collection("teams").doc(tid).collection("academy").doc("config");
                const candidatesRef = academyConfigRef.collection("candidates");
                const cSnap = await candidatesRef.get();
                const resetBatch = db.batch();
                cSnap.forEach((d) => resetBatch.delete(d.ref));
                selectedSnap.forEach((d) => resetBatch.delete(d.ref));

                // Reset seasonal scouting quota
                resetBatch.update(academyConfigRef, { scoutsUsedThisSeason: 0 });

                await resetBatch.commit();

                await addOfficeNews(tid, {
                  title: "Youth Academy Reset",
                  message: "The season has ended. Your academy candidates and trainees have been reset for the new season.",
                  type: "INFO",
                });
              }
            }
          }
        }

        // 5. Update Budget and Transactions
        const currentBudget = teamData.budget || 0;
        const newBudget = currentBudget + weeklyIncome - weeklyExpense;

        // weekStatus: reset only weekly-flag fields via dot notation.
        // Persistent fields (trainer/psychologist level, name, assignedTo) are NOT listed here
        // so Firestore leaves them untouched. New fields added in future versions are also safe.
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
          "sponsors": updatedSponsors,
          "budget": newBudget,
        });

        // Use ISO String for dates in JS so it matches Dart expectations
        // (nowIso is defined above)

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

        // Replaced by specific ACADEMY transaction logic in Step 4.

        await batch.commit();
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

      // Sync standings — must run after postRaceProcessed=true so points/stats are final
      await syncUniverseStats();

      logger.info(`Post-race done: ${rDoc.id}`);
    }
  } catch (err) {
    logger.error("Error in postRaceProcessing", err);
  }
});

// ─────────────────────────────────────────────
// 8. SCHEDULED DAILY FITNESS RECOVERY (Midnight COT)
// ─────────────────────────────────────────────
exports.scheduledDailyFitnessRecovery = onSchedule({
  schedule: "0 0 * * *",
  timeZone: "America/Bogota",
  memory: "512MiB",
  timeoutSeconds: 300,
}, async () => {
  logger.info("=== DAILY FITNESS RECOVERY START ===");

  try {
    const driversRef = db.collection("drivers");
    const snapshot = await driversRef.get();

    if (snapshot.empty) {
      logger.info("No drivers found. Skipping.");
      return;
    }

    // Firestore matches have a limit of 500 writes per batch
    const batches = [];
    let currentBatch = db.batch();
    let opCount = 0;

    snapshot.docs.forEach((doc) => {
      const driver = doc.data();
      const stats = driver.stats || {};

      const currentFitness = stats.fitness || 50;

      if (currentFitness < 100) {
        const newFitness = Math.min(100, currentFitness + 1.5);

        currentBatch.update(doc.ref, {
          "stats.fitness": newFitness,
        });

        opCount++;

        // If batch is full (500 limit), push and start a new one
        if (opCount === 500) {
          batches.push(currentBatch.commit());
          currentBatch = db.batch();
          opCount = 0;
        }
      }
    });

    // Commit any remaining operations in the last batch
    if (opCount > 0) {
      batches.push(currentBatch.commit());
    }

    await Promise.all(batches);

    logger.info(`=== DAILY FITNESS RECOVERY COMPLETE. Batches: ${batches.length} ===`);
  } catch (error) {
    logger.error("Error in scheduledDailyFitnessRecovery:", error);
  }
});

// ─────────────────────────────────────────────
// 9. SCHEDULED TRANSFER MARKET RESOLVER (Hourly)
// ─────────────────────────────────────────────
exports.resolveTransferMarket = onSchedule({
  schedule: "0 * * * *",
  timeZone: "America/Bogota",
  memory: "512MiB",
  timeoutSeconds: 300,
}, async () => {
  logger.info("=== TRANSFER MARKET RESOLVER START ===");

  try {
    const now = admin.firestore.Timestamp.now();
    // 24 hours ago
    const yesterday = new Date(now.toDate().getTime() - (24 * 60 * 60 * 1000));
    const yesterdayTs = admin.firestore.Timestamp.fromDate(yesterday);

    const driversRef = db.collection("drivers");
    const snapshot = await driversRef
      .where("isTransferListed", "==", true)
      .where("transferListedAt", "<=", yesterdayTs)
      .get();

    if (snapshot.empty) {
      logger.info("No expired transfer listings found.");
      return;
    }

    const batches = [];
    let currentBatch = db.batch();
    let opCount = 0;

    for (const doc of snapshot.docs) {
      const driver = doc.data();

      const highestBid = driver.currentHighestBid || 0;
      const highestBidderId = driver.highestBidderTeamId;
      const originalTeamId = driver.teamId;

      if (highestBid > 0 && highestBidderId) {
        // Driver Sold

        // Transfer driver to new team
        currentBatch.update(doc.ref, {
          isTransferListed: false,
          transferListedAt: admin.firestore.FieldValue.delete(),
          currentHighestBid: admin.firestore.FieldValue.delete(),
          highestBidderTeamId: admin.firestore.FieldValue.delete(),
          teamId: highestBidderId,
          salary: Math.max(driver.salary || 10000, 10000), // maintain or set default
          contractYearsRemaining: 1, // standard 1 year after transfer
        });
        opCount++;

        // Give money to original team if it exists
        if (originalTeamId) {
          const sellerRef = db.collection("teams").doc(originalTeamId);
          currentBatch.update(sellerRef, {
            budget: admin.firestore.FieldValue.increment(highestBid),
          });
          opCount++;

          // Notify Seller
          await addOfficeNews(originalTeamId, {
            title: "Driver Sold",
            message: `${driver.name} was successfully sold in the transfer market for $${highestBid.toLocaleString()}.`,
            type: "TRANSFER_SOLD",
          });
        }

        // Notify Buyer
        await addOfficeNews(highestBidderId, {
          title: "Transfer Bid Won",
          message: `You won the bid for ${driver.name} for $${highestBid.toLocaleString()}! They have joined your team.`,
          type: "TRANSFER_WON",
        });
      } else {
        // Driver Unsold
        currentBatch.update(doc.ref, {
          isTransferListed: false,
          transferListedAt: admin.firestore.FieldValue.delete(),
          currentHighestBid: admin.firestore.FieldValue.delete(),
          highestBidderTeamId: admin.firestore.FieldValue.delete(),
        });
        opCount++;

        if (originalTeamId) {
          // Notify Seller
          await addOfficeNews(originalTeamId, {
            title: "Driver Unsold",
            message: `Nobody bid on ${driver.name} in the transfer market. They remain in your team.`,
            type: "TRANSFER_UNSOLD",
          });
        } else {
          // If it was generated and no one bought him, he just hangs in the pool or we delete?
          // Deleting keeps the pool clean from unsold admin generated drivers
          currentBatch.delete(doc.ref);
          opCount++;
        }
      }

      if (opCount >= 400) {
        batches.push(currentBatch.commit());
        currentBatch = db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      batches.push(currentBatch.commit());
    }

    await Promise.all(batches);

    logger.info(`=== TRANSFER MARKET RESOLVER COMPLETE. Batches: ${batches.length} ===`);
  } catch (error) {
    logger.error("Error in resolveTransferMarket:", error);
  }
});

exports.megaFixDebriefs = onCall({
  cors: true,
  invoker: "public",
  memory: "1GiB",
  timeoutSeconds: 540,
}, async (request) => {
  logger.info("=== MEGA FIX DEBRIEFS START ===");
  try {
    const leaguesSnap = await db.collection("leagues").get();
    let totalUpdated = 0;

    // Fetch all drivers once to avoid inside-loop latency
    const dSnap = await db.collection("drivers").get();
    const driversMap = {};
    dSnap.forEach((doc) => {
      driversMap[doc.id] = { ...doc.data(), id: doc.id };
    });

    for (const lDoc of leaguesSnap.docs) {
      const league = lDoc.data();
      const sId = league.currentSeasonId;
      if (!sId) continue;

      const sDoc = await db.collection("seasons").doc(sId).get();
      if (!sDoc.exists) continue;
      const season = sDoc.data();

      // Find last COMPLETED race
      let rIdx = -1;
      if (season.calendar) {
        for (let i = season.calendar.length - 1; i >= 0; i--) {
          if (season.calendar[i].isCompleted) {
            rIdx = i;
            break;
          }
        }
      }

      if (rIdx === -1) {
        logger.info(`League ${lDoc.id} has no completed races.`);
        continue;
      }

      const rEvent = season.calendar[rIdx];
      const raceDocId = `${sId}_${rEvent.id}`;
      const rSnap = await db.collection("races").doc(raceDocId).get();

      if (!rSnap.exists) {
        logger.warn(`No race doc for ${raceDocId}`);
        continue;
      }

      const rData = rSnap.data();
      const driversInRace = driversMap; // Reusing the map fetched earlier
      
      const teamGrp = {};
      Object.values(driversInRace).forEach(d => {
        if (!teamGrp[d.teamId]) teamGrp[d.teamId] = [];
        teamGrp[d.teamId].push(d);
      });

      for (const tid of Object.keys(teamGrp)) {
        await generateTeamDebrief(tid, teamGrp[tid], rData, rEvent);
        totalUpdated++;
      }
    }
    logger.info(`=== MEGA FIX COMPLETED: ${totalUpdated} updated ===`);
    return { success: true, updated: totalUpdated };
  } catch (err) {
    logger.error("MegaFix failed", err);
    return { success: false, error: err.message };
  }
});

exports.forceFixGBA = onCall({
  cors: true,
  invoker: "public",
  timeoutSeconds: 120,
}, async (request) => {
  logger.info("=== FORCE FIX GBA START ===");
  try {
    const teamSnap = await db.collection("teams").where("name", "==", "GBA Racing").get();
    if (teamSnap.empty) return { success: false, error: "GBA Racing not found" };
    const teamDoc = teamSnap.docs[0];
    const tid = teamDoc.id;
    const teamData = teamDoc.data();
    const lId = teamData.leagueId;
    if (!lId) return { success: false, error: "League not found for GBA" };

    const lDoc = await db.collection("leagues").doc(lId).get();
    if (!lDoc.exists) return { success: false, error: "League doc not found" };
    const sId = lDoc.data().currentSeasonId;
    if (!sId) return { success: false, error: "Current season not found" };

    const sDoc = await db.collection("seasons").doc(sId).get();
    if (!sDoc.exists) return { success: false, error: "Season doc not found" };
    const season = sDoc.data();

    // Find last COMPLETED race
    let rIdx = -1;
    if (season.calendar) {
      for (let i = season.calendar.length - 1; i >= 0; i--) {
        if (season.calendar[i].isCompleted) {
          rIdx = i;
          break;
        }
      }
    }

    if (rIdx === -1) return { success: false, error: "No completed races in this season" };
    const rEvent = season.calendar[rIdx];
    const raceDocId = `${sId}_${rEvent.id}`;
    const rSnap = await db.collection("races").doc(raceDocId).get();
    if (!rSnap.exists) return { success: false, error: `Race doc ${raceDocId} not found` };
    const rData = rSnap.data();

    const dSnap = await db.collection("drivers").where("teamId", "==", tid).get();
    const drivers = dSnap.docs.map((d) => ({ ...d.data(), id: d.id }));
    const results = rData.results;
    if (!results || !results.finalPositions) return { success: false, error: "No positions in race results" };

    const lines = drivers.map((d) => {
      const pos = results.finalPositions[d.id];
      const isDnf = (results.dnfs || []).includes(d.id);
      return `${d.name}: ${isDnf ? "DNF" : "P" + pos}`;
    }).join("\n");

    const debrief = "Analysis forced for GBA: Reviewing telemetry from " + rEvent.trackName + ". Highlights: " + lines;

    await teamDoc.ref.update({ lastRaceDebrief: debrief, lastRaceResult: lines });
    await addOfficeNews(tid, {
      title: `Race Summary: ${rEvent.trackName}`,
      message: `${lines}\n\nANALYSIS:\n${debrief}`,
      type: "RACE_RESULT",
    });
    return { success: true, tid };
  } catch (err) {
    logger.error("forceFixGBA failed", err);
    return { success: false, error: err.message };
  }
});

/**
 * Admin utility to restore historical data (2020-2025) for active drivers.
 */
exports.restoreDriversHistory = onCall({
  cors: true,
  invoker: "public",
  memory: "512MiB",
  timeoutSeconds: 540,
}, async (request) => {
  logger.info("restoreDriversHistory triggered", { auth: request.auth ? request.auth.uid : null });
  try {
    const driversSnap = await db.collection("drivers").get();
    const teamsSnap = await db.collection("teams").get();
    const teamsMap = {};
    teamsSnap.docs.forEach((d) => {
      teamsMap[d.id] = d.data().name || "Unknown Team";
    });

    const batch = db.batch();
    let count = 0;

    for (const dDoc of driversSnap.docs) {
      const data = dDoc.data();
      const isActive = data.teamId != null || data.isTransferListed === true;
      if (!isActive) continue;

      const age = data.age || 25;
      const potential = data.potential || 3;
      const careerHistory = [];
      let tR = 0; let tW = 0; let tP = 0; let tC = 0;

      const wRB = potential * 0.04;
      const pRB = potential * 0.10;
      const teamN = teamsMap[data.teamId] || "Independent";

      for (let y = 2025; y >= 2020; y--) {
        const yA = 2026 - y;
        const aAY = age - yA;
        if (aAY < 18) continue;

        let pF = 1.0;
        if (aAY < 23) pF = 0.7 + Math.random() * 0.2;
        else if (aAY < 27) pF = 0.9 + Math.random() * 0.2;
        else if (aAY <= 32) pF = 1.1 + Math.random() * 0.3;
        else if (aAY <= 36) pF = 0.8 + Math.random() * 0.2;
        else pF = 0.5 + Math.random() * 0.3;

        const sR = 9 + Math.floor(Math.random() * 2);
        let yW = Math.floor(sR * wRB * pF * (0.8 + Math.random() * 0.4));
        let yP = Math.floor(sR * pRB * pF * (0.8 + Math.random() * 0.4));

        if (yW > sR) yW = sR;
        if (yP > sR) yP = sR;
        if (yP < yW) yP = yW;

        const isC = yW >= 5 && Math.random() > 0.6;

        careerHistory.push({
          year: y,
          teamName: data.teamId ? teamN : "Independiente",
          series: "FTG LEAGUE",
          races: sR,
          wins: yW,
          podiums: yP,
          isChampion: isC,
        });

        tR += sR; tW += yW; tP += yP;
        if (isC) tC++;
      }

      batch.update(dDoc.ref, {
        races: tR,
        wins: tW,
        podiums: tP,
        championships: tC,
        careerHistory: careerHistory,
      });
      count++;
    }

    await batch.commit();
    return { success: true, count };
  } catch (err) {
    logger.error("restoreDriversHistory failed", err);
    return { success: false, error: err.message };
  }
});

// ---------------------------------------------------------------------------
// T-019: Daily JSON backup to Cloud Storage
// ---------------------------------------------------------------------------

const BACKUP_BUCKET = "ftg-racing-manager.firebasestorage.app";
const BACKUP_COLLECTIONS = ["races", "teams", "seasons", "drivers"];
const BACKUP_RETENTION_DAYS = 8;

/**
 * Reads all documents in a Firestore collection and returns them as a
 * JSON-serializable array. Timestamps are preserved as { _seconds, _nanoseconds }
 * objects which is sufficient for disaster recovery.
 * @param {string} collectionName
 * @return {Promise<Object[]>}
 */
async function backupCollection(collectionName) {
  const snap = await db.collection(collectionName).get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

/**
 * Writes one JSON backup per collection to gs://BUCKET/backups/YYYY-MM-DD/.
 * Then deletes any backup folders older than BACKUP_RETENTION_DAYS.
 */
async function runDailyBackup() {
  const bucket = admin.storage().bucket(BACKUP_BUCKET);
  const today = new Date().toISOString().split("T")[0]; // "YYYY-MM-DD"

  // 1. Write today's snapshot
  for (const collName of BACKUP_COLLECTIONS) {
    const docs = await backupCollection(collName);
    const json = JSON.stringify(docs, null, 2);
    const filePath = `backups/${today}/${collName}.json`;
    const file = bucket.file(filePath);
    await file.save(json, { contentType: "application/json" });
    logger.info(`[dailyBackup] Wrote ${filePath} (${docs.length} docs)`);
  }

  // 2. Delete backups older than BACKUP_RETENTION_DAYS
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - BACKUP_RETENTION_DAYS);

  const [files] = await bucket.getFiles({ prefix: "backups/" });
  for (const file of files) {
    const match = file.name.match(/^backups\/(\d{4}-\d{2}-\d{2})\//);
    if (!match) continue;
    const fileDate = new Date(match[1]);
    if (fileDate < cutoff) {
      await file.delete();
      logger.info(`[dailyBackup] Deleted expired backup: ${file.name}`);
    }
  }

  logger.info(`[dailyBackup] Completed for ${today}. Retention: last ${BACKUP_RETENTION_DAYS} days.`);
}

/**
 * Scheduled daily backup — runs at 03:00 COT (08:00 UTC).
 * Backs up: races, teams, seasons, drivers → gs://ftg-racing-manager.firebasestorage.app/backups/YYYY-MM-DD/
 * Retention: 8 days (auto-deletes older folders).
 */
exports.scheduledDailyBackup = onSchedule({
  schedule: "0 3 * * *",
  timeZone: "America/Bogota",
  region: "us-central1",
}, async () => {
  try {
    await runDailyBackup();
  } catch (err) {
    logger.error("[dailyBackup] Backup failed:", err);
    throw err;
  }
});

