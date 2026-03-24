/**
 * Driver repository — single point of contact for all Firestore driver reads/writes.
 * Services import this instead of calling the Firestore SDK directly.
 * Can be swapped for an in-memory fake in unit tests.
 */
import { db } from '$lib/firebase/config';
import { collection, doc, getDoc, getDocs, query, updateDoc, where } from 'firebase/firestore';
import type { Driver } from '$lib/types';

export const driverRepository = {
    /**
     * Returns the Firestore DocumentReference for a driver.
     * Use this when you need to pass a ref into a runTransaction block.
     */
    docRef(driverId: string) {
        return doc(db, 'drivers', driverId);
    },

    /**
     * Fetches a single driver by ID.
     * @returns The driver with its document ID, or null if not found.
     */
    async getDriver(driverId: string): Promise<Driver | null> {
        const snap = await getDoc(doc(db, 'drivers', driverId));
        if (!snap.exists()) return null;
        return { id: snap.id, ...snap.data() } as Driver;
    },

    /**
     * Fetches all drivers belonging to a team.
     * Sorted by carIndex ascending.
     */
    async getTeamDrivers(teamId: string): Promise<Driver[]> {
        const q = query(collection(db, 'drivers'), where('teamId', '==', teamId));
        const snap = await getDocs(q);
        return snap.docs
            .map(d => ({ id: d.id, ...d.data() }) as Driver)
            .sort((a, b) => a.carIndex - b.carIndex);
    },

    /**
     * Writes partial stats to a driver document.
     * For atomic updates involving budget or ownership, use runTransaction instead.
     */
    async updateDriverStats(driverId: string, stats: Record<string, unknown>): Promise<void> {
        await updateDoc(doc(db, 'drivers', driverId), { stats });
    },
};
