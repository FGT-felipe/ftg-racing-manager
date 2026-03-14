import { db } from '$lib/firebase/config';
import {
    collection,
    doc,
    runTransaction,
    serverTimestamp
} from 'firebase/firestore';
import {
    SponsorTier,
    SponsorSlot,
    SponsorPersonality,
    type SponsorOffer,
    type ActiveContract
} from '$lib/types';

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

const SPONSOR_POOL: Record<SponsorTier, { id: string, name: string, countryCode: string }[]> = {
    [SponsorTier.title]: [
        { id: 'liberty_petrol', name: 'Liberty Petroleum', countryCode: 'US' },
        { id: 'samba_bio', name: 'Samba Bio-Fuel', countryCode: 'BR' },
        { id: 'north_star', name: 'North Star Precision', countryCode: 'CA' },
        { id: 'empire_state', name: 'Empire State Capital', countryCode: 'US' },
        { id: 'titans_oil', name: 'Titans Oil', countryCode: 'US' },
        { id: 'zenith_sky', name: 'Zenith Sky', countryCode: 'GB' },
        { id: 'global_tech', name: 'Global Tech', countryCode: '' },
    ],
    [SponsorTier.major]: [
        { id: 'sol_mexico', name: 'Sol de México Logistics', countryCode: 'MX' },
        { id: 'aconcagua_energy', name: 'Aconcagua Energy', countryCode: 'AR' },
        { id: 'sao_paulo_stream', name: 'São Paulo Stream', countryCode: 'BR' },
        { id: 'spark_energy', name: 'Spark Energy', countryCode: 'US' },
        { id: 'fast_logistics', name: 'Fast Logistics', countryCode: 'DE' },
        { id: 'pampa_gear', name: 'Pampa Gear', countryCode: 'AR' },
        { id: 'eco_pulse', name: 'Eco Pulse', countryCode: '' },
    ],
    [SponsorTier.partner]: [
        { id: 'maya_micro', name: 'Maya Microchips', countryCode: 'MX' },
        { id: 'andes_techno', name: 'Andes Techno', countryCode: 'CL' },
        { id: 'caribbean_surf', name: 'Caribbean Surf', countryCode: 'VE' },
        { id: 'local_drinks', name: 'Local Drinks', countryCode: 'AR' },
        { id: 'micro_chips', name: 'Micro Chips', countryCode: 'US' },
        { id: 'nitro_gear', name: 'Nitro Gear', countryCode: 'BR' },
    ]
};

const OBJECTIVES_BY_TIER: Record<SponsorTier, { desc: string, bonus: number }[]> = {
    [SponsorTier.title]: [
        { desc: "Race Win", bonus: 300000 },
        { desc: "Finish Top 3", bonus: 250000 },
        { desc: "Double Podium", bonus: 450000 },
        { desc: "Finish Top 5", bonus: 180000 },
    ],
    [SponsorTier.major]: [
        { desc: "Finish Top 5", bonus: 150000 },
        { desc: "Finish Top 8", bonus: 110000 },
        { desc: "Finish Top 10", bonus: 100000 },
        { desc: "Fastest Lap", bonus: 120000 },
        { desc: "Home Race Win", bonus: 220000 },
    ],
    [SponsorTier.partner]: [
        { desc: "Finish Top 16", bonus: 50000 },
        { desc: "Finish Race", bonus: 40000 },
        { desc: "Improve Grid", bonus: 40000 },
        { desc: "Overtake 3 Cars", bonus: 35000 },
        { desc: "Home Race Win", bonus: 80000 },
    ]
};

export class SponsorService {
    getAvailableSponsors(
        slot: SponsorSlot,
        role: string,
        negotiations: Record<string, any>,
        activeContracts: Record<string, ActiveContract> = {}
    ): SponsorOffer[] {
        let multiplier = 1.0;
        let isAdmin = false;

        if (role === 'business') {
            multiplier = 1.15;
            isAdmin = true;
        }

        const getRandomPersonality = () => {
            const values = Object.values(SponsorPersonality);
            return values[Math.floor(Math.random() * values.length)];
        };

        const getRandomDuration = () => 4 + Math.floor(Math.random() * 7);

        // Map slot to Tier
        let targetTier = SponsorTier.partner;
        switch (slot) {
            case SponsorSlot.rearWing:
                targetTier = SponsorTier.title;
                break;
            case SponsorSlot.frontWing:
            case SponsorSlot.sidepods:
                targetTier = SponsorTier.major;
                break;
            case SponsorSlot.nose:
            case SponsorSlot.halo:
                targetTier = SponsorTier.partner;
                break;
        }

        // Base financial values by tier
        const TIER_FINANCES = {
            [SponsorTier.title]: { sign: 900000, weekly: 150000 },
            [SponsorTier.major]: { sign: 320000, weekly: 50000 },
            [SponsorTier.partner]: { sign: 65000, weekly: 15000 }
        };

        const finances = TIER_FINANCES[targetTier];
        const activeSponsorIds = new Set(Object.values(activeContracts).map(c => c.sponsorId));
        
        // Pick 3 random sponsors from pool for this tier, avoiding duplicates
        const sponsorPool = SPONSOR_POOL[targetTier].filter(s => !activeSponsorIds.has(s.id));
        const pickedSponsors = [...sponsorPool].sort(() => 0.5 - Math.random()).slice(0, 3);

        const offers: SponsorOffer[] = pickedSponsors.map((s) => {
            // Pick a random objective for this tier
            const objPool = OBJECTIVES_BY_TIER[targetTier];
            const obj = objPool[Math.floor(Math.random() * objPool.length)];

            return {
                id: s.id,
                name: s.name,
                tier: targetTier,
                countryCode: s.countryCode,
                signingBonus: Math.round(finances.sign * multiplier * (0.9 + Math.random() * 0.2)),
                weeklyBasePayment: Math.round(finances.weekly * multiplier * (0.9 + Math.random() * 0.2)),
                objectiveBonus: Math.round(obj.bonus * multiplier),
                objectiveDescription: obj.desc,
                personality: getRandomPersonality(),
                contractDuration: getRandomDuration(),
                isAdminBonusApplied: isAdmin,
                attemptsMade: 0,
                consecutiveFailuresAllowed: 2
            };
        });

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
            const attemptsMade = (offer.attemptsMade || 0) + 1;
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
            objectiveBonus: offer.objectiveBonus,
            objectiveDescription: offer.objectiveDescription,
            countryCode: offer.countryCode,
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
