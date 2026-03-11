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

        console.log("📡 UniverseStore: Initializing...");
        this.value.loading = true;

        const universeRef = doc(db, "universe", "game_universe_v1");

        this.unsubscribe = onSnapshot(
            universeRef,
            (snap) => {
                if (snap.exists()) {
                    this.value.universe = snap.data() as GameUniverse;
                    this.value.loading = false;
                    console.log("✅ UniverseStore: Loaded");
                } else {
                    this.value.error = "Universe document not found.";
                    this.value.loading = false;
                }
            },
            (error) => {
                console.error("❌ UniverseStore: Snapshot error:", error);
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
        return this.value.universe.leagues.find(l =>
            l.teams.some((t: any) => t.id === teamId)
        );
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

    clear() {
        if (this.unsubscribe) {
            this.unsubscribe();
            this.unsubscribe = null;
        }
        this.value.universe = null;
    }
}

export const universeStore = new UniverseStore();
