import { db } from '$lib/firebase/config';
import { collection, onSnapshot } from 'firebase/firestore';
import { browser } from '$app/environment';
import { authStore } from '$lib/stores/auth.svelte';
import { partsWearService } from '$lib/services/parts_wear_service.svelte';
import type { Part, ConditionTier } from '$lib/types';

function createPartsStore() {
    let parts = $state<Record<string, Part>>({});
    let isLoading = $state(true);
    let unsubscribe: (() => void) | null = null;

    return {
        /**
         * Starts a Firestore onSnapshot listener on the parts sub-collection for
         * the given team / car slot. Call once when team data is available.
         * Returns the unsubscribe function for cleanup in $effect.
         *
         * @param teamId - Firestore team document ID
         * @param carIndex - Car slot index (0 = Car A)
         */
        init(teamId: string, carIndex: number): () => void {
            if (!browser || !authStore.user) {
                isLoading = false;
                return () => {};
            }

            if (unsubscribe) {
                unsubscribe();
                unsubscribe = null;
            }

            isLoading = true;
            const partsCol = collection(db, 'teams', teamId, 'cars', String(carIndex), 'parts');

            unsubscribe = onSnapshot(
                partsCol,
                (snap) => {
                    const updated: Record<string, Part> = {};
                    snap.docs.forEach((d) => {
                        updated[d.id] = { ...d.data(), updatedAt: d.data().updatedAt?.toDate() ?? null } as Part;
                    });
                    parts = updated;
                    isLoading = false;
                },
                (err) => {
                    console.error('[PartsStore] onSnapshot error:', err);
                    isLoading = false;
                }
            );

            return () => {
                if (unsubscribe) {
                    unsubscribe();
                    unsubscribe = null;
                }
            };
        },

        get loading() {
            return isLoading;
        },

        /** Returns the engine Part document, or null if not yet seeded. */
        get enginePart(): Part | null {
            return parts['engine'] ?? null;
        },

        /**
         * Returns the raw condition value for a part (0–100), defaulting to 100
         * when the part document does not exist (backward compat — AC#8).
         */
        getCondition(partId: string): number {
            return parts[partId]?.condition ?? 100;
        },

        /** Returns the visual tier for a part's current condition. */
        getTier(partId: string): ConditionTier {
            return partsWearService.getConditionTier(this.getCondition(partId));
        },
    };
}

export const partsStore = createPartsStore();
