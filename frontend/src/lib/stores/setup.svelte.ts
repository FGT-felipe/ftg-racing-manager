import { db } from '$lib/firebase/config';
import { collection, query, where, onSnapshot, orderBy, limit } from 'firebase/firestore';
import { teamStore } from './team.svelte';
import { type CarSetup } from '$lib/types';

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
        loading: false
    });

    private unsubscribe: (() => void) | null = null;

    init(teamId: string) {
        if (this.unsubscribe) return;

        console.log("📡 SetupStore: Initializing for team", teamId);
        this.value.loading = true;

        const resultsRef = collection(db, 'teams', teamId, 'practice_results');
        const q = query(resultsRef, orderBy('timestamp', 'desc'), limit(20));

        this.unsubscribe = onSnapshot(q, (snapshot) => {
            this.value.history = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            } as PracticeHistoryItem));
            this.value.loading = false;
        });
    }

    getHistoryByDriver(driverId: string) {
        return this.value.history.filter(h => h.driverId === driverId);
    }

    getBestLap(driverId: string) {
        const driverHistory = this.getHistoryByDriver(driverId).filter(h => !h.isCrashed);
        if (driverHistory.length === 0) return null;
        return Math.min(...driverHistory.map(h => h.lapTime));
    }

    clear() {
        if (this.unsubscribe) {
            this.unsubscribe();
            this.unsubscribe = null;
        }
        this.value.history = [];
        this.value.selectedDriverId = null;
    }
}

export const setupStore = new SetupStore();
