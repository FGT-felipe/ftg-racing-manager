/** Current application version. Update on every release. */
export const APP_VERSION = 'V1.8.0';

/** Maximum number of practice laps allowed per driver in a race weekend. */
export const MAX_PRACTICE_LAPS_PER_DRIVER = 50;

/** Number of race drivers per team. */
export const DEFAULT_DRIVERS_PER_TEAM = 2;

/** IANA timezone for all race week calculations. */
export const BOGOTA_TIMEZONE = 'America/Bogota';

/** Weekly academy wage per trainee (USD). */
export const ACADEMY_TRAINEE_WEEKLY_WAGE = 10_000;

/** One-time cost to start practice for a driver in a race weekend. */
export const PRACTICE_SESSION_COST = 10_000;

// ─── Parts Wear System (T-007) ────────────────────────────────────────────────

/** Condition points removed from an engine after every completed race (Slice 1 flat delta). */
export const PARTS_BASE_RACE_DELTA = 8;

/** Flat cost in USD to repair an engine to 100% condition. */
export const PARTS_ENGINE_REPAIR_COST_FLAT = 25_000;

/**
 * Lower-bound thresholds for each condition tier.
 * green:  condition >= 80
 * yellow: condition >= 50 && < 80
 * orange: condition >= 30 && < 50
 * red:    condition < 30
 */
export const PARTS_TIER_THRESHOLDS = { yellow: 80, orange: 50, red: 30 } as const;

// ─── Parts Wear System (T-007 Slice 2) ────────────────────────────────────────

/** Per-round repair budget cap (USD). Firestore config is authoritative at runtime; this is the code fallback. */
export const PARTS_REPAIR_BUDGET_CAP_PER_ROUND = 150_000;

/** Base race wear deltas per part type (condition points). Firestore config is authoritative at runtime. */
export const PARTS_BASE_RACE_DELTAS: Record<string, number> = {
  engine: 8,
  gearbox: 6,
  brakes: 5,
  frontWing: 4,
  rearWing: 4,
  suspension: 5,
};

/** Max seconds added to lap time from fully degraded brakes (linear scale by condition). */
export const BRAKES_PENALTY_MAX = 0.8;

/** Extra seconds added to lap time on a brakes failure roll. */
export const BRAKES_FAILURE_LAP_PENALTY = 3.0;

/** Extra seconds added to lap time on a gearbox failure roll (grid penalty deferred to S3). */
export const GEARBOX_FAILURE_LAP_PENALTY = 2.0;

/** Extra seconds added to lap time on a front/rear wing failure roll. */
export const WING_FAILURE_LAP_PENALTY = 1.5;

/** Extra seconds added to lap time on a suspension failure roll. */
export const SUSPENSION_FAILURE_LAP_PENALTY = 1.0;
