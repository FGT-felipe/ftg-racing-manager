"use strict";
/**
 * Centralized business constants for the FTG Racing Manager backend.
 * All hardcoded values from index.js are extracted here.
 * Never embed fees, thresholds, or multipliers directly in logic files.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_SETUP = exports.QUALY_PRIZES = exports.ACADEMY_XP_BONUS_PER_LEVEL = exports.SPECIALTY_STAT_THRESHOLD = exports.SPECIALTY_BASESKILL_THRESHOLD = exports.RAINMASTER_WET_DF_BONUS = exports.TYRE_WHISPERER_WEAR_REDUCTION = exports.DEFENSIVE_MINISTER_CRASH_REDUCTION = exports.APEX_HUNTER_STAT_BOOST = exports.LATE_BRAKER_STAT_BOOST = exports.IRON_NERVE_NOISE_REDUCTION = exports.QUALY_ACE_LAPTIME_BONUS = exports.FATIGUE_PENALTY_FACTOR = exports.FATIGUE_PENALTY_THRESHOLD = exports.FATIGUE_DRAIN_BY_STYLE = exports.XP_PER_SKILL_LEVEL = exports.NAME_CHANGE_COST = exports.ACADEMY_TRAINEE_WEEKLY_COST = exports.FITNESS_TRAINER_SALARIES = exports.HQ_MAINTENANCE_PER_LEVEL = exports.EX_DRIVER_SALARY_MULTIPLIER = exports.WEEKS_PER_YEAR = exports.POINT_VALUE = exports.BASE_PRIZE = exports.POINT_SYSTEM = exports.FALLBACK_BONUSES = void 0;
exports.getRacePrize = getRacePrize;
// ─── Sponsor fallback bonuses ────────────────────────────────────────────────
/** Fallback bonus amounts per sponsor ID when objectiveBonus is missing. */
exports.FALLBACK_BONUSES = {
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
// ─── Race points & prizes ────────────────────────────────────────────────────
/** Championship points awarded by finishing position (index 0 = P1). */
exports.POINT_SYSTEM = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
/** Base prize money awarded per race regardless of position. */
exports.BASE_PRIZE = 250_000;
/** Additional prize money per championship point scored. */
exports.POINT_VALUE = 150_000;
// ─── Economy ─────────────────────────────────────────────────────────────────
/** Weeks per year — used to convert annual salary to weekly wage. */
exports.WEEKS_PER_YEAR = 52;
/** Salary multiplier applied when manager role is "ex_driver" (+20%). */
exports.EX_DRIVER_SALARY_MULTIPLIER = 1.2;
/** Weekly maintenance cost per facility level. */
exports.HQ_MAINTENANCE_PER_LEVEL = 15_000;
/**
 * Annual salary per fitness trainer level (index = level).
 * Level 0 = no trainer (free), levels 1–5 have increasing costs.
 */
exports.FITNESS_TRAINER_SALARIES = [0, 0, 50_000, 120_000, 250_000, 500_000];
/** Flat weekly cost per active academy trainee. */
exports.ACADEMY_TRAINEE_WEEKLY_COST = 10_000;
/** Team rename fee. */
exports.NAME_CHANGE_COST = 500_000;
// ─── Academy / XP ────────────────────────────────────────────────────────────
/** XP points required to trigger a skill level-up for academy drivers. */
exports.XP_PER_SKILL_LEVEL = 500;
// ─── Specialization — Fatigue model ──────────────────────────────────────────
/**
 * Per-lap fatigue drain per driving style.
 * Applied each race lap to reduce the driver's current fatigue (0–100).
 * Iron Wall specialty bypasses this drain entirely.
 */
exports.FATIGUE_DRAIN_BY_STYLE = {
    defensive: 0.3,
    normal: 0.5,
    offensive: 0.8,
    mostRisky: 1.2,
};
/**
 * Fatigue level (0–100) below which lap time penalties start applying.
 * Represents physical exhaustion visibly affecting performance.
 */
exports.FATIGUE_PENALTY_THRESHOLD = 30;
/**
 * Penalty applied to the driver factor (df) per fatigue point below threshold.
 * Formula: df *= (1 + (threshold - fatigue) * FACTOR)
 * At fatigue=0 with threshold=30: df is multiplied by (1 + 30 * 0.005) = 1.15 (+15% slower).
 */
exports.FATIGUE_PENALTY_FACTOR = 0.005;
// ─── Specialization — sim effects ────────────────────────────────────────────
/** Qualy Ace: lap time multiplier applied during qualifying sessions (1.5% faster). */
exports.QUALY_ACE_LAPTIME_BONUS = 0.015;
/** Iron Nerve: fraction by which random lap noise is reduced (60% less variance). */
exports.IRON_NERVE_NOISE_REDUCTION = 0.6;
/**
 * Late Braker: multiplier boost applied to the braking stat contribution in df.
 * 0.5 = braking contributes 50% more to the driver factor.
 */
exports.LATE_BRAKER_STAT_BOOST = 0.5;
/**
 * Apex Hunter: multiplier boost applied to the cornering stat contribution in df.
 * 0.5 = cornering contributes 50% more to the driver factor.
 */
exports.APEX_HUNTER_STAT_BOOST = 0.5;
/** Defensive Minister: fraction by which crash probability is reduced. */
exports.DEFENSIVE_MINISTER_CRASH_REDUCTION = 0.35;
/** Tyre Whisperer: fraction by which tyre wear accumulation is reduced each lap. */
exports.TYRE_WHISPERER_WEAR_REDUCTION = 0.15;
/** Rainmaster: additional df reduction (speed bonus) in wet conditions. */
exports.RAINMASTER_WET_DF_BONUS = 0.015;
// ─── Specialization — academy trigger threshold ───────────────────────────────
/**
 * Minimum baseSkill an academy trainee must have to be eligible for a specialty.
 * Mirrors the guard in post-race.ts: `if (!yDriver.specialty && baseSkill >= THRESHOLD)`.
 */
exports.SPECIALTY_BASESKILL_THRESHOLD = 8;
/** Stat value (on 1–20 scale) a trainee must reach to trigger a specialization. */
exports.SPECIALTY_STAT_THRESHOLD = 11;
/** Additional XP bonus per academy level above 1. */
exports.ACADEMY_XP_BONUS_PER_LEVEL = 8;
// ─── Race prizes ─────────────────────────────────────────────────────────────
/**
 * Returns the prize money for a given 0-based finishing position.
 * Mirrors the getRacePrize() function previously inlined in runRaceLogic().
 * @param posIndex 0-based finishing index (0 = winner).
 */
function getRacePrize(posIndex) {
    if (posIndex === 0)
        return 500_000;
    if (posIndex === 1)
        return 350_000;
    if (posIndex === 2)
        return 250_000;
    if (posIndex >= 3 && posIndex <= 5)
        return 150_000;
    if (posIndex >= 6 && posIndex <= 9)
        return 100_000;
    return 25_000;
}
// ─── Qualy prizes (P1: 50k, P2: 30k, P3: 15k) ───────────────────────────────
exports.QUALY_PRIZES = [50_000, 30_000, 15_000];
// ─── Default car setup ───────────────────────────────────────────────────────
/** Default setup applied when a driver has not submitted a custom one. */
exports.DEFAULT_SETUP = {
    frontWing: 50,
    rearWing: 50,
    suspension: 50,
    gearRatio: 50,
    tyreCompound: "medium",
    qualifyingStyle: "normal",
    raceStyle: "normal",
    initialFuel: 50.0,
    pitStops: ["hard"],
    pitStopStyles: ["normal"],
    pitStopFuel: [50.0],
};
