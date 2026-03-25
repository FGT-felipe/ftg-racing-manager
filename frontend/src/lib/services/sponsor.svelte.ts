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
import { ActiveContractSchema } from '$lib/schemas/sponsor.schema';
import {
    SPONSOR_TIER_FINANCES,
    SPONSOR_OBJECTIVE_BONUSES,
    SPONSOR_BUSINESS_MULTIPLIER,
    SPONSOR_MAX_NEGOTIATION_ATTEMPTS,
    SPONSOR_OFFERS_PER_SLOT,
    SPONSOR_CONTRACT_DURATION_MIN,
    SPONSOR_CONTRACT_DURATION_RANGE,
} from '$lib/constants/economics';

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
        { desc: "Race Win",      bonus: SPONSOR_OBJECTIVE_BONUSES.title.race_win },
        { desc: "Finish Top 3",  bonus: SPONSOR_OBJECTIVE_BONUSES.title.top_3 },
        { desc: "Double Podium", bonus: SPONSOR_OBJECTIVE_BONUSES.title.double_podium },
        { desc: "Finish Top 5",  bonus: SPONSOR_OBJECTIVE_BONUSES.title.top_5 },
    ],
    [SponsorTier.major]: [
        { desc: "Finish Top 5",  bonus: SPONSOR_OBJECTIVE_BONUSES.major.top_5 },
        { desc: "Finish Top 8",  bonus: SPONSOR_OBJECTIVE_BONUSES.major.top_8 },
        { desc: "Finish Top 10", bonus: SPONSOR_OBJECTIVE_BONUSES.major.top_10 },
        { desc: "Fastest Lap",   bonus: SPONSOR_OBJECTIVE_BONUSES.major.fastest_lap },
        { desc: "Home Race Win", bonus: SPONSOR_OBJECTIVE_BONUSES.major.home_win },
    ],
    [SponsorTier.partner]: [
        { desc: "Finish Top 16",  bonus: SPONSOR_OBJECTIVE_BONUSES.partner.top_16 },
        { desc: "Finish Race",    bonus: SPONSOR_OBJECTIVE_BONUSES.partner.finish_race },
        { desc: "Improve Grid",   bonus: SPONSOR_OBJECTIVE_BONUSES.partner.improve_grid },
        { desc: "Overtake 3 Cars",bonus: SPONSOR_OBJECTIVE_BONUSES.partner.overtake_3 },
        { desc: "Home Race Win",  bonus: SPONSOR_OBJECTIVE_BONUSES.partner.home_win },
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
            multiplier = SPONSOR_BUSINESS_MULTIPLIER;
            isAdmin = true;
        }

        const getRandomPersonality = () => {
            const values = Object.values(SponsorPersonality);
            return values[Math.floor(Math.random() * values.length)];
        };

        const getRandomDuration = () => SPONSOR_CONTRACT_DURATION_MIN + Math.floor(Math.random() * SPONSOR_CONTRACT_DURATION_RANGE);

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

        const finances = SPONSOR_TIER_FINANCES[targetTier];
        const activeSponsorIds = new Set(Object.values(activeContracts).map(c => c.sponsorId));
        
        // Pick 3 random sponsors from pool for this tier, avoiding duplicates
        const sponsorPool = SPONSOR_POOL[targetTier].filter(s => !activeSponsorIds.has(s.id));
        const pickedSponsors = [...sponsorPool].sort(() => 0.5 - Math.random()).slice(0, SPONSOR_OFFERS_PER_SLOT);

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

        if (offer.attemptsMade >= SPONSOR_MAX_NEGOTIATION_ATTEMPTS) {
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
            const remaining = SPONSOR_MAX_NEGOTIATION_ATTEMPTS - attemptsMade;
            let lockedUntil: Date | null = null;

            if (attemptsMade >= SPONSOR_MAX_NEGOTIATION_ATTEMPTS) {
                lockedUntil = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
            }

            await this.updateNegotiationState(teamId, {
                ...offer,
                attemptsMade,
                lockedUntil
            });

            if (attemptsMade >= SPONSOR_MAX_NEGOTIATION_ATTEMPTS) {
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

        const parsed = ActiveContractSchema.safeParse(contract);
        if (!parsed.success) {
            console.error('[SponsorService:signContract] Invalid ActiveContract — aborting Firestore write:', parsed.error.flatten());
            throw new Error(`Invalid contract: ${parsed.error.issues.map(i => i.message).join(', ')}`);
        }

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
