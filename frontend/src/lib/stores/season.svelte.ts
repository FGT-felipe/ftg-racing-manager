import { onSnapshot, doc, getFirestore } from "firebase/firestore";
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

    init(seasonId: string) {
        // Support for Playwright/Testing Mocking
        if (browser && (window as any).__MOCK_SEASON__) {
            if (this.value.season !== (window as any).__MOCK_SEASON__) {
                console.log('🧪 MOCK Season Active');
                this.value.season = (window as any).__MOCK_SEASON__;
                this.value.loading = false;
            }
            return;
        }

        if (!seasonId) {
            this.value.loading = false;
            this.value.season = null;
            return;
        }
        if (this.currentSeasonId === seasonId) return;

        console.log(`📡 SeasonStore: Initializing for Season ${seasonId}`);
        this.clear();
        this.currentSeasonId = seasonId;
        this.value.loading = true;

        const seasonRef = doc(db, "seasons", seasonId);

        this.unsubscribe = onSnapshot(
            seasonRef,
            (seasonSnap) => {
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
                    console.error("❌ SeasonStore: Document not found", seasonId);
                    this.value.error = "Season document not found.";
                    this.value.loading = false;
                }
            },
            (error) => {
                console.error("❌ SeasonStore: Snapshot error:", error);
                this.value.error = error.message;
                this.value.loading = false;
            }
        );
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
