import { describe, it, expect, vi, beforeEach } from 'vitest';

// ─── Firestore mock ───────────────────────────────────────────────────────────

const mockSet = vi.fn();
const mockUpdate = vi.fn();
const mockTransactionGet = vi.fn();

const mockTransaction = {
    get: mockTransactionGet,
    update: mockUpdate,
    set: mockSet,
};

vi.mock('$lib/firebase/config', () => ({ db: {} }));
vi.mock('firebase/firestore', () => ({
    doc: vi.fn(() => ({ id: 'mock-doc-ref' })),
    collection: vi.fn(() => ({})),
    runTransaction: vi.fn(async (_db: any, fn: (t: any) => Promise<void>) => {
        await fn(mockTransaction);
    }),
    serverTimestamp: vi.fn(() => 'SERVER_TIMESTAMP'),
}));
vi.mock('$lib/repositories/team.repository', () => ({
    teamRepository: { docRef: vi.fn(() => ({ id: 'team-ref' })) },
}));
vi.mock('$lib/constants/app_constants', () => ({
    PARTS_ENGINE_REPAIR_COST_FLAT: 25_000,
    PARTS_REPAIR_BUDGET_CAP_PER_ROUND: 150_000,
    PARTS_REPAIR_HQ_CAP_MULTIPLIER_STEP: 0.5,
    PARTS_TIER_THRESHOLDS: { yellow: 80, orange: 50, red: 30 },
    PARTS_BASE_RACE_DELTA: 8,
    GARAGE_REPAIR_MAX_TABLE: { 1: 65, 2: 75, 3: 85, 4: 95, 5: 100 },
    PARTS_REPAIR_COOLDOWN_ROUNDS: 2,
}));

// ─── Subject ──────────────────────────────────────────────────────────────────

import { PartsWearService } from './parts_wear_service.svelte';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function makeTeamDoc(budget: number, opts: {
    garageLevel?: number;
    hqLevel?: number;
    repairSpent?: number;
    isLastRound?: boolean;
} = {}) {
    const { garageLevel = 1, hqLevel = 1, repairSpent = 0, isLastRound = false } = opts;
    return {
        exists: () => true,
        data: () => ({
            budget,
            facilities: {
                garage: { level: garageLevel },
                hq: { level: hqLevel },
            },
            weekStatus: { repairSpentThisRound: repairSpent, isLastRound },
        }),
    };
}

function makePartDoc(condition: number) {
    return { exists: () => true, data: () => ({ condition, maxCondition: 100 }) };
}

// ─── Tests: getGarageRepairTarget ────────────────────────────────────────────

describe('PartsWearService.getGarageRepairTarget', () => {
    let service: PartsWearService;
    beforeEach(() => { service = new PartsWearService(); });

    it.each([
        [1, 65], [2, 75], [3, 85], [4, 95], [5, 100],
    ])('Garage L%i → %i%%', (level, expected) => {
        expect(service.getGarageRepairTarget({ facilities: { garage: { level } } })).toBe(expected);
    });
    it('missing garage facility → defaults to L1 (65%)', () => {
        expect(service.getGarageRepairTarget({})).toBe(65);
    });
    it('garage level 6 (bad data) → clamps to L5 (100%)', () => {
        expect(service.getGarageRepairTarget({ facilities: { garage: { level: 6 } } })).toBe(100);
    });
});

// ─── Tests: getRepairCap ─────────────────────────────────────────────────────

describe('PartsWearService.getRepairCap', () => {
    let service: PartsWearService;
    beforeEach(() => { service = new PartsWearService(); });

    it('HQ L1 → $150k', () => expect(service.getRepairCap({ facilities: { hq: { level: 1 } } })).toBe(150_000));
    it('HQ L2 → $225k', () => expect(service.getRepairCap({ facilities: { hq: { level: 2 } } })).toBe(225_000));
    it('HQ L3 → $300k', () => expect(service.getRepairCap({ facilities: { hq: { level: 3 } } })).toBe(300_000));
    it('HQ L5 → $450k', () => expect(service.getRepairCap({ facilities: { hq: { level: 5 } } })).toBe(450_000));
    it('missing hq → defaults to L1 ($150k)', () => expect(service.getRepairCap({})).toBe(150_000));
});

// ─── Tests: repairPart ────────────────────────────────────────────────────────

describe('PartsWearService.repairPart', () => {
    let service: PartsWearService;

    beforeEach(() => {
        service = new PartsWearService();
        vi.clearAllMocks();
    });

    it('success — decrements budget, sets condition to garage target, sets cooldown', async () => {
        mockTransactionGet
            .mockResolvedValueOnce(makeTeamDoc(100_000, { garageLevel: 1 }))
            .mockResolvedValueOnce(makePartDoc(40));

        await service.repairPart('team-1', 0, 'engine');

        expect(mockUpdate).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({ budget: 100_000 - 25_000 })
        );
        // Garage L1 → repair target 65
        expect(mockUpdate).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({ condition: 65, maxCondition: 65, repairCooldownRoundsLeft: 2 })
        );
        expect(mockSet).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({ amount: -25_000, type: 'OTHER' })
        );
    });

    it('Garage L5 → repair target 100', async () => {
        mockTransactionGet
            .mockResolvedValueOnce(makeTeamDoc(100_000, { garageLevel: 5 }))
            .mockResolvedValueOnce(makePartDoc(40));

        await service.repairPart('team-1', 0, 'engine');

        expect(mockUpdate).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({ condition: 100, maxCondition: 100 })
        );
    });

    it('throws INSUFFICIENT_BUDGET when budget < repair cost', async () => {
        mockTransactionGet
            .mockResolvedValueOnce(makeTeamDoc(10_000))
            .mockResolvedValueOnce(makePartDoc(40));

        await expect(service.repairPart('team-1', 0, 'engine')).rejects.toThrow('INSUFFICIENT_BUDGET');
        expect(mockUpdate).not.toHaveBeenCalled();
        expect(mockSet).not.toHaveBeenCalled();
    });

    it('throws REPAIR_BUDGET_EXCEEDED when cap (HQ L1 $150k) would be exceeded', async () => {
        mockTransactionGet
            .mockResolvedValueOnce(makeTeamDoc(500_000, { repairSpent: 140_000 }))
            .mockResolvedValueOnce(makePartDoc(40));

        await expect(service.repairPart('team-1', 0, 'engine')).rejects.toThrow('REPAIR_BUDGET_EXCEEDED');
    });

    it('isLastRound doubles cap — repair succeeds when it would otherwise be blocked', async () => {
        // spent=140k, cost=25k, HQ L1 cap=150k → normally blocked; with doubling cap=300k → allowed
        mockTransactionGet
            .mockResolvedValueOnce(makeTeamDoc(500_000, { repairSpent: 140_000, isLastRound: true }))
            .mockResolvedValueOnce(makePartDoc(40));

        await expect(service.repairPart('team-1', 0, 'engine')).resolves.toBeUndefined();
    });

    it('0% condition edge — repairs successfully', async () => {
        mockTransactionGet
            .mockResolvedValueOnce(makeTeamDoc(50_000))
            .mockResolvedValueOnce(makePartDoc(0));

        await service.repairPart('team-1', 0, 'engine');
        expect(mockUpdate).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({ condition: 65 })
        );
    });
});

// ─── Tests: getConditionTier ──────────────────────────────────────────────────

describe('PartsWearService.getConditionTier', () => {
    let service: PartsWearService;

    beforeEach(() => {
        service = new PartsWearService();
    });

    it.each([
        [100, 'green'],
        [80,  'green'],
        [79,  'yellow'],
        [50,  'yellow'],
        [49,  'orange'],
        [30,  'orange'],
        [29,  'red'],
        [0,   'red'],
    ])('condition %i → tier %s', (condition, expected) => {
        expect(service.getConditionTier(condition)).toBe(expected);
    });
});
