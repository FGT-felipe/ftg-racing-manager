import { db } from '$lib/firebase/config';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import { teamStore } from '$lib/stores/team.svelte';
import { browser } from '$app/environment';
import type { Driver } from '$lib/types';

export function createDriverStore() {
    let drivers = $state<Driver[]>([]);
    let isLoading = $state(true);
    let unsubscribe: (() => void) | null = null;

    function init() {
        $effect(() => {
            const teamId = teamStore.value.team?.id;

            if (unsubscribe) {
                unsubscribe();
                unsubscribe = null;
            }

            if (!teamId) {
                drivers = [];
                isLoading = false;
                return;
            }

            if (!browser) return;

            isLoading = true;
            const q = query(
                collection(db, 'drivers'),
                where('teamId', '==', teamId)
            );

            unsubscribe = onSnapshot(q, (snapshot) => {
                drivers = snapshot.docs.map(doc => ({
                    id: doc.id,
                    ...doc.data()
                })) as Driver[];

                // Sort by carIndex
                drivers.sort((a, b) => a.carIndex - b.carIndex);

                isLoading = false;
            }, (error) => {
                console.error("Error fetching team drivers:", error);
                isLoading = false;
            });

            return () => {
                if (unsubscribe) unsubscribe();
            };
        });
    }

    return {
        get drivers() { return drivers; },
        get isLoading() { return isLoading; },
        get carADriver() { return drivers.find(d => d.carIndex === 0); },
        get carBDriver() { return drivers.find(d => d.carIndex === 1); },
        init
    };
}

export const driverStore = createDriverStore();
