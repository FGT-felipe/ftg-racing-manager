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
    PARTS_TIER_THRESHOLDS: { yellow: 80, orange: 50, red: 30 },
    PARTS_BASE_RACE_DELTA: 8,
}));

// ─── Subject ──────────────────────────────────────────────────────────────────

import { PartsWearService } from './parts_wear_service.svelte';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function makeTeamDoc(budget: number) {
    return { exists: () => true, data: () => ({ budget }) };
}

function makePartDoc(condition: number) {
    return { exists: () => true, data: () => ({ condition }) };
}

// ─── Tests: repairPart ────────────────────────────────────────────────────────

describe('PartsWearService.repairPart', () => {
    let service: PartsWearService;

    beforeEach(() => {
        service = new PartsWearService();
        vi.clearAllMocks();
    });

    it('success — decrements budget, sets condition to 100, writes transaction entry', async () => {
        mockTransactionGet
            .mockResolvedValueOnce(makeTeamDoc(100_000))  // teamDoc
            .mockResolvedValueOnce(makePartDoc(40));       // partDoc

        await service.repairPart('team-1', 0, 'engine');

        // budget reduced by repair cost
        expect(mockUpdate).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({ budget: 100_000 - 25_000 })
        );
        // condition set to 100
        expect(mockUpdate).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({ condition: 100 })
        );
        // transaction entry written
        expect(mockSet).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({ amount: -25_000, type: 'OTHER' })
        );
    });

    it('rollback — throws INSUFFICIENT_BUDGET when budget < repair cost', async () => {
        mockTransactionGet
            .mockResolvedValueOnce(makeTeamDoc(10_000))  // budget < 25000
            .mockResolvedValueOnce(makePartDoc(40));

        await expect(service.repairPart('team-1', 0, 'engine')).rejects.toThrow('INSUFFICIENT_BUDGET');
        // no writes should have happened
        expect(mockUpdate).not.toHaveBeenCalled();
        expect(mockSet).not.toHaveBeenCalled();
    });

    it('0% condition edge — repairs from 0 to 100 successfully', async () => {
        mockTransactionGet
            .mockResolvedValueOnce(makeTeamDoc(50_000))
            .mockResolvedValueOnce(makePartDoc(0));

        await service.repairPart('team-1', 0, 'engine');

        expect(mockUpdate).toHaveBeenCalledWith(
            expect.anything(),
            expect.objectContaining({ condition: 100 })
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
