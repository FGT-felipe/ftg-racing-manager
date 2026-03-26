import { describe, it, expect } from 'vitest';
import {
    MORALE_DEFAULT,
    MORALE_NEUTRAL,
    MORALE_LAPTIME_FACTOR,
    MORALE_EVENT_WIN_RACE,
    MORALE_EVENT_PODIUM,
    MORALE_EVENT_DNF,
    MORALE_EVENT_FINISH_LOW,
    MORALE_EVENT_TRANSFER_LISTED,
    MORALE_EVENT_BAD_PRACTICE,
    DISMISS_MORALE_PENALTY,
} from '$lib/constants/economics';

// ─── Shared helpers (mirrors CF and practice_service logic) ──────────────────

/**
 * Computes the lap time multiplier for a given morale value.
 * Positive result = slower (penalty). Negative = faster (bonus).
 */
function moraleLaptimeFactor(morale: number): number {
    return MORALE_LAPTIME_FACTOR * (morale - MORALE_NEUTRAL) / 100;
}

/**
 * Applies a morale delta to a current value, clamped to [0, 100].
 */
function applyMoraleEvent(current: number, delta: number): number {
    return Math.max(0, Math.min(100, current + delta));
}

// ─── Laptime formula ─────────────────────────────────────────────────────────

describe('moraleLaptimeFactor', () => {
    it('returns 0 at neutral morale (50)', () => {
        expect(moraleLaptimeFactor(MORALE_NEUTRAL)).toBe(0);
    });

    it('returns a positive factor (speed bonus) when morale > neutral', () => {
        // Factor is added to the skill sum in driverFactor: higher sum = lower df = faster lap
        const factor = moraleLaptimeFactor(100);
        expect(factor).toBeCloseTo(0.01); // 0.02 * (100-50)/100 = +0.01
        expect(factor).toBeGreaterThan(0);
    });

    it('returns a negative factor (speed penalty) when morale < neutral', () => {
        // Negative factor reduces skill sum → higher driverFactor → slower lap
        const factor = moraleLaptimeFactor(0);
        expect(factor).toBeCloseTo(-0.01); // 0.02 * (0-50)/100 = -0.01
        expect(factor).toBeLessThan(0);
    });

    it('uses MORALE_DEFAULT (70) as a mild bonus over neutral', () => {
        const factor = moraleLaptimeFactor(MORALE_DEFAULT);
        expect(factor).toBeCloseTo(0.004); // 0.02 * (70-50)/100 = +0.004
        expect(factor).toBeGreaterThan(0);
    });

    it('effect is symmetric: +X at morale=NEUTRAL+d equals -X at morale=NEUTRAL-d', () => {
        const above = moraleLaptimeFactor(MORALE_NEUTRAL + 30);
        const below = moraleLaptimeFactor(MORALE_NEUTRAL - 30);
        expect(above).toBeCloseTo(-below);
    });
});

// ─── Morale clamping ─────────────────────────────────────────────────────────

describe('applyMoraleEvent — clamping', () => {
    it('clamps to 0 when delta pushes below 0', () => {
        expect(applyMoraleEvent(10, -DISMISS_MORALE_PENALTY)).toBe(0); // 10 - 20 = -10 → 0
    });

    it('clamps to 100 when delta pushes above 100', () => {
        expect(applyMoraleEvent(95, MORALE_EVENT_WIN_RACE)).toBe(100); // 95 + 15 = 110 → 100
    });

    it('applies exact value when within range', () => {
        expect(applyMoraleEvent(50, MORALE_EVENT_WIN_RACE)).toBe(65);
        expect(applyMoraleEvent(70, MORALE_EVENT_DNF)).toBe(60);
    });

    it('does not go below 0 with stacked penalties', () => {
        let morale = 15;
        morale = applyMoraleEvent(morale, MORALE_EVENT_DNF);        // 15 - 10 = 5
        morale = applyMoraleEvent(morale, MORALE_EVENT_TRANSFER_LISTED); // 5 - 10 = -5 → 0
        morale = applyMoraleEvent(morale, DISMISS_MORALE_PENALTY * -1);  // 0 - 20 = -20 → 0
        expect(morale).toBe(0);
    });

    it('does not exceed 100 with stacked boosts', () => {
        let morale = 85;
        morale = applyMoraleEvent(morale, MORALE_EVENT_WIN_RACE);   // 85 + 15 = 100
        morale = applyMoraleEvent(morale, MORALE_EVENT_PODIUM);     // 100 + 8 = 108 → 100
        expect(morale).toBe(100);
    });
});

// ─── Event constants sanity checks ───────────────────────────────────────────

describe('morale event constants', () => {
    it('win race boosts more than podium', () => {
        expect(MORALE_EVENT_WIN_RACE).toBeGreaterThan(MORALE_EVENT_PODIUM);
    });

    it('all negative events are actually negative', () => {
        expect(MORALE_EVENT_DNF).toBeLessThan(0);
        expect(MORALE_EVENT_FINISH_LOW).toBeLessThan(0);
        expect(MORALE_EVENT_TRANSFER_LISTED).toBeLessThan(0);
        expect(MORALE_EVENT_BAD_PRACTICE).toBeLessThan(0);
    });

    it('DNF is a larger penalty than finishing low', () => {
        expect(MORALE_EVENT_DNF).toBeLessThan(MORALE_EVENT_FINISH_LOW);
    });

    it('MORALE_DEFAULT is above MORALE_NEUTRAL (drivers start in a positive state)', () => {
        expect(MORALE_DEFAULT).toBeGreaterThan(MORALE_NEUTRAL);
    });
});
