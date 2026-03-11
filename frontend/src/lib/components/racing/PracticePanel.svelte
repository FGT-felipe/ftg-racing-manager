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
        ShieldCheck,
        Gauge,
        AlertTriangle,
        CheckCircle2,
        History,
        Trash2,
        ChevronRight,
        Copy,
        Flag,
        Info,
        Lock,
        User,
    } from "lucide-svelte";
    import { onMount } from "svelte";
    import { fade, slide, fly } from "svelte/transition";

    let { carIndex = 0 } = $props();

    // Local state for sliders and additional fields
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
    let activeDriverId = $state<string | null>(null);

    const teamDrivers = $derived(driverStore.drivers);
    const driver = $derived(
        teamDrivers.find((d: Driver) => d.id === activeDriverId) ||
            (carIndex === 0 ? driverStore.carADriver : driverStore.carBDriver),
    );

    const nextEvent = $derived(seasonStore.nextEvent);
    const circuit = $derived(
        nextEvent
            ? circuitService.getCircuitProfile(nextEvent.circuitId)
            : null,
    );
    const history = $derived(
        driver ? setupStore.getHistoryByDriver(driver.id) : [],
    );

    onMount(() => {
        if (teamStore.value.team?.id) {
            setupStore.init(teamStore.value.team.id);
        }

        // Default to the driver assigned to this car
        const initialDriver =
            carIndex === 0 ? driverStore.carADriver : driverStore.carBDriver;
        if (initialDriver) activeDriverId = initialDriver.id;

        // Load latest setup from history if available
        if (history.length > 0) {
            const lastSetup = history[0].setupUsed;
            setup = { ...setup, ...lastSetup };
        }
    });

    async function runPractice() {
        if (!driver || !circuit || !teamStore.value.team) return;

        isSimulating = true;

        // Cost: $3,000 per lap
        const cost = 3000 * lapsToRun;
        if (teamStore.value.team.budget < cost) {
            alert("Insufficient funds for practice runs.");
            isSimulating = false;
            return;
        }

        // Apply selected style to the setup for this run
        const setupToRun = { ...setup, qualifyingStyle: currentDriverStyle };

        // Simulate laps
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
                setupToRun,
            );

            // Wait for visual feedback
            await new Promise((r) => setTimeout(r, 800));
        }

        isSimulating = false;
    }

    async function copyToQualifying() {
        if (!driver || !teamStore.value.team) return;

        try {
            const teamRef = doc(db, "teams", teamStore.value.team.id);
            const path = `weekStatus.driverSetups.${driver.id}.qualifying`;

            await updateDoc(teamRef, {
                [path]: { ...setup },
            });

            alert(`✓ Practice setup copied to Qualifying for ${driver.name}`);
        } catch (e) {
            console.error("Error copying setup:", e);
            alert("Error copying setup to Qualifying.");
        }
    }

    async function copyToRace() {
        if (!driver || !teamStore.value.team) return;

        try {
            const teamRef = doc(db, "teams", teamStore.value.team.id);
            const path = `weekStatus.driverSetups.${driver.id}.race`;

            await updateDoc(teamRef, {
                [path]: { ...setup },
            });

            alert(`✓ Practice setup copied to Race for ${driver.name}`);
        } catch (e) {
            console.error("Error copying setup:", e);
            alert("Error copying setup to Race.");
        }
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

<div class="space-y-6">
    <!-- Top Bar: Driver Selector & Circuit Intel -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <!-- Driver Selector -->
        <div
            class="bg-app-surface border border-app-border rounded-xl p-4 flex flex-wrap gap-2"
        >
            {#each teamDrivers as d}
                <button
                    class="px-3 py-1.5 rounded-lg border text-[10px] font-black uppercase transition-all flex items-center gap-2 {driver?.id ===
                    d.id
                        ? 'bg-app-primary border-app-primary text-app-primary-foreground'
                        : 'bg-app-text/5 border-app-border text-app-text/40'}"
                    onclick={() => (activeDriverId = d.id)}
                >
                    <User size={12} />
                    {d.name}
                </button>
            {/each}
        </div>

        <!-- Circuit Intel -->
        <div
            class="bg-app-surface border border-app-border rounded-xl p-4 flex items-center overflow-x-auto gap-2 no-scrollbar"
        >
            {#if circuit}
                {#each Object.entries(circuit.characteristics) as [key, val]}
                    <div
                        class="px-3 py-1.5 rounded-lg bg-blue-500/10 border border-blue-500/20 whitespace-nowrap"
                    >
                        <span
                            class="text-[9px] font-black text-blue-400 uppercase tracking-tighter"
                            >{key}: {val}</span
                        >
                    </div>
                {/each}
            {/if}
        </div>
    </div>

    <!-- Main Content Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <!-- Left Column: Controls -->
        <div class="lg:col-span-7 space-y-6">
            <!-- Setup Card -->
            <div
                class="bg-app-surface border border-app-border rounded-2xl p-6 relative overflow-hidden shadow-2xl"
            >
                <!-- Header with copy buttons -->
                <div class="flex items-center justify-between mb-8">
                    <div>
                        <h3
                            class="font-black text-xs text-app-text uppercase tracking-[0.2em]"
                        >
                            Practice Setup
                        </h3>
                    </div>
                    <div class="flex gap-2">
                        <button
                            onclick={copyToQualifying}
                            class="flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-app-primary/10 border border-app-primary/20 text-app-primary hover:bg-app-primary hover:text-app-primary-foreground transition-all"
                        >
                            <Timer size={12} />
                            <span class="text-[9px] font-black uppercase"
                                >Set Qualy</span
                            >
                        </button>
                        <button
                            onclick={copyToRace}
                            class="flex items-center gap-1.5 px-3 py-1.5 rounded-md bg-red-500/10 border border-red-500/20 text-red-500 hover:bg-red-500 hover:text-app-text transition-all"
                        >
                            <Flag size={12} />
                            <span class="text-[9px] font-black uppercase"
                                >Set Race</span
                            >
                        </button>
                    </div>
                </div>

                <!-- Sliders -->
                <div class="space-y-6">
                    {#each [{ label: "Front Wing", field: "frontWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400" }, { label: "Rear Wing", field: "rearWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400" }, { label: "Suspension", field: "suspension" as keyof CarSetup, icon: Navigation, color: "text-purple-400" }, { label: "Gear Ratio", field: "gearRatio" as keyof CarSetup, icon: Zap, color: "text-orange-400" }] as item}
                        <div class="space-y-3">
                            <div class="flex justify-between items-center px-1">
                                <div
                                    class="flex items-center gap-2 {item.color}"
                                >
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
                                    class="w-2.5 h-2.5 rounded-full {tc ===
                                    'soft'
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
                                    ? 'bg-app-text/10 border-app-border ' +
                                      style.color
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

                    <button
                        class="flex-[2] py-3.5 bg-app-primary text-app-primary-foreground font-black uppercase tracking-widest text-xs rounded-xl hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 disabled:scale-100 flex items-center justify-center gap-2 shadow-lg shadow-app-primary/20"
                        disabled={isSimulating || !driver}
                        onclick={runPractice}
                    >
                        {#if isSimulating}
                            <div
                                class="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin"
                            ></div>
                            Simulation Active
                        {:else}
                            <Timer size={16} />
                            Start Practice
                        {/if}
                    </button>
                </div>
            </div>
        </div>

        <!-- Right Column: Results & Pit Board -->
        <div class="lg:col-span-5 space-y-6">
            <!-- Pit Board -->
            <div
                class="bg-app-surface border-l-4 border-app-primary rounded-xl p-5 shadow-xl"
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
                    <p
                        class="text-sm font-black italic text-app-text leading-tight"
                    >
                        {#if isSimulating}
                            TRACK STATUS: LIVE SESSION
                        {:else if lastResult}
                            GARAGE STATUS: DEBRIEFING
                        {:else}
                            TRACK STATUS: PITS OPEN
                        {/if}
                    </p>
                    <p class="text-[10px] font-bold text-app-text/40 leading-none">
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
                            {(lastResult.setupConfidence * 100).toFixed(0)}%
                            CONF
                        </span>
                    {/if}
                </div>

                <div class="flex items-end justify-between">
                    <span
                        class="text-3xl font-black italic text-app-text tabular-nums"
                    >
                        {lastResult
                            ? formatTime(lastResult.lapTime)
                            : "0:00.000"}
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

            <!-- Feedback & History Tabs (Consolidated) -->
            <div
                class="bg-app-surface border border-app-border rounded-2xl flex flex-col h-[400px]"
            >
                <div class="flex border-b border-app-border">
                    <button
                        class="flex-1 py-3 text-[10px] font-black uppercase tracking-widest border-b-2 border-app-primary text-app-text bg-app-text/5"
                        >Feedback</button
                    >
                    <button
                        class="flex-1 py-3 text-[10px] font-black uppercase tracking-widest text-app-text/20 hover:text-app-text/40 transition-all"
                        >Laps</button
                    >
                </div>

                <div
                    class="flex-1 overflow-y-auto p-4 space-y-3 custom-scrollbar"
                >
                    {#if lastResult}
                        {#each lastResult.driverFeedback as msg}
                            <div
                                class="p-3 bg-app-text/5 rounded-lg border-l-2 border-red-500/50"
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
    .no-scrollbar::-webkit-scrollbar {
        display: none;
    }
    .no-scrollbar {
        -ms-overflow-style: none;
        scrollbar-width: none;
    }
</style>
