import { db } from "../firebase/config";
import { collection, addDoc, doc, updateDoc, increment, serverTimestamp } from "firebase/firestore";
import { type Driver, type Team, type CarSetup } from "../types";
import { type CircuitProfile } from "./circuit_service.svelte";

export interface PracticeRunResult {
    lapTime: number;
    driverFeedback: string[];
    tyreFeedback: string[];
    setupConfidence: number;
    isCrashed: boolean;
}

class PracticeService {
    /**
     * Simulates a practice lap based on the Flutter RaceService logic.
     */
    simulatePracticeRun(
        circuit: CircuitProfile,
        team: Team,
        driver: Driver,
        setup: CarSetup,
        weatherOverride?: string
    ): PracticeRunResult {
        const ideal = circuit.idealSetup;
        const carStats = team.carStats[driver.carIndex.toString()] || { aero: 1, powertrain: 1, chassis: 1 };

        // Bonuses based on car development (max stats 20)
        let aeroBonus = 1.0 - (Math.min(carStats.aero || 1, 20) / 40.0);
        let powerBonus = 1.0 - (Math.min(carStats.powertrain || 1, 20) / 40.0);
        let chassisBonus = 1.0 - (Math.min(carStats.chassis || 1, 20) / 40.0);

        let setupPenalty = 0.0;
        const driverFeedback: string[] = [];
        const tyreFeedback: string[] = [];

        // 1. Aero Front
        const gapFront = setup.frontWing - ideal.frontWing;
        const effectiveGapFront = Math.abs(gapFront) <= 3 ? 0 : Math.abs(gapFront) - 3;
        setupPenalty += effectiveGapFront * 0.03 * aeroBonus;
        if (gapFront > 15) driverFeedback.push("The front end is way too sharp, I'm fighting oversteer.");
        else if (gapFront < -15) driverFeedback.push("The car is lazy on entry, we have too much understeer.");

        // 2. Aero Rear
        const gapRear = setup.rearWing - ideal.rearWing;
        const effectiveGapRear = Math.abs(gapRear) <= 3 ? 0 : Math.abs(gapRear) - 3;
        setupPenalty += effectiveGapRear * 0.03 * aeroBonus;
        if (gapRear > 15) driverFeedback.push("We're slow on the straights, feels like we have a parachute.");
        else if (gapRear < -15) driverFeedback.push("The rear is very nervous. I can't put the power down.");

        // 3. Suspension
        const gapSusp = setup.suspension - ideal.suspension;
        const effectiveGapSusp = Math.abs(gapSusp) <= 3 ? 0 : Math.abs(gapSusp) - 3;
        setupPenalty += effectiveGapSusp * 0.02 * chassisBonus;
        if (gapSusp > 15) driverFeedback.push("The car is too stiff, it's bouncing like crazy.");
        else if (gapSusp < -15) driverFeedback.push("The suspension feels like jelly, too much roll.");

        // 4. Gear Ratio
        const gapGear = setup.gearRatio - ideal.gearRatio;
        const effectiveGapGear = Math.abs(gapGear) <= 3 ? 0 : Math.abs(gapGear) - 3;
        setupPenalty += effectiveGapGear * 0.025 * powerBonus;
        if (gapGear > 15) driverFeedback.push("Gears are too short, hitting the limiter too early.");
        else if (gapGear < -15) driverFeedback.push("Gears are too long, acceleration is non-existent.");

        // 5. Driver Performance Factor
        const aeroVal = Math.min(carStats.aero || 1, 20);
        const powerVal = Math.min(carStats.powertrain || 1, 20);
        const chassisVal = Math.min(carStats.chassis || 1, 20);

        const weightedStat = (aeroVal * circuit.aeroWeight) + (powerVal * circuit.powertrainWeight) + (chassisVal * circuit.chassisWeight);
        const carPerformanceFactor = 1.0 - ((weightedStat / 20.0) * 0.25);

        const braking = (driver.stats.braking || 50) / 100.0;
        const cornering = (driver.stats.cornering || 50) / 100.0;
        const adaptability = (driver.stats.adaptability || 50) / 100.0;
        const focusVal = (driver.stats.focus || 50) / 100.0;
        const morale = (driver.stats.morale || 70) / 100.0;

        let driverFactor = 1.0 - (braking * 0.02 + cornering * 0.025 + adaptability * 0.015 + focusVal * 0.01 + (morale - 0.5) * 0.01);

        // 6. Accident logic (simplified)
        const isCrashed = Math.random() < 0.0005;

        // 7. Tyre compounds
        let tyreDelta = 0.0;
        const isWet = weatherOverride?.toLowerCase().includes('rain') || weatherOverride?.toLowerCase().includes('wet');

        if (isWet) {
            if (setup.tyreCompound === 'wet') {
                tyreDelta = -0.3;
                tyreFeedback.push("Wets are working well.");
            } else {
                tyreDelta = 8.0;
                setupPenalty += 5.0;
                tyreFeedback.push("Zero grip! Need wets!");
            }
        } else {
            const deltas = { soft: -0.5, medium: -0.3, hard: -0.1, wet: 3.0 };
            tyreDelta = deltas[setup.tyreCompound];
            if (setup.tyreCompound === 'wet') {
                setupPenalty += 2.0;
                tyreFeedback.push("Wets are overheating on this dry track.");
            }
        }

        const actualLapTime = circuit.baseLapTime * carPerformanceFactor * driverFactor + tyreDelta + setupPenalty;

        // Final confidence calculation
        const totalGap = Math.abs(gapFront) + Math.abs(gapRear) + Math.abs(gapSusp) + Math.abs(gapGear);
        const confidence = Math.max(0, Math.min(1, 1.0 - (totalGap / 100.0)));

        return {
            lapTime: isCrashed ? 999.0 : actualLapTime + (Math.random() - 0.5) * 0.5,
            driverFeedback,
            tyreFeedback,
            setupConfidence: confidence,
            isCrashed
        };
    }

    async savePracticeRun(teamId: string, driverId: string, result: PracticeRunResult, setup: CarSetup) {
        const teamRef = doc(db, "teams", teamId);
        const resultsRef = collection(teamRef, "practice_results");

        await addDoc(resultsRef, {
            driverId,
            lapTime: result.lapTime,
            setupUsed: setup,
            feedback: result.driverFeedback.concat(result.tyreFeedback),
            setupConfidence: result.setupConfidence,
            isCrashed: result.isCrashed,
            timestamp: serverTimestamp()
        });

        // Update team weekStatus for laps taken
        const updatePath = `weekStatus.practiceLaps.${driverId}`;
        await updateDoc(teamRef, {
            [updatePath]: increment(1)
        });
    }
}

export const practiceService = new PracticeService();
