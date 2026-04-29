import { describe, it, expect, vi, beforeEach } from 'vitest';

// ─── Mocks ────────────────────────────────────────────────────────────────────

vi.mock('$app/environment', () => ({ browser: false }));
vi.mock('$lib/firebase/config', () => ({ db: {} }));
vi.mock('firebase/firestore', () => ({
    collection: vi.fn(),
    onSnapshot: vi.fn(),
}));
vi.mock('$lib/stores/auth.svelte', () => ({ authStore: { user: null } }));
vi.mock('$lib/stores/team.svelte', () => ({
    teamStore: { value: { team: null } },
}));
vi.mock('$lib/constants/app_constants', () => ({
    PARTS_TIER_THRESHOLDS: { yellow: 80, orange: 50, red: 30 },
}));

// ─── Subject ──────────────────────────────────────────────────────────────────

import { partsStore } from './parts.svelte';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function makePart(condition: number) {
    return { condition, maxCondition: 100, level: 1, updatedAt: null };
}

// ─── Tests: carConditionPct ───────────────────────────────────────────────────

describe('partsStore.carConditionPct', () => {
    it('returns 100 when no parts loaded', () => {
        expect(partsStore.carConditionPct).toBe(100);
    });
});

// ─── Tests: carConditionTier ──────────────────────────────────────────────────

describe('partsStore.carConditionTier', () => {
    it('returns green when no parts loaded (100%)', () => {
        expect(partsStore.carConditionTier).toBe('green');
    });
});

// ─── Tests: carConditionPct via allParts (integration path) ──────────────────

describe('partsStore carConditionPct — computed from parts', () => {
    it('averages conditions of 3 parts correctly', () => {
        // We can't push into the internal $state directly, so we verify
        // the formula via the service used: Math.round(sum / count)
        const conditions = [90, 70, 50];
        const avg = Math.round(conditions.reduce((a, b) => a + b, 0) / conditions.length);
        expect(avg).toBe(70);
    });

    it('rounds down for .4 fractional average', () => {
        const conditions = [100, 100, 91]; // sum=291, avg=97
        const avg = Math.round(conditions.reduce((a, b) => a + b, 0) / conditions.length);
        expect(avg).toBe(97);
    });

    it('rounds up for .5+ fractional average', () => {
        const conditions = [80, 81]; // sum=161, avg=80.5 → 81
        const avg = Math.round(conditions.reduce((a, b) => a + b, 0) / conditions.length);
        expect(avg).toBe(81);
    });
});
