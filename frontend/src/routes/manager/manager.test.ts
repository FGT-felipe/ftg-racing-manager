import { describe, it, expect } from 'vitest';
import { computeCareerTotals } from './career';
import type { Team } from '$lib/types';

function makeTeam(overrides: Partial<Team> = {}): Team {
    return {
        id: 'team1',
        name: 'Test FC',
        isBot: false,
        budget: 0,
        managerId: 'mgr1',
        points: 0,
        races: 0,
        wins: 0,
        podiums: 0,
        poles: 0,
        seasonPoints: 0,
        seasonRaces: 0,
        seasonWins: 0,
        seasonPodiums: 0,
        seasonPoles: 0,
        nameChangeCount: 0,
        carStats: {},
        weekStatus: {},
        sponsors: {},
        facilities: {},
        transferBudgetPercentage: 20,
        ...overrides,
    } as Team;
}

describe('computeCareerTotals', () => {
    it('returns zeros when team has no history and no current season stats', () => {
        const totals = computeCareerTotals(makeTeam());
        expect(totals).toEqual({ titles: 0, wins: 0, podiums: 0, poles: 0, races: 0 });
    });

    it('sums career fields with current season fields', () => {
        const team = makeTeam({
            wins: 10, podiums: 25, poles: 8, races: 50,
            seasonWins: 3, seasonPodiums: 5, seasonPoles: 2, seasonRaces: 9,
        });
        const totals = computeCareerTotals(team);
        expect(totals.wins).toBe(13);
        expect(totals.podiums).toBe(30);
        expect(totals.poles).toBe(10);
        expect(totals.races).toBe(59);
    });

    it('counts titles from seasonHistory isConstructorsChampion', () => {
        const team = makeTeam({
            seasonHistory: [
                { seasonId: 'S1', year: 2025, constructorsPosition: 1, points: 200, races: 18, wins: 8, podiums: 14, isConstructorsChampion: true },
                { seasonId: 'S2', year: 2026, constructorsPosition: 3, points: 120, races: 18, wins: 2, podiums: 5, isConstructorsChampion: false },
            ],
        });
        expect(computeCareerTotals(team).titles).toBe(1);
    });

    it('handles missing optional fields gracefully (undefined → 0)', () => {
        const team = makeTeam({ wins: undefined as unknown as number });
        expect(computeCareerTotals(team).wins).toBe(0);
    });
});
