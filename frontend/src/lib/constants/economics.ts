/**
 * Economics Constants — FTG Racing Manager
 *
 * Single source of truth for all monetary values, cost tables, and
 * business-rule multipliers used across the frontend.
 *
 * Backend equivalents live in functions/src/config/constants.ts.
 * Keep both in sync when changing values that affect server-side logic.
 */

// ---------------------------------------------------------------------------
// Team
// ---------------------------------------------------------------------------

/** Cost to rename a team after the first free change (USD). */
export const TEAM_RENAME_COST = 500_000;

// ---------------------------------------------------------------------------
// Car Upgrades
// ---------------------------------------------------------------------------

/** Base cost for the first two upgrade levels (USD). Scales via Fibonacci above level 2. */
export const CAR_UPGRADE_BASE_COST = 100_000;

/** Maximum level any car part can reach. */
export const CAR_PART_MAX_LEVEL = 20;

/** Weeks a Bureaucrat manager must wait between car upgrades. */
export const BUREAUCRAT_UPGRADE_COOLDOWN_WEEKS = 2;

// ---------------------------------------------------------------------------
// Facilities
// ---------------------------------------------------------------------------

/** Upgrade cost per level tier (index = current level, value = cost to upgrade to next). */
export const FACILITY_UPGRADE_COSTS: Record<number, number> = {
    0: 250_000,
    1: 750_000,
    2: 1_800_000,
    3: 3_500_000,
    4: 6_000_000,
};

/** Youth Academy upgrade cost multiplier per level (cost = multiplier × current level). */
export const YOUTH_ACADEMY_UPGRADE_COST_PER_LEVEL = 1_500_000;

/** Weekly maintenance cost per facility level (USD). */
export const FACILITY_MAINTENANCE_COST_PER_LEVEL = 15_000;

/** Discount multiplier applied to facility upgrades for Business/Bureaucrat managers. */
export const FACILITY_ROLE_DISCOUNT = 0.9;

/** Maximum level any facility can reach. */
export const FACILITY_MAX_LEVEL = 5;

// ---------------------------------------------------------------------------
// Sponsors
// ---------------------------------------------------------------------------

/** Signing bonus, weekly payment (USD) per sponsor tier. */
export const SPONSOR_TIER_FINANCES = {
    title:   { sign: 900_000, weekly: 150_000 },
    major:   { sign: 320_000, weekly:  50_000 },
    partner: { sign:  65_000, weekly:  15_000 },
} as const;

/** Objective bonus amounts per tier (USD). Indexed to OBJECTIVES_BY_TIER in sponsor.svelte.ts. */
export const SPONSOR_OBJECTIVE_BONUSES = {
    title: {
        race_win:      300_000,
        top_3:         250_000,
        double_podium: 450_000,
        top_5:         180_000,
    },
    major: {
        top_5:         150_000,
        top_8:         110_000,
        top_10:        100_000,
        fastest_lap:   120_000,
        home_win:      220_000,
    },
    partner: {
        top_16:        50_000,
        finish_race:   40_000,
        improve_grid:  40_000,
        overtake_3:    35_000,
        home_win:      80_000,
    },
} as const;

/** Payment multiplier applied when manager role is 'business'. */
export const SPONSOR_BUSINESS_MULTIPLIER = 1.15;

/** Maximum failed negotiation attempts before a sponsor locks for a week. */
export const SPONSOR_MAX_NEGOTIATION_ATTEMPTS = 2;

/** Number of sponsor offers presented per slot. */
export const SPONSOR_OFFERS_PER_SLOT = 3;

/** Min and max contract duration in races. */
export const SPONSOR_CONTRACT_DURATION_MIN = 4;
export const SPONSOR_CONTRACT_DURATION_RANGE = 7;

// ---------------------------------------------------------------------------
// Race Weekend
// ---------------------------------------------------------------------------

/** One-time entry fee charged on the first qualifying attempt per driver per weekend (USD). */
export const QUALY_ENTRY_FEE = 10_000;

// ---------------------------------------------------------------------------
// Fitness Trainer
// ---------------------------------------------------------------------------

/** Weekly salary per trainer level (index = level). Level 0-1 are free. */
export const FITNESS_TRAINER_SALARY_BY_LEVEL = [0, 0, 50_000, 120_000, 250_000, 500_000];

/** Fitness stat bonus per trainer level (index = level). */
export const FITNESS_TRAINER_BONUS_BY_LEVEL = [0, 3, 6, 9, 12, 15];

/** One-time upgrade cost per trainer level (index = target level). */
export const FITNESS_TRAINER_UPGRADE_COSTS = [0, 0, 100_000, 250_000, 500_000, 1_000_000];

/** Maximum trainer level. */
export const FITNESS_TRAINER_MAX_LEVEL = 5;
