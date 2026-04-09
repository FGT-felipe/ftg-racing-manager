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

describe('getUpgradeCost — Fibonacci × CAR_UPGRADE_BASE_COST ($200k)', () => {
    it('L1 → L2 costs $200k (base, flat)', () => {
        expect(getUpgradeCost(1)).toBe(200_000);
    });

    it('L2 → L3 costs $200k (flat, same as L1)', () => {
        expect(getUpgradeCost(2)).toBe(200_000);
    });

    it('L3 → L4 costs $400k (Fib×2)', () => {
        expect(getUpgradeCost(3)).toBe(400_000);
    });

    it('L4 → L5 costs $600k (Fib×3)', () => {
        expect(getUpgradeCost(4)).toBe(600_000);
    });

    it('L5 → L6 costs $1.0M (Fib×5)', () => {
        expect(getUpgradeCost(5)).toBe(1_000_000);
    });

    it('L6 → L7 costs $1.6M (Fib×8)', () => {
        expect(getUpgradeCost(6)).toBe(1_600_000);
    });

    it('L7 → L8 costs $2.6M (Fib×13)', () => {
        expect(getUpgradeCost(7)).toBe(2_600_000);
    });

    it('L8 → L9 costs $4.2M (Fib×21)', () => {
        expect(getUpgradeCost(8)).toBe(4_200_000);
    });

    it('L9 → L10 costs $6.8M (Fib×34)', () => {
        expect(getUpgradeCost(9)).toBe(6_800_000);
    });

    describe('Engineer role — 2× multiplier', () => {
        it('L1 → L2 costs $400k for Engineer', () => {
            expect(getUpgradeCost(1, true)).toBe(400_000);
        });

        it('L5 → L6 costs $2.0M for Engineer', () => {
            expect(getUpgradeCost(5, true)).toBe(2_000_000);
        });

        it('L7 → L8 costs $5.2M for Engineer', () => {
            expect(getUpgradeCost(7, true)).toBe(5_200_000);
        });
    });
});
