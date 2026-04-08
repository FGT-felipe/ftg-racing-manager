import { type CarSetup } from '$lib/types';

export interface CircuitProfile {
    id: string;
    name: string;
    flagEmoji: string;
    countryCode: string;
    baseLapTime: number;
    laps: number;
    tyreWearMultiplier: number;
    fuelConsumptionMultiplier: number;
    aeroWeight: number;
    powertrainWeight: number;
    chassisWeight: number;
    idealSetup: Pick<CarSetup, 'frontWing' | 'rearWing' | 'suspension' | 'gearRatio'>;
    difficulty: number;
    characteristics: Record<string, string>;
}

/** Dynamically derived trait badge for a circuit component. */
export interface CircuitComponentTrait {
    label: string;
    tooltipKey: string;
}

class CircuitService {
    private circuits: Record<string, CircuitProfile> = {
        mexico: {
            id: 'mexico',
            name: 'Autódromo Hermanos Rodríguez',
            countryCode: 'MX',
            flagEmoji: '🇲🇽',
            baseLapTime: 76.0,
            laps: 71,
            tyreWearMultiplier: 1.1,
            fuelConsumptionMultiplier: 1.0,
            aeroWeight: 0.4,
            powertrainWeight: 0.4,
            chassisWeight: 0.2,
            idealSetup: { frontWing: 80, rearWing: 75, suspension: 50, gearRatio: 85 },
            difficulty: 0.6,
            characteristics: { 'Tyre Wear': 'Medium', 'Fuel Consumption': 'Normal' },
        },
        vegas: {
            id: 'vegas',
            name: 'Las Vegas Strip Circuit',
            countryCode: 'US',
            flagEmoji: '🇺🇸',
            baseLapTime: 92.0,
            laps: 50,
            tyreWearMultiplier: 0.8,
            fuelConsumptionMultiplier: 1.1,
            aeroWeight: 0.2,
            powertrainWeight: 0.6,
            chassisWeight: 0.2,
            idealSetup: { frontWing: 25, rearWing: 20, suspension: 70, gearRatio: 90 },
            difficulty: 0.5,
            characteristics: { 'Tyre Wear': 'Low', 'Fuel Consumption': 'High' },
        },
        interlagos: {
            id: 'interlagos',
            name: 'Autódromo José Carlos Pace',
            countryCode: 'BR',
            flagEmoji: '🇧🇷',
            baseLapTime: 70.5,
            laps: 71,
            tyreWearMultiplier: 1.2,
            fuelConsumptionMultiplier: 1.2,
            aeroWeight: 0.3,
            powertrainWeight: 0.3,
            chassisWeight: 0.4,
            idealSetup: { frontWing: 65, rearWing: 60, suspension: 45, gearRatio: 55 },
            difficulty: 0.6,
            characteristics: { 'Tyre Wear': 'High', 'Fuel Consumption': 'High' },
        },
        miami: {
            id: 'miami',
            name: 'Miami International Autodrome',
            countryCode: 'US',
            flagEmoji: '🇺🇸',
            baseLapTime: 90.0,
            laps: 57,
            tyreWearMultiplier: 1.0,
            fuelConsumptionMultiplier: 1.0,
            aeroWeight: 0.4,
            powertrainWeight: 0.3,
            chassisWeight: 0.3,
            idealSetup: { frontWing: 55, rearWing: 50, suspension: 60, gearRatio: 65 },
            difficulty: 0.5,
            characteristics: { 'Tyre Wear': 'Normal', 'Fuel Consumption': 'Normal' },
        },
        san_pablo_street: {
            id: 'san_pablo_street',
            name: 'São Paulo Street Circuit',
            countryCode: 'BR',
            flagEmoji: '🇧🇷',
            baseLapTime: 82.0,
            laps: 40,
            tyreWearMultiplier: 1.3,
            fuelConsumptionMultiplier: 1.3,
            aeroWeight: 0.2,
            powertrainWeight: 0.2,
            chassisWeight: 0.6,
            idealSetup: { frontWing: 85, rearWing: 80, suspension: 30, gearRatio: 35 },
            difficulty: 0.7,
            characteristics: { 'Tyre Wear': 'High', 'Fuel Consumption': 'High' },
        },
        indianapolis: {
            id: 'indianapolis',
            name: 'Indianapolis Motor Speedway',
            countryCode: 'US',
            flagEmoji: '🇺🇸',
            baseLapTime: 72.0,
            laps: 73,
            tyreWearMultiplier: 1.1,
            fuelConsumptionMultiplier: 1.1,
            aeroWeight: 0.3,
            powertrainWeight: 0.4,
            chassisWeight: 0.3,
            idealSetup: { frontWing: 40, rearWing: 35, suspension: 75, gearRatio: 80 },
            difficulty: 0.5,
            characteristics: { 'Tyre Wear': 'Medium', 'Fuel Consumption': 'High' },
        },
        montreal: {
            id: 'montreal',
            name: 'Circuit Gilles Villeneuve',
            countryCode: 'CA',
            flagEmoji: '🇨🇦',
            baseLapTime: 73.0,
            laps: 70,
            tyreWearMultiplier: 0.9,
            fuelConsumptionMultiplier: 1.3,
            aeroWeight: 0.2,
            powertrainWeight: 0.4,
            chassisWeight: 0.4,
            idealSetup: { frontWing: 45, rearWing: 40, suspension: 55, gearRatio: 70 },
            difficulty: 0.6,
            characteristics: { 'Tyre Wear': 'Low', 'Fuel Consumption': 'High' },
        },
        texas: {
            id: 'texas',
            name: 'Circuit of the Americas',
            countryCode: 'US',
            flagEmoji: '🇺🇸',
            baseLapTime: 94.0,
            laps: 56,
            tyreWearMultiplier: 1.4,
            fuelConsumptionMultiplier: 1.1,
            aeroWeight: 0.5,
            powertrainWeight: 0.2,
            chassisWeight: 0.3,
            idealSetup: { frontWing: 75, rearWing: 70, suspension: 50, gearRatio: 60 },
            difficulty: 0.6,
            characteristics: { 'Tyre Wear': 'High', 'Fuel Consumption': 'High' },
        },
        buenos_aires: {
            id: 'buenos_aires',
            name: 'Autódromo Oscar y Juan Gálvez',
            countryCode: 'AR',
            flagEmoji: '🇦🇷',
            baseLapTime: 74.0,
            laps: 72,
            tyreWearMultiplier: 1.1,
            fuelConsumptionMultiplier: 1.0,
            aeroWeight: 0.3,
            powertrainWeight: 0.2,
            chassisWeight: 0.5,
            idealSetup: { frontWing: 65, rearWing: 60, suspension: 45, gearRatio: 50 },
            difficulty: 0.6,
            characteristics: { 'Tyre Wear': 'Medium', 'Fuel Consumption': 'Normal' },
        },
    };

    /** Neutral fallback profile — used when the calendar references a circuitId
     *  that the frontend doesn't know about. Previously this returned Interlagos,
     *  which caused the UI to show "Brazil / High Downforce / Stiff" for every
     *  unknown circuit and made the widget look frozen on the previous round. */
    private readonly GENERIC_CIRCUIT: CircuitProfile = {
        id: 'generic',
        name: 'Unknown Circuit',
        countryCode: '',
        flagEmoji: '🏁',
        baseLapTime: 85.0,
        laps: 50,
        tyreWearMultiplier: 1.0,
        fuelConsumptionMultiplier: 1.0,
        aeroWeight: 0.33,
        powertrainWeight: 0.34,
        chassisWeight: 0.33,
        idealSetup: { frontWing: 50, rearWing: 50, suspension: 50, gearRatio: 50 },
        difficulty: 0.5,
        characteristics: { 'Tyre Wear': 'Normal', 'Fuel Consumption': 'Normal' },
    };

    getCircuitProfile(circuitId: string): CircuitProfile {
        if (!circuitId) return this.GENERIC_CIRCUIT;
        const id = circuitId.toLowerCase();
        return this.circuits[id] || this.GENERIC_CIRCUIT;
    }

    getAllCircuits(): CircuitProfile[] {
        return Object.values(this.circuits);
    }

    /**
     * Derives the dynamic component trait badges from a circuit's numerical profile.
     * Aero: High Downforce (aeroWeight >= 0.35) or Low Downforce.
     * Power: Top Speed (gearRatio >= 70) or Acceleration.
     * Chassis: Stiff (chassisWeight >= 0.3 AND suspension < 55) or Soft.
     */
    getComponentTraits(circuit: CircuitProfile): {
        aero: CircuitComponentTrait;
        power: CircuitComponentTrait;
        chassis: CircuitComponentTrait;
    } {
        const aero: CircuitComponentTrait = circuit.aeroWeight >= 0.35
            ? { label: 'High Downforce', tooltipKey: 'circuit_trait_high_downforce' }
            : { label: 'Low Downforce', tooltipKey: 'circuit_trait_low_downforce' };

        const power: CircuitComponentTrait = circuit.idealSetup.gearRatio >= 70
            ? { label: 'Top Speed', tooltipKey: 'circuit_trait_top_speed' }
            : { label: 'Acceleration', tooltipKey: 'circuit_trait_acceleration' };

        const chassis: CircuitComponentTrait = (circuit.chassisWeight >= 0.3 && circuit.idealSetup.suspension < 55)
            ? { label: 'Stiff', tooltipKey: 'circuit_trait_stiff' }
            : { label: 'Soft', tooltipKey: 'circuit_trait_soft' };

        return { aero, power, chassis };
    }
}

export const circuitService = new CircuitService();
