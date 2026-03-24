import { z } from 'zod';
import { SponsorSlot } from '$lib/types';

/**
 * Zod schema for ActiveContract.
 * Validates the contract object before writing to Firestore sponsors.{slot}.
 * Missing fields break post-race sponsor payment processing in the backend.
 */
export const ActiveContractSchema = z.object({
    sponsorId:            z.string().min(1, 'sponsorId cannot be empty'),
    sponsorName:          z.string().min(1, 'sponsorName cannot be empty'),
    slot:                 z.nativeEnum(SponsorSlot),
    currentFailures:      z.number().min(0),
    weeklyBasePayment:    z.number().min(0),
    objectiveBonus:       z.number().min(0),
    objectiveDescription: z.string().min(1, 'objectiveDescription cannot be empty'),
    countryCode:          z.string().optional(),
    racesRemaining:       z.number().min(0),
});

export type ValidatedActiveContract = z.infer<typeof ActiveContractSchema>;
