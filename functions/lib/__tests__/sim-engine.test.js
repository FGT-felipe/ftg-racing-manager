"use strict";
/**
 * Unit tests for the FTG sim engine (simulateLap).
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
// ─── Tests ────────────────────────────────────────────────────────────────────
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
        // Both calls use random=0.5 so noise cancels out
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
        // With reliability=10: accProb = 0.001 * (1 - 10/30) ≈ 0.000667
        // ex_driver: extraCrash = 0.001 → total ≈ 0.001667
        // Mock random to 0.001: falls between the two thresholds
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
        // Even mostRisky + ex_driver: max accProb ≈ 0.003 * 0.667 + 0.001 ≈ 0.003
        const result = (0, sim_engine_1.simulateLap)({ ...baseParams, style: "mostRisky", teamRole: "ex_driver" });
        expect(result.isCrashed).toBe(false);
        expect(result.lapTime).not.toBe(999.0);
    });
    // ─── 6. mostRisky has higher crash probability than defensive ─────────────
    it("mostRisky style crashes where defensive style does not", () => {
        jest.restoreAllMocks();
        // With reliability=10:
        // defensive: accProb = 0.0005 * 0.667 ≈ 0.000333
        // mostRisky: accProb = 0.003 * 0.667 ≈ 0.002
        // Mock random to 0.001: between the two thresholds
        jest.spyOn(Math, "random").mockReturnValue(0.001);
        const risky = (0, sim_engine_1.simulateLap)({ ...baseParams, style: "mostRisky" });
        const defensive = (0, sim_engine_1.simulateLap)({ ...baseParams, style: "defensive" });
        expect(risky.isCrashed).toBe(true); // 0.001 < 0.002 → crashed
        expect(defensive.isCrashed).toBe(false); // 0.001 > 0.000333 → not crashed
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
