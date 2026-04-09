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

// ---------------------------------------------------------------------------
// HR Manager (Psychologist)
// ---------------------------------------------------------------------------

/** Weekly salary per psychologist level (index = level). Level 0-1 are free. */
export const PSYCHOLOGIST_SALARY_BY_LEVEL = [0, 0, 50_000, 120_000, 250_000, 500_000];

/** Morale points added per manual session at each psychologist level (index = level). */
export const PSYCHOLOGIST_BONUS_BY_LEVEL = [0, 5, 8, 12, 16, 20];

/** One-time upgrade cost per psychologist level (index = target level). */
export const PSYCHOLOGIST_UPGRADE_COSTS = [0, 0, 100_000, 250_000, 500_000, 1_000_000];

/** Maximum psychologist level. */
export const PSYCHOLOGIST_MAX_LEVEL = 5;

// ---------------------------------------------------------------------------
// Morale System
// ---------------------------------------------------------------------------

/** Default morale value for drivers that have no morale field (lazy init). */
export const MORALE_DEFAULT = 70;

/** Neutral morale value — no laptime effect above or below this point. */
export const MORALE_NEUTRAL = 50;

/**
 * Laptime multiplier factor for morale deviation from neutral.
 * Formula: lap *= (1 + MORALE_LAPTIME_FACTOR * (MORALE_NEUTRAL - morale) / 100)
 * At morale=0 → +1% slower. At morale=100 → −1% faster.
 */
export const MORALE_LAPTIME_FACTOR = 0.02;

// Morale event deltas (positive = boost, negative = decay)
export const MORALE_EVENT_WIN_RACE          =  15;
export const MORALE_EVENT_PODIUM            =   8;  // P2 or P3
export const MORALE_EVENT_POLE              =  10;
export const MORALE_EVENT_SPONSOR_OBJECTIVE =   8;
export const MORALE_EVENT_DNF               = -10;
export const MORALE_EVENT_FINISH_LOW        =  -5;  // P10 or lower
export const MORALE_EVENT_TRANSFER_LISTED   = -10;
export const MORALE_EVENT_BAD_PRACTICE      =  -5;
export const MORALE_EVENT_GOOD_PRACTICE     =   1;  // Well-dialled setup in practice

// ---------------------------------------------------------------------------
// Transfer Market
// ---------------------------------------------------------------------------

/** Potential multiplier added per star above 1 (e.g. 5-star → 1 + 4 × 0.5 = 3×). */
export const TRANSFER_MARKET_POTENTIAL_MULTIPLIER_PER_STAR = 0.5;

/** Weight of current performance in the market value formula (0.5 → contributes 0.6× to 1.0×). */
export const TRANSFER_MARKET_CURRENT_PERFORMANCE_WEIGHT = 0.5;

/** Peak age for driver value. Drivers younger than this receive a premium. */
export const TRANSFER_MARKET_AGE_PEAK = 27;

/** Value depreciation rate per year above the age peak (4% per year). */
export const TRANSFER_MARKET_AGE_DEPRECIATION_RATE = 0.04;

/** Value premium rate per year below the age peak (3% per year). */
export const TRANSFER_MARKET_AGE_PREMIUM_RATE = 0.03;

/** Minimum age factor floor (prevents value reaching zero for very old drivers). */
export const TRANSFER_MARKET_AGE_FLOOR = 0.3;

/** Minimum market value for any listed driver (USD). */
export const TRANSFER_MARKET_MIN_VALUE = 100_000;

/** Listing fee as a fraction of market value (10%). */
export const TRANSFER_MARKET_LISTING_FEE_RATE = 0.10;

/** Driver release fee as a fraction of market value (10%). */
export const TRANSFER_MARKET_RELEASE_FEE_RATE = 0.10;

/**
 * Non-refundable commission charged to the buyer upon placing a bid (10% of driver marketValue).
 * Deducted immediately when the bid is submitted. Lost even if negotiations fail or the bid is outbid.
 * Equals TRANSFER_MARKET_LISTING_FEE_RATE — symmetrical cost between seller and buyer.
 */
export const TRANSFER_MARKET_BID_COMMISSION_RATE = 0.10;

/** Minimum increment above the current highest bid required to place a new bid (USD). */
export const TRANSFER_MARKET_BID_INCREMENT = 50_000;

/** Duration a transfer listing remains active before expiring (hours). */
export const TRANSFER_LISTING_DURATION_HOURS = 24;

/** Duration a transfer listing remains active before expiring (milliseconds). */
export const TRANSFER_LISTING_DURATION_MS = TRANSFER_LISTING_DURATION_HOURS * 3_600_000;

/** Time before expiry at which a listing is considered "expiring soon" (milliseconds). */
export const LISTING_EXPIRY_WARNING_MS = 5 * 60 * 1_000;

// ---------------------------------------------------------------------------
// Contract Negotiation
// ---------------------------------------------------------------------------

/** Fee charged to renew a driver's contract (10% of annualSalary × years). */
export const DRIVER_RENEWAL_FEE_RATE = 0.10;

/** Morale points deducted from a driver when they are dismissed. */
export const DISMISS_MORALE_PENALTY = 20;

/** Maximum negotiation attempts before a driver walks away. */
export const NEGOTIATION_MAX_ATTEMPTS = 3;

/** Morale penalty applied to a driver per failed negotiation attempt. */
export const NEGOTIATION_MORALE_PENALTY_PER_FAIL = 5;

/** Additional morale penalty when all attempts are exhausted (stacks with per-fail penalties). */
export const NEGOTIATION_MORALE_PENALTY_TOTAL_FAIL = 15;

/**
 * Driver counter-proposal multiplier by statusTitle.
 * Value = additional fraction the driver demands on top of the offered salary.
 */
export const NEGOTIATION_TITLE_WEIGHT: Record<string, number> = {
    'Living Legend':        0.30,
    'Era Dominator':        0.25,
    'The Heir':             0.20,
    'Elite Veteran':        0.15,
    'Young Wonder':         0.15,
    'Rising Star':          0.12,
    'Solid Specialist':     0.10,
    'Midfield Spark':       0.08,
    'Last Dance':           0.05,
    'Stuck Promise':        0.05,
    'Journeyman':           0.05,
    'Past Glory':           0.03,
    'Unsung Driver':        0.02,
    'Grid Filler':          0.00,
};

/**
 * Driver counter-proposal multiplier per star level (currentStars 1–5).
 * Index = stars value (index 0 unused).
 */
export const NEGOTIATION_STARS_WEIGHT = [0, 0.00, 0.05, 0.10, 0.15, 0.20];

// ---------------------------------------------------------------------------
// Academy
// ---------------------------------------------------------------------------

/** One-time cost to establish a Youth Academy (USD). */
export const ACADEMY_PURCHASE_COST = 10_000;

/** Weekly maintenance cost for a level-1 Youth Academy facility (USD). */
export const ACADEMY_MAINTENANCE_COST = 15_000;

/** Fallback weekly salary when a trainee has no stored salary value (USD). */
export const ACADEMY_TRAINEE_WEEKLY_SALARY = 10_000;

/** Base salary for a newly generated academy candidate (USD). */
export const ACADEMY_SALARY_BASE = 5_000;

/** Random range added on top of ACADEMY_SALARY_BASE when generating a candidate salary (USD). */
export const ACADEMY_SALARY_RANGE = 10_000;

/** Per-level cost multiplier for academy upgrades: total = multiplier × currentLevel (USD). */
export const ACADEMY_UPGRADE_COST_MULTIPLIER = 1_000_000;

/** Cost charged to accept an Intensive Training event for an academy driver (USD). */
export const ACADEMY_INTENSIVE_TRAINING_COST = 25_000;

/** XP awarded to a trainee per lap completed in a practice session. */
export const ACADEMY_PRACTICE_XP_PER_LAP = 2;

/** Minimum laps required in a practice session for the trainee to earn a +1 stat gain. */
export const ACADEMY_PRACTICE_STAT_THRESHOLD = 15;

/** Fitness drained from the trainee per lap completed in practice. */
export const ACADEMY_PRACTICE_FITNESS_DRAIN_PER_LAP = 2;

// ---------------------------------------------------------------------------
// Budget Rebalance (Admin)
// ---------------------------------------------------------------------------

/** Budget threshold above which teams receive a rebalance tax reduction (USD). */
export const BUDGET_REBALANCE_THRESHOLD_HIGH = 3_000_000;

/** Minimum budget floor applied to teams below this threshold (USD). */
export const BUDGET_REBALANCE_THRESHOLD_LOW = 1_500_000;

/** Fraction of excess budget above the high threshold that a team retains after the tax. */
export const BUDGET_REBALANCE_REDUCTION_RATE = 0.2;

// ---------------------------------------------------------------------------
// Specializations — Academy
// ---------------------------------------------------------------------------

/**
 * Minimum baseSkill an academy trainee must have to be eligible for a specialty.
 * Mirrors SPECIALTY_BASESKILL_THRESHOLD in functions/src/config/constants.ts.
 */
export const SPECIALTY_BASESKILL_THRESHOLD = 8;

/**
 * Stat value (on 1–20 scale) a trainee must reach to trigger a specialization.
 * Mirrors SPECIALTY_STAT_THRESHOLD in functions/src/config/constants.ts.
 */
export const SPECIALTY_STAT_THRESHOLD = 11;
