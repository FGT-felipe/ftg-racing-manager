import type { Driver, YoungDriver } from '../types';

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
