import { db } from '$lib/firebase/config';
import {
    collection,
    doc,
    runTransaction,
    serverTimestamp,
    type DocumentReference
} from 'firebase/firestore';
import {
    SponsorTier,
    SponsorSlot,
    SponsorPersonality,
    type SponsorOffer,
    type ActiveContract
} from '$lib/types';
import { notificationStore } from '$lib/stores/notifications.svelte';

export enum NegotiationStatus {
    success = 'success',
    failed = 'failed',
    locked = 'locked'
}

export interface NegotiationResult {
    status: NegotiationStatus;
    message: string;
    remainingAttempts: number;
}

export class SponsorService {
    getAvailableSponsors(
        slot: SponsorSlot,
        role: string,
        negotiations: Record<string, any>
    ): SponsorOffer[] {
        let multiplier = 1.0;
        let isAdmin = false;

        if (role === 'businessAdmin') {
            multiplier = 1.15;
            isAdmin = true;
        }

        const getRandomPersonality = () => {
            const values = Object.values(SponsorPersonality);
            return values[Math.floor(Math.random() * values.length)];
        };

        const getRandomDuration = () => 4 + Math.floor(Math.random() * 7);

        const createOffer = (params: {
            id: string,
            name: string,
            tier: SponsorTier,
            baseSign: number,
            baseWeekly: number,
            baseObj: number,
            objDesc: string
        }): SponsorOffer => ({
            id: params.id,
            name: params.name,
            tier: params.tier,
            signingBonus: Math.round(params.baseSign * multiplier),
            weeklyBasePayment: Math.round(params.baseWeekly * multiplier),
            objectiveBonus: Math.round(params.baseObj * multiplier),
            objectiveDescription: params.objDesc,
            personality: getRandomPersonality(),
            contractDuration: getRandomDuration(),
            isAdminBonusApplied: isAdmin,
            attemptsMade: 0,
            consecutiveFailuresAllowed: 2
        });

        let offers: SponsorOffer[] = [];

        switch (slot) {
            case SponsorSlot.rearWing:
                offers = [
                    createOffer({ id: 'titans_oil', name: 'Titans Oil', tier: SponsorTier.title, baseSign: 1000000, baseWeekly: 150000, baseObj: 250000, objDesc: "Finish Top 3" }),
                    createOffer({ id: 'global_tech', name: 'Global Tech', tier: SponsorTier.title, baseSign: 800000, baseWeekly: 180000, baseObj: 200000, objDesc: "Both in Points" }),
                    createOffer({ id: 'zenith_sky', name: 'Zenith Sky', tier: SponsorTier.title, baseSign: 900000, baseWeekly: 140000, baseObj: 300000, objDesc: "Race Win" }),
                ];
                break;
            case SponsorSlot.frontWing:
            case SponsorSlot.sidepods:
                offers = [
                    createOffer({ id: 'fast_logistics', name: 'Fast Logistics', tier: SponsorTier.major, baseSign: 300000, baseWeekly: 50000, baseObj: 100000, objDesc: "Finish Top 10" }),
                    createOffer({ id: 'spark_energy', name: 'Spark Energy', tier: SponsorTier.major, baseSign: 350000, baseWeekly: 40000, baseObj: 120000, objDesc: "Fastest Lap" }),
                    createOffer({ id: 'eco_pulse', name: 'Eco Pulse', tier: SponsorTier.major, baseSign: 250000, baseWeekly: 60000, baseObj: 80000, objDesc: "Finish Race" }),
                ];
                break;
            default:
                offers = [
                    createOffer({ id: 'local_drinks', name: 'Local Drinks', tier: SponsorTier.partner, baseSign: 50000, baseWeekly: 15000, baseObj: 30000, objDesc: "Finish Race" }),
                    createOffer({ id: 'micro_chips', name: 'Micro Chips', tier: SponsorTier.partner, baseSign: 70000, baseWeekly: 12000, baseObj: 40000, objDesc: "Improve Grid" }),
                    createOffer({ id: 'nitro_gear', name: 'Nitro Gear', tier: SponsorTier.partner, baseSign: 60000, baseWeekly: 18000, baseObj: 35000, objDesc: "Overtake 3 Cars" }),
                ];
        }

        // Apply state
        return offers.map(offer => {
            if (negotiations[offer.id]) {
                const state = negotiations[offer.id];
                return {
                    ...offer,
                    attemptsMade: state.attemptsMade || 0,
                    lockedUntil: state.lockedUntil ? new Date(state.lockedUntil) : null
                };
            }
            return offer;
        });
    }

    async negotiate(params: {
        teamId: string,
        offer: SponsorOffer,
        tactic: string,
        slot: SponsorSlot
    }): Promise<NegotiationResult> {
        const { teamId, offer, tactic, slot } = params;

        if (offer.attemptsMade >= 2) {
            return { status: NegotiationStatus.locked, message: "Negotiation failed too many times.", remainingAttempts: 0 };
        }

        if (offer.lockedUntil && offer.lockedUntil > new Date()) {
            return { status: NegotiationStatus.locked, message: "Sponsor is still reconsidering.", remainingAttempts: 0 };
        }

        let chance = 30;
        const personality = offer.personality.toUpperCase();
        const normalizedTactic = tactic.toUpperCase();

        let effectiveTactic = normalizedTactic;
        if (normalizedTactic === 'PERSUASIVE') effectiveTactic = 'AGGRESSIVE';
        if (normalizedTactic === 'NEGOTIATOR') effectiveTactic = 'PROFESSIONAL';
        if (normalizedTactic === 'COLLABORATIVE') effectiveTactic = 'FRIENDLY';

        if (effectiveTactic === personality) {
            chance += 50;
        } else if (effectiveTactic === 'PROFESSIONAL' || personality === 'PROFESSIONAL') {
            chance += 10;
        } else {
            chance -= 20;
        }

        const isWin = Math.random() * 100 < chance;

        if (isWin) {
            await this.signContract(teamId, offer, slot);
            return { status: NegotiationStatus.success, message: "Deal Signed!", remainingAttempts: 0 };
        } else {
            const attemptsMade = offer.attemptsMade + 1;
            const remaining = 2 - attemptsMade;
            let lockedUntil: Date | null = null;

            if (attemptsMade >= 2) {
                lockedUntil = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
            }

            await this.updateNegotiationState(teamId, {
                ...offer,
                attemptsMade,
                lockedUntil
            });

            if (attemptsMade >= 2) {
                return { status: NegotiationStatus.locked, message: "Sponsor walked away.", remainingAttempts: 0 };
            }

            return { status: NegotiationStatus.failed, message: "Negotiation failed.", remainingAttempts: remaining };
        }
    }

    private async updateNegotiationState(teamId: string, offer: SponsorOffer) {
        const teamRef = doc(db, 'teams', teamId);
        await runTransaction(db, async (transaction) => {
            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) return;

            const data = teamDoc.data();
            const weekStatus = { ...(data.weekStatus || {}) };
            const negotiations = { ...(weekStatus.sponsorNegotiations || {}) };

            negotiations[offer.id] = {
                attemptsMade: offer.attemptsMade,
                lockedUntil: offer.lockedUntil?.toISOString()
            };

            weekStatus.sponsorNegotiations = negotiations;
            transaction.update(teamRef, { weekStatus });
        });
    }

    private async signContract(teamId: string, offer: SponsorOffer, slot: SponsorSlot) {
        const teamRef = doc(db, 'teams', teamId);

        const contract: ActiveContract = {
            sponsorId: offer.id,
            sponsorName: offer.name,
            slot: slot,
            weeklyBasePayment: offer.weeklyBasePayment,
            racesRemaining: offer.contractDuration,
            currentFailures: 0
        };

        await runTransaction(db, async (transaction) => {
            const teamDoc = await transaction.get(teamRef);
            if (!teamDoc.exists()) return;

            const data = teamDoc.data();
            const currentBudget = data.budget || 0;
            const newBudget = currentBudget + offer.signingBonus;

            const sponsors = { ...(data.sponsors || {}) };
            sponsors[slot] = contract;

            const weekStatus = { ...(data.weekStatus || {}) };
            const negotiations = { ...(weekStatus.sponsorNegotiations || {}) };
            delete negotiations[offer.id];
            weekStatus.sponsorNegotiations = negotiations;

            transaction.update(teamRef, {
                budget: newBudget,
                sponsors,
                weekStatus
            });

            const txRef = doc(collection(teamRef, 'transactions'));
            transaction.set(txRef, {
                id: txRef.id,
                description: `Signing Bonus: ${offer.name}`,
                amount: offer.signingBonus,
                date: new Date().toISOString(),
                type: 'SPONSOR'
            });

            // Add Notification
            const notifRef = doc(collection(teamRef, 'notifications'));
            transaction.set(notifRef, {
                title: "New Sponsor",
                message: `Signed a new contract with ${offer.name} for the ${slot} slot.`,
                type: 'SUCCESS',
                timestamp: serverTimestamp(),
                isRead: false,
                actionRoute: '/management/sponsors'
            });
        });
    }
}

export const sponsorService = new SponsorService();
