import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Driver } from '$lib/types';

// ─── Firestore mock ───────────────────────────────────────────────────────────
const mockUpdate = vi.fn();
const mockGet = vi.fn();
const mockTransaction = {
    get: mockGet,
    update: mockUpdate,
    set: vi.fn(),
};

vi.mock('$lib/firebase/config', () => ({ db: {} }));
vi.mock('firebase/firestore', () => ({
    doc: vi.fn(() => ({})),
    collection: vi.fn(() => ({})),
    increment: vi.fn((v: number) => v),
    updateDoc: vi.fn(),
    runTransaction: vi.fn(async (_db: any, fn: (t: any) => Promise<void>) => {
        await fn(mockTransaction);
    }),
}));
vi.mock('$lib/repositories/driver.repository', () => ({
    driverRepository: { docRef: vi.fn(() => ({})) },
}));
vi.mock('$lib/repositories/team.repository', () => ({
    teamRepository: { docRef: vi.fn(() => ({})) },
}));
vi.mock('$lib/utils/driver', () => ({
    calculateDriverMarketValue: vi.fn(() => 1_000_000),
}));
vi.mock('$lib/constants/economics', () => ({
    TRANSFER_MARKET_LISTING_FEE_RATE: 0.10,
    DRIVER_RENEWAL_FEE_RATE: 0.10,
    DISMISS_MORALE_PENALTY: 20,
    MORALE_DEFAULT: 70,
    MORALE_EVENT_TRANSFER_LISTED: -10,
    PSYCHOLOGIST_UPGRADE_COSTS: [0, 0, 100_000, 250_000, 500_000, 1_000_000],
}));

// ─── Helpers ─────────────────────────────────────────────────────────────────
function makeDriver(overrides: Partial<Driver> = {}): Driver {
    return {
        id: 'driver-1',
        teamId: 'team-1',
        name: 'Test Driver',
        age: 25,
        salary: 500_000,
        potential: 3,
        currentStars: 3,
        gender: 'male',
        countryCode: 'CO',
        role: 'driver',
        contractYearsRemaining: 2,
        stats: { cornering: 10, braking: 10, focus: 10, fitness: 80, adaptability: 10, consistency: 10, smoothness: 10, overtaking: 10, morale: 60 },
        seasonPoints: 0,
        seasonRaces: 0,
        seasonWins: 0,
        seasonPodiums: 0,
        seasonPoles: 0,
        form: 0,
        championshipForm: [],
        isTransferListed: false,
        marketValue: 1_000_000,
        currentHighestBid: 0,
        carIndex: 0,
        ...overrides,
    } as Driver;
}

// ─── Tests ───────────────────────────────────────────────────────────────────
describe('StaffService', () => {
    let staffService: import('./staff.svelte').StaffService;

    beforeEach(async () => {
        vi.resetAllMocks();
        // Restore runTransaction implementation after reset
        const { runTransaction } = await import('firebase/firestore');
        vi.mocked(runTransaction).mockImplementation(async (_db: any, fn: (t: any) => Promise<unknown>) => {
            await fn(mockTransaction);
        });
        const mod = await import('./staff.svelte');
        staffService = new mod.StaffService();
    });

    describe('cancelListing()', () => {
        it('throws immediately when driver has an active bid', async () => {
            const driver = makeDriver({ currentHighestBid: 50_000, isTransferListed: true });

            await expect(staffService.cancelListing('team-1', driver))
                .rejects.toThrow('Cannot cancel listing with active bids');

            // Firestore transaction must NOT have been called
            const { runTransaction } = await import('firebase/firestore');
            expect(runTransaction).not.toHaveBeenCalled();
        });

        it('clears isTransferListed and transferListedAt when no active bids', async () => {
            const driver = makeDriver({ currentHighestBid: 0, isTransferListed: true });

            mockGet.mockResolvedValueOnce({ exists: () => true, data: () => ({}) });

            await staffService.cancelListing('team-1', driver);

            expect(mockUpdate).toHaveBeenCalledWith(
                expect.anything(),
                expect.objectContaining({
                    isTransferListed: false,
                    transferListedAt: null,
                })
            );
        });

        it('does not deduct budget when cancelling', async () => {
            const driver = makeDriver({ currentHighestBid: 0, isTransferListed: true });
            const { teamRepository } = await import('$lib/repositories/team.repository');

            mockGet.mockResolvedValueOnce({ exists: () => true, data: () => ({}) });

            await staffService.cancelListing('team-1', driver);

            // teamRepository.docRef should not be accessed for a budget mutation
            expect(teamRepository.docRef).not.toHaveBeenCalled();
        });
    });

    describe('listDriverOnMarket()', () => {
        it('deducts the 10% listing fee from budget', async () => {
            const driver = makeDriver();
            // listDriverOnMarket reads team first, then driver (for morale)
            mockGet.mockResolvedValueOnce({ exists: () => true, data: () => ({ budget: 2_000_000 }) });
            mockGet.mockResolvedValueOnce({ exists: () => true, data: () => ({ stats: { morale: 70 } }) });

            await staffService.listDriverOnMarket('team-1', driver);

            expect(mockUpdate).toHaveBeenCalledWith(
                expect.anything(),
                expect.objectContaining({ budget: -100_000 }) // 10% of 1_000_000
            );
        });

        it('throws when budget is insufficient for listing fee', async () => {
            const driver = makeDriver();
            mockGet.mockResolvedValueOnce({ exists: () => true, data: () => ({ budget: 0 }) });

            await expect(staffService.listDriverOnMarket('team-1', driver))
                .rejects.toThrow('Insufficient budget');
        });

        it('sets isTransferListed to true on the driver', async () => {
            const driver = makeDriver();
            mockGet.mockResolvedValueOnce({ exists: () => true, data: () => ({ budget: 2_000_000 }) });
            mockGet.mockResolvedValueOnce({ exists: () => true, data: () => ({ stats: { morale: 70 } }) });

            await staffService.listDriverOnMarket('team-1', driver);

            expect(mockUpdate).toHaveBeenCalledWith(
                expect.anything(),
                expect.objectContaining({ isTransferListed: true })
            );
        });
    });
});
