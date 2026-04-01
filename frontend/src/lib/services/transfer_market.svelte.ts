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
    arrayUnion,
    Timestamp,
} from 'firebase/firestore';
import { calculateCurrentStars, calculateDriverMarketValue } from '$lib/utils/driver';
import type { Driver } from '$lib/types';
import { t } from '$lib/utils/i18n';
import {
    TRANSFER_MARKET_BID_COMMISSION_RATE,
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
    /** Teams blacklisted from bidding (negotiation was rejected by driver). */
    rejectedNegotiationTeams?: string[];
    /** Per-team contract negotiation results. */
    pendingContracts?: Record<string, PendingContract>;
}

/** Stored on the driver document per bidding team after contract negotiation. */
export interface PendingContract {
    bidAmount: number;
    role: 'main' | 'secondary' | 'equal';
    replacedDriverId: string;
    salary: number;
    years: number;
    status: 'accepted' | 'rejected';
    negotiatedAt: Timestamp;
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
     * Immediately deducts the non-refundable buyer commission (10% of marketValue).
     * The bid modal MUST be followed by the negotiation flow — this is enforced in the UI.
     * Throws if the team is blacklisted (driver previously rejected them).
     *
     * @param driverId - Target driver document ID.
     * @param bidAmount - Proposed bid amount in USD.
     * @param myTeamId - Bidding team document ID.
     * @param myBudget - Current budget of the bidding team in USD.
     * @returns The commission amount deducted, for display in the UI.
     */
    async placeBid(
        driverId: string,
        bidAmount: number,
        myTeamId: string,
        myBudget: number
    ): Promise<{ commission: number }> {
        const driverRef = doc(db, 'drivers', driverId);
        const teamRef = doc(db, 'teams', myTeamId);
        let commission = 0;

        await runTransaction(db, async (txn) => {
            const [driverSnap, teamSnap] = await Promise.all([
                txn.get(driverRef),
                txn.get(teamRef),
            ]);

            if (!driverSnap.exists()) throw new Error('Driver not found');
            if (!teamSnap.exists()) throw new Error('Team not found');

            const data = driverSnap.data();

            // Blacklist check — driver already rejected this team's negotiation
            const rejected: string[] = data.rejectedNegotiationTeams ?? [];
            if (rejected.includes(myTeamId)) {
                throw new Error(t('market_bid_rejected_error'));
            }

            const minBid =
                data.currentHighestBid === 0
                    ? data.marketValue
                    : data.currentHighestBid + TRANSFER_MARKET_BID_INCREMENT;

            if (bidAmount < minBid)
                throw new Error(t('market_bid_min_error').replace('{amount}', formatCurrencyShort(minBid)));

            commission = Math.round((data.marketValue ?? bidAmount) * TRANSFER_MARKET_BID_COMMISSION_RATE);
            const totalRequired = bidAmount + commission;
            const currentBudget = teamSnap.data().budget ?? 0;

            if (currentBudget < totalRequired) {
                throw new Error(
                    t('market_bid_budget_error')
                        .replace('{bid}', formatCurrencyShort(bidAmount))
                        .replace('{commission}', formatCurrencyShort(commission))
                );
            }

            // Deduct commission immediately (non-refundable)
            txn.update(teamRef, { budget: currentBudget - commission });

            // Register commission transaction record
            const txColRef = collection(teamRef, 'transactions');
            const txDocRef = doc(txColRef);
            txn.set(txDocRef, {
                id: txDocRef.id,
                description: t('transaction_bid_commission').replace('{name}', data.name ?? driverId),
                amount: -commission,
                date: new Date().toISOString(),
                type: 'TRANSFER',
            });

            // Update bid on driver (only if higher than current)
            const updates: Record<string, any> = {};
            if (bidAmount > (data.currentHighestBid ?? 0)) {
                updates.currentHighestBid = bidAmount;
                updates.highestBidderTeamId = myTeamId;
            }
            if (Object.keys(updates).length > 0) {
                txn.update(driverRef, updates);
            }
        });

        return { commission };
    },

    /**
     * Records the successful result of a contract negotiation for a specific team.
     * Called after the manager completes NegotiationModal with driver acceptance.
     * The driver is NOT transferred yet — the resolver does that at auction end.
     *
     * @param driverId - Target driver document ID.
     * @param teamId - The team that negotiated the contract.
     * @param contract - Agreed contract terms (role, replacement, salary, years, bid amount).
     */
    async submitContractAccepted(
        driverId: string,
        teamId: string,
        contract: Omit<PendingContract, 'status' | 'negotiatedAt'>
    ): Promise<void> {
        const driverRef = doc(db, 'drivers', driverId);
        await updateDoc(driverRef, {
            [`pendingContracts.${teamId}`]: {
                ...contract,
                status: 'accepted',
                negotiatedAt: Timestamp.now(),
            } satisfies PendingContract,
        });
    },

    /**
     * Records a failed negotiation for a team. Adds the team to the driver's blacklist
     * so they cannot bid again. If the team was the current highest bidder, clears that
     * field so the auction reopens to the next valid bidder.
     *
     * @param driverId - Target driver document ID.
     * @param teamId - The team whose negotiation was rejected.
     * @param bidAmount - The team's bid amount (for clearing highestBid if applicable).
     * @param moraleChange - Cumulative morale delta to apply to the driver (≤ 0).
     */
    async submitContractRejected(
        driverId: string,
        teamId: string,
        bidAmount: number,
        moraleChange: number
    ): Promise<void> {
        const driverRef = doc(db, 'drivers', driverId);

        await runTransaction(db, async (txn) => {
            const snap = await txn.get(driverRef);
            if (!snap.exists()) return;
            const data = snap.data();

            const updates: Record<string, any> = {
                [`pendingContracts.${teamId}`]: {
                    bidAmount,
                    status: 'rejected',
                    negotiatedAt: Timestamp.now(),
                },
                rejectedNegotiationTeams: arrayUnion(teamId),
            };

            // Apply morale penalty to driver for negotiation failure
            if (moraleChange !== 0) {
                const current = data.stats?.morale ?? 70;
                updates['stats.morale'] = Math.max(0, Math.min(100, current + moraleChange));
            }

            // If this team was the highest bidder, clear so auction reopens
            if (data.highestBidderTeamId === teamId) {
                // Find next valid bid from pendingContracts (accepted status, highest amount)
                const contracts: Record<string, PendingContract> = data.pendingContracts ?? {};
                let nextBestBid = 0;
                let nextBestTeam: string | null = null;
                for (const [tid, c] of Object.entries(contracts)) {
                    if (tid !== teamId && c.status === 'accepted' && c.bidAmount > nextBestBid) {
                        nextBestBid = c.bidAmount;
                        nextBestTeam = tid;
                    }
                }
                updates.currentHighestBid = nextBestBid;
                updates.highestBidderTeamId = nextBestTeam ?? null;
            }

            txn.update(driverRef, updates);
        });
    },

    /**
     * Cancels the calling team's bid on a driver, resetting bid fields to zero.
     * Only allowed if the team has NOT yet negotiated (no entry in pendingContracts).
     *
     * @param driverId - Target driver document ID.
     * @param myTeamId - Team cancelling the bid.
     */
    async cancelBid(driverId: string, myTeamId: string): Promise<void> {
        const driverRef = doc(db, 'drivers', driverId);
        await runTransaction(db, async (txn) => {
            const snap = await txn.get(driverRef);
            if (!snap.exists()) return;
            const data = snap.data();

            // If this team already negotiated, cannot cancel
            const contracts: Record<string, any> = data.pendingContracts ?? {};
            if (contracts[myTeamId]) {
                throw new Error('No puedes cancelar una puja una vez iniciada la negociación.');
            }

            const updates: Record<string, any> = {};
            if (data.highestBidderTeamId === myTeamId) {
                updates.currentHighestBid = 0;
                updates.highestBidderTeamId = null;
            }
            if (Object.keys(updates).length > 0) {
                txn.update(driverRef, updates);
            }
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
     * In the new T-028 flow this is ONLY used as a fallback safety net for listings
     * that expired while the buyer had an accepted contract but no transfer was executed.
     *
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
