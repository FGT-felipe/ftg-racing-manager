import {
  calculateWeeklyDriverSalary,
  calculateHQMaintenance,
  calculateFitnessTrainerCost,
  calculateTotalFacilityMaintenance,
} from "../domains/economy/salaries";
import { HQ_MAINTENANCE_PER_LEVEL, FITNESS_TRAINER_SALARIES, WEEKS_PER_YEAR } from "../config/constants";
import type { Driver } from "../shared/types";

// ─── Helpers ─────────────────────────────────────────────────────────────────

const makeDriver = (salary: number): Driver => ({
  id: "d1",
  teamId: "t1",
  name: "Test Driver",
  salary,
  age: 25,
  potential: 3,
  stats: {
    cornering: 10, braking: 10, focus: 10, fitness: 100,
    adaptability: 10, consistency: 10, smoothness: 10, overtaking: 10,
  },
});

// ─── calculateWeeklyDriverSalary ─────────────────────────────────────────────

describe("calculateWeeklyDriverSalary", () => {
  it("returns annual salary / 52", () => {
    const driver = makeDriver(520_000);
    expect(calculateWeeklyDriverSalary(driver, "normal")).toBe(
      Math.round(520_000 / WEEKS_PER_YEAR),
    );
  });

  it("applies +20% surcharge for ex_driver manager role", () => {
    const driver = makeDriver(520_000);
    const base = Math.round(520_000 / WEEKS_PER_YEAR);
    const withSurcharge = calculateWeeklyDriverSalary(driver, "ex_driver");
    expect(withSurcharge).toBe(Math.round((520_000 * 1.2) / WEEKS_PER_YEAR));
    expect(withSurcharge).toBeGreaterThan(base);
  });

  it("does not apply surcharge for other manager roles", () => {
    const driver = makeDriver(520_000);
    const base = Math.round(520_000 / WEEKS_PER_YEAR);
    expect(calculateWeeklyDriverSalary(driver, "business")).toBe(base);
    expect(calculateWeeklyDriverSalary(driver, "engineer")).toBe(base);
    expect(calculateWeeklyDriverSalary(driver, "")).toBe(base);
  });

  it("defaults to $10,000 annual salary when driver.salary is 0", () => {
    const driver = makeDriver(0);
    expect(calculateWeeklyDriverSalary(driver, "")).toBe(
      Math.round(10_000 / WEEKS_PER_YEAR),
    );
  });
});

// ─── calculateHQMaintenance ───────────────────────────────────────────────────

describe("calculateHQMaintenance", () => {
  it("returns level * HQ_MAINTENANCE_PER_LEVEL", () => {
    expect(calculateHQMaintenance(3)).toBe(3 * HQ_MAINTENANCE_PER_LEVEL);
    expect(calculateHQMaintenance(1)).toBe(HQ_MAINTENANCE_PER_LEVEL);
  });

  it("returns 0 for level 0 (unbuilt facility)", () => {
    expect(calculateHQMaintenance(0)).toBe(0);
  });

  it("returns 0 for negative levels", () => {
    expect(calculateHQMaintenance(-1)).toBe(0);
  });
});

// ─── calculateFitnessTrainerCost ──────────────────────────────────────────────

describe("calculateFitnessTrainerCost", () => {
  it("returns 0 for levels 0 and 1 (free basic staff)", () => {
    expect(calculateFitnessTrainerCost(0)).toBe(0);
    expect(calculateFitnessTrainerCost(1)).toBe(0);
  });

  it("returns the correct cost for each trainer level", () => {
    FITNESS_TRAINER_SALARIES.forEach((expected, level) => {
      expect(calculateFitnessTrainerCost(level)).toBe(expected);
    });
  });

  it("returns 0 for out-of-range levels", () => {
    expect(calculateFitnessTrainerCost(99)).toBe(0);
    expect(calculateFitnessTrainerCost(-1)).toBe(0);
  });
});

// ─── calculateTotalFacilityMaintenance ────────────────────────────────────────

describe("calculateTotalFacilityMaintenance", () => {
  it("sums maintenance across all facilities correctly", () => {
    const facilities = {
      wind_tunnel: { level: 2 },
      simulator: { level: 3 },
    };
    expect(calculateTotalFacilityMaintenance(facilities)).toBe(
      (2 + 3) * HQ_MAINTENANCE_PER_LEVEL,
    );
  });

  it("skips facilities with level 0", () => {
    const facilities = {
      wind_tunnel: { level: 0 },
      simulator: { level: 2 },
    };
    expect(calculateTotalFacilityMaintenance(facilities)).toBe(
      2 * HQ_MAINTENANCE_PER_LEVEL,
    );
  });

  it("returns 0 for empty facilities map", () => {
    expect(calculateTotalFacilityMaintenance({})).toBe(0);
  });
});
