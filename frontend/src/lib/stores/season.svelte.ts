import { onSnapshot, doc, getDoc, updateDoc, getFirestore, collection, query, orderBy, limit } from "firebase/firestore";
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
    /** Guards against repeated self-heal writes during the same session. */
    private selfHealRunning = false;

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
                console.debug('🧪 MOCK Season Active');
                this.value.season = (window as any).__MOCK_SEASON__;
                this.value.loading = false;
            }
            return;
        }

        if (this.currentSeasonId === (seasonId || "latest")) return;

        console.debug(`📡 SeasonStore: Initializing for Season ${seasonId || "Latest"}`);
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
            console.debug(`✅ SeasonStore: Loaded ${this.value.season.id}`);

            // Cross-validate calendar against race documents to catch stale isCompleted flags.
            // postRaceProcessing sometimes fails to update seasons/{id}.calendar[].isCompleted.
            this.syncFinishedEvents(seasonSnap.id, rawData.calendar ?? []);
        } else {
            console.error("❌ SeasonStore: Document not found", this.currentSeasonId);
            this.value.error = "Season document not found.";
            this.value.loading = false;
        }
    }

    /**
     * Self-heal: if seasons/{id}.calendar has events where isCompleted=false but the
     * corresponding races/{seasonId}_{eventId}.isFinished=true, patch the calendar
     * in Firestore. The onSnapshot listener will receive the updated document and
     * re-render nextEvent correctly. Idempotent — only writes when a stale flag is found.
     */
    private async syncFinishedEvents(seasonId: string, calendar: any[]) {
        if (this.selfHealRunning) return;
        this.selfHealRunning = true;
        try {
            const db = getFirestore();
            const updatedCalendar = calendar.map((e) => ({ ...e }));
            let anyUpdated = false;

            for (let i = 0; i < updatedCalendar.length; i++) {
                const event = updatedCalendar[i];
                if (event.isCompleted) continue;
                try {
                    const raceRef = doc(db, "races", `${seasonId}_${event.id}`);
                    const raceSnap = await getDoc(raceRef);
                    if (raceSnap.exists() && raceSnap.data()?.isFinished === true) {
                        updatedCalendar[i].isCompleted = true;
                        anyUpdated = true;
                        console.debug(`[SeasonStore] Stale calendar detected: ${event.id} isFinished in races/ — patching.`);
                    } else {
                        // First truly incomplete event — stop scanning
                        break;
                    }
                } catch (e) {
                    console.warn(`[SeasonStore] Could not verify race ${seasonId}_${event.id}:`, e);
                    break;
                }
            }

            if (anyUpdated) {
                try {
                    const seasonRef = doc(db, "seasons", seasonId);
                    await updateDoc(seasonRef, { calendar: updatedCalendar });
                    console.debug(`[SeasonStore] Calendar self-heal complete for ${seasonId}`);
                } catch (e) {
                    console.error("[SeasonStore] Calendar self-heal write failed:", e);
                }
            }
        } finally {
            this.selfHealRunning = false;
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
