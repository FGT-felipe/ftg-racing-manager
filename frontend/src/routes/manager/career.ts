import type { Team } from "$lib/types";

export interface CareerTotals {
    titles: number;
    wins: number;
    podiums: number;
    poles: number;
    races: number;
}

/** Pure function — computes manager career totals from team-level fields. */
export function computeCareerTotals(team: Team): CareerTotals {
    return {
        titles:  (team.seasonHistory ?? []).filter(s => s.isConstructorsChampion).length,
        wins:    (team.wins    ?? 0) + (team.seasonWins    ?? 0),
        podiums: (team.podiums ?? 0) + (team.seasonPodiums ?? 0),
        poles:   (team.poles   ?? 0) + (team.seasonPoles   ?? 0),
        races:   (team.races   ?? 0) + (team.seasonRaces   ?? 0),
    };
}
