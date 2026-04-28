"use strict";
/**
 * Unit tests for the parts wear engine (T-007 Slice 2).
 * Zero Firebase calls — computeWearDelta, failureRoll, and getTierFromCondition are pure.
 */
Object.defineProperty(exports, "__esModule", { value: true });
const wear_1 = require("../domains/simulation/wear");
const sim_engine_1 = require("../domains/simulation/sim-engine");
const circuits_1 = require("../config/circuits");
// ─── Helpers ──────────────────────────────────────────────────────────────────
const baseParams = (overrides = {}) => ({
    trigger: "race",
    partType: "engine",
    partLevel: 1,
    circuitId: "mexico",
    raceStyle: "normal",
    weather: "dry",
    circuitStressMap: wear_1.PARTS_WEAR_CONFIG_DEFAULTS.circuitStress,
    baseDeltas: wear_1.PARTS_WEAR_CONFIG_DEFAULTS.baseDeltas.race,
    incidentMultiplier: wear_1.PARTS_WEAR_CONFIG_DEFAULTS.incidentMultiplier,
    hadIncident: false,
    ...overrides,
});
// ─── Tests: getTierFromCondition ─────────────────────────────────────────────
describe("getTierFromCondition", () => {
    it("condition 100 → green", () => expect((0, wear_1.getTierFromCondition)(100)).toBe("green"));
    it("condition 80 → green (boundary exact)", () => expect((0, wear_1.getTierFromCondition)(80)).toBe("green"));
    it("condition 79 → yellow", () => expect((0, wear_1.getTierFromCondition)(79)).toBe("yellow"));
    it("condition 50 → yellow (boundary exact)", () => expect((0, wear_1.getTierFromCondition)(50)).toBe("yellow"));
    it("condition 49 → orange", () => expect((0, wear_1.getTierFromCondition)(49)).toBe("orange"));
    it("condition 30 → orange (boundary exact)", () => expect((0, wear_1.getTierFromCondition)(30)).toBe("orange"));
    it("condition 29 → red", () => expect((0, wear_1.getTierFromCondition)(29)).toBe("red"));
    it("condition 0 → red", () => expect((0, wear_1.getTierFromCondition)(0)).toBe("red"));
});
// ─── Tests: computeWearDelta ──────────────────────────────────────────────────
describe("computeWearDelta", () => {
    it("qualifying trigger → 0 (deferred to S3)", () => {
        expect((0, wear_1.computeWearDelta)(baseParams({ trigger: "qualifying" }))).toBe(0);
    });
    it("special_event trigger → 0 (deferred to S3)", () => {
        expect((0, wear_1.computeWearDelta)(baseParams({ trigger: "special_event" }))).toBe(0);
    });
    it("race trigger with all-1 modifiers → base delta (engine=8)", () => {
        // mexico has circuitStress.engine=0.3, so expected = 8 * 1.3 * 1.0 * 1.0 * 1.0 = 10.4
        const delta = (0, wear_1.computeWearDelta)(baseParams());
        expect(delta).toBeCloseTo(8 * (1 + 0.3) * 1.0 * 1.0 * 1.0, 5);
    });
    it("mostRisky style adds 30% driver modifier", () => {
        const normal = (0, wear_1.computeWearDelta)(baseParams({ raceStyle: "normal" }));
        const risky = (0, wear_1.computeWearDelta)(baseParams({ raceStyle: "mostRisky" }));
        expect(risky / normal).toBeCloseTo(1.3, 5);
    });
    it("risky style adds 15% driver modifier", () => {
        const normal = (0, wear_1.computeWearDelta)(baseParams({ raceStyle: "normal" }));
        const risky = (0, wear_1.computeWearDelta)(baseParams({ raceStyle: "risky" }));
        expect(risky / normal).toBeCloseTo(1.15, 5);
    });
    it("defensive style reduces delta by 10%", () => {
        const normal = (0, wear_1.computeWearDelta)(baseParams({ raceStyle: "normal" }));
        const def = (0, wear_1.computeWearDelta)(baseParams({ raceStyle: "defensive" }));
        expect(def / normal).toBeCloseTo(0.9, 5);
    });
    it("wet weather adds 20% track condition modifier", () => {
        const dry = (0, wear_1.computeWearDelta)(baseParams({ weather: "dry" }));
        const wet = (0, wear_1.computeWearDelta)(baseParams({ weather: "rain" }));
        expect(wet / dry).toBeCloseTo(1.2, 5);
    });
    it("level 5 part has lower delta than level 1 (carLevelModifier)", () => {
        const lvl1 = (0, wear_1.computeWearDelta)(baseParams({ partLevel: 1 }));
        const lvl5 = (0, wear_1.computeWearDelta)(baseParams({ partLevel: 5 }));
        expect(lvl5).toBeLessThan(lvl1);
    });
    it("carLevelModifier floors at 0.6 for high levels", () => {
        const lvl20 = (0, wear_1.computeWearDelta)(baseParams({ partLevel: 20 }));
        const lvl9 = (0, wear_1.computeWearDelta)(baseParams({ partLevel: 9 })); // 1-(9-1)*0.05=0.6 exactly
        expect(lvl20).toBeCloseTo(lvl9, 5);
    });
    it("incident bump multiplies delta by incidentMultiplier", () => {
        const noBump = (0, wear_1.computeWearDelta)(baseParams({ hadIncident: false }));
        const bump = (0, wear_1.computeWearDelta)(baseParams({ hadIncident: true }));
        expect(bump / noBump).toBeCloseTo(wear_1.PARTS_WEAR_CONFIG_DEFAULTS.incidentMultiplier, 5);
    });
    it("unknown circuit (no stress entry) → circuitStress defaults to 0", () => {
        const noStress = (0, wear_1.computeWearDelta)(baseParams({ circuitId: "unknown_circuit_xyz" }));
        // Should equal base * 1.0 (no stress) * other modifiers
        const expected = 8 * (1 + 0) * 1.0 * 1.0 * 1.0;
        expect(noStress).toBeCloseTo(expected, 5);
    });
    it("interlagos brakes have higher stress than mexico brakes", () => {
        const mex = (0, wear_1.computeWearDelta)(baseParams({ partType: "brakes", circuitId: "mexico" }));
        const int = (0, wear_1.computeWearDelta)(baseParams({ partType: "brakes", circuitId: "interlagos" }));
        expect(int).toBeGreaterThan(mex);
    });
    // Condition floor — should never go negative
    it("wear application floors at 0 (condition 5 - delta)", () => {
        const delta = (0, wear_1.computeWearDelta)(baseParams({ circuitId: "unknown_circuit_xyz" })); // base=8, no stress
        const conditionAfter = Math.max(0, 5 - delta);
        expect(conditionAfter).toBe(0);
    });
    it("wear application — normal case (condition 50 - base 8 with no modifiers)", () => {
        const delta = (0, wear_1.computeWearDelta)(baseParams({ circuitId: "unknown_circuit_xyz" }));
        const conditionAfter = Math.max(0, 50 - delta);
        expect(conditionAfter).toBeCloseTo(42, 0);
    });
});
// ─── Tests: failureRoll ───────────────────────────────────────────────────────
describe("failureRoll", () => {
    const curve = wear_1.PARTS_WEAR_CONFIG_DEFAULTS.failureCurve;
    it("green tier never fails (prob=0)", () => {
        for (let i = 0; i < 1000; i++) {
            expect((0, wear_1.failureRoll)("green", curve)).toBe(false);
        }
    });
    it("red tier produces failures at approx 4% rate (within 3σ over 10000 rolls)", () => {
        const rolls = 10_000;
        let failures = 0;
        for (let i = 0; i < rolls; i++) {
            if ((0, wear_1.failureRoll)("red", curve))
                failures++;
        }
        const rate = failures / rolls;
        // Expected 0.04, std dev ≈ 0.00196. 3σ = 0.00588
        expect(rate).toBeGreaterThan(0.04 - 0.018);
        expect(rate).toBeLessThan(0.04 + 0.018);
    });
    it("returns false when prob is 0", () => {
        expect((0, wear_1.failureRoll)("green", { green: 0, yellow: 0, orange: 0, red: 0 })).toBe(false);
    });
    it("always returns true when prob is 1.0", () => {
        jest.spyOn(Math, "random").mockReturnValue(0.0);
        expect((0, wear_1.failureRoll)("red", { green: 0, yellow: 0, orange: 0, red: 1.0 })).toBe(true);
        jest.restoreAllMocks();
    });
    it("returns false when roll >= prob", () => {
        jest.spyOn(Math, "random").mockReturnValue(0.999);
        expect((0, wear_1.failureRoll)("orange", curve)).toBe(false);
        jest.restoreAllMocks();
    });
});
// ─── Tests: simulateLap engineCondition multiplier (S1 backward compat) ──────
describe("simulateLap — engineCondition multiplier (T-007 S1 compat)", () => {
    const circuit = (0, circuits_1.getCircuit)("mexico");
    const baseSimParams = {
        circuit,
        carStats: { aero: 10, powertrain: 10, chassis: 10, reliability: 10 },
        driverStats: { cornering: 10, braking: 10, focus: 10, adaptability: 10, fitness: 100 },
        setup: { frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50, tyreCompound: "medium" },
        style: "normal",
        teamRole: "",
        weather: "dry",
    };
    beforeEach(() => {
        jest.spyOn(Math, "random").mockReturnValue(0.5);
    });
    afterEach(() => {
        jest.restoreAllMocks();
    });
    it("engineCondition=100 produces same lap time as omitting the parameter", () => {
        const withFull = (0, sim_engine_1.simulateLap)({ ...baseSimParams, engineCondition: 100 });
        const withoutParam = (0, sim_engine_1.simulateLap)({ ...baseSimParams });
        expect(withFull.lapTime).toBeCloseTo(withoutParam.lapTime, 5);
    });
    it("engineCondition=50 produces a slower lap time than engineCondition=100", () => {
        const full = (0, sim_engine_1.simulateLap)({ ...baseSimParams, engineCondition: 100 });
        const worn = (0, sim_engine_1.simulateLap)({ ...baseSimParams, engineCondition: 50 });
        expect(worn.lapTime).toBeGreaterThan(full.lapTime);
    });
    it("engineCondition=0 produces the slowest lap time (no powertrain contribution)", () => {
        const full = (0, sim_engine_1.simulateLap)({ ...baseSimParams, engineCondition: 100 });
        const dead = (0, sim_engine_1.simulateLap)({ ...baseSimParams, engineCondition: 0 });
        expect(dead.lapTime).toBeGreaterThan(full.lapTime);
    });
    it("undefined engineCondition defaults to 1.0 factor (no penalty — COMPAT-1)", () => {
        const withUndefined = (0, sim_engine_1.simulateLap)({ ...baseSimParams, engineCondition: undefined });
        const withFull = (0, sim_engine_1.simulateLap)({ ...baseSimParams, engineCondition: 100 });
        expect(withUndefined.lapTime).toBeCloseTo(withFull.lapTime, 5);
    });
});
