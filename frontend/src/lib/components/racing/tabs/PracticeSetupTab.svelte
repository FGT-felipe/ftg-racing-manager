<script lang="ts">
    import { db } from "$lib/firebase/config";
    import { doc, updateDoc } from "firebase/firestore";
    import { teamStore } from "$lib/stores/team.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { setupStore } from "$lib/stores/setup.svelte";
    import {
        practiceService,
        type PracticeRunResult,
    } from "$lib/services/practice_service.svelte";
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

    const teamDrivers = $derived(driverStore.drivers);
    const driver = $derived(teamDrivers.find((d: any) => d.id === driverId));

    const nextEvent = $derived(seasonStore.nextEvent);
    const circuit = $derived(
        nextEvent
            ? circuitService.getCircuitProfile(nextEvent.circuitId)
            : null,
    );

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

    async function runPractice() {
        if (!driver || !circuit || !teamStore.value.team) return;

        isSimulating = true;

        // Cost: $3,000 per run of practice
        const cost = 3000;
        if (teamStore.value.team.budget < cost) {
            alert("Insufficient funds for practice runs. Cost is $3,000.");
            isSimulating = false;
            return;
        }

        // Apply selected style to the setup for this run
        const setupToRun = { ...setup, qualifyingStyle: currentDriverStyle };

        try {
            // Simulate laps iteratively for visual
            for (let i = 0; i < lapsToRun; i++) {
                const result = practiceService.simulatePracticeRun(
                    circuit,
                    teamStore.value.team,
                    driver,
                    setupToRun,
                );
                lastResult = result;

                await practiceService.savePracticeRun(
                    teamStore.value.team.id,
                    driver.id,
                    result,
                    setupToRun, // Use the localized setup with the Style
                );

                // Wait for visual feedback
                await new Promise((r) => setTimeout(r, 800));

                if (result.isCrashed) {
                    break;
                }
            }

            // Charge the team the $3k fee for the OUTING (not per lap)
            const teamRef = doc(db, "teams", teamStore.value.team.id);
            await updateDoc(teamRef, {
                budget: teamStore.value.team.budget - cost,
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
            class="bg-[#121212] border border-white/10 rounded-2xl p-6 relative overflow-hidden shadow-2xl"
        >
            <h3
                class="font-black text-xs text-white uppercase tracking-[0.2em] mb-8"
            >
                Practice Target Setup
            </h3>

            <!-- Sliders -->
            <div class="space-y-6">
                {#each [{ label: "Front Wing", field: "frontWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400" }, { label: "Rear Wing", field: "rearWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400" }, { label: "Suspension", field: "suspension" as keyof CarSetup, icon: Navigation, color: "text-purple-400" }, { label: "Gear Ratio", field: "gearRatio" as keyof CarSetup, icon: Zap, color: "text-orange-400" }] as item}
                    <div class="space-y-3">
                        <div class="flex justify-between items-center px-1">
                            <div class="flex items-center gap-2 {item.color}">
                                <item.icon size={14} />
                                <span
                                    class="text-[10px] font-black uppercase tracking-widest"
                                    >{item.label}</span
                                >
                            </div>
                            <span class="text-sm font-black text-white"
                                >{setup[item.field]}</span
                            >
                        </div>
                        <input
                            type="range"
                            min="0"
                            max="100"
                            bind:value={setup[item.field]}
                            class="w-full accent-current h-1.5 bg-white/5 rounded-full appearance-none cursor-pointer {item.color.replace(
                                'text-',
                                'accent-',
                            )}"
                        />
                    </div>
                {/each}
            </div>

            <!-- Tyres -->
            <div class="mt-8 space-y-3">
                <span
                    class="text-[9px] font-black text-white/40 uppercase tracking-widest"
                    >Tyre Compound</span
                >
                <div class="grid grid-cols-4 gap-3">
                    {#each [TyreCompound.soft, TyreCompound.medium, TyreCompound.hard, TyreCompound.wet] as tc}
                        <button
                            class="px-2 py-3 rounded-xl border transition-all flex flex-col items-center gap-2 {setup.tyreCompound ===
                            tc
                                ? 'bg-app-primary border-app-primary text-black'
                                : 'bg-white/5 border-white/5 text-white/40 hover:bg-white/10'}"
                            onclick={() => (setup.tyreCompound = tc)}
                        >
                            <div
                                class="w-2.5 h-2.5 rounded-full {tc === 'soft'
                                    ? 'bg-red-500'
                                    : tc === 'medium'
                                      ? 'bg-yellow-500'
                                      : tc === 'hard'
                                        ? 'bg-white'
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
                    class="text-[10px] font-black text-white/40 uppercase tracking-widest"
                >
                    Driving Aggression
                </h4>
                <div class="flex gap-1.5">
                    {#each styleConfigs as style}
                        <button
                            class="w-8 h-8 rounded-lg border flex items-center justify-center transition-all {currentDriverStyle ===
                            style.id
                                ? 'bg-white/10 border-white/20 ' + style.color
                                : 'bg-white/5 border-transparent text-white/20 hover:text-white/40'}"
                            onclick={() => (currentDriverStyle = style.id)}
                            title={style.label}
                        >
                            <style.icon size={14} />
                        </button>
                    {/each}
                </div>
            </div>

            <div class="flex items-center gap-4">
                <div class="flex-1 bg-black/20 rounded-xl p-1.5 flex gap-1">
                    {#each [1, 3, 5] as laps}
                        <button
                            class="flex-1 py-1.5 rounded-lg text-[10px] font-black uppercase transition-all {lapsToRun ===
                            laps
                                ? 'bg-white/10 text-white'
                                : 'text-white/20 hover:text-white/40'}"
                            onclick={() => (lapsToRun = laps)}
                        >
                            {laps}
                            {laps === 1 ? "Lap" : "Laps"}
                        </button>
                    {/each}
                </div>

                <div class="flex-[2] flex flex-col items-end">
                    <button
                        class="w-full py-3.5 bg-app-primary text-black font-black uppercase tracking-widest text-xs rounded-xl hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 disabled:scale-100 flex items-center justify-center gap-2 shadow-lg shadow-app-primary/20"
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
                        >-$3,000 Outing Fee</span
                    >
                </div>
            </div>
        </div>
    </div>

    <!-- Right Column: Results & Pit Board -->
    <div class="lg:col-span-5 space-y-6">
        <!-- Pit Board -->
        <div
            class="bg-[#121212] border-l-4 border-app-primary rounded-xl p-5 shadow-xl"
        >
            <div class="flex items-center justify-between mb-4">
                <span
                    class="text-[10px] font-black text-app-primary uppercase tracking-[0.2em] italic"
                    >Pit Board</span
                >
                <div
                    class="w-2 h-2 rounded-full bg-app-primary animate-pulse"
                ></div>
            </div>
            <div class="space-y-2">
                <p class="text-sm font-black italic text-white leading-tight">
                    {#if isSimulating}
                        TRACK STATUS: LIVE SESSION
                    {:else if lastResult}
                        GARAGE STATUS: DEBRIEFING
                    {:else}
                        TRACK STATUS: PITS OPEN
                    {/if}
                </p>
                <p class="text-[10px] font-bold text-white/40 leading-none">
                    DRV: {driver?.name?.toUpperCase() || "NONE"} • {circuit?.name?.toUpperCase() ||
                        "NO TRACK"}
                </p>
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
                        class="text-[10px] font-black text-white/40 uppercase tracking-widest"
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
                    class="text-3xl font-black italic text-white tabular-nums"
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

        <!-- Feedback -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl flex flex-col h-[350px]"
        >
            <div class="flex border-b border-app-border">
                <div
                    class="flex-1 py-3 text-center text-[10px] font-black uppercase tracking-widest border-b-2 border-app-primary text-white bg-white/5"
                >
                    Feedback
                </div>
            </div>

            <div class="flex-1 overflow-y-auto p-4 space-y-3 custom-scrollbar">
                {#if lastResult}
                    {#each lastResult.driverFeedback as msg}
                        <div
                            class="p-3 bg-white/5 rounded-lg border-l-2 border-app-primary"
                        >
                            <p
                                class="text-[11px] italic text-white/70 leading-relaxed font-medium"
                            >
                                "{msg}"
                            </p>
                        </div>
                    {/each}
                    {#if lastResult.driverFeedback.length === 0}
                        <div
                            class="p-4 flex flex-col items-center justify-center text-center opacity-30 mt-10"
                        >
                            <CheckCircle2 size={32} class="mb-3" />
                            <p class="text-[10px] font-black uppercase">
                                No Issues Reported
                            </p>
                        </div>
                    {/if}
                {:else}
                    <div
                        class="p-4 flex flex-col items-center justify-center text-center opacity-10 mt-20"
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
