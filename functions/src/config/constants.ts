/**
 * Centralized business constants for the FTG Racing Manager backend.
 * All hardcoded values from index.js are extracted here.
 * Never embed fees, thresholds, or multipliers directly in logic files.
 */

// ─── Sponsor fallback bonuses ────────────────────────────────────────────────

/** Fallback bonus amounts per sponsor ID when objectiveBonus is missing. */
export const FALLBACK_BONUSES: Record<string, number> = {
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
export const POINT_SYSTEM = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];

/** Base prize money awarded per race regardless of position. */
export const BASE_PRIZE = 250_000;

/** Additional prize money per championship point scored. */
export const POINT_VALUE = 150_000;

// ─── Economy ─────────────────────────────────────────────────────────────────

/** Weeks per year — used to convert annual salary to weekly wage. */
export const WEEKS_PER_YEAR = 52;

/** Salary multiplier applied when manager role is "ex_driver" (+20%). */
export const EX_DRIVER_SALARY_MULTIPLIER = 1.2;

/** Weekly maintenance cost per facility level. */
export const HQ_MAINTENANCE_PER_LEVEL = 15_000;

/**
 * Annual salary per fitness trainer level (index = level).
 * Level 0 = no trainer (free), levels 1–5 have increasing costs.
 */
export const FITNESS_TRAINER_SALARIES = [0, 0, 50_000, 120_000, 250_000, 500_000];

/** Flat weekly cost per active academy trainee. */
export const ACADEMY_TRAINEE_WEEKLY_COST = 10_000;

/** Team rename fee. */
export const NAME_CHANGE_COST = 500_000;

// ─── Academy / XP ────────────────────────────────────────────────────────────

/** XP points required to trigger a skill level-up for academy drivers. */
export const XP_PER_SKILL_LEVEL = 500;

// ─── Specialization — Fatigue model ──────────────────────────────────────────

/**
 * Per-lap fatigue drain per driving style.
 * Applied each race lap to reduce the driver's current fatigue (0–100).
 * Iron Wall specialty bypasses this drain entirely.
 */
export const FATIGUE_DRAIN_BY_STYLE: Record<string, number> = {
  defensive: 0.3,
  normal:    0.5,
  offensive: 0.8,
  mostRisky: 1.2,
};

/**
 * Fatigue level (0–100) below which lap time penalties start applying.
 * Represents physical exhaustion visibly affecting performance.
 */
export const FATIGUE_PENALTY_THRESHOLD = 30;

/**
 * Penalty applied to the driver factor (df) per fatigue point below threshold.
 * Formula: df *= (1 + (threshold - fatigue) * FACTOR)
 * At fatigue=0 with threshold=30: df is multiplied by (1 + 30 * 0.005) = 1.15 (+15% slower).
 */
export const FATIGUE_PENALTY_FACTOR = 0.005;

// ─── Specialization — sim effects ────────────────────────────────────────────

/** Qualy Ace: lap time multiplier applied during qualifying sessions (1.5% faster). */
export const QUALY_ACE_LAPTIME_BONUS = 0.015;

/** Iron Nerve: fraction by which random lap noise is reduced (60% less variance). */
export const IRON_NERVE_NOISE_REDUCTION = 0.6;

/**
 * Late Braker: multiplier boost applied to the braking stat contribution in df.
 * 0.5 = braking contributes 50% more to the driver factor.
 */
export const LATE_BRAKER_STAT_BOOST = 0.5;

/**
 * Apex Hunter: multiplier boost applied to the cornering stat contribution in df.
 * 0.5 = cornering contributes 50% more to the driver factor.
 */
export const APEX_HUNTER_STAT_BOOST = 0.5;

/** Defensive Minister: fraction by which crash probability is reduced. */
export const DEFENSIVE_MINISTER_CRASH_REDUCTION = 0.35;

/** Tyre Whisperer: fraction by which tyre wear accumulation is reduced each lap. */
export const TYRE_WHISPERER_WEAR_REDUCTION = 0.15;

/** Rainmaster: additional df reduction (speed bonus) in wet conditions. */
export const RAINMASTER_WET_DF_BONUS = 0.015;

// ─── Specialization — academy trigger threshold ───────────────────────────────

/**
 * Minimum baseSkill an academy trainee must have to be eligible for a specialty.
 * Mirrors the guard in post-race.ts: `if (!yDriver.specialty && baseSkill >= THRESHOLD)`.
 */
export const SPECIALTY_BASESKILL_THRESHOLD = 8;

/** Stat value (on 1–20 scale) a trainee must reach to trigger a specialization. */
export const SPECIALTY_STAT_THRESHOLD = 11;

/** Additional XP bonus per academy level above 1. */
export const ACADEMY_XP_BONUS_PER_LEVEL = 8;

// ─── Race prizes ─────────────────────────────────────────────────────────────

/**
 * Returns the prize money for a given 0-based finishing position.
 * Mirrors the getRacePrize() function previously inlined in runRaceLogic().
 * @param posIndex 0-based finishing index (0 = winner).
 */
export function getRacePrize(posIndex: number): number {
  if (posIndex === 0) return 500_000;
  if (posIndex === 1) return 350_000;
  if (posIndex === 2) return 250_000;
  if (posIndex >= 3 && posIndex <= 5) return 150_000;
  if (posIndex >= 6 && posIndex <= 9) return 100_000;
  return 25_000;
}

// ─── Qualy prizes (P1: 50k, P2: 30k, P3: 15k) ───────────────────────────────
export const QUALY_PRIZES = [50_000, 30_000, 15_000];

// ─── Season-end prizes ───────────────────────────────────────────────────────

/**
 * End-of-season constructors championship prize table (index 0 = P1).
 * All 10 positions receive money — last place still earns $200k.
 */
export const SEASON_PRIZE_TABLE = [
  6_000_000,  // P1
  4_500_000,  // P2
  3_000_000,  // P3
  2_000_000,  // P4
  1_500_000,  // P5
  1_000_000,  // P6
    700_000,  // P7
    500_000,  // P8
    350_000,  // P9
    200_000,  // P10
];

/** Additional budget bonus for the team whose driver wins the Drivers Championship. */
export const DRIVERS_CHAMPION_TEAM_BONUS = 2_000_000;

/** Market value multiplier applied to the Drivers Championship winner. */
export const DRIVERS_CHAMPION_MARKET_VALUE_BOOST = 1.20;

// ─── Default car setup ───────────────────────────────────────────────────────

/** Default setup applied when a driver has not submitted a custom one. */
export const DEFAULT_SETUP = {
  frontWing: 50,
  rearWing: 50,
  suspension: 50,
  gearRatio: 50,
  tyreCompound: "medium" as import("../shared/types").TyreCompound,
  qualifyingStyle: "normal" as import("../shared/types").DrivingStyle,
  raceStyle: "normal" as import("../shared/types").DrivingStyle,
  initialFuel: 50.0,
  pitStops: ["hard"] as import("../shared/types").TyreCompound[],
  pitStopStyles: ["normal"] as import("../shared/types").DrivingStyle[],
  pitStopFuel: [50.0],
};
