import { db } from '$lib/firebase/config';
import {
    collection,
    query,
    where,
    orderBy,
    limit,
    startAfter,
    getDocs,
    doc,
    runTransaction,
    updateDoc,
    Timestamp,
} from 'firebase/firestore';
import { calculateCurrentStars, calculateDriverMarketValue } from '$lib/utils/driver';
import type { Driver } from '$lib/types';
import {
    TRANSFER_MARKET_BID_INCREMENT,
    TRANSFER_LISTING_DURATION_HOURS,
} from '$lib/constants/economics';

export const MARKET_PAGE_SIZE = 15;

const TRANSFER_LISTING_MS = TRANSFER_LISTING_DURATION_HOURS * 3600 * 1000;

export interface MarketDriver {
    id: string;
    name: string;
    age: number;
    gender?: string;
    countryCode?: string;
    role?: string;
    currentStars: number;
    potential: number;
    salary: number;
    contractYearsRemaining: number;
    marketValue: number;
    currentHighestBid: number;
    highestBidderTeamId?: string;
    teamId?: string;
    transferListedAt?: any;
    isTransferListed?: boolean;
    stats?: Record<string, number>;
}

function formatCurrencyShort(value: number): string {
    if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
    if (value >= 1_000) return `$${(value / 1_000).toFixed(0)}K`;
    return `$${value}`;
}

export const transferMarketService = {
    /**
     * Fetches a paginated page of active transfer market listings.
     * @param pageIndex - Zero-based page index.
     * @param pageHistory - Array of Firestore cursor documents for pagination.
     * @returns Drivers on this page and the last document cursor.
     */
    async fetchPage(
        pageIndex: number,
        pageHistory: any[]
    ): Promise<{ drivers: MarketDriver[]; lastDoc: any }> {
        const cutoff = Timestamp.fromMillis(Date.now() - TRANSFER_LISTING_MS);
        const constraints: any[] = [
            where('isTransferListed', '==', true),
            where('transferListedAt', '>', cutoff),
            orderBy('transferListedAt'),
            limit(MARKET_PAGE_SIZE),
        ];

        const cursor = pageHistory[pageIndex];
        if (pageIndex > 0 && cursor) {
            constraints.push(startAfter(cursor));
        }

        const snap = await getDocs(query(collection(db, 'drivers'), ...constraints));
        const docs = snap.docs;
        const drivers = docs.map((d: any) => {
            const raw = { id: d.id, ...d.data() } as MarketDriver;
            raw.currentStars = calculateCurrentStars(raw as any);
            if (!raw.marketValue) {
                raw.marketValue = calculateDriverMarketValue(raw as any);
            }
            return raw;
        });

        return { drivers, lastDoc: docs.length > 0 ? docs[docs.length - 1] : null };
    },

    /**
     * Places a bid on a transfer-listed driver via a Firestore transaction.
     * @param driverId - Target driver document ID.
     * @param bidAmount - Proposed bid amount in USD.
     * @param myTeamId - Bidding team document ID.
     * @param myBudget - Current budget of the bidding team in USD.
     */
    async placeBid(
        driverId: string,
        bidAmount: number,
        myTeamId: string,
        myBudget: number
    ): Promise<void> {
        const driverRef = doc(db, 'drivers', driverId);
        await runTransaction(db, async (txn) => {
            const snap = await txn.get(driverRef);
            if (!snap.exists()) throw new Error('Driver not found');
            const data = snap.data();
            const minBid =
                data.currentHighestBid === 0
                    ? data.marketValue
                    : data.currentHighestBid + TRANSFER_MARKET_BID_INCREMENT;
            if (bidAmount < minBid)
                throw new Error(`Bid must be at least ${formatCurrencyShort(minBid)}`);
            if (bidAmount > myBudget) throw new Error('Insufficient budget');
            txn.update(driverRef, {
                currentHighestBid: bidAmount,
                highestBidderTeamId: myTeamId,
            });
        });
    },

    /**
     * Cancels the calling team's bid on a driver, resetting bid fields to zero.
     * @param driverId - Target driver document ID.
     */
    async cancelBid(driverId: string): Promise<void> {
        await updateDoc(doc(db, 'drivers', driverId), {
            currentHighestBid: 0,
            highestBidderTeamId: null,
        });
    },

    /**
     * Removes a driver from the transfer market listing (owner team only).
     * @param driverId - Target driver document ID.
     */
    async cancelTransfer(driverId: string): Promise<void> {
        await updateDoc(doc(db, 'drivers', driverId), {
            isTransferListed: false,
            transferListedAt: null,
        });
    },

    /**
     * Fetches drivers with a pending negotiation assigned to the given team.
     * @param myTeamId - Team document ID to filter by.
     * @returns Array of Driver objects awaiting negotiation completion.
     */
    async fetchPendingNegotiations(myTeamId: string): Promise<Driver[]> {
        const snap = await getDocs(
            query(
                collection(db, 'drivers'),
                where('pendingNegotiation', '==', true),
                where('pendingBuyerTeamId', '==', myTeamId)
            )
        );
        return snap.docs.map((d: any) => {
            const raw = { id: d.id, ...d.data() } as Driver;
            (raw as any).currentStars = calculateCurrentStars(raw);
            if (!raw.marketValue) raw.marketValue = calculateDriverMarketValue(raw);
            return raw;
        });
    },
};
