"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const salaries_1 = require("../domains/economy/salaries");
const constants_1 = require("../config/constants");
// ─── Helpers ─────────────────────────────────────────────────────────────────
const makeDriver = (salary) => ({
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
        expect((0, salaries_1.calculateWeeklyDriverSalary)(driver, "normal")).toBe(Math.round(520_000 / constants_1.WEEKS_PER_YEAR));
    });
    it("applies +20% surcharge for ex_driver manager role", () => {
        const driver = makeDriver(520_000);
        const base = Math.round(520_000 / constants_1.WEEKS_PER_YEAR);
        const withSurcharge = (0, salaries_1.calculateWeeklyDriverSalary)(driver, "ex_driver");
        expect(withSurcharge).toBe(Math.round((520_000 * 1.2) / constants_1.WEEKS_PER_YEAR));
        expect(withSurcharge).toBeGreaterThan(base);
    });
    it("does not apply surcharge for other manager roles", () => {
        const driver = makeDriver(520_000);
        const base = Math.round(520_000 / constants_1.WEEKS_PER_YEAR);
        expect((0, salaries_1.calculateWeeklyDriverSalary)(driver, "business")).toBe(base);
        expect((0, salaries_1.calculateWeeklyDriverSalary)(driver, "engineer")).toBe(base);
        expect((0, salaries_1.calculateWeeklyDriverSalary)(driver, "")).toBe(base);
    });
    it("defaults to $10,000 annual salary when driver.salary is 0", () => {
        const driver = makeDriver(0);
        expect((0, salaries_1.calculateWeeklyDriverSalary)(driver, "")).toBe(Math.round(10_000 / constants_1.WEEKS_PER_YEAR));
    });
});
// ─── calculateHQMaintenance ───────────────────────────────────────────────────
describe("calculateHQMaintenance", () => {
    it("returns level * HQ_MAINTENANCE_PER_LEVEL", () => {
        expect((0, salaries_1.calculateHQMaintenance)(3)).toBe(3 * constants_1.HQ_MAINTENANCE_PER_LEVEL);
        expect((0, salaries_1.calculateHQMaintenance)(1)).toBe(constants_1.HQ_MAINTENANCE_PER_LEVEL);
    });
    it("returns 0 for level 0 (unbuilt facility)", () => {
        expect((0, salaries_1.calculateHQMaintenance)(0)).toBe(0);
    });
    it("returns 0 for negative levels", () => {
        expect((0, salaries_1.calculateHQMaintenance)(-1)).toBe(0);
    });
});
// ─── calculateFitnessTrainerCost ──────────────────────────────────────────────
describe("calculateFitnessTrainerCost", () => {
    it("returns 0 for levels 0 and 1 (free basic staff)", () => {
        expect((0, salaries_1.calculateFitnessTrainerCost)(0)).toBe(0);
        expect((0, salaries_1.calculateFitnessTrainerCost)(1)).toBe(0);
    });
    it("returns the correct cost for each trainer level", () => {
        constants_1.FITNESS_TRAINER_SALARIES.forEach((expected, level) => {
            expect((0, salaries_1.calculateFitnessTrainerCost)(level)).toBe(expected);
        });
    });
    it("returns 0 for out-of-range levels", () => {
        expect((0, salaries_1.calculateFitnessTrainerCost)(99)).toBe(0);
        expect((0, salaries_1.calculateFitnessTrainerCost)(-1)).toBe(0);
    });
});
// ─── calculateTotalFacilityMaintenance ────────────────────────────────────────
describe("calculateTotalFacilityMaintenance", () => {
    it("sums maintenance across all facilities correctly", () => {
        const facilities = {
            wind_tunnel: { level: 2 },
            simulator: { level: 3 },
        };
        expect((0, salaries_1.calculateTotalFacilityMaintenance)(facilities)).toBe((2 + 3) * constants_1.HQ_MAINTENANCE_PER_LEVEL);
    });
    it("skips facilities with level 0", () => {
        const facilities = {
            wind_tunnel: { level: 0 },
            simulator: { level: 2 },
        };
        expect((0, salaries_1.calculateTotalFacilityMaintenance)(facilities)).toBe(2 * constants_1.HQ_MAINTENANCE_PER_LEVEL);
    });
    it("returns 0 for empty facilities map", () => {
        expect((0, salaries_1.calculateTotalFacilityMaintenance)({})).toBe(0);
    });
});
