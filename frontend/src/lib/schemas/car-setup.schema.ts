import { z } from 'zod';
import { TyreCompound, DriverStyle } from '$lib/types';

/**
 * Zod schema for CarSetup.
 * Validates all fields before writing to Firestore weekStatus.driverSetups.
 * A malformed setup (e.g. tyreCompound: null) corrupts the backend simulation.
 */
export const CarSetupSchema = z.object({
    frontWing:       z.number().min(0).max(100),
    rearWing:        z.number().min(0).max(100),
    suspension:      z.number().min(0).max(100),
    gearRatio:       z.number().min(0).max(100),
    tyreCompound:    z.nativeEnum(TyreCompound),
    pitStops:        z.array(z.nativeEnum(TyreCompound)),
    initialFuel:     z.number().min(0).max(100),
    pitStopFuel:     z.array(z.number().min(0).max(100)),
    qualifyingStyle: z.nativeEnum(DriverStyle),
    raceStyle:       z.nativeEnum(DriverStyle),
    pitStopStyles:   z.array(z.nativeEnum(DriverStyle)),
});

export type ValidatedCarSetup = z.infer<typeof CarSetupSchema>;
