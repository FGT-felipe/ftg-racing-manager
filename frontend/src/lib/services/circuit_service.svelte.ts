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
                'Top Speed': 'High',
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
                'Night Race': 'Yes',
                'Top Speed': 'Very High',
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
                'Elevation': 'Significant',
                'Weather': 'Unpredictable',
                'Tyre Wear': 'High',
                'Top Speed': 'Medium',
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
                'Environment': 'Complex',
                'Surface': 'Smooth',
                'Top Speed': 'High',
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
}

export const circuitService = new CircuitService();
