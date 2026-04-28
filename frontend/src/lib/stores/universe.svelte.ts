import { onSnapshot, doc, getFirestore } from "firebase/firestore";
import type { League, Team, Driver } from "../types";

const db = getFirestore();

interface GameUniverse {
    leagues: any[];
    activeSeasonId?: string;
}

class UniverseStore {
    value = $state<{
        universe: GameUniverse | null;
        loading: boolean;
        error: string | null;
    }>({
        universe: null,
        loading: true,
        error: null,
    });

    private unsubscribe: (() => void) | null = null;

    init() {
        if (this.unsubscribe) return;

        console.debug("[UniverseStore] Initializing: Setting up Firestore snapshot listener for 'game_universe_v1'.");
        this.value.loading = true;

        const universeRef = doc(db, "universe", "game_universe_v1");

        this.unsubscribe = onSnapshot(
            universeRef,
            (snap) => {
                if (snap.exists()) {
                    const data = snap.data();

                    this.value.universe = data as GameUniverse;
                    this.value.loading = false;
                    console.debug("[UniverseStore] Snapshot update: Universe loaded successfully.", {
                        leaguesCount: this.value.universe?.leagues?.length || 0,
                        activeSeasonId: this.value.universe?.activeSeasonId
                    });
                } else {
                    console.error("[UniverseStore] Snapshot update: Universe document not found in Firestore.");
                    this.value.error = "Universe document not found.";
                    this.value.loading = false;
                }
            },
            (error) => {
                console.error("[UniverseStore] Snapshot subscription failed:", error);
                this.value.error = error.message;
                this.value.loading = false;
                // Allow re-initialization after auth completes
                if (this.unsubscribe) {
                    this.unsubscribe();
                    this.unsubscribe = null;
                }
            }
        );
    }

    getLeagueByTeamId(teamId: string) {
        if (!this.value.universe) return null;
        const league = this.value.universe.leagues.find(l =>
            l.teams.some((t: any) => t.id === teamId)
        );
        console.debug(`[UniverseStore] getLeagueByTeamId searching for ${teamId}: ${league ? 'Found ' + league.name : 'NOT FOUND'}`);
        return league;
    }

    getTeamStanding(teamId: string) {
        const league = this.getLeagueByTeamId(teamId);
        if (!league) return null;

        const sortedTeams = [...league.teams].sort((a, b) =>
            (b.seasonPoints || 0) - (a.seasonPoints || 0)
        );

        const index = sortedTeams.findIndex(t => t.id === teamId);
        return {
            position: index + 1,
            total: sortedTeams.length,
            points: sortedTeams[index]?.seasonPoints || 0
        };
    }

    getDriverStandings(teamId: string) {
        const league = this.getLeagueByTeamId(teamId);
        if (!league) return [];

        const sortedDrivers = [...league.drivers].sort((a, b) =>
            (b.seasonPoints || 0) - (a.seasonPoints || 0)
        );

        return sortedDrivers
            .map((d, i) => ({ ...d, position: i + 1 }))
            .filter(d => d.teamId === teamId);
    }

    /** All teams in the player's league, sorted P1→P10 by seasonPoints desc, with 1-based position. */
    getAllTeamStandings(teamId: string) {
        const league = this.getLeagueByTeamId(teamId);
        if (!league) return [];
        return [...(league.teams as any[])]
            .sort((a, b) => (b.seasonPoints || 0) - (a.seasonPoints || 0))
            .map((team, idx) => ({ ...team, position: idx + 1 }));
    }

    /** Drivers champion in the player's league. Tie-break: wins → podiums → id asc. Enriched with teamName. */
    getDriversChampion(teamId: string) {
        const league = this.getLeagueByTeamId(teamId);
        if (!league || !(league.drivers as any[])?.length) return null;
        const champion = [...(league.drivers as any[])].sort((a, b) => {
            const pts = (b.seasonPoints || 0) - (a.seasonPoints || 0);
            if (pts !== 0) return pts;
            const wins = (b.seasonWins || 0) - (a.seasonWins || 0);
            if (wins !== 0) return wins;
            const pods = (b.seasonPodiums || 0) - (a.seasonPodiums || 0);
            if (pods !== 0) return pods;
            return a.id < b.id ? -1 : a.id > b.id ? 1 : 0;
        })[0] ?? null;
        if (champion) {
            const team = (league.teams as any[])?.find((t: any) => t.id === champion.teamId);
            champion.teamName = team?.name ?? '';
        }
        return champion;
    }

    getDriverById(driverId: string) {
        if (!this.value.universe) return null;
        for (const league of this.value.universe.leagues) {
            if (!league.drivers) continue;
            const driver = league.drivers.find((d: any) => d.id === driverId);
            if (driver) return driver;
        }
        return null;
    }

    clear() {
        if (this.unsubscribe) {
            this.unsubscribe();
            this.unsubscribe = null;
        }
        this.value.universe = null;
    }
}

export const universeStore = new UniverseStore();
