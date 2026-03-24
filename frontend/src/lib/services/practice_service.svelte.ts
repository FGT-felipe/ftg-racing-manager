import { db } from "../firebase/config";
import { collection, addDoc, doc, updateDoc, increment, serverTimestamp } from "firebase/firestore";
import { type Driver, type Team, type CarSetup, DriverTrait, TyreCompound, DriverStyle } from "../types";
import { type CircuitProfile } from "./circuit_service.svelte";
import { t } from "../utils/i18n";
import { CarSetupSchema } from "../schemas/car-setup.schema";

export interface SetupHint {
    min: number;
    max: number;
}

export interface PracticeRunResult {
    lapTime: number;
    driverFeedback: string[];
    tyreFeedback: string[];
    setupConfidence: number;
    setupUsed: CarSetup;
    isCrashed: boolean;
    fitnessPenalty?: number;
    setupHints?: {
        frontWing: SetupHint;
        rearWing: SetupHint;
        suspension: SetupHint;
        gearRatio: SetupHint;
    };
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
        weatherOverride?: string,
        isQualifying: boolean = false
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

        const feedbackStat = (driver.stats.feedback || 10) / 20.0;
        
        // Helper to add feedback with quality check
        const addFeedback = (specific: string, vague: string, gap: number) => {
            // High feedback drivers give feedback sooner and more accurately
            // Threshold for gap: 12 (0 skill) to 2 (max skill) in 0-100 setup space
            const threshold = 12 - (feedbackStat * 10); 
            if (Math.abs(gap) > threshold) {
                // Clarity: High skill gives technical info, low skill gives vague hints
                if (feedbackStat > 0.75) {
                    driverFeedback.push(specific);
                } else if (feedbackStat > 0.4) {
                    // Mid-skill: 50/50 chance of being specific or vague
                    driverFeedback.push(Math.random() > 0.5 ? specific : vague);
                } else {
                    driverFeedback.push(vague);
                }
            }
        };

        // 1. Aero Front
        const gapFront = setup.frontWing - ideal.frontWing;
        const effectiveGapFront = Math.abs(gapFront) <= 3 ? 0 : Math.abs(gapFront) - 3;
        setupPenalty += effectiveGapFront * 0.03 * aeroBonus;
        addFeedback(
            gapFront > 0 ? "The front end is way too sharp, I'm fighting oversteer." : "The car is lazy on entry, we have too much understeer.",
            "The front balance doesn't feel right, I can't hit the apex.",
            gapFront
        );

        // 2. Aero Rear
        const gapRear = setup.rearWing - ideal.rearWing;
        const effectiveGapRear = Math.abs(gapRear) <= 3 ? 0 : Math.abs(gapRear) - 3;
        setupPenalty += effectiveGapRear * 0.03 * aeroBonus;
        addFeedback(
            gapRear > 0 ? "We're slow on the straights, feels like we have a parachute." : "The rear is very nervous. I can't put the power down.",
            "The rear of the car is giving me zero confidence.",
            gapRear
        );

        // 3. Suspension
        const gapSusp = setup.suspension - ideal.suspension;
        const effectiveGapSusp = Math.abs(gapSusp) <= 3 ? 0 : Math.abs(gapSusp) - 3;
        setupPenalty += effectiveGapSusp * 0.02 * chassisBonus;
        addFeedback(
            gapSusp > 0 ? "The car is too stiff, it's bouncing like crazy." : "The suspension feels like jelly, too much roll.",
            "The car's handling over the bumps is very poor.",
            gapSusp
        );

        // 4. Gear Ratio
        const gapGear = setup.gearRatio - ideal.gearRatio;
        const effectiveGapGear = Math.abs(gapGear) <= 3 ? 0 : Math.abs(gapGear) - 3;
        setupPenalty += effectiveGapGear * 0.025 * powerBonus;
        addFeedback(
            gapGear > 0 ? "Gears are too short, hitting the limiter too early." : "Gears are too long, acceleration is non-existent.",
            "The engine mapping doesn't match the track layout.",
            gapGear
        );

        // 5. Driver Performance Factor
        const aeroVal = Math.min(carStats.aero || 1, 20);
        const powerVal = Math.min(carStats.powertrain || 1, 20);
        const chassisVal = Math.min(carStats.chassis || 1, 20);

        const weightedStat = (aeroVal * circuit.aeroWeight) + (powerVal * circuit.powertrainWeight) + (chassisVal * circuit.chassisWeight);
        const carPerformanceFactor = 1.0 - ((weightedStat / 20.0) * 0.25);

        const braking = (driver.stats.braking || 10) / 20.0;
        const cornering = (driver.stats.cornering || 10) / 20.0;
        const focusVal = (driver.stats.focus || 10) / 20.0;
        const adaptability = (driver.stats.adaptability || 10) / 20.0;
        const morale = (driver.stats.morale || 70) / 100.0;

        let driverFactor = 1.0 - (braking * 0.02 + cornering * 0.025 + adaptability * 0.015 + focusVal * 0.01 + (morale - 0.5) * 0.01);

        // 6. Driving style modifier (matches race_service logic)
        const st = setup.qualifyingStyle || DriverStyle.normal;
        let sBonus = 0;
        let accProb = 0.001;

        if (st === DriverStyle.mostRisky) {
            sBonus = 0.04; accProb = 0.003;
        } else if (st === DriverStyle.offensive) {
            sBonus = 0.02; accProb = 0.0015;
        } else if (st === DriverStyle.defensive) {
            sBonus = -0.01; accProb = 0.0005;
        }

        driverFactor -= sBonus;

        // 7. Accident logic (style-aware)
        const isCrashed = Math.random() < accProb;

        // 8. Tyre compounds
        let tyreDelta = 0.0;
        const isWet = weatherOverride?.toLowerCase().includes('rain') || weatherOverride?.toLowerCase().includes('wet');

        if (isWet) {
            // Base wet surface penalty: sessions in rain are always slower
            tyreDelta += 1.5;

            if (setup.tyreCompound === TyreCompound.wet) {
                tyreDelta -= 0.3;
                tyreFeedback.push(t("wets_working_well"));
                
                // Rain Master trait bonus
                if (driver.traits && driver.traits.includes(DriverTrait.rainMaster)) {
                    driverFactor -= 0.015;
                }
            } else {
                tyreDelta = 8.0;
                setupPenalty += 5.0;
                tyreFeedback.push(t("zero_grip_need_wets"));
            }
        } else {
            const deltas: Record<string, number> = { 
                [TyreCompound.soft]: -0.5, 
                [TyreCompound.medium]: -0.3, 
                [TyreCompound.hard]: -0.1, 
                [TyreCompound.wet]: 3.0 
            };
            tyreDelta = deltas[setup.tyreCompound] || 0;
            if (setup.tyreCompound === TyreCompound.wet) {
                setupPenalty += 2.0;
                tyreFeedback.push(t("wets_overheating"));
            }
        }

        const actualLapTime = circuit.baseLapTime * carPerformanceFactor * driverFactor + tyreDelta + setupPenalty;

        // Final confidence calculation
        const totalGap = Math.abs(gapFront) + Math.abs(gapRear) + Math.abs(gapSusp) + Math.abs(gapGear);
        const confidence = Math.max(0, Math.min(1, 1.0 - (totalGap / 100.0)));

        // 8. Setup Hints (Range Indicators)
        // High adaptability = narrower and more accurate range
        const generateHint = (idealVal: number) => {
            const baseWidth = 25; // Maximum width for 0 feedback
            const width = Math.max(5, baseWidth * (1.1 - feedbackStat)); 
            
            // Random offset also depends on feedback skill (lower skill = more error)
            const maxOffset = (1.0 - feedbackStat) * 12;
            const offset = (Math.random() * maxOffset * 2) - maxOffset;
            
            const center = idealVal + offset;
            return {
                min: Math.max(0, Math.round(center - width / 2)),
                max: Math.min(100, Math.round(center + width / 2))
            };
        };

        const setupHints = {
            frontWing: generateHint(ideal.frontWing),
            rearWing: generateHint(ideal.rearWing),
            suspension: generateHint(ideal.suspension),
            gearRatio: generateHint(ideal.gearRatio)
        };

        let fitnessPenalty = 0;
        if (isQualifying) {
            // El impacto en la forma debe depender del nivel de foco: a mayor foco, menos impacto en la forma (1.5% a 3%)
            const focusStat = Math.min(Math.max(driver.stats.focus || 10, 1), 20);
            fitnessPenalty = 1.5 + ((20 - focusStat) / 19) * 1.5;
        }

        return {
            lapTime: isCrashed ? 999.0 : actualLapTime + (Math.random() - 0.5) * 0.5,
            driverFeedback,
            tyreFeedback,
            setupConfidence: confidence,
            setupUsed: { ...setup },
            isCrashed,
            fitnessPenalty,
            setupHints
        };
    }

    async savePracticeRun(
        team: Team,
        driverId: string,
        result: PracticeRunResult,
        setup: CarSetup,
        sessionId?: string,
        lapCount: number = 1,
        driverStats?: Record<string, number>
    ) {
        const parsed = CarSetupSchema.safeParse(setup);
        if (!parsed.success) {
            console.error('[PracticeService:savePracticeRun] Invalid CarSetup — aborting Firestore write:', parsed.error.flatten());
            throw new Error(`Invalid setup: ${parsed.error.issues.map(i => i.message).join(', ')}`);
        }

        // Bypass the subcollection entirely to avoid permission issues reported by the user
        // We still log to console for debugging
        console.debug(`[PracticeService] Skipping subcollection write due to permission errors. Data preserved in team document.`);

        const practiceLapsPath = `weekStatus.practiceLaps.${driverId}`;
        const practiceSetupPath = `weekStatus.driverSetups.${driverId}.practice`;
        const driverSetup = team.weekStatus?.driverSetups?.[driverId]?.practice || {};
        const currentBest = driverSetup.bestLapTime || 9999;
        const isNewBest = result.lapTime < currentBest && !result.isCrashed;

        // The Standings table now aggregates data from each team's document in RaceService
        // No need to write to a global practice_sessions document which might have permission issues

        const updates: any = {
            [practiceLapsPath]: increment(lapCount),
            [`${practiceSetupPath}.frontWing`]: setup.frontWing,
            [`${practiceSetupPath}.rearWing`]: setup.rearWing,
            [`${practiceSetupPath}.suspension`]: setup.suspension,
            [`${practiceSetupPath}.gearRatio`]: setup.gearRatio,
            [`${practiceSetupPath}.tyreCompound`]: setup.tyreCompound,
            [`${practiceSetupPath}.laps`]: increment(lapCount),
            // Persistent session feedback and last result data
            [`${practiceSetupPath}.sessionFeedback`]: result.driverFeedback.concat(result.tyreFeedback),
            [`${practiceSetupPath}.lastResult`]: {
                lapTime: result.lapTime,
                setupConfidence: result.setupConfidence,
                isCrashed: result.isCrashed,
                setupUsed: setup,
                setupHints: result.setupHints
            }
        };

        if (isNewBest) {
            updates[`${practiceSetupPath}.bestLapTime`] = result.lapTime;
            updates[`${practiceSetupPath}.bestLapTyre`] = setup.tyreCompound;
            updates[`${practiceSetupPath}.bestLapSetup`] = setup;
        }

        const teamRef = doc(db, "teams", team.id);
        await updateDoc(teamRef, updates);

        // Update driver fitness and morale after the session
        if (driverStats !== undefined) {
            const fitnessCost = Math.max(3, lapCount * 2);
            let moralePenalty = 0;
            if (result.isCrashed) {
                moralePenalty = 5;
            } else if (result.setupConfidence < 0.60) {
                moralePenalty = 2;
            } else if (result.setupConfidence > 0.85) {
                moralePenalty = -1;
            }

            const newFitness = Math.max(0, (driverStats.fitness || 100) - fitnessCost);
            const newMorale = Math.max(0, Math.min(100, (driverStats.morale || 100) - moralePenalty));

            const driverRef = doc(db, "drivers", driverId);
            await updateDoc(driverRef, {
                "stats.fitness": newFitness,
                "stats.morale": newMorale,
            });
        }
    }
}

export const practiceService = new PracticeService();
