import { type CarSetup } from '$lib/types';

/**
 * Legacy setup history store.
 *
 * Historically this subscribed to the `teams/{teamId}/practice_results`
 * Firestore subcollection. That subcollection has NO writer anywhere in the
 * codebase (neither frontend nor Cloud Functions) — any documents sitting in
 * it are leftover state from the deprecated Flutter build. Reading it caused
 * practice history from previous race weekends to bleed into the current
 * round forever.
 *
 * The store is kept as a no-op shim so existing call sites (PracticePanel,
 * PracticeSetupTab) continue to compile. The source of truth for
 * per-weekend practice runs is `driverSetups[driverId].practiceRuns[]`,
 * which is already session-gated at the component level.
 */
export interface PracticeHistoryItem {
    id: string;
    driverId: string;
    lapTime: number;
    setupUsed: CarSetup;
    feedback: string[];
    setupConfidence: number;
    isCrashed: boolean;
    timestamp: any;
}

class SetupStore {
    value = $state<{
        selectedDriverId: string | null;
        history: PracticeHistoryItem[];
        loading: boolean;
    }>({
        selectedDriverId: null,
        history: [],
        loading: false,
    });

    init(_teamId: string) {
        // no-op: legacy practice_results subcollection is abandoned
    }

    getHistoryByDriver(_driverId: string): PracticeHistoryItem[] {
        return [];
    }

    getBestLap(_driverId: string): number | null {
        return null;
    }

    clear() {
        this.value.history = [];
        this.value.selectedDriverId = null;
    }
}

export const setupStore = new SetupStore();
