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
            name: 'Autodromo Hermanos Rodriguez',
            countryCode: 'MX',
            flagEmoji: '🇲🇽',
            baseLapTime: 76.0,
            laps: 71,
            tyreWearMultiplier: 1.1,
            fuelConsumptionMultiplier: 1.0,
            aeroWeight: 0.4,
            powertrainWeight: 0.4,
            chassisWeight: 0.2,
            idealSetup: {
                frontWing: 80,
                rearWing: 75,
                suspension: 50,
                gearRatio: 85,
            },
            difficulty: 0.6,
            characteristics: {
                'Tyre Wear': 'Medium',
                'Fuel Consumption': 'Normal',
            },
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
            idealSetup: {
                frontWing: 25,
                rearWing: 20,
                suspension: 70,
                gearRatio: 90,
            },
            difficulty: 0.5,
            characteristics: {
                'Tyre Wear': 'Low',
                'Fuel Consumption': 'High',
            },
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
            idealSetup: {
                frontWing: 65,
                rearWing: 60,
                suspension: 45,
                gearRatio: 55,
            },
            difficulty: 0.6,
            characteristics: {
                'Tyre Wear': 'High',
                'Fuel Consumption': 'High',
            },
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
            idealSetup: {
                frontWing: 55,
                rearWing: 50,
                suspension: 60,
                gearRatio: 65,
            },
            difficulty: 0.5,
            characteristics: {
                'Tyre Wear': 'Normal',
                'Fuel Consumption': 'Normal',
            },
        }
    };

    getCircuitProfile(circuitId: string): CircuitProfile {
        const id = circuitId.toLowerCase();
        return this.circuits[id] || this.circuits['interlagos'];
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
