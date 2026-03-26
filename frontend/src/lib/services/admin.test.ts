import { describe, it, expect, vi, beforeEach } from 'vitest';

// ─── Firestore mock ───────────────────────────────────────────────────────────
const mockBatchUpdate = vi.fn();
const mockBatchSet = vi.fn();
const mockBatchDelete = vi.fn();
const mockBatchCommit = vi.fn();

const mockBatch = {
    update: mockBatchUpdate,
    set: mockBatchSet,
    delete: mockBatchDelete,
    commit: mockBatchCommit,
};

const mockGetDocs = vi.fn();

vi.mock('$lib/firebase/config', () => ({ db: {} }));
vi.mock('firebase/firestore', () => ({
    collection: vi.fn((_db: any, ...path: string[]) => ({ _path: path.join('/') })),
    doc: vi.fn((_db: any, ...path: string[]) => ({ _path: path.join('/') })),
    getDocs: (...args: any[]) => mockGetDocs(...args),
    writeBatch: vi.fn(() => mockBatch),
    deleteField: vi.fn(() => '__DELETE__'),
    increment: vi.fn((v: number) => ({ _increment: v })),
    serverTimestamp: vi.fn(() => '__SERVER_TS__'),
    addDoc: vi.fn(),
    getDoc: vi.fn(),
    updateDoc: vi.fn(),
    setDoc: vi.fn(),
    deleteDoc: vi.fn(),
    query: vi.fn((...args: any[]) => args[0]),
    where: vi.fn(),
    limit: vi.fn(),
    collectionGroup: vi.fn(),
}));
vi.mock('$lib/constants/economics', () => ({
    BUDGET_REBALANCE_THRESHOLD_HIGH: 50_000_000,
    BUDGET_REBALANCE_THRESHOLD_LOW: 5_000_000,
    BUDGET_REBALANCE_REDUCTION_RATE: 0.5,
    QUALY_ENTRY_FEE: 10_000,
}));

// ─── Helpers ──────────────────────────────────────────────────────────────────
function makeTeamDoc(id: string, overrides: Record<string, any> = {}) {
    return {
        id,
        ref: { id },
        data: () => ({
            isBot: false,
            budget: 30_000_000,
            weekStatus: { driverSetups: {} },
            ...overrides,
        }),
    };
}

function makeRaceDoc(id: string, overrides: Record<string, any> = {}) {
    return {
        id,
        ref: { id },
        data: () => ({
            isFinished: false,
            qualyGrid: [],
            ...overrides,
        }),
    };
}

// ─── Tests ────────────────────────────────────────────────────────────────────
describe('adminService — resetQualifyingSession', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('dry-run returns affected doc IDs without calling batch.commit()', async () => {
        const teamWithQualy = makeTeamDoc('team-1', {
            weekStatus: {
                driverSetups: {
                    'driver-1': { qualifyingAttempts: 2, qualifyingBestTime: 80000 },
                },
            },
        });
        const raceWithGrid = makeRaceDoc('S1_r4', {
            qualyGrid: [{ driverId: 'driver-1', position: 1 }],
        });
        const finishedRace = makeRaceDoc('S1_r3', {
            isFinished: true,
            qualyGrid: [{ driverId: 'driver-1', position: 1 }],
        });

        mockGetDocs
            .mockResolvedValueOnce({ docs: [teamWithQualy] })   // teams
            .mockResolvedValueOnce({ docs: [raceWithGrid, finishedRace] }); // races

        const { adminService } = await import('./admin.svelte');
        const result = await adminService.resetQualifyingSession(true);

        expect('affectedDocIds' in result).toBe(true);
        if (!('affectedDocIds' in result)) return;

        // Must include the affected team and the unfinished race
        expect(result.affectedDocIds).toContain('teams/team-1');
        expect(result.affectedDocIds).toContain('races/S1_r4');

        // Must NOT include the finished race
        expect(result.affectedDocIds).not.toContain('races/S1_r3');

        // No writes committed in dry-run
        expect(mockBatchCommit).not.toHaveBeenCalled();
    });

    it('dry-run with no qualifying data returns empty affectedDocIds', async () => {
        const teamNoQualy = makeTeamDoc('team-2');
        const raceNoGrid = makeRaceDoc('S1_r4');

        mockGetDocs
            .mockResolvedValueOnce({ docs: [teamNoQualy] })
            .mockResolvedValueOnce({ docs: [raceNoGrid] });

        const { adminService } = await import('./admin.svelte');
        const result = await adminService.resetQualifyingSession(true);

        expect('affectedDocIds' in result).toBe(true);
        if (!('affectedDocIds' in result)) return;
        expect(result.affectedDocIds).toHaveLength(0);
        expect(mockBatchCommit).not.toHaveBeenCalled();
    });

    it('live run commits batch and returns teamsFixed / driversFixed', async () => {
        const teamWithQualy = makeTeamDoc('team-1', {
            weekStatus: {
                driverSetups: {
                    'driver-1': { qualifyingAttempts: 1 },
                },
            },
        });
        const raceWithGrid = makeRaceDoc('S1_r4', {
            qualyGrid: [{ driverId: 'driver-1', position: 1 }],
        });

        mockGetDocs
            .mockResolvedValueOnce({ docs: [teamWithQualy] })
            .mockResolvedValueOnce({ docs: [raceWithGrid] });

        const { adminService } = await import('./admin.svelte');
        const result = await adminService.resetQualifyingSession(false);

        expect('teamsFixed' in result).toBe(true);
        if (!('teamsFixed' in result)) return;
        expect(result.teamsFixed).toBe(1);
        expect(result.driversFixed).toBe(1);
        expect(mockBatchCommit).toHaveBeenCalled();
    });

    it('live run skips bot teams', async () => {
        const botTeam = makeTeamDoc('bot-1', {
            isBot: true,
            weekStatus: {
                driverSetups: { 'driver-99': { qualifyingAttempts: 3 } },
            },
        });

        mockGetDocs
            .mockResolvedValueOnce({ docs: [botTeam] })
            .mockResolvedValueOnce({ docs: [] });

        const { adminService } = await import('./admin.svelte');
        const result = await adminService.resetQualifyingSession(false);

        expect('teamsFixed' in result).toBe(true);
        if (!('teamsFixed' in result)) return;
        expect(result.teamsFixed).toBe(0);
    });
});

describe('adminService — applyGreatRebalanceTax', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('dry-run returns all team IDs without committing', async () => {
        mockGetDocs.mockResolvedValueOnce({
            docs: [
                makeTeamDoc('team-a', { budget: 80_000_000 }),
                makeTeamDoc('team-b', { budget: 2_000_000 }),
            ],
        });

        const { adminService } = await import('./admin.svelte');
        const result = await adminService.applyGreatRebalanceTax(true);

        expect(result).not.toBe(true);
        if (result === true) return;
        expect(result.affectedDocIds).toContain('teams/team-a');
        expect(result.affectedDocIds).toContain('teams/team-b');
        expect(mockBatchCommit).not.toHaveBeenCalled();
    });

    it('live run commits batch', async () => {
        mockGetDocs.mockResolvedValueOnce({
            docs: [makeTeamDoc('team-a', { budget: 80_000_000 })],
        });

        const { adminService } = await import('./admin.svelte');
        const result = await adminService.applyGreatRebalanceTax(false);

        expect(result).toBe(true);
        expect(mockBatchCommit).toHaveBeenCalled();
    });
});
