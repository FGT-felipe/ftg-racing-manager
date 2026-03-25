import { db } from '$lib/firebase/config';
import { collection, query, orderBy, limit, onSnapshot } from 'firebase/firestore';
import { teamStore } from './team.svelte';
import { browser } from '$app/environment';

export interface NewsItem {
    id: string;
    title: string;
    message: string;
    type: 'INFO' | 'SUCCESS' | 'WARNING' | 'ERROR';
    timestamp: Date;
}

function createNewsStore() {
    let items = $state<NewsItem[]>([]);
    let unsubscribe: (() => void) | null = null;

    /** Start real-time listener for teams/{teamId}/news. Safe to call multiple times. */
    function init() {
        $effect(() => {
            const teamId = teamStore.value.team?.id;

            if (unsubscribe) {
                unsubscribe();
                unsubscribe = null;
            }

            if (!teamId || !browser) {
                items = [];
                return;
            }

            const q = query(
                collection(db, 'teams', teamId, 'news'),
                orderBy('timestamp', 'desc'),
                limit(10)
            );

            unsubscribe = onSnapshot(
                q,
                (snapshot) => {
                    items = snapshot.docs.map((doc) => {
                        const data = doc.data();
                        return {
                            id: doc.id,
                            title: data.title ?? '',
                            message: data.message ?? '',
                            type: data.type ?? 'INFO',
                            timestamp: (data.timestamp as any)?.toDate?.() ?? new Date(),
                        };
                    });
                },
                (err) => {
                    console.error('[newsStore] Snapshot error:', err);
                }
            );

            return () => {
                if (unsubscribe) unsubscribe();
            };
        });
    }

    return {
        get items() { return items; },
        init,
    };
}

export const newsStore = createNewsStore();
