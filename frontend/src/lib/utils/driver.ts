import type { Driver, YoungDriver } from '../types';
import {
    TRANSFER_MARKET_POTENTIAL_MULTIPLIER_PER_STAR,
    TRANSFER_MARKET_CURRENT_PERFORMANCE_WEIGHT,
    TRANSFER_MARKET_AGE_PEAK,
    TRANSFER_MARKET_AGE_DEPRECIATION_RATE,
    TRANSFER_MARKET_AGE_PREMIUM_RATE,
    TRANSFER_MARKET_AGE_FLOOR,
    TRANSFER_MARKET_MIN_VALUE,
    NEGOTIATION_TITLE_WEIGHT,
    NEGOTIATION_STARS_WEIGHT,
} from '../constants/economics';

// ---------------------------------------------------------------------------
// Driver Level
// ---------------------------------------------------------------------------

export interface DriverLevelInfo {
    label: string;
    color: string;
    borderColor: string;
}

/**
 * Returns display label and color classes for a driver's current star level.
 * Used consistently across all views (market, roster, negotiation, academy).
 *
 * @param stars - Current star rating (1–5)
 * @param t - i18n translation function
 */
export function getDriverLevelInfo(stars: number, t: (key: string) => string): DriverLevelInfo {
    if (stars >= 5) return { label: t('elite'),               color: 'text-yellow-500', borderColor: 'border-yellow-500/40' };
    if (stars >= 4) return { label: t('pro'),                 color: 'text-blue-400',   borderColor: 'border-blue-400/40' };
    if (stars >= 3) return { label: t('driver_level_veteran'),color: 'text-green-400',  borderColor: 'border-green-400/40' };
    if (stars >= 2) return { label: t('driver_level_talent'), color: 'text-orange-400', borderColor: 'border-orange-400/40' };
    return              { label: t('driver_level_rookie'),    color: 'text-app-text/40', borderColor: 'border-app-border' };
}

/**
 * Calculates current stars for regular professional drivers.
 * Rule: ceil(averageDrivingStats / 4.0).clamp(1, 5), capped at potential.
 */
export function calculateCurrentStars(driver: Driver): number {
    if (!driver || !driver.stats) return 1;

    const stats = [
        driver.stats.braking || 10,
        driver.stats.cornering || 10,
        driver.stats.smoothness || 10,
        driver.stats.overtaking || 10,
        driver.stats.consistency || 10,
        driver.stats.adaptability || 10
    ];
    
    const avg = stats.reduce((a, b) => a + b, 0) / stats.length;

    // 1-20 scale: 20/4 = 5 stars
    let stars = Math.ceil(avg / 4.0);

    // Constraints
    stars = Math.max(1, Math.min(5, stars));

    // Cap at potential
    const pot = driver.potential || 5;
    if (stars > pot) stars = pot;

    return stars;
}

/**
 * Returns potential stars for professional drivers.
 */
export function calculateMaxStars(driver: Driver): number {
    if (!driver) return 1;
    return driver.potential || 1;
}

/**
 * Academy Drivers: Current Skill Stars
 * Formula: round(baseSkill / 4.0).clamp(1, 5)
 */
export function calculateAcademyCurrentStars(candidate: any): number {
    const baseSkill = candidate.baseSkill || 10;
    let stars = Math.round(baseSkill / 4.0);
    return Math.max(1, Math.min(5, stars));
}

/**
 * Academy Drivers: Potential Stars
 * Formula: round(maxSkill / 4.0).clamp(1, 5)
 */
export function calculateAcademyMaxStars(candidate: any): number {
    const maxSkill = candidate.maxSkill || 10;
    let stars = Math.round(maxSkill / 4.0);
    return Math.max(1, Math.min(5, stars));
}

/**
 * Calculates a driver's market value based on their potential, current performance, and age.
 *
 * Formula: annualSalary × potentialMultiplier × currentPerformanceFactor × ageFactor
 *
 * - potentialMultiplier: 1.0× (1-star) to 3.0× (5-star potential ceiling)
 * - currentPerformanceFactor: 0.6× (1-star perf) to 1.0× (5-star perf)
 * - ageFactor: premium below peak age (TRANSFER_MARKET_AGE_PEAK), depreciation above it
 *
 * @param driver - The driver object (must have salary [annual], potential, age, stats)
 * @returns Market value in USD, floored at TRANSFER_MARKET_MIN_VALUE
 */
export function calculateDriverMarketValue(driver: Driver): number {
    const currentStars = calculateCurrentStars(driver);
    const annualSalary = driver.salary; // driver.salary is stored as annual per reglas_negocio.md

    // 1.0× for 1-star potential, 3.0× for 5-star potential
    const potentialMultiplier = 1 + (driver.potential - 1) * TRANSFER_MARKET_POTENTIAL_MULTIPLIER_PER_STAR;

    // 0.6× for 1-star current performance, 1.0× for 5-star
    const currentPerformanceFactor = 0.5 + (currentStars / 5) * TRANSFER_MARKET_CURRENT_PERFORMANCE_WEIGHT;

    // Age factor: premium for youth, depreciation for veterans
    const ageDiff = driver.age - TRANSFER_MARKET_AGE_PEAK;
    const ageFactor = ageDiff < 0
        ? 1 + Math.abs(ageDiff) * TRANSFER_MARKET_AGE_PREMIUM_RATE
        : Math.max(TRANSFER_MARKET_AGE_FLOOR, 1 - ageDiff * TRANSFER_MARKET_AGE_DEPRECIATION_RATE);

    return Math.max(
        TRANSFER_MARKET_MIN_VALUE,
        Math.round(annualSalary * potentialMultiplier * currentPerformanceFactor * ageFactor)
    );
}

/**
 * Formats a driver's full name to F1-style abbreviated format: "L. Hamilton".
 * Handles suffixes (Jr, Sr, II, III) by preserving them with the surname.
 * Returns the original name unchanged when it has only one word.
 *
 * @param fullName - The driver's full name (e.g., "Lewis Hamilton")
 * @returns Abbreviated name (e.g., "L. Hamilton"), or empty string if null/undefined
 */
export function formatDriverName(fullName: string | null | undefined): string {
    if (!fullName) return '';
    const parts = fullName.trim().split(/\s+/);
    if (parts.length === 1) return parts[0];
    const initial = parts[0][0].toUpperCase();
    const suffixes = new Set(['jr', 'sr', 'ii', 'iii', 'iv', 'v']);
    const last = parts[parts.length - 1];
    const surname = suffixes.has(last.toLowerCase()) && parts.length > 2
        ? `${parts[parts.length - 2]} ${last}`
        : last;
    return `${initial}. ${surname}`;
}

/**
 * Checks if a driver is nearing retirement (Age >= 38)
 */
export function isNearingRetirement(driver: Driver | YoungDriver): boolean {
    if (!driver) return false;
    // Retiring soon: 35-37
    return driver.age >= 35 && driver.age < 38;
}

export function isRetiringNextSeason(driver: Driver | YoungDriver): boolean {
    if (!driver) return false;
    // Strict cutoff for renewal: 38+
    return driver.age >= 38;
}

export function rejectsLongContracts(driver: Driver | YoungDriver): boolean {
    if (!driver) return false;
    return driver.age >= 37;
}

// ---------------------------------------------------------------------------
// Contract Negotiation
// ---------------------------------------------------------------------------

/**
 * Calculates how much a driver raises their counter-proposal above the offered salary.
 * Formula: offeredSalary × (titleWeight + starsWeight)
 *
 * - titleWeight: based on driver.statusTitle (0.00 for Grid Filler → 0.30 for Living Legend)
 * - starsWeight: based on currentStars (0.00 for 1-star → 0.20 for 5-star)
 *
 * @param driver - Driver being negotiated with
 * @param offeredSalary - Weekly salary offered by the manager
 * @returns Counter-proposed weekly salary (always >= offeredSalary)
 */
export function calculateDriverCounterProposal(driver: Driver, offeredSalary: number): number {
    const currentStars = calculateCurrentStars(driver);
    const titleWeight = NEGOTIATION_TITLE_WEIGHT[driver.statusTitle] ?? 0;
    const starsWeight = NEGOTIATION_STARS_WEIGHT[currentStars] ?? 0;
    const totalMarkup = titleWeight + starsWeight;
    return Math.round(offeredSalary * (1 + totalMarkup));
}

/**
 * Maps a driver specialty string to its i18n key.
 * Returns null if no specialty is assigned.
 */
export function getSpecialtyI18nKey(specialty: string | null | undefined): string | null {
    if (!specialty) return null;
    const map: Record<string, string> = {
        'Rainmaster':           'rain_master',
        'Tyre Whisperer':       'tyre_whisperer',
        'Late Braker':          'late_braker',
        'Defensive Minister':   'defensive_minister',
        'Apex Hunter':          'apex_hunter',
        'Iron Nerve':           'iron_nerve',
        'Qualy Ace':            'qualy_ace',
        'Iron Wall':            'iron_wall',
    };
    return map[specialty] ?? null;
}
