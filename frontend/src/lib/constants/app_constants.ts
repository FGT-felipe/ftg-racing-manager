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
