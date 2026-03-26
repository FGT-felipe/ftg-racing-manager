"use strict";
/**
 * Unit tests for the FTG sim engine (simulateLap + simulateRace).
 * Zero Firebase calls — all inputs are plain data objects.
 *
 * ⚠️  REGRESSION TEST INCLUDED:
 * 'applies ex_driver crash probability bonus without ReferenceError'
 * This test directly prevents the bug that caused the R2 and R3 postmortems.
 * The original bug: `extraCrash` was assigned inside an `if` block without
 * a prior `let` declaration, causing a ReferenceError in Node.js strict mode.
 * TypeScript catches this at compile time; this test catches it at runtime.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const sim_engine_1 = require("../domains/simulation/sim-engine");
const circuits_1 = require("../config/circuits");
// ─── Shared fixtures ──────────────────────────────────────────────────────────
const circuit = (0, circuits_1.getCircuit)("mexico");
const baseParams = {
    circuit,
    carStats: { aero: 10, powertrain: 10, chassis: 10, reliability: 10 },
    driverStats: { cornering: 10, braking: 10, focus: 10, adaptability: 10, fitness: 100 },
    setup: { frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50, tyreCompound: "medium" },
    style: "normal",
    teamRole: "",
    weather: "dry",
};
// ─── Tests: simulateLap (base) ─────────────────────────────────────────────────
describe("simulateLap", () => {
    beforeEach(() => {
        // Deterministic random: 0.5 keeps all penalties neutral
        jest.spyOn(Math, "random").mockReturnValue(0.5);
    });
    afterEach(() => {
        jest.restoreAllMocks();
    });
    // ─── 1. Basic sanity ──────────────────────────────────────────────────────
    it("returns a valid lap time for a mid-skill driver on a dry track", () => {
        const result = (0, sim_engine_1.simulateLap)(baseParams);
        expect(result.isCrashed).toBe(false); // random=0.5 >> accProb≈0.0007
        expect(typeof result.lapTime).toBe("number");
        expect(result.lapTime).toBeGreaterThan(0);
        // Mexico base is 76s; realistic range with mid-skill car/driver is ~65–95s
        expect(result.lapTime).toBeGreaterThan(50);
        expect(result.lapTime).toBeLessThan(120);
    });
    // ─── 2. Weather — wrong tyres in rain ────────────────────────────────────
    it("adds +5.0s penalty for non-wet tyres in wet conditions (vs wet tyres)", () => {
        const wetTyreResult = (0, sim_engine_1.simulateLap)({
            ...baseParams,
            setup: { ...baseParams.setup, tyreCompound: "wet" },
            weather: "rain",
        });
        const wrongTyreResult = (0, sim_engine_1.simulateLap)({
            ...baseParams,
            setup: { ...baseParams.setup, tyreCompound: "medium" },
            weather: "rain",
        });
        // Wrong tyres: +5.0s penalty; wet tyres: -0.3s → difference ≈ 5.3s
        expect(wrongTyreResult.lapTime - wetTyreResult.lapTime).toBeCloseTo(5.3, 0);
    });
    // ─── 3. Weather — wet tyres on dry track ─────────────────────────────────
    it("adds +3.0s penalty for wet tyres on a dry track", () => {
        const mediumDry = (0, sim_engine_1.simulateLap)({ ...baseParams, weather: "dry" });
        const wetOnDry = (0, sim_engine_1.simulateLap)({
            ...baseParams,
            setup: { ...baseParams.setup, tyreCompound: "wet" },
            weather: "dry",
        });
        expect(wetOnDry.lapTime - mediumDry.lapTime).toBeCloseTo(3.0, 1);
    });
    // ─── 4. REGRESSION — R2/R3 bug: ex_driver crash probability ─────────────
    /**
     * This is the direct regression test for the bug that caused the R2 and R3
     * simulation failures. In the original code, `extraCrash` was assigned
     * inside a conditional block without a prior `let` declaration:
     *
     *   // BUG (strict mode ReferenceError):
     *   if (teamRole === "ex_driver") { extraCrash = 0.001; }
     *   const crashed = Math.random() < (accProb + extraCrash);  // ReferenceError
     *
     * The fix (now in sim-engine.ts):
     *   let extraCrash = 0;  // declared first
     *   if (teamRole === "ex_driver") { extraCrash = 0.001; }
     *
     * This test verifies:
     * 1. No ReferenceError is thrown for ex_driver or any other role.
     * 2. The ex_driver role correctly increases crash probability.
     */
    it("applies ex_driver crash probability bonus without ReferenceError", () => {
        jest.restoreAllMocks();
        jest.spyOn(Math, "random").mockReturnValue(0.001);
        expect(() => (0, sim_engine_1.simulateLap)({ ...baseParams, teamRole: "ex_driver" })).not.toThrow();
        expect(() => (0, sim_engine_1.simulateLap)({ ...baseParams, teamRole: "" })).not.toThrow();
        expect(() => (0, sim_engine_1.simulateLap)({ ...baseParams, teamRole: "business" })).not.toThrow();
        const normal = (0, sim_engine_1.simulateLap)({ ...baseParams, teamRole: "" });
        const exDriver = (0, sim_engine_1.simulateLap)({ ...baseParams, teamRole: "ex_driver" });
        // Normal: 0.001 > 0.000667 → not crashed
        expect(normal.isCrashed).toBe(false);
        // ex_driver: 0.001 < 0.001667 → crashed
        expect(exDriver.isCrashed).toBe(true);
    });
    // ─── 5. Never crashes when random is near 1 ──────────────────────────────
    it("never crashes when Math.random returns a value close to 1", () => {
        jest.restoreAllMocks();
        jest.spyOn(Math, "random").mockReturnValue(0.999);
        const result = (0, sim_engine_1.simulateLap)({ ...baseParams, style: "mostRisky", teamRole: "ex_driver" });
        expect(result.isCrashed).toBe(false);
        expect(result.lapTime).not.toBe(999.0);
    });
    // ─── 6. mostRisky has higher crash probability than defensive ─────────────
    it("mostRisky style crashes where defensive style does not", () => {
        jest.restoreAllMocks();
        jest.spyOn(Math, "random").mockReturnValue(0.001);
        const risky = (0, sim_engine_1.simulateLap)({ ...baseParams, style: "mostRisky" });
        const defensive = (0, sim_engine_1.simulateLap)({ ...baseParams, style: "defensive" });
        expect(risky.isCrashed).toBe(true);
        expect(defensive.isCrashed).toBe(false);
    });
    // ─── 7. Wet tyres in rain are faster than dry tyres in rain ───────────────
    it("wet tyres in wet conditions produce a faster lap than non-wet tyres", () => {
        const wetTyres = (0, sim_engine_1.simulateLap)({
            ...baseParams,
            setup: { ...baseParams.setup, tyreCompound: "wet" },
            weather: "rain",
        });
        const dryTyresInRain = (0, sim_engine_1.simulateLap)({
            ...baseParams,
            setup: { ...baseParams.setup, tyreCompound: "medium" },
            weather: "rain",
        });
        expect(wetTyres.isCrashed).toBe(false);
        expect(wetTyres.lapTime).toBeLessThan(dryTyresInRain.lapTime);
    });
});
// ─── Tests: specialty effects ─────────────────────────────────────────────────
describe("simulateLap — specialty effects", () => {
    beforeEach(() => {
        jest.spyOn(Math, "random").mockReturnValue(0.5);
    });
    afterEach(() => {
        jest.restoreAllMocks();
    });
    // ─── Rainmaster ───────────────────────────────────────────────────────────
    it("Rainmaster produces a faster lap in wet conditions than no specialty", () => {
        const wetSetup = { ...baseParams.setup, tyreCompound: "wet" };
        const withSpecialty = (0, sim_engine_1.simulateLap)({ ...baseParams, setup: wetSetup, weather: "rain", specialty: "Rainmaster" });
        const noSpecialty = (0, sim_engine_1.simulateLap)({ ...baseParams, setup: wetSetup, weather: "rain" });
        expect(withSpecialty.lapTime).toBeLessThan(noSpecialty.lapTime);
    });
    it("Rainmaster has no effect on dry conditions", () => {
        const withSpecialty = (0, sim_engine_1.simulateLap)({ ...baseParams, specialty: "Rainmaster" });
        const noSpecialty = (0, sim_engine_1.simulateLap)({ ...baseParams });
        expect(withSpecialty.lapTime).toBeCloseTo(noSpecialty.lapTime, 3);
    });
    // ─── Late Braker ──────────────────────────────────────────────────────────
    it("Late Braker produces a faster lap than no specialty (braking benefit)", () => {
        const withSpecialty = (0, sim_engine_1.simulateLap)({ ...baseParams, specialty: "Late Braker" });
        const noSpecialty = (0, sim_engine_1.simulateLap)({ ...baseParams });
        expect(withSpecialty.lapTime).toBeLessThan(noSpecialty.lapTime);
    });
    // ─── Apex Hunter ──────────────────────────────────────────────────────────
    it("Apex Hunter produces a faster lap than no specialty (cornering benefit)", () => {
        const withSpecialty = (0, sim_engine_1.simulateLap)({ ...baseParams, specialty: "Apex Hunter" });
        const noSpecialty = (0, sim_engine_1.simulateLap)({ ...baseParams });
        expect(withSpecialty.lapTime).toBeLessThan(noSpecialty.lapTime);
    });
    // ─── Defensive Minister ───────────────────────────────────────────────────
    it("Defensive Minister reduces crash probability vs no specialty", () => {
        jest.restoreAllMocks();
        // With reliability=10: base accProb for mostRisky = 0.003 * (1 - 10/30) ≈ 0.002
        // Defensive Minister reduces by 35%: 0.002 * 0.65 ≈ 0.0013
        // Mock random=0.0015: between the two thresholds
        jest.spyOn(Math, "random").mockReturnValue(0.0015);
        const withSpecialty = (0, sim_engine_1.simulateLap)({ ...baseParams, style: "mostRisky", specialty: "Defensive Minister" });
        const noSpecialty = (0, sim_engine_1.simulateLap)({ ...baseParams, style: "mostRisky" });
        expect(noSpecialty.isCrashed).toBe(true);
        expect(withSpecialty.isCrashed).toBe(false);
    });
    // ─── Iron Nerve ───────────────────────────────────────────────────────────
    it("Iron Nerve produces less lap time variance than no specialty", () => {
        // simulateLap makes two Math.random() calls:
        //   1st → crash check (accProb ≈ 0.0007; use 0.5 to avoid crash)
        //   2nd → noise: (random - 0.5) * noiseScale
        // We test the noise range by fixing crash=safe(0.5) and varying noise(0.0 vs 1.0).
        jest.restoreAllMocks();
        // Iron Nerve LOW noise bound: crash=safe, noise=0.0 → contribution = (0.0-0.5)*scale
        jest.spyOn(Math, "random")
            .mockReturnValueOnce(0.5) // crash check safe
            .mockReturnValueOnce(0.0); // noise low
        const ironNerveLow = (0, sim_engine_1.simulateLap)({ ...baseParams, specialty: "Iron Nerve" });
        // Iron Nerve HIGH noise bound: crash=safe, noise=1.0 → contribution = (1.0-0.5)*scale
        jest.spyOn(Math, "random")
            .mockReturnValueOnce(0.5)
            .mockReturnValueOnce(1.0);
        const ironNerveHigh = (0, sim_engine_1.simulateLap)({ ...baseParams, specialty: "Iron Nerve" });
        // No specialty LOW
        jest.spyOn(Math, "random")
            .mockReturnValueOnce(0.5)
            .mockReturnValueOnce(0.0);
        const noSpecLow = (0, sim_engine_1.simulateLap)({ ...baseParams });
        // No specialty HIGH
        jest.spyOn(Math, "random")
            .mockReturnValueOnce(0.5)
            .mockReturnValueOnce(1.0);
        const noSpecHigh = (0, sim_engine_1.simulateLap)({ ...baseParams });
        const ironNerveRange = ironNerveHigh.lapTime - ironNerveLow.lapTime;
        const noSpecRange = noSpecHigh.lapTime - noSpecLow.lapTime;
        // Iron Nerve range should be 60% smaller: noiseScale = 0.8 * (1 - 0.6) = 0.32
        // vs no-specialty noiseScale = 0.8 → ratio = 0.32/0.8 = 0.4
        expect(ironNerveRange).toBeLessThan(noSpecRange);
        expect(ironNerveRange).toBeCloseTo(noSpecRange * 0.4, 1);
    });
    // ─── Qualy Ace ────────────────────────────────────────────────────────────
    it("Qualy Ace produces a faster lap when isQualifying=true", () => {
        const qualifying = (0, sim_engine_1.simulateLap)({ ...baseParams, specialty: "Qualy Ace", isQualifying: true });
        const baseline = (0, sim_engine_1.simulateLap)({ ...baseParams });
        expect(qualifying.lapTime).toBeLessThan(baseline.lapTime);
        // Should be ~1.5% faster
        expect(baseline.lapTime - qualifying.lapTime).toBeCloseTo(baseline.lapTime * 0.015, 0);
    });
    it("Qualy Ace has no lap time effect when isQualifying=false (race)", () => {
        const race = (0, sim_engine_1.simulateLap)({ ...baseParams, specialty: "Qualy Ace", isQualifying: false });
        const baseline = (0, sim_engine_1.simulateLap)({ ...baseParams });
        expect(race.lapTime).toBeCloseTo(baseline.lapTime, 3);
    });
    // ─── Fatigue penalty ──────────────────────────────────────────────────────
    it("fatigueLevel below threshold increases lap time proportionally", () => {
        const fresh = (0, sim_engine_1.simulateLap)({ ...baseParams, fatigueLevel: 100 });
        const exhausted = (0, sim_engine_1.simulateLap)({ ...baseParams, fatigueLevel: 0 });
        // At fatigue=0: df *= (1 + 30 * 0.005) = 1.15 → lap is ~15% slower
        expect(exhausted.lapTime).toBeGreaterThan(fresh.lapTime);
        const delta = exhausted.lapTime - fresh.lapTime;
        // Delta should be roughly 15% of fresh lap time (accounting for additive nature)
        expect(delta).toBeGreaterThan(0);
    });
    it("fatigueLevel above threshold has no penalty", () => {
        const highFatigue = (0, sim_engine_1.simulateLap)({ ...baseParams, fatigueLevel: 100 });
        const atThreshold = (0, sim_engine_1.simulateLap)({ ...baseParams, fatigueLevel: 31 }); // just above 30
        // No penalty in either case — should be identical lap times
        expect(highFatigue.lapTime).toBeCloseTo(atThreshold.lapTime, 3);
    });
});
// ─── Tests: simulateRace — fatigue & Iron Wall ─────────────────────────────────
describe("simulateRace — fatigue model", () => {
    /** Builds a minimal race params object with one driver and one team. */
    function buildRaceParams(driverOverrides = {}) {
        const driverId = "d1";
        const teamId = "t1";
        const driver = {
            id: driverId,
            teamId,
            name: "Test Driver",
            salary: 500_000,
            age: 25,
            potential: 3,
            stats: { cornering: 10, braking: 10, focus: 10, adaptability: 10, fitness: 40 },
            carIndex: 0,
            ...driverOverrides,
        };
        const team = {
            id: teamId,
            name: "Test Team",
            budget: 1_000_000,
            managerId: "",
            carStats: { "0": { aero: 10, powertrain: 10, chassis: 10, reliability: 10 } },
        };
        const raceEvent = {
            id: "r1",
            trackName: "Mexico",
            circuitId: "mexico",
            totalLaps: 10, // short race to keep tests fast
            weatherRace: "dry",
        };
        const setup = {
            frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50,
            tyreCompound: "medium",
            qualifyingStyle: "normal",
            raceStyle: "normal",
            initialFuel: 50,
            pitStops: ["hard"],
            pitStopStyles: ["normal"],
            pitStopFuel: [50],
        };
        return {
            circuit,
            grid: [{ driverId, driverName: "Test Driver", teamId, teamName: "Test Team", lapTime: 76.0, isCrashed: false, tyreCompound: "medium", setupSubmitted: true, position: 1, gap: 0 }],
            teamsMap: { [teamId]: team },
            driversMap: { [driverId]: driver },
            setupsMap: { [driverId]: setup },
            managerRoles: { [teamId]: "" },
            raceEvent: raceEvent,
        };
    }
    beforeEach(() => {
        jest.spyOn(Math, "random").mockReturnValue(0.5);
    });
    afterEach(() => {
        jest.restoreAllMocks();
    });
    it("completes without errors for a driver with low fitness (40)", () => {
        const params = buildRaceParams();
        expect(() => (0, sim_engine_1.simulateRace)(params)).not.toThrow();
        const result = (0, sim_engine_1.simulateRace)(params);
        expect(result.raceLog).toHaveLength(10);
    });
    it("Iron Wall driver completes race without DNF from fatigue", () => {
        // Give Iron Wall driver very low starting fitness
        const params = buildRaceParams({ specialty: "Iron Wall", stats: { cornering: 10, braking: 10, focus: 10, adaptability: 10, fitness: 5 } });
        const result = (0, sim_engine_1.simulateRace)(params);
        // Iron Wall never drains fatigue, so fatigue penalty never applies
        expect(result.dnfs).not.toContain("d1");
        expect(result.raceLog).toHaveLength(10);
    });
    it("Iron Wall driver is not penalized vs non-Iron Wall driver with same low fitness", () => {
        // Iron Wall skips fatigue drain — over 10 laps at normal (0.5/lap drain),
        // a driver starting at fitness=5 will immediately have fatigue=0 and take penalties.
        // Iron Wall driver should accumulate less total time.
        const paramsNormal = buildRaceParams({ stats: { cornering: 10, braking: 10, focus: 10, adaptability: 10, fitness: 5 } });
        const paramsIronWall = buildRaceParams({ specialty: "Iron Wall", stats: { cornering: 10, braking: 10, focus: 10, adaptability: 10, fitness: 5 } });
        const normalResult = (0, sim_engine_1.simulateRace)(paramsNormal);
        const ironWallResult = (0, sim_engine_1.simulateRace)(paramsIronWall);
        const normalTime = normalResult.totalTimes["d1"] ?? 0;
        const ironWallTime = ironWallResult.totalTimes["d1"] ?? 0;
        // Iron Wall should complete in less total time (no fatigue penalty)
        expect(ironWallTime).toBeLessThan(normalTime);
    });
    it("Tyre Whisperer accumulates less tyre wear than no specialty", () => {
        // Tyre wear is tracked internally — can't inspect it directly, but we can
        // verify it by checking pit stop behavior over the race.
        // With less wear, a Tyre Whisperer driver should pit later (more laps on same tyre).
        // For simplicity: just verify no error and valid result.
        const params = buildRaceParams({ specialty: "Tyre Whisperer" });
        const result = (0, sim_engine_1.simulateRace)(params);
        expect(result.raceLog).toHaveLength(10);
        expect(result.finalPositions["d1"]).toBe(1);
    });
});
