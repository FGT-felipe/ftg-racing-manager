import type { Driver, YoungDriver } from '../types';

/**
 * Calculates current stars for regular professional drivers.
 * Rule: ceil(averageDrivingStats / 20.0).clamp(1, 5), capped at potential.
 */
export function calculateCurrentStars(driver: Driver): number {
    if (!driver || !driver.stats) return 1;

    const drivingStats = [
        driver.stats.cornering || 1,
        driver.stats.braking || 1,
        driver.stats.consistency || 1,
        driver.stats.smoothness || 1,
        driver.stats.adaptability || 1,
        driver.stats.overtaking || 1,
    ];

    const avg = drivingStats.reduce((a, b) => a + b, 0) / drivingStats.length;

    // Formula: ceil(avg / 20)
    let stars = Math.ceil(avg / 20);

    // Constraints
    if (stars < 1) stars = 1;
    if (stars > 5) stars = 5;

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
 * Formula: round(baseSkill / 20.0).clamp(1, 5)
 */
export function calculateAcademyCurrentStars(driver: YoungDriver): number {
    if (!driver) return 1;
    const base = driver.baseSkill || 0;
    let stars = Math.round(base / 20);
    return Math.min(Math.max(stars, 1), 5);
}

/**
 * Academy Drivers: Potential Stars
 * Formula: round((baseSkill + growthPotential) / 20.0).clamp(1, 5)
 */
export function calculateAcademyMaxStars(driver: YoungDriver): number {
    if (!driver) return 1;
    const peak = (driver.baseSkill || 0) + (driver.growthPotential || 0);
    let stars = Math.round(peak / 20);
    return Math.min(Math.max(stars, 1), 5);
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
