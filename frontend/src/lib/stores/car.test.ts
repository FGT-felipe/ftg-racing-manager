import { describe, it, expect, vi, beforeEach } from 'vitest';
import { CAR_UPGRADE_BASE_COST } from '$lib/constants/economics';

// ── Isolate getUpgradeCost from store dependencies ─────────────────────────
// We extract the pure formula so tests don't require Firebase or Svelte context.
function getUpgradeCost(currentLevel: number, isEngineer = false): number {
    if (currentLevel <= 2) {
        const base = CAR_UPGRADE_BASE_COST;
        return isEngineer ? base * 2 : base;
    }

    let a = 1;
    let b = 1;
    for (let i = 2; i < currentLevel; i++) {
        const temp = a + b;
        a = b;
        b = temp;
    }

    const base = b * CAR_UPGRADE_BASE_COST;
    return isEngineer ? base * 2 : base;
}

describe('getUpgradeCost — Fibonacci × CAR_UPGRADE_BASE_COST ($350k)', () => {
    it('L1 → L2 costs $350k (base, flat)', () => {
        expect(getUpgradeCost(1)).toBe(350_000);
    });

    it('L2 → L3 costs $350k (flat, same as L1)', () => {
        expect(getUpgradeCost(2)).toBe(350_000);
    });

    it('L3 → L4 costs $700k (Fib×2)', () => {
        expect(getUpgradeCost(3)).toBe(700_000);
    });

    it('L4 → L5 costs $1.05M (Fib×3)', () => {
        expect(getUpgradeCost(4)).toBe(1_050_000);
    });

    it('L5 → L6 costs $1.75M (Fib×5)', () => {
        expect(getUpgradeCost(5)).toBe(1_750_000);
    });

    it('L6 → L7 costs $2.8M (Fib×8)', () => {
        expect(getUpgradeCost(6)).toBe(2_800_000);
    });

    it('L7 → L8 costs $4.55M (Fib×13)', () => {
        expect(getUpgradeCost(7)).toBe(4_550_000);
    });

    it('L8 → L9 costs $7.35M (Fib×21)', () => {
        expect(getUpgradeCost(8)).toBe(7_350_000);
    });

    it('L9 → L10 costs $11.9M (Fib×34)', () => {
        expect(getUpgradeCost(9)).toBe(11_900_000);
    });

    describe('Engineer role — 2× multiplier', () => {
        it('L1 → L2 costs $700k for Engineer', () => {
            expect(getUpgradeCost(1, true)).toBe(700_000);
        });

        it('L5 → L6 costs $3.5M for Engineer', () => {
            expect(getUpgradeCost(5, true)).toBe(3_500_000);
        });

        it('L7 → L8 costs $9.1M for Engineer', () => {
            expect(getUpgradeCost(7, true)).toBe(9_100_000);
        });
    });
});
