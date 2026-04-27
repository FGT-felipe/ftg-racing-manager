/**
 * Unit tests for the parts wear engine (T-007 Slice 1).
 * Zero Firebase calls — computeWearDelta is pure; applyWearDelta is integration-
 * tested separately (Firestore emulator required).
 */

import { computeWearDelta } from "../domains/simulation/wear";
import { simulateLap, SimLapParams } from "../domains/simulation/sim-engine";
import { getCircuit } from "../config/circuits";

// ─── Tests: computeWearDelta ──────────────────────────────────────────────────

describe("computeWearDelta", () => {
  it("returns PARTS_BASE_RACE_DELTA (8) for 'race' trigger", () => {
    expect(computeWearDelta("race")).toBe(8);
  });

  it("returns 0 for 'qualifying' trigger (deferred to Slice 2)", () => {
    expect(computeWearDelta("qualifying")).toBe(0);
  });

  it("returns 0 for 'special_event' trigger (deferred to Slice 2)", () => {
    expect(computeWearDelta("special_event")).toBe(0);
  });

  it("returns 0 for unknown trigger", () => {
    expect(computeWearDelta("unknown")).toBe(0);
  });

  // Condition floor — should never go negative
  it("wear application floors at 0 (5 - 8 = 0)", () => {
    const conditionBefore = 5;
    const delta = computeWearDelta("race");
    const conditionAfter = Math.max(0, conditionBefore - delta);
    expect(conditionAfter).toBe(0);
  });

  it("wear application — normal case (50 - 8 = 42)", () => {
    const conditionBefore = 50;
    const delta = computeWearDelta("race");
    const conditionAfter = Math.max(0, conditionBefore - delta);
    expect(conditionAfter).toBe(42);
  });
});

// ─── Tests: simulateLap engineCondition parameter ────────────────────────────

describe("simulateLap — engineCondition multiplier (T-007 S1)", () => {
  const circuit = getCircuit("mexico");

  const baseParams: SimLapParams = {
    circuit,
    carStats: { aero: 10, powertrain: 10, chassis: 10, reliability: 10 },
    driverStats: { cornering: 10, braking: 10, focus: 10, adaptability: 10, fitness: 100 },
    setup: { frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50, tyreCompound: "medium" },
    style: "normal",
    teamRole: "",
    weather: "dry",
  };

  beforeEach(() => {
    // Deterministic random — 0.5 avoids crashes
    jest.spyOn(Math, "random").mockReturnValue(0.5);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it("engineCondition=100 produces same lap time as omitting the parameter", () => {
    const withFull = simulateLap({ ...baseParams, engineCondition: 100 });
    const withoutParam = simulateLap({ ...baseParams });
    expect(withFull.lapTime).toBeCloseTo(withoutParam.lapTime, 5);
  });

  it("engineCondition=50 produces a slower lap time than engineCondition=100", () => {
    const full = simulateLap({ ...baseParams, engineCondition: 100 });
    const worn = simulateLap({ ...baseParams, engineCondition: 50 });
    expect(worn.lapTime).toBeGreaterThan(full.lapTime);
  });

  it("engineCondition=0 produces the slowest lap time (no powertrain contribution)", () => {
    const full = simulateLap({ ...baseParams, engineCondition: 100 });
    const dead = simulateLap({ ...baseParams, engineCondition: 0 });
    expect(dead.lapTime).toBeGreaterThan(full.lapTime);
  });

  it("undefined engineCondition defaults to 1.0 factor (no penalty — AC#12, COMPAT-1)", () => {
    const withUndefined = simulateLap({ ...baseParams, engineCondition: undefined });
    const withFull = simulateLap({ ...baseParams, engineCondition: 100 });
    expect(withUndefined.lapTime).toBeCloseTo(withFull.lapTime, 5);
  });
});
