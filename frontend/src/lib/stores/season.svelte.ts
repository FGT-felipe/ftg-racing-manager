import { onSnapshot, doc, getFirestore, collection, query, orderBy, limit } from "firebase/firestore";
import { teamStore } from "./team.svelte";
import type { Season, RaceEvent } from "../types";
import { browser } from "$app/environment";

// Firebase App is already initialized in authStore / teamStore flow
const db = getFirestore();

class SeasonStore {
    // Svelte 5 runes
    value = $state<{
        season: Season | null;
        loading: boolean;
        error: string | null;
    }>({
        season: null,
        loading: true,
        error: null,
    });

    private unsubscribe: (() => void) | null = null;
    private currentSeasonId: string | null = null;

    // Derived store logic to get the next upcoming event
    get nextRace() {
        if (!this.value.season || !this.value.season.calendar) {
            // Failsafe Mock for local UI testing
            return {
                id: 'mock-race-id',
                circuitId: 'barcelona',
                trackName: 'Circuit de Barcelona-Catalunya',
                flagEmoji: '🇪🇸',
                totalLaps: 50,
                weatherPractice: 'Sunny',
                weatherQualifying: 'Sunny',
                weatherRace: 'Sunny'
            } as any;
        }
        return this.value.season.calendar.find((event) => !event.isCompleted) || null;
    }

    // Keep nextEvent for backward compatibility if any component uses it
    get nextEvent() {
        return this.nextRace;
    }

    init(seasonId?: string) {
        // Support for Playwright/Testing Mocking
        if (browser && (window as any).__MOCK_SEASON__) {
            if (this.value.season !== (window as any).__MOCK_SEASON__) {
                console.log('🧪 MOCK Season Active');
                this.value.season = (window as any).__MOCK_SEASON__;
                this.value.loading = false;
            }
            return;
        }

        if (this.currentSeasonId === (seasonId || "latest")) return;

        console.log(`📡 SeasonStore: Initializing for Season ${seasonId || "Latest"}`);
        this.clear();
        this.currentSeasonId = seasonId || "latest";
        this.value.loading = true;

        if (seasonId) {
            // Fetch specific season by ID
            const seasonRef = doc(db, "seasons", seasonId);
            this.unsubscribe = onSnapshot(
                seasonRef,
                (seasonSnap) => this.handleSnapshot(seasonSnap),
                (error) => this.handleError(error)
            );
        } else {
            // Fetch 'active' season via query like Flutter: orderBy startDate desc, limit 1
            const q = query(collection(db, "seasons"), orderBy("startDate", "desc"), limit(1));
            this.unsubscribe = onSnapshot(
                q,
                (querySnap: any) => {
                    if (!querySnap.empty) {
                        this.handleSnapshot(querySnap.docs[0]);
                    } else {
                        console.error("❌ SeasonStore: No active season found in query.");
                        this.value.error = "No active season found.";
                        this.value.loading = false;
                    }
                },
                (error: any) => this.handleError(error)
            );
        }
    }

    private handleSnapshot(seasonSnap: any) {
        if (seasonSnap.exists()) {
            const rawData = seasonSnap.data();
            if (rawData.calendar) {
                // Ensure dates are parsed from Firestore Timestamps
                rawData.calendar = rawData.calendar.map((e: any) => ({
                    ...e,
                    date: e.date?.toDate ? e.date.toDate() : (e.date ? new Date(e.date) : null)
                }));
            }

            this.value.season = {
                id: seasonSnap.id,
                ...rawData
            } as Season;

            this.value.loading = false;
            console.log(`✅ SeasonStore: Loaded ${this.value.season.id}`);
        } else {
            console.error("❌ SeasonStore: Document not found", this.currentSeasonId);
            this.value.error = "Season document not found.";
            this.value.loading = false;
        }
    }

    private handleError(error: any) {
        console.error("❌ SeasonStore: Snapshot error:", error);
        this.value.error = error.message;
        this.value.loading = false;
    }

    clear() {
        if (this.unsubscribe) {
            this.unsubscribe();
            this.unsubscribe = null;
        }
        this.currentSeasonId = null;
        this.value.season = null;
        this.value.loading = false;
        this.value.error = null;
    }
}

export const seasonStore = new SeasonStore();
