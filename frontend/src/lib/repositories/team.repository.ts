/**
 * Team repository — single point of contact for all Firestore team reads/writes.
 * Services import this instead of calling the Firestore SDK directly.
 * Can be swapped for an in-memory fake in unit tests.
 *
 * Note: Budget and ownership mutations MUST use runTransaction — use docRef() to get
 * the reference and pass it into the transaction block. Direct updateBudget calls are
 * prohibited per CLAUDE.md §3.3.
 */
import { db } from '$lib/firebase/config';
import { doc, getDoc } from 'firebase/firestore';
import type { Team } from '$lib/types';

export const teamRepository = {
    /**
     * Returns the Firestore DocumentReference for a team.
     * Use this when you need to pass a ref into a runTransaction block.
     */
    docRef(teamId: string) {
        return doc(db, 'teams', teamId);
    },

    /**
     * Fetches a single team by ID.
     * @returns The team with its document ID, or null if not found.
     */
    async getTeam(teamId: string): Promise<Team | null> {
        const snap = await getDoc(doc(db, 'teams', teamId));
        if (!snap.exists()) return null;
        return { id: snap.id, ...snap.data() } as Team;
    },
};
