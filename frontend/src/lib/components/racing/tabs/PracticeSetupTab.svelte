<script lang="ts">
    import { db } from "$lib/firebase/config";
    import { doc, updateDoc, increment, addDoc, collection, serverTimestamp } from "firebase/firestore";
    import { teamStore } from "$lib/stores/team.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { setupStore, type PracticeHistoryItem } from "$lib/stores/setup.svelte";
    import {
        raceService,
    } from "$lib/services/race_service.svelte";
    import {
        practiceService,
        type PracticeRunResult,
    } from "$lib/services/practice_service.svelte";
    import { MAX_PRACTICE_LAPS_PER_DRIVER, PRACTICE_SESSION_COST } from "$lib/constants/app_constants";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { circuitService } from "$lib/services/circuit_service.svelte";
    import {
        type CarSetup,
        TyreCompound,
        DriverStyle,
        type Driver,
    } from "$lib/types";
    import {
        Timer,
        Zap,
        Wind,
        Navigation,
        AlertTriangle,
        CheckCircle2,
        History,
        Info,
        ChevronRight,
    } from "lucide-svelte";
    import { onMount, untrack } from "svelte";

    let { driverId } = $props<{ driverId: string | null }>();

    let setup = $state<CarSetup>({
        frontWing: 50,
        rearWing: 50,
        suspension: 50,
        gearRatio: 50,
        tyreCompound: TyreCompound.medium,
        pitStops: [TyreCompound.hard],
        initialFuel: 50,
        pitStopFuel: [50],
        qualifyingStyle: DriverStyle.normal,
        raceStyle: DriverStyle.normal,
        pitStopStyles: [DriverStyle.normal],
    });

    let currentDriverStyle = $state<DriverStyle>(DriverStyle.normal);
    let isSimulating = $state(false);
    let lastResult = $state<PracticeRunResult | null>(null);
    let lapsToRun = $state(1);
    let pitBoardMessages = $state<string[]>([]);
    let sessionLapTimes = $state<number[]>([]);

    let competitorTimes = $state<
        Array<{ teamName: string; driverName: string; time: number }>
    >([]);

    const teamDrivers = $derived(driverStore.drivers);
    const driver = $derived(teamDrivers.find((d: any) => d.id === driverId));

    const nextEvent = $derived(seasonStore.nextEvent);
    const circuit = $derived(
        nextEvent
            ? circuitService.getCircuitProfile(nextEvent.circuitId)
            : null,
    );

    const practiceHistory = $derived(
        driver ? setupStore.getHistoryByDriver(driver.id) : [],
    );

    const legacyPracticeRuns = $derived(() => {
        const team = teamStore.value.team;
        if (!driver || !team?.weekStatus?.driverSetups) return [];
        const driverSetup = team.weekStatus.driverSetups[driver.id] || {};
        return driverSetup.practiceRuns || [];
    });

    const combinedHistory = $derived(() => {
        const base = practiceHistory as PracticeHistoryItem[];
        if (!driver) return base;

        const legacy: PracticeHistoryItem[] = legacyPracticeRuns.map(
            (run: any, idx: number) => ({
                id: `legacy-${idx}`,
                driverId: driver.id,
                lapTime: run.time,
                setupUsed: run.setupUsed,
                feedback: [],
                setupConfidence: 0,
                isCrashed: !!run.isCrashed,
                timestamp: null,
            }),
        );

        return [...base, ...legacy];
    });

    const enrichedHistory = $derived(() => {
        if (!driver || !circuit || !teamStore.value.team) return combinedHistory;

        return (combinedHistory as PracticeHistoryItem[]).map((entry) => {
            if (entry.feedback && entry.feedback.length > 0) return entry;
            if (!entry.setupUsed) return entry;

            const sim = practiceService.simulatePracticeRun(
                circuit,
                teamStore.value.team,
                driver,
                entry.setupUsed,
                nextEvent?.weatherPractice || "Sunny",
            );

            return {
                ...entry,
                feedback: sim.driverFeedback.concat(sim.tyreFeedback),
                setupConfidence: sim.setupConfidence,
                isCrashed:
                    entry.isCrashed !== undefined
                        ? entry.isCrashed
                        : sim.isCrashed,
            };
        });
    });

    // Watch for driver changes to load their history setup
    $effect(() => {
        if (driverId) {
            untrack(() => {
                const history = setupStore.getHistoryByDriver(driverId);
                if (history.length > 0) {
                    const lastSetup = history[0].setupUsed;
                    setup = { ...setup, ...lastSetup };
                }
            });
        }
    });

    onMount(() => {
        if (teamStore.value.team?.id) {
            setupStore.init(teamStore.value.team.id);
        }

        // Fetch competitor times
        if (teamStore.value.team?.currentSeasonId) {
            raceService
                .getCompetitorPracticeTimes(
                    teamStore.value.team.currentSeasonId,
                )
                .then((times) => {
                    competitorTimes = times;
                });
        }
    });

    async function runPractice() {
        if (!driver || !circuit || !teamStore.value.team) return;

        isSimulating = true;
        sessionLapTimes = [];

        const team = teamStore.value.team;
        if (!team) return;

        // One-time cost check: $10,000 per driver per weekend
        const weekStatus = team.weekStatus || {};
        const practicePaid = weekStatus.practicePaid || {};
        const hasPaid = practicePaid[driver.id];

        if (!hasPaid) {
            if (team.budget < PRACTICE_SESSION_COST) {
                alert("Insufficient funds for practice runs. Cost is $10,000.");
                isSimulating = false;
                return;
            }

            // Pay the fee
            try {
                const teamRef = doc(db, "teams", team.id);
                const txRef = collection(db, "teams", team.id, "transactions");

                await updateDoc(teamRef, {
                    budget: team.budget - PRACTICE_SESSION_COST,
                    [`weekStatus.practicePaid.${driver.id}`]: true
                });

                await addDoc(txRef, {
                    description: `Track access fee for ${driver.name}`,
                    amount: -PRACTICE_SESSION_COST,
                    date: serverTimestamp(),
                    type: "PRACTICE"
                });
            } catch (err) {
                console.error("Error paying practice fee:", err);
                alert("Error processing payment.");
                isSimulating = false;
                return;
            }
        }

        // Check maximum laps limit
        const practiceLapsMap = weekStatus.practiceLaps || {};
        const driverSetupsMap = weekStatus.driverSetups || {};
        const driverSetupCheck = driverSetupsMap[driver.id] || {};
        const legacyLaps = practiceLapsMap[driver.id] || 0;
        const driverSetupLaps = driverSetupCheck.practice?.laps || 0;
        const currentLaps = Math.max(legacyLaps, driverSetupLaps);

        if (currentLaps + lapsToRun > MAX_PRACTICE_LAPS_PER_DRIVER) {
            alert(
                `Practice aborted. Maximum of ${MAX_PRACTICE_LAPS_PER_DRIVER} laps per weekend. You have ${Math.max(
                    0,
                    MAX_PRACTICE_LAPS_PER_DRIVER - currentLaps,
                )} laps remaining.`,
            );
            isSimulating = false;
            return;
        }

        // Apply selected style to the setup for this run
        const setupToRun = { ...setup, qualifyingStyle: currentDriverStyle };

        pitBoardMessages = [
            `${driver.name} heads out for ${lapsToRun} ${
                lapsToRun === 1 ? "lap" : "laps"
            }.`,
            ...pitBoardMessages,
        ].slice(0, 30);

        try {
            // Simulate laps iteratively for visual
            for (let i = 0; i < lapsToRun; i++) {
                const result = practiceService.simulatePracticeRun(
                    circuit,
                    teamStore.value.team,
                    driver,
                    setupToRun,
                    nextEvent?.weatherPractice || "Sunny",
                );

                lastResult = result;

                // Pit board narrative
                const storedHistory = driver
                    ? setupStore.getHistoryByDriver(driver.id)
                    : [];

                const nonCrashHistoryTimes = storedHistory
                    .filter((h) => !h.isCrashed)
                    .map((h) => h.lapTime);

                const previousBest =
                    nonCrashHistoryTimes.length > 0
                        ? Math.min(...nonCrashHistoryTimes, ...sessionLapTimes)
                        : sessionLapTimes.length > 0
                            ? Math.min(...sessionLapTimes)
                            : null;

                let suffix = "";
                if (result.isCrashed) {
                    suffix = " - CRASH";
                } else if (
                    previousBest === null ||
                    result.lapTime < previousBest
                ) {
                    suffix = " - NEW PERSONAL BEST";
                }

                pitBoardMessages = [
                    `${driver.name} - Lap ${i + 1}: ${formatTime(
                        result.lapTime,
                    )}${suffix}`,
                    ...pitBoardMessages,
                ].slice(0, 30);

                sessionLapTimes = [...sessionLapTimes, result.lapTime];

                await practiceService.savePracticeRun(
                    teamStore.value.team.id,
                    driver.id,
                    result,
                    setupToRun,
                );

                // Also maintain per-driver practiceRuns history used by competitor benchmarks
                const teamRef = doc(db, "teams", teamStore.value.team.id);
                const currentSetups =
                    teamStore.value.team.weekStatus?.driverSetups || {};
                const driverSetup = currentSetups[driver.id] || {};
                const practiceRuns = driverSetup.practiceRuns || [];

                practiceRuns.push({
                    time: result.lapTime,
                    setupUsed: setupToRun,
                    isCrashed: result.isCrashed,
                });

                await updateDoc(teamRef, {
                    [`weekStatus.driverSetups.${driver.id}.practiceRuns`]:
                        practiceRuns,
                });

                // Wait for visual feedback
                await new Promise((r) => setTimeout(r, 800));

                if (result.isCrashed) {
                    break;
                }
            }

            // Calculate team budget cost
            const teamRef = doc(db, "teams", teamStore.value.team.id);
            await updateDoc(teamRef, {
                budget: teamStore.value.team.budget - cost,
            });

            // Calculate Stamina (forma) and Morale changes for the Driver
            const staminaCost = lapsToRun * 1; // 1 pt of stamina reduction per lap
            let moralePenalty = 0;
            
            if (lastResult) {
                if (lastResult.isCrashed) {
                    moralePenalty = 5; // -5 for a crash
                } else if (lastResult.setupConfidence < 0.60) {
                    moralePenalty = 2; // -2 for a bad setup feeling
                } else if (lastResult.setupConfidence > 0.85) {
                    moralePenalty = -1; // +1 if it went exceptionally well
                }
            }

            const driverRef = doc(db, "drivers", driver.id);
            const currentStats = driver.stats || {};
            const newStamina = Math.max(
                0,
                (currentStats.stamina || 100) - staminaCost,
            );
            const newMorale = Math.max(
                0,
                Math.min(100, (currentStats.morale || 100) - moralePenalty),
            );

            await updateDoc(driverRef, {
                "stats.stamina": newStamina,
                "stats.morale": newMorale,
            });

        } catch (e) {
            console.error(e);
            alert("Error running practice session.");
        }

        isSimulating = false;
    }

    function getConfidenceColor(conf: number) {
        if (conf > 0.9) return "text-green-500";
        if (conf > 0.7) return "text-emerald-400";
        if (conf > 0.4) return "text-yellow-400";
        return "text-red-400";
    }

    function formatTime(seconds: number) {
        if (seconds >= 999) return "DNF";
        const mins = Math.floor(seconds / 60);
        const secs = (seconds % 60).toFixed(3);
        return `${mins}:${secs.padStart(6, "0")}`;
    }

    const styleConfigs = [
        {
            id: DriverStyle.defensive,
            icon: ChevronRight,
            color: "text-blue-400",
            label: "Defensive",
        },
        {
            id: DriverStyle.normal,
            icon: Zap,
            color: "text-green-400",
            label: "Normal",
        },
        {
            id: DriverStyle.offensive,
            icon: Zap,
            color: "text-orange-400",
            label: "Offensive",
        },
        {
            id: DriverStyle.mostRisky,
            icon: Zap,
            color: "text-red-500",
            label: "Risky",
        },
    ];
</script>

<div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
    <!-- Left Column: Controls -->
    <div class="lg:col-span-7 space-y-6">
        <!-- Setup Card -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl p-6 relative overflow-hidden shadow-2xl"
        >
            <h3
                class="font-black text-xs text-app-text uppercase tracking-[0.2em] mb-8"
            >
                Practice Target Setup
            </h3>

            <!-- Sliders -->
            <div class="space-y-6">
                {#each [
                    { label: "Front Wing", field: "frontWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400", hintL: "Top Speed (0)", hintR: "Corner Grip (100)" }, 
                    { label: "Rear Wing", field: "rearWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400", hintL: "Top Speed (0)", hintR: "Corner Grip (100)" }, 
                    { label: "Suspension", field: "suspension" as keyof CarSetup, icon: Navigation, color: "text-purple-400", hintL: "Soft/Bumps (0)", hintR: "Stiff/Aero (100)" }, 
                    { label: "Gear Ratio", field: "gearRatio" as keyof CarSetup, icon: Zap, color: "text-orange-400", hintL: "Acceleration (0)", hintR: "Top Speed (100)" }
                ] as item}
                    <div class="space-y-3 group">
                        <div class="flex justify-between items-center px-1">
                            <div class="flex items-center gap-2 {item.color}">
                                <item.icon size={14} />
                                <span
                                    class="text-[10px] font-black uppercase tracking-widest"
                                    >{item.label}</span
                                >
                            </div>
                            <span class="text-sm font-black text-app-text"
                                >{setup[item.field]}</span
                            >
                        </div>
                        <input
                            type="range"
                            min="0"
                            max="100"
                            bind:value={setup[item.field]}
                            class="w-full accent-current h-1.5 bg-app-text/5 rounded-full appearance-none cursor-pointer {item.color.replace(
                                'text-',
                                'accent-',
                            )}"
                        />
                        <div class="flex justify-between px-1 opacity-0 group-hover:opacity-100 transition-opacity">
                            <span class="text-[8px] font-bold text-app-text/40 uppercase tracking-wider text-left max-w-[45%]">{item.hintL}</span>
                            <span class="text-[8px] font-bold text-app-text/40 uppercase tracking-wider text-right max-w-[45%]">{item.hintR}</span>
                        </div>
                    </div>
                {/each}
            </div>

            <!-- Tyres -->
            <div class="mt-8 space-y-3">
                <span
                    class="text-[9px] font-black text-app-text/40 uppercase tracking-widest"
                    >Tyre Compound</span
                >
                <div class="grid grid-cols-4 gap-3">
                    {#each [TyreCompound.soft, TyreCompound.medium, TyreCompound.hard, TyreCompound.wet] as tc}
                        <button
                            class="px-2 py-3 rounded-xl border transition-all flex flex-col items-center gap-2 {setup.tyreCompound ===
                            tc
                                ? 'bg-app-primary border-app-primary text-app-primary-foreground'
                                : 'bg-app-text/5 border-app-border text-app-text/40 hover:bg-app-text/10'}"
                            onclick={() => (setup.tyreCompound = tc)}
                        >
                            <div
                                class="w-2.5 h-2.5 rounded-full {tc === 'soft'
                                    ? 'bg-red-500'
                                    : tc === 'medium'
                                      ? 'bg-yellow-500'
                                      : tc === 'hard'
                                        ? 'bg-app-surface'
                                        : 'bg-blue-500'} shadow-[0_0_10px_rgba(255,255,255,0.2)]"
                            ></div>
                            <span
                                class="text-[9px] font-black uppercase tracking-tighter"
                                >{tc}</span
                            >
                        </button>
                    {/each}
                </div>
            </div>
        </div>

        <!-- Driver Style & Lap Selection -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl p-6 space-y-6"
        >
            <div class="flex items-center justify-between">
                <h4
                    class="text-[10px] font-black text-app-text/40 uppercase tracking-widest"
                >
                    Driving Aggression
                </h4>
                <div class="flex gap-1.5">
                    {#each styleConfigs as style}
                        <button
                            class="w-8 h-8 rounded-lg border flex items-center justify-center transition-all {currentDriverStyle ===
                            style.id
                                ? 'bg-app-text/10 border-app-border ' + style.color
                                : 'bg-app-text/5 border-transparent text-app-text/20 hover:text-app-text/40'}"
                            onclick={() => (currentDriverStyle = style.id)}
                            title={style.label}
                        >
                            <style.icon size={14} />
                        </button>
                    {/each}
                </div>
            </div>

            <div class="flex items-center gap-4">
                <div class="flex-1 bg-app-text/20 rounded-xl p-1.5 flex gap-1">
                    {#each [1, 3, 5] as laps}
                        <button
                            class="flex-1 py-1.5 rounded-lg text-[10px] font-black uppercase transition-all {lapsToRun ===
                            laps
                                ? 'bg-app-text/10 text-app-text'
                                : 'text-app-text/20 hover:text-app-text/40'}"
                            onclick={() => (lapsToRun = laps)}
                        >
                            {laps}
                            {laps === 1 ? "Lap" : "Laps"}
                        </button>
                    {/each}
                </div>

                <div class="flex-[2] flex flex-col items-end">
                    <button
                        class="w-full py-3.5 bg-app-primary text-app-primary-foreground font-black uppercase tracking-widest text-xs rounded-xl hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 disabled:scale-100 flex items-center justify-center gap-2 shadow-lg shadow-app-primary/20"
                        disabled={isSimulating || !driver}
                        onclick={runPractice}
                    >
                        {#if isSimulating}
                            <div
                                class="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin"
                            ></div>
                            Running...
                        {:else}
                            <Timer size={16} />
                            Start Practice
                        {/if}
                    </button>
                    <span
                        class="text-[9px] uppercase tracking-widest font-black text-red-400 mt-2"
                        >-${PRACTICE_SESSION_COST.toLocaleString()} Outing Fee</span
                    >
                </div>
            </div>
        </div>
    </div>

    <!-- Right Column: Results & Pit Board -->
    <div class="lg:col-span-5 space-y-6">
        <!-- Competitor Times & Pit Board -->
        <div
            class="bg-app-surface border-l-4 border-app-primary rounded-xl p-5 shadow-xl"
        >
            <div class="flex items-center justify-between mb-4">
                <span
                    class="text-[10px] font-black text-app-primary uppercase tracking-[0.2em] italic"
                    >Rival Best Times (Free Practice)</span
                >
                <div
                    class="w-2 h-2 rounded-full bg-app-primary animate-pulse"
                ></div>
            </div>
            
            <div class="space-y-3">
                {#if competitorTimes.length === 0}
                    <p class="text-xs text-app-text/40 italic">Waiting for others to hit the track...</p>
                {:else}
                    {#each competitorTimes as comp, i}
                        <div class="flex justify-between items-center bg-app-text/5 px-3 py-2 rounded-lg">
                            <span class="text-[10px] font-bold text-app-text/70">P{i+1}. {comp.teamName} <span class="opacity-50">({comp.driverName})</span></span>
                            <span class="text-xs font-black text-app-text font-mono tabular-nums">{formatTime(comp.time)}</span>
                        </div>
                    {/each}
                {/if}
            </div>

            <div class="mt-4 pt-3 border-t border-app-border/40">
                <div class="flex items-center justify-between mb-2">
                    <span
                        class="text-[10px] font-black text-app-primary uppercase tracking-[0.2em] italic"
                        >Pit Board</span
                    >
                </div>
                <div
                    class="max-h-40 overflow-y-auto space-y-2 custom-scrollbar"
                >
                    {#if pitBoardMessages.length === 0}
                        <p class="text-[10px] text-app-text/40 italic">
                            Awaiting session messages...
                        </p>
                    {:else}
                        {#each pitBoardMessages as msg}
                            <div
                                class="text-[10px] text-app-text/70 font-mono tabular-nums"
                            >
                                {msg}
                            </div>
                        {/each}
                    {/if}
                </div>
            </div>
        </div>

        <!-- Last Lap Card -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl p-6 flex flex-col gap-4"
        >
            <div class="flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <History size={16} class="text-app-primary" />
                    <h4
                        class="text-[10px] font-black text-app-text/40 uppercase tracking-widest"
                    >
                        Last Outing Result
                    </h4>
                </div>
                {#if lastResult}
                    <span
                        class="text-[9px] font-black {getConfidenceColor(
                            lastResult.setupConfidence,
                        )}"
                    >
                        {(lastResult.setupConfidence * 100).toFixed(0)}% CONF
                    </span>
                {/if}
            </div>

            <div class="flex items-end justify-between">
                <span
                    class="text-3xl font-black italic text-app-text tabular-nums"
                >
                    {lastResult ? formatTime(lastResult.lapTime) : "0:00.000"}
                </span>
                {#if lastResult?.isCrashed}
                    <div
                        class="flex items-center gap-1.5 px-2 py-1 rounded bg-red-500/20 text-red-500 text-[9px] font-black uppercase"
                    >
                        <AlertTriangle size={10} />
                        Accident
                    </div>
                {/if}
            </div>
        </div>

        <!-- Feedback & History -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl flex flex-col h-[350px]"
        >
            <div class="flex border-b border-app-border">
                <div
                    class="flex-1 py-3 text-center text-[10px] font-black uppercase tracking-widest border-b-2 border-app-primary text-app-text bg-app-text/5"
                >
                    Feedback
                </div>
                <div
                    class="flex-1 py-3 text-center text-[10px] font-black uppercase tracking-widest text-app-text/40 bg-app-surface border-b border-app-border"
                >
                    Lap History
                </div>
            </div>

            <div class="flex-1 overflow-y-auto p-4 space-y-4 custom-scrollbar">
                <!-- Feedback block -->
                <div class="space-y-3">
                    {#if lastResult}
                        {#each lastResult.driverFeedback as msg}
                            <div
                                class="p-3 bg-app-text/5 rounded-lg border-l-2 border-app-primary"
                            >
                                <p
                                    class="text-[11px] italic text-app-text/70 leading-relaxed font-medium"
                                >
                                    "{msg}"
                                </p>
                            </div>
                        {/each}
                        {#if lastResult.driverFeedback.length === 0}
                            <div
                                class="p-4 flex flex-col items-center justify-center text-center opacity-30 mt-4"
                            >
                                <CheckCircle2 size={32} class="mb-3" />
                                <p class="text-[10px] font-black uppercase">
                                    No Issues Reported
                                </p>
                            </div>
                        {/if}
                    {:else}
                        <div
                            class="p-4 flex flex-col items-center justify-center text-center opacity-10 mt-4"
                        >
                            <Info size={40} class="mb-3" />
                            <p
                                class="text-[10px] font-black uppercase tracking-widest"
                            >
                                Awaiting First Run
                            </p>
                        </div>
                    {/if}
                </div>

                <!-- History block -->
                <div class="pt-2 border-t border-app-border/40 space-y-2">
                    <h4
                        class="text-[9px] font-black text-app-text/40 uppercase tracking-widest"
                    >
                        Recent Laps
                    </h4>
                    {#if enrichedHistory.length === 0}
                        <p class="text-[10px] text-app-text/30 italic">
                            No recorded laps yet for this driver.
                        </p>
                    {:else}
                        {#each enrichedHistory as entry}
                            <div
                                class="flex items-center justify-between text-[11px] px-2 py-1.5 rounded-lg bg-app-text/5"
                            >
                                <div class="flex flex-col">
                                    <span class="font-mono font-black">
                                        {formatTime(entry.lapTime)}
                                    </span>
                                    <span
                                        class="text-[9px] text-app-text/40 uppercase tracking-widest"
                                    >
                                        CONF{" "}
                                        {Math.round(
                                            (entry.setupConfidence || 0) * 100,
                                        )}%
                                    </span>
                                </div>
                                {#if entry.isCrashed}
                                    <span class="text-[9px] text-red-400">
                                        CRASH
                                    </span>
                                {:else}
                                    <span class="text-[9px] text-app-text/40">
                                        {entry.feedback[0] || "Clean lap"}
                                    </span>
                                {/if}
                            </div>
                        {/each}
                    {/if}
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    .custom-scrollbar::-webkit-scrollbar {
        width: 4px;
    }
    .custom-scrollbar::-webkit-scrollbar-track {
        background: rgba(255, 255, 255, 0.05);
    }
    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: rgba(197, 160, 89, 0.2);
        border-radius: 10px;
    }
</style>
