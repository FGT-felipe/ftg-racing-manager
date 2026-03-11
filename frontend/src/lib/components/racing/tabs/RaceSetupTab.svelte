<script lang="ts">
    import { onMount, untrack } from "svelte";
    import { fade, slide, fly } from "svelte/transition";
    import {
        Flag,
        Gauge,
        History,
        Settings,
        Fuel,
        Zap,
        Trash2,
        Plus,
        ChevronRight,
        Timer,
        AlertTriangle,
        ShieldCheck,
        Save,
        Activity
    } from "lucide-svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { timeService } from "$lib/services/time_service.svelte";
    import {
        type CarSetup,
        TyreCompound,
        DriverStyle,
        type Driver,
    } from "$lib/types";
    import { db } from "$lib/firebase/config";
    import { doc, updateDoc, getDoc } from "firebase/firestore";

    let { driverId } = $props<{ driverId: string | null }>();

    let isSaving = $state(false);

    let strategy = $state<CarSetup>({
        frontWing: 50,
        rearWing: 50,
        suspension: 50,
        gearRatio: 50,
        tyreCompound: TyreCompound.medium,
        pitStops: [],
        initialFuel: 50,
        pitStopFuel: [],
        qualifyingStyle: DriverStyle.normal,
        raceStyle: DriverStyle.normal,
        pitStopStyles: [],
    });

    const teamDrivers = $derived(driverStore.drivers);
    const driver = $derived(teamDrivers.find((d: Driver) => d.id === driverId));
    const team = $derived(teamStore.value.team);

    let qualyCompounds = $state<Record<string, TyreCompound>>({});

    // Watch for driver changes to load their RACE setup and Qualy tyre
    $effect(() => {
        if (driverId && team) {
            untrack(() => {
                const existing =
                    team.weekStatus?.driverSetups?.[driverId]?.race;
                if (existing) {
                    strategy = { ...strategy, ...existing };
                } else {
                    // Fallback to Qualifying or Practice setup if Race strategy isn't saved yet
                    const qualy =
                        team.weekStatus?.driverSetups?.[driverId]?.qualifying;
                    const prac =
                        team.weekStatus?.driverSetups?.[driverId]?.practice;
                    if (qualy) {
                        strategy = { ...strategy, ...qualy };
                    } else if (prac) {
                        strategy = { ...strategy, ...prac };
                    }
                }

                // Also fetch the qualy grid constraints
                fetchQualyConstraints(driverId);
            });
        }
    });

    async function fetchQualyConstraints(dId: string) {
        try {
            const nextEvent = seasonStore.nextEvent;
            if (nextEvent && seasonStore.value.season) {
                const raceDocId = `${seasonStore.value.season.id}_${nextEvent.id}`;
                const raceSnap = await getDoc(doc(db, "races", raceDocId));
                if (raceSnap.exists()) {
                    const data = raceSnap.data();
                    const grid = data.qualifyingResults || data.qualyGrid;
                    if (grid && Array.isArray(grid)) {
                        grid.forEach((row) => {
                            if (row.driverId && row.tyreCompound) {
                                qualyCompounds[row.driverId] =
                                    row.tyreCompound as TyreCompound;
                            }
                        });

                        // Force lock tyre if they qualified
                        if (qualyCompounds[dId]) {
                            strategy.tyreCompound = qualyCompounds[dId];
                        }
                    }
                }
            }
        } catch (e) {
            console.error("Error fetching constraints", e);
        }
    }

    async function saveStrategy() {
        if (!driver || !team) return;
        isSaving = true;
        try {
            const teamRef = doc(db, "teams", team.id);
            const path = `weekStatus.driverSetups.${driver.id}.race`;
            await updateDoc(teamRef, {
                [path]: { ...strategy },
            });
            alert("✓ Race Strategy Saved");
        } catch (e) {
            console.error("Error saving strategy:", e);
            alert("Error saving strategy.");
        } finally {
            isSaving = false;
        }
    }

    function addPitStop() {
        strategy.pitStops = [...strategy.pitStops, TyreCompound.medium];
        strategy.pitStopFuel = [...strategy.pitStopFuel, 40];
        strategy.pitStopStyles = [
            ...strategy.pitStopStyles,
            DriverStyle.normal,
        ];
    }

    function removePitStop(index: number) {
        strategy.pitStops = strategy.pitStops.filter((_, i) => i !== index);
        strategy.pitStopFuel = strategy.pitStopFuel.filter(
            (_, i) => i !== index,
        );
        strategy.pitStopStyles = strategy.pitStopStyles.filter(
            (_, i) => i !== index,
        );
    }

    const styleConfigs = [
        {
            id: DriverStyle.defensive,
            icon: ChevronRight,
            color: "text-blue-400",
            label: "DEFE",
        },
        {
            id: DriverStyle.normal,
            icon: Zap,
            color: "text-green-400",
            label: "NORM",
        },
        {
            id: DriverStyle.offensive,
            icon: Zap,
            color: "text-orange-400",
            label: "OFFE",
        },
        {
            id: DriverStyle.mostRisky,
            icon: Zap,
            color: "text-red-500",
            label: "RISK",
        },
    ];
</script>

{#if timeService.currentStatus === 'qualifying'}
    <!-- Qualy in Progress Holding View -->
    <div class="flex flex-col items-center justify-center p-12 text-center min-h-[400px]">
        <Activity size={64} class="text-[#FFB800] mb-6 animate-pulse" />
        <h2 class="text-3xl font-black italic text-app-text uppercase tracking-widest mb-4">
            Qualifying Session in Progress
        </h2>
        <p class="text-sm text-app-text/60 max-w-lg mb-8 leading-relaxed">
            The servers are currently processing the official Qualifying session. 
            Race setups cannot be modified until the grid is finalized.
        </p>
        <div class="flex items-center gap-2 text-[#FFB800] px-4 py-2 bg-[#FFB800]/10 rounded-lg">
            <Timer size={16} />
            <span class="text-[10px] font-black uppercase tracking-widest">Awaiting Grid Results...</span>
        </div>
    </div>
{:else if timeService.currentStatus === 'race'}
    <!-- Race in Progress Holding View -->
    <div class="flex flex-col items-center justify-center p-12 text-center min-h-[400px]">
        <Flag size={64} class="text-[#E040FB] mb-6 animate-bounce" />
        <h2 class="text-3xl font-black italic text-app-text uppercase tracking-widest mb-4">
            Race Session in Progress
        </h2>
        <p class="text-sm text-app-text/60 max-w-lg mb-8 leading-relaxed">
            The Grand Prix is currently underway! 
            You can no longer change your strategy. Head over to the Live Timing screen to see the action!
        </p>
        <div class="flex items-center gap-2 text-[#E040FB] px-4 py-2 bg-[#E040FB]/10 rounded-lg">
            <Timer size={16} />
            <span class="text-[10px] font-black uppercase tracking-widest">Simulating Race...</span>
        </div>
    </div>
{:else}
<div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
    <!-- Initial Setup & Fuel -->
    <div class="lg:col-span-12 space-y-6">
        <div
            class="bg-app-surface border border-app-border rounded-2xl p-6 shadow-xl"
        >
            <div class="flex items-center justify-between mb-8">
                <h3
                    class="font-black text-xs text-app-text uppercase tracking-[0.2em] italic"
                >
                    Race Start Configuration
                </h3>
                <div
                    class="px-3 py-1 bg-green-500/10 border border-green-500/20 rounded flex items-center gap-2"
                >
                    <ShieldCheck size={12} class="text-green-500" />
                    <span class="text-[9px] font-black text-app-text/60 uppercase"
                        >Validated</span
                    >
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-10">
                <!-- Fuel -->
                <div class="space-y-6">
                    <div class="flex justify-between items-center">
                        <div class="flex items-center gap-2 text-cyan-400">
                            <Fuel size={16} />
                            <span
                                class="text-[10px] font-black uppercase tracking-widest"
                                >Initial Fuel Load</span
                            >
                        </div>
                        <span class="text-xl font-black text-app-text italic"
                            >{strategy.initialFuel} L</span
                        >
                    </div>
                    <input
                        type="range"
                        min="5"
                        max="100"
                        bind:value={strategy.initialFuel}
                        class="w-full h-2 bg-app-text/5 rounded-full appearance-none cursor-pointer accent-cyan-400"
                    />
                    <div
                        class="flex justify-between text-[9px] font-bold text-app-text/20 uppercase"
                    >
                        <span>Light (Min)</span>
                        <span>Heavy (Full)</span>
                    </div>
                </div>

                <!-- Starting Tyre & Style -->
                <div class="grid grid-cols-2 gap-6">
                    <div class="space-y-4">
                        <span
                            class="text-[10px] font-black text-app-text/30 uppercase tracking-widest"
                        >
                            Start Tyres {driverId && qualyCompounds[driverId]
                                ? "(Qualy Locked)"
                                : "(Free Choice)"}
                        </span>
                        <div class="grid grid-cols-2 gap-2">
                            {#each [TyreCompound.soft, TyreCompound.medium, TyreCompound.hard] as tc}
                                <div
                                    class="py-2 rounded-lg border text-center text-[9px] font-black transition-all {strategy.tyreCompound ===
                                    tc
                                        ? 'bg-app-primary border-app-primary text-app-primary-foreground'
                                        : 'bg-app-text/5 border-app-border text-app-text/40'} {driverId &&
                                    qualyCompounds[driverId] &&
                                    qualyCompounds[driverId] !== tc
                                        ? 'opacity-30'
                                        : ''}"
                                >
                                    {tc.toUpperCase()}
                                </div>
                            {/each}
                        </div>
                    </div>
                    <div class="space-y-4">
                        <span
                            class="text-[10px] font-black text-app-text/30 uppercase tracking-widest"
                            >Initial Pace</span
                        >
                        <div class="grid grid-cols-2 gap-2">
                            {#each styleConfigs as style}
                                <button
                                    class="py-2 rounded-lg border text-[9px] font-black transition-all {strategy.raceStyle ===
                                    style.id
                                        ? 'bg-app-primary border-app-primary text-app-primary-foreground'
                                        : 'bg-app-text/5 border-app-border text-app-text/40'}"
                                    onclick={() =>
                                        (strategy.raceStyle = style.id)}
                                >
                                    {style.label}
                                </button>
                            {/each}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Pit Stop Builder -->
    <div class="lg:col-span-12 space-y-4">
        <div class="flex items-center justify-between px-2">
            <h3
                class="font-black text-xs text-app-text uppercase tracking-[0.2em] italic"
            >
                Pit Stop Strategy
            </h3>
            <button
                onclick={addPitStop}
                disabled={strategy.pitStops.length >= 4}
                class="flex items-center gap-2 px-4 py-2 rounded-xl bg-app-primary/10 border border-app-primary/20 text-app-primary hover:bg-app-primary hover:text-app-primary-foreground transition-all disabled:opacity-30"
            >
                <Plus size={14} />
                <span class="text-[10px] font-black uppercase"
                    >Add Pit Stop</span
                >
            </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {#each strategy.pitStops as compound, i}
                <div
                    in:fly={{ y: 20 }}
                    class="bg-app-surface border border-app-border rounded-2xl p-5 space-y-6 relative overflow-hidden group"
                >
                    <div
                        class="absolute top-0 left-0 w-1 h-full bg-app-primary"
                    ></div>

                    <div class="flex items-center justify-between">
                        <div class="flex items-center gap-2">
                            <div
                                class="w-6 h-6 rounded-lg bg-app-text/5 flex items-center justify-center text-[10px] font-black"
                            >
                                #{i + 1}
                            </div>
                            <span
                                class="text-[10px] font-black uppercase tracking-widest text-app-text/60"
                                >Stint Configuration</span
                            >
                        </div>
                        <button
                            onclick={() => removePitStop(i)}
                            class="text-app-text/20 hover:text-red-500 transition-colors"
                        >
                            <Trash2 size={14} />
                        </button>
                    </div>

                    <div class="space-y-4">
                        <!-- Tyre -->
                        <div class="flex items-center justify-between">
                            <span
                                class="text-[10px] font-black text-app-text/30 uppercase"
                                >Compound</span
                            >
                            <div class="flex gap-1.5">
                                {#each [TyreCompound.soft, TyreCompound.medium, TyreCompound.hard] as tc}
                                    <button
                                        class="w-8 h-8 rounded-lg border flex items-center justify-center text-[9px] font-black transition-all {strategy
                                            .pitStops[i] === tc
                                            ? 'bg-app-text/10 border-app-border text-app-primary'
                                            : 'bg-app-text/5 border-transparent text-app-text/20'}"
                                        onclick={() =>
                                            (strategy.pitStops[i] = tc)}
                                    >
                                        {tc[0].toUpperCase()}
                                    </button>
                                {/each}
                            </div>
                        </div>

                        <!-- Fuel -->
                        <div class="space-y-2">
                            <div
                                class="flex justify-between text-[9px] font-black uppercase text-app-text/40"
                            >
                                <span>Fuel to Add</span>
                                <span class="text-app-text"
                                    >{strategy.pitStopFuel[i]} L</span
                                >
                            </div>
                            <input
                                type="range"
                                min="0"
                                max="80"
                                bind:value={strategy.pitStopFuel[i]}
                                class="w-full h-1 bg-app-text/5 rounded-full appearance-none cursor-pointer accent-white/20"
                            />
                        </div>

                        <!-- Style -->
                        <div class="flex items-center justify-between">
                            <span
                                class="text-[10px] font-black text-app-text/30 uppercase"
                                >Agression</span
                            >
                            <div class="flex gap-1">
                                {#each styleConfigs as style}
                                    <button
                                        class="w-7 h-7 rounded bg-app-text/5 flex items-center justify-center transition-all {strategy
                                            .pitStopStyles[i] === style.id
                                            ? 'bg-app-text/10 text-app-text border border-app-border'
                                            : 'text-app-text/20'}"
                                        onclick={() =>
                                            (strategy.pitStopStyles[i] =
                                                style.id)}
                                    >
                                        <style.icon size={12} />
                                    </button>
                                {/each}
                            </div>
                        </div>
                    </div>
                </div>
            {/each}

            {#if strategy.pitStops.length === 0}
                <div
                    class="border border-dashed border-app-border rounded-2xl p-10 flex flex-col items-center justify-center text-center opacity-20"
                >
                    <History size={32} class="mb-3" />
                    <p class="text-[10px] font-black uppercase tracking-widest">
                        No Pit Stops Planned
                    </p>
                    <p class="text-[8px] font-bold mt-1">
                        Single stint strategy (No Stops)
                    </p>
                </div>
            {/if}
        </div>
    </div>

    <!-- Actions -->
    <div class="lg:col-span-12 pt-4">
        <button
            class="w-full py-5 bg-app-primary text-app-primary-foreground font-black uppercase tracking-[0.2em] text-xs rounded-2xl hover:scale-[1.01] active:scale-95 transition-all shadow-xl shadow-app-primary/10 flex items-center justify-center gap-3 disabled:opacity-50"
            disabled={isSaving || !driver}
            onclick={saveStrategy}
        >
            {#if isSaving}
                <div
                    class="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin"
                ></div>
                Updating Telemetry...
            {:else}
                <Save size={18} />
                Submit Race Strategy
            {/if}
        </button>
    </div>
</div>
{/if}
