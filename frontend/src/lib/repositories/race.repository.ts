/**
 * Race repository — single point of contact for all Firestore race reads.
 * The qualifying grid and race results are written by Cloud Functions, not the frontend.
 * This repository exposes read access only.
 */
import { db } from '$lib/firebase/config';
import { doc, getDoc } from 'firebase/firestore';

export const raceRepository = {
    /**
     * Returns the Firestore DocumentReference for a race document.
     * Race document IDs follow the pattern: `{seasonId}_{eventId}`.
     */
    docRef(raceId: string) {
        return doc(db, 'races', raceId);
    },

    /**
     * Fetches a race document by ID.
     * @returns Raw race data, or null if not found.
     */
    async getRace(raceId: string): Promise<Record<string, unknown> | null> {
        const snap = await getDoc(doc(db, 'races', raceId));
        if (!snap.exists()) return null;
        return { id: snap.id, ...snap.data() } as Record<string, unknown>;
    },
};
