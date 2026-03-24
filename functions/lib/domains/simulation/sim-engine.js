"use strict";
/**
 * FTG Racing Manager — Simulation Engine
 *
 * PURE MODULE: This file contains zero Firestore calls.
 * All inputs are plain data objects. All outputs are plain return values.
 * This makes the engine fully unit-testable without a Firebase emulator.
 *
 * Faithfully extracted from SimEngine in functions/index.js (lines 279–603).
 *
 * ⚠️  CRITICAL RULE: If a `db.`, `admin.`, `firebase-admin`, or
 * `firebase-functions` import ever appears here, reject the change.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.POINT_SYSTEM = void 0;
exports.simulateLap = simulateLap;
exports.simulateRace = simulateRace;
const constants_1 = require("../../config/constants");
Object.defineProperty(exports, "POINT_SYSTEM", { enumerable: true, get: function () { return constants_1.POINT_SYSTEM; } });
// ─── Helpers ─────────────────────────────────────────────────────────────────
const clamp = (v, lo, hi) => Math.min(Math.max(v, lo), hi);
const gap = (a, b) => Math.abs(a - b);
// ─── simulateLap ─────────────────────────────────────────────────────────────
/**
 * Simulates a single qualifying or race lap.
 * Pure function — no side effects, no Firestore calls.
 *
 * @param params Lap simulation inputs (circuit, car stats, driver stats, setup, weather).
 * @returns Lap result with lapTime (999.0 if crashed) and isCrashed flag.
 */
function simulateLap(params) {
    const { circuit, setup, style } = params;
    const driverStats = params.driverStats ?? {};
    const ideal = circuit.idealSetup;
    const s = params.carStats ?? { aero: 1, powertrain: 1, chassis: 1 };
    // --- Setup penalty ---
    const aB = 1.0 - (clamp(s.aero ?? 1, 1, 20) / 40.0);
    const pB = 1.0 - (clamp(s.powertrain ?? 1, 1, 20) / 40.0);
    const cB = 1.0 - (clamp(s.chassis ?? 1, 1, 20) / 40.0);
    let penalty = 0;
    const g1 = gap(setup.frontWing ?? 50, ideal.frontWing);
    penalty += (g1 <= 3 ? 0 : g1 - 3) * 0.03 * aB;
    const g2 = gap(setup.rearWing ?? 50, ideal.rearWing);
    penalty += (g2 <= 3 ? 0 : g2 - 3) * 0.03 * aB;
    const g3 = gap(setup.suspension ?? 50, ideal.suspension);
    penalty += (g3 <= 3 ? 0 : g3 - 3) * 0.02 * cB;
    const g4 = gap(setup.gearRatio ?? 50, ideal.gearRatio);
    penalty += (g4 <= 3 ? 0 : g4 - 3) * 0.025 * pB;
    // --- Car performance ---
    const aV = clamp(s.aero ?? 1, 1, 20);
    const pV = clamp(s.powertrain ?? 1, 1, 20);
    const cV = clamp(s.chassis ?? 1, 1, 20);
    const w = aV * (circuit.aeroWeight ?? 0.33) +
        pV * (circuit.powertrainWeight ?? 0.34) +
        cV * (circuit.chassisWeight ?? 0.33);
    const carFactor = 1.0 - (w / 20.0) * 0.25;
    // --- Driver contribution ---
    const brk = (driverStats.braking ?? 10) / 20.0;
    const crn = (driverStats.cornering ?? 10) / 20.0;
    const foc = (driverStats.focus ?? 10) / 20.0;
    let df = 1.0 - (brk * 0.02 + crn * 0.025 + (foc - 0.5) * 0.01);
    // --- Weather & tyres ---
    const isWet = (params.weather ?? "").toLowerCase().includes("rain") ||
        (params.weather ?? "").toLowerCase().includes("wet");
    if (isWet) {
        if (driverStats.traits?.includes("rainMaster")) {
            df -= 0.01;
        }
        if (setup.tyreCompound !== "wet") {
            penalty += 5.0; // Wrong tyres in rain
        }
        else {
            penalty -= 0.3; // Wet tyre bonus in rain
        }
    }
    else if (setup.tyreCompound === "wet") {
        penalty += 3.0; // Wet tyres on dry track
    }
    // --- Driving style ---
    const st = style ?? "normal";
    let sBonus = 0;
    let accProb = 0.001;
    if (st === "mostRisky") {
        sBonus = 0.04;
        accProb = 0.003;
    }
    else if (st === "offensive") {
        sBonus = 0.02;
        accProb = 0.0015;
    }
    else if (st === "defensive") {
        sBonus = -0.01;
        accProb = 0.0005;
    }
    df -= sBonus;
    // --- Reliability reduces crash chance ---
    const rV = clamp(s.reliability ?? 1, 1, 20);
    accProb *= 1.0 - rV / 30.0;
    // --- Manager role modifiers ---
    // ⚠️  CRITICAL: extraCrash MUST be declared with `let` before any conditional
    // assignment. An undeclared assignment throws ReferenceError in strict mode.
    // This is the exact pattern that caused the R2 and R3 simulation failures.
    const teamRole = params.teamRole ?? "";
    let extraCrash = 0;
    if (teamRole === "ex_driver") {
        extraCrash = 0.001;
        df -= 0.02; // +2% pace bonus
    }
    else if (teamRole === "business") {
        df += 0.02; // -2% pace penalty
    }
    const crashed = Math.random() < accProb + extraCrash;
    let lap = circuit.baseLapTime * carFactor * df + penalty;
    lap += (Math.random() - 0.5) * 0.8;
    return { lapTime: crashed ? 999.0 : lap, isCrashed: crashed };
}
// ─── simulateRace ─────────────────────────────────────────────────────────────
/**
 * Simulates a full race lap by lap, starting from the qualifying grid.
 * Pure function — no side effects, no Firestore calls.
 *
 * @param params Race simulation inputs.
 * @returns Full race result including lap log, final positions, DNFs, and fast lap.
 */
function simulateRace(params) {
    const { circuit, grid, teamsMap, driversMap, setupsMap, managerRoles, raceEvent } = params;
    const roles = managerRoles ?? {};
    const totalLaps = raceEvent.totalLaps ?? circuit.laps;
    const isWet = (raceEvent.weatherRace ?? "").toLowerCase().includes("rain") ||
        (raceEvent.weatherRace ?? "").toLowerCase().includes("wet");
    // --- Initialise state ---
    const order = grid.map((g) => g.driverId);
    const total = {};
    const wear = {};
    const fuel = {};
    const compound = {};
    const style = {};
    const stops = {};
    const usedHard = {};
    const dnfs = [];
    const raceLog = [];
    for (const id of order) {
        const su = { ...constants_1.DEFAULT_SETUP, ...(setupsMap[id] ?? {}) };
        total[id] = 0;
        wear[id] = 0;
        fuel[id] = su.initialFuel ?? 50;
        compound[id] = su.tyreCompound ?? "medium";
        style[id] = su.raceStyle ?? "normal";
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
            if (dnfs.includes(did))
                continue;
            const driver = driversMap[did];
            const team = driver ? teamsMap[driver.teamId] : null;
            if (!driver || !team) {
                dnfs.push(did);
                lapEvents.push({ lap, driverId: did, desc: "DNS: Driver or team data missing", type: "DNF" });
                continue;
            }
            const su = { ...constants_1.DEFAULT_SETUP, ...(setupsMap[did] ?? {}) };
            const idx = driver.carIndex ?? 0;
            const cs = (team.carStats?.[String(idx)]) ?? { aero: 1, powertrain: 1, chassis: 1 };
            const res = simulateLap({
                circuit,
                carStats: cs,
                driverStats: driver.stats ?? {},
                setup: { ...su, tyreCompound: compound[did] },
                style: style[did],
                teamRole: roles[driver.teamId] ?? "",
                weather: raceEvent.weatherRace,
            });
            if (res.isCrashed) {
                dnfs.push(did);
                lapEvents.push({ lap, driverId: did, desc: "CRASH: Retired from race", type: "DNF" });
                continue;
            }
            let lt = res.lapTime;
            // Tyre wear penalty
            lt += Math.pow(wear[did] / 100.0, 2) * 8.0;
            // Fuel weight penalty
            lt += (fuel[did] / 100.0) * 1.5;
            // Fuel consumption
            const baseFuelC = 2.5 * (circuit.fuelConsumptionMultiplier ?? 1);
            let fMod = 1.0;
            let wMod = 1.0;
            if (style[did] === "defensive") {
                fMod = 0.85;
                wMod = 0.75;
            }
            else if (style[did] === "offensive") {
                fMod = 1.15;
                wMod = 1.25;
            }
            else if (style[did] === "mostRisky") {
                fMod = 1.35;
                wMod = 1.6;
            }
            fuel[did] -= baseFuelC * fMod;
            if (fuel[did] <= 0) {
                lt += 10.0;
                fuel[did] = 0.5;
                lapEvents.push({ lap, driverId: did, desc: "OUT OF FUEL: Limping to pits", type: "INFO" });
            }
            // Pit stop logic
            const needsT = wear[did] > 80;
            const needsF = fuel[did] < baseFuelC * 2.5;
            if ((needsT || needsF) && lap < totalLaps) {
                lt += 24.0 + Math.random() * 2.0;
                wear[did] = 0;
                const si = stops[did];
                const pFuels = su.pitStopFuel ?? [50];
                fuel[did] = si < pFuels.length ? pFuels[si] : 50;
                const plan = su.pitStops ?? ["hard"];
                const splan = su.pitStopStyles ?? ["normal"];
                let nc;
                if (si < plan.length) {
                    nc = plan[si];
                }
                else {
                    nc = usedHard[did]
                        ? (plan.length ? plan[plan.length - 1] : "medium")
                        : "hard";
                }
                style[did] = si < splan.length ? splan[si] : "normal";
                compound[did] = nc;
                stops[did] = si + 1;
                if (nc === "hard")
                    usedHard[did] = true;
                lapEvents.push({
                    lap, driverId: did,
                    desc: `In for a stop! Swapping to ${nc.toUpperCase()}s.`, type: "PIT",
                });
            }
            else {
                // Tyre wear accumulation
                let cwMod = 1.0;
                if (compound[did] === "soft")
                    cwMod = 1.6;
                else if (compound[did] === "medium")
                    cwMod = 1.1;
                else if (compound[did] === "hard")
                    cwMod = 0.7;
                wear[did] +=
                    4.5 * (circuit.tyreWearMultiplier ?? 1) * cwMod * wMod + Math.random();
                // Ex-Engineer: -10% tyre wear
                const teamRoleW = roles[driversMap[did].teamId] ?? "";
                if (teamRoleW === "engineer") {
                    wear[did] *= 0.9;
                }
            }
            lapTimes[did] = lt;
            total[did] = (total[did] ?? 0) + lt;
            if (lt < fast_lap_time) {
                fast_lap_time = lt;
                fast_lap_driver = did;
            }
        }
        // Sort by cumulative time
        const newOrd = [...curOrder];
        newOrd.sort((a, b) => {
            if (dnfs.includes(a))
                return 1;
            if (dnfs.includes(b))
                return -1;
            return (total[a] ?? 0) - (total[b] ?? 0);
        });
        // Detect overtakes
        for (let i = 0; i < newOrd.length; i++) {
            if (dnfs.includes(newOrd[i]))
                continue;
            const old = curOrder.indexOf(newOrd[i]);
            if (old !== -1 && i < old) {
                let flavor = "Overtake move!";
                if (i + 1 < newOrd.length) {
                    const passedId = newOrd[i + 1];
                    const passedName = driversMap[passedId]?.name ?? "rival";
                    const phrases = [
                        `Dives down the inside of ${passedName}!`,
                        `Moves past ${passedName} for P${i + 1}!`,
                        `Great move on ${passedName}!`,
                        `Takes P${i + 1} from ${passedName}!`,
                    ];
                    flavor = phrases[newOrd.length % phrases.length];
                }
                lapEvents.push({ lap, driverId: newOrd[i], desc: flavor, type: "OVERTAKE" });
            }
        }
        curOrder = newOrd;
        const pos = {};
        curOrder.forEach((id, i) => { pos[id] = i + 1; });
        raceLog.push({ lap, lapTimes, positions: pos, tyres: { ...compound }, events: lapEvents });
    }
    // Hard compound penalty (35s) — only if NOT wet
    for (const did of curOrder) {
        if (!dnfs.includes(did) && !usedHard[did] && !isWet) {
            total[did] = (total[did] ?? 0) + 35.0;
            if (raceLog.length) {
                raceLog[raceLog.length - 1].events.push({
                    lap: totalLaps,
                    driverId: did,
                    desc: "35s PENALTY: Failed to use Hard compound",
                    type: "INFO",
                });
            }
        }
    }
    // Final sort
    curOrder.sort((a, b) => {
        if (dnfs.includes(a))
            return 1;
        if (dnfs.includes(b))
            return -1;
        return (total[a] ?? 0) - (total[b] ?? 0);
    });
    const finalPositions = {};
    curOrder.forEach((id, i) => { finalPositions[id] = i + 1; });
    return {
        raceLog,
        finalPositions,
        totalTimes: total,
        dnfs,
        fast_lap_time,
        fast_lap_driver,
    };
}
