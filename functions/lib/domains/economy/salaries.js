"use strict";
/**
 * Economy calculation helpers — pure module.
 * Extracted from postRaceProcessing() salary/maintenance logic
 * in functions/index.js (lines 1893–1926).
 *
 * PURE MODULE: No Firestore calls, no side effects.
 * All inputs are plain data objects. Fully unit-testable without Firebase.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.calculateWeeklyDriverSalary = calculateWeeklyDriverSalary;
exports.calculateHQMaintenance = calculateHQMaintenance;
exports.calculateFitnessTrainerCost = calculateFitnessTrainerCost;
exports.calculateTotalFacilityMaintenance = calculateTotalFacilityMaintenance;
const constants_1 = require("../../config/constants");
/**
 * Calculates the weekly driver salary cost.
 * Applies a +20% surcharge when the team manager role is "ex_driver".
 * Defaults to $10,000/year if the driver has no salary set.
 *
 * @param driver The driver document.
 * @param managerRole The team manager's role string (e.g., "ex_driver", "business").
 * @returns Weekly salary in dollars (rounded to nearest integer).
 */
function calculateWeeklyDriverSalary(driver, managerRole) {
    let salary = driver.salary || 10_000;
    if (managerRole === "ex_driver") {
        salary *= constants_1.EX_DRIVER_SALARY_MULTIPLIER;
    }
    return Math.round(salary / constants_1.WEEKS_PER_YEAR);
}
/**
 * Calculates the weekly maintenance cost for a single facility based on its level.
 * Returns 0 for level 0 (unbuilt).
 *
 * @param level Facility upgrade level (0 = no facility).
 * @returns Weekly maintenance cost in dollars.
 */
function calculateHQMaintenance(level) {
    if (level <= 0)
        return 0;
    return level * constants_1.HQ_MAINTENANCE_PER_LEVEL;
}
/**
 * Returns the weekly fitness trainer salary for a given trainer level.
 * Level 0 and 1 are free (basic staff). Levels 2–5 have increasing costs.
 *
 * @param level Fitness trainer level (0–5).
 * @returns Trainer salary amount in dollars.
 */
function calculateFitnessTrainerCost(level) {
    if (level >= 0 && level < constants_1.FITNESS_TRAINER_SALARIES.length) {
        return constants_1.FITNESS_TRAINER_SALARIES[level];
    }
    return 0;
}
/**
 * Calculates total HQ maintenance cost across all of a team's facilities.
 *
 * @param facilities Map of facility name to Facility object.
 * @returns Total weekly maintenance cost in dollars.
 */
function calculateTotalFacilityMaintenance(facilities) {
    let total = 0;
    for (const facility of Object.values(facilities)) {
        total += calculateHQMaintenance(facility.level || 0);
    }
    return total;
}
