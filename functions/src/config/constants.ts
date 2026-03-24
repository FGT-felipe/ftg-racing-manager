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
