<script lang="ts">
    import { db } from "$lib/firebase/config";
    import { doc, updateDoc, increment } from "firebase/firestore";
    import { teamStore } from "$lib/stores/team.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import {
        type CarSetup,
        TyreCompound,
        DriverStyle,
        type Driver,
    } from "$lib/types";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { circuitService } from "$lib/services/circuit_service.svelte";
    import { practiceService } from "$lib/services/practice_service.svelte";
    import {
        Timer,
        Zap,
        Wind,
        Navigation,
        AlertTriangle,
        Info,
        ChevronRight,
        Flag,
    } from "lucide-svelte";
    import { onMount, untrack } from "svelte";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";

    let { driverId } = $props<{ driverId: string | null }>();

    // Derived Data
    const teamDrivers = $derived(driverStore.drivers);
    const driver = $derived(teamDrivers.find((d: Driver) => d.id === driverId));
    const team = $derived(teamStore.value.team);
    const nextEvent = $derived(seasonStore.nextEvent);
    const circuit = $derived(
        nextEvent
            ? circuitService.getCircuitProfile(nextEvent.circuitId)
            : null,
    );

    // Setup State
    let setup = $state<CarSetup>({
        frontWing: 50,
        rearWing: 50,
        suspension: 50,
        gearRatio: 50,
        tyreCompound: TyreCompound.soft,
        pitStops: [],
        initialFuel: 10,
        pitStopFuel: [],
        qualifyingStyle: DriverStyle.mostRisky,
        raceStyle: DriverStyle.normal,
        pitStopStyles: [],
    });

    // Qualifying State
    const MAX_ATTEMPTS = 6;
    let isSimulating = $state(false);
    let driverStatus = $derived.by(() => {
        if (!team || !driverId) return null;
        return team.weekStatus?.driverSetups?.[driverId];
    });

    let attempts = $derived(driverStatus?.qualifyingAttempts || 0);
    let bestTime = $derived(driverStatus?.qualifyingBestTime || 0);
    let isDnf = $derived(driverStatus?.qualifyingDnf || false);
    let isParcFerme = $derived(driverStatus?.qualifyingParcFerme || false);

    // Table Data
    let qualyResults = $derived.by(() => {
        if (!team) return [];
        const results = [];

        // Push currently stored times
        for (const drv of teamDrivers) {
            const st = team?.weekStatus?.driverSetups?.[drv.id];
            results.push({
                driverId: drv.id,
                name: drv?.name || "Unknown",
                gender: drv?.gender || "male",
                bestTime: st?.qualifyingBestTime || 0,
                laps: st?.qualifyingLaps || 0,
                compound: st?.qualifyingBestCompound || "soft",
                isDnf: st?.qualifyingDnf || false,
                attempts: st?.qualifyingAttempts || 0,
            });
        }

        // Sort: Active times first (ascending), then 0.0 times
        return results.sort((a, b) => {
            if (a.bestTime === 0 && b.bestTime === 0) return 0;
            if (a.bestTime === 0) return 1;
            if (b.bestTime === 0) return -1;
            return a.bestTime - b.bestTime;
        });
    });

    // Watch for driver changes to load their QUALY setup
    $effect(() => {
        if (driverId && team) {
            untrack(() => {
                const existing =
                    team.weekStatus?.driverSetups?.[driverId]?.qualifying;
                if (existing) {
                    setup = { ...setup, ...existing };
                } else {
                    // Fallback to practice if Qualy doesn't exist yet
                    const prac =
                        team.weekStatus?.driverSetups?.[driverId]?.practice;
                    if (prac) setup = { ...setup, ...prac };
                }
            });
        }
    });

    async function runQualyAttempt() {
        if (!driver || !circuit || !team) return;
        if (attempts >= MAX_ATTEMPTS || isDnf) return;

        isSimulating = true;

        try {
            // First attempt charges the $10,000 Entry Fee
            if (attempts === 0) {
                const cost = 10000;
                if (team.budget < cost) {
                    alert(
                        "Insufficient funds for Qualy Entry. Cost is $10,000.",
                    );
                    isSimulating = false;
                    return;
                }
                const teamRef = doc(db, "teams", team.id);
                await updateDoc(teamRef, {
                    budget: increment(-cost),
                });
            }

            // Copy setup for sim
            const setupToRun = {
                ...setup,
                qualifyingStyle: DriverStyle.mostRisky,
            };

            // Simulate Flying Lap
            const result = practiceService.simulatePracticeRun(
                circuit,
                team,
                driver,
                setupToRun,
            );

            // Wait for visual effect
            await new Promise((r) => setTimeout(r, 1500));

            const teamRef = doc(db, "teams", team.id);
            const pathPrefix = `weekStatus.driverSetups.${driver.id}`;
            const newAttempts = attempts + 1;

            if (result.isCrashed) {
                await updateDoc(teamRef, {
                    [`${pathPrefix}.qualifyingAttempts`]: MAX_ATTEMPTS,
                    [`${pathPrefix}.qualifyingLaps`]: increment(2), // Out + Flying
                    [`${pathPrefix}.qualifyingDnf`]: true,
                    [`${pathPrefix}.qualifyingParcFerme`]: true,
                    [`${pathPrefix}.qualifying`]: setup,
                });
                alert(`${driver.name} crashed during the Qualifying attempt!`);
            } else {
                // Determine if new personal best
                const currentBest = bestTime;
                let newBest = currentBest;
                let bestCompound = setup.tyreCompound;

                if (currentBest === 0 || result.lapTime < currentBest) {
                    newBest = result.lapTime;
                } else {
                    bestCompound =
                        driverStatus?.qualifyingBestCompound ||
                        setup.tyreCompound;
                }

                await updateDoc(teamRef, {
                    [`${pathPrefix}.qualifyingAttempts`]: newAttempts,
                    [`${pathPrefix}.qualifyingBestTime`]: newBest,
                    [`${pathPrefix}.qualifyingLaps`]: increment(3), // Out + Flying + In
                    [`${pathPrefix}.qualifyingBestCompound`]: bestCompound,
                    [`${pathPrefix}.qualifyingParcFerme`]: true,
                    [`${pathPrefix}.qualifying`]: setup,
                });
            }
        } catch (e) {
            console.error(e);
            alert("Error running qualifying lap.");
        }

        isSimulating = false;
    }

    function formatTime(seconds: number) {
        if (seconds === 0) return "--:---.---";
        if (seconds >= 999) return "DNF";
        const mins = Math.floor(seconds / 60);
        const secs = (seconds % 60).toFixed(3);
        return `${mins}:${secs.padStart(6, "0")}`;
    }
</script>

<div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
    <!-- Left Column: Setup Controls -->
    <div class="lg:col-span-6 space-y-6">
        {#if attempts === 0 && !isSimulating}
            <div
                class="bg-blue-500/10 border border-blue-500/30 rounded-xl p-4 flex items-start gap-3"
            >
                <Info size={16} class="text-blue-400 mt-0.5" />
                <div>
                    <h4
                        class="text-xs font-black uppercase text-blue-400 mb-1 tracking-widest"
                    >
                        Entry Fee Required
                    </h4>
                    <p class="text-[11px] text-blue-400/80 leading-relaxed">
                        The first Qualifying Attempt charges a $10,000
                        regulatory entry fee. Subsequent attempts are free (max
                        6). Once you run a lap, Parc Fermé rules apply (locking
                        Rear Wing, Suspension, Gear Ratio).
                    </p>
                </div>
            </div>
        {/if}

        <div
            class="bg-[#121212] border border-white/10 rounded-2xl p-6 relative overflow-hidden shadow-2xl"
        >
            <div class="flex items-center justify-between mb-8">
                <h3
                    class="font-black text-xs text-white uppercase tracking-[0.2em]"
                >
                    Qualifying Setup
                </h3>
                {#if isParcFerme}
                    <div
                        class="px-2 py-1 bg-red-500/20 text-red-500 border border-red-500/30 rounded text-[9px] font-black uppercase tracking-widest"
                    >
                        Parc Fermé Active
                    </div>
                {/if}
            </div>

            <!-- Sliders -->
            <div class="space-y-6">
                {#each [{ label: "Front Wing", field: "frontWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400", locked: false }, { label: "Rear Wing", field: "rearWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400", locked: isParcFerme }, { label: "Suspension", field: "suspension" as keyof CarSetup, icon: Navigation, color: "text-purple-400", locked: isParcFerme }, { label: "Gear Ratio", field: "gearRatio" as keyof CarSetup, icon: Zap, color: "text-orange-400", locked: isParcFerme }] as item}
                    <div
                        class="space-y-3 {item.locked
                            ? 'opacity-50 grayscale'
                            : ''}"
                    >
                        <div class="flex justify-between items-center px-1">
                            <div class="flex items-center gap-2 {item.color}">
                                <item.icon size={14} />
                                <span
                                    class="text-[10px] font-black uppercase tracking-widest"
                                    >{item.label}</span
                                >
                                {#if item.locked}
                                    <span class="text-[8px] text-red-400 ml-1"
                                        >(LOCKED)</span
                                    >
                                {/if}
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
                            disabled={item.locked}
                            class="w-full accent-current h-1.5 bg-white/5 rounded-full appearance-none {item.locked
                                ? 'cursor-not-allowed'
                                : 'cursor-pointer'} {item.color.replace(
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
                    >Qualifying Compound</span
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
    </div>

    <!-- Right Column: Status & Attempts -->
    <div class="lg:col-span-6 space-y-6 flex flex-col">
        <!-- Action Trigger -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl p-6 flex flex-col gap-4"
        >
            <div class="flex justify-between items-start">
                <div>
                    <h4
                        class="text-[10px] font-black text-white/40 uppercase tracking-widest mb-1"
                    >
                        Qualy Attempts
                    </h4>
                    <div class="flex gap-1 mt-2">
                        {#each Array(MAX_ATTEMPTS) as _, i}
                            <div
                                class="w-6 h-2 rounded {i < attempts
                                    ? isDnf && i === attempts - 1
                                        ? 'bg-red-500'
                                        : 'bg-app-primary'
                                    : 'bg-white/10'}"
                            ></div>
                        {/each}
                    </div>
                </div>
                <div class="text-right">
                    <h4
                        class="text-[10px] font-black text-white/40 uppercase tracking-widest mb-1"
                    >
                        Best Lap Time
                    </h4>
                    <span
                        class="text-2xl font-black italic text-white tabular-nums"
                    >
                        {formatTime(bestTime)}
                    </span>
                </div>
            </div>

            {#if isDnf}
                <div
                    class="bg-red-500/10 border border-red-500/20 text-red-500 rounded-xl p-4 flex flex-col items-center justify-center text-center mt-4"
                >
                    <AlertTriangle size={24} class="mb-2" />
                    <span class="text-xs font-black uppercase"
                        >Driver Crashed - Session Over</span
                    >
                </div>
            {:else if attempts >= MAX_ATTEMPTS}
                <div
                    class="bg-white/5 border border-white/10 text-white/50 rounded-xl p-4 flex flex-col items-center justify-center text-center mt-4"
                >
                    <Flag size={24} class="mb-2" />
                    <span class="text-xs font-black uppercase"
                        >Max Attempts Reached</span
                    >
                </div>
            {:else}
                <button
                    class="w-full mt-4 py-4 bg-app-primary text-black font-black uppercase tracking-widest text-sm rounded-xl hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 disabled:scale-100 flex items-center justify-center gap-2 shadow-lg shadow-app-primary/20"
                    disabled={isSimulating || !driver}
                    onclick={runQualyAttempt}
                >
                    {#if isSimulating}
                        <div
                            class="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin"
                        ></div>
                        Pushing...
                    {:else}
                        <Timer size={16} />
                        Run Flying Lap
                    {/if}
                </button>
            {/if}
        </div>

        <!-- Official Results Table (Mini View) -->
        <div
            class="flex-1 bg-[#121212] border border-white/10 rounded-2xl flex flex-col overflow-hidden"
        >
            <div
                class="bg-app-primary/10 border-b border-app-primary/20 px-4 py-3 flex items-center gap-2"
            >
                <Flag size={14} class="text-app-primary" />
                <span
                    class="text-[10px] font-black uppercase tracking-widest text-app-primary"
                    >Current Standings</span
                >
            </div>

            <!-- Table Header -->
            <div class="flex px-4 py-2 bg-white/5 border-b border-white/5">
                <span class="w-8 text-[9px] font-black text-white/30 uppercase"
                    >Pos</span
                >
                <span
                    class="flex-1 text-[9px] font-black text-white/30 uppercase"
                    >Driver</span
                >
                <span
                    class="w-12 text-[9px] font-black text-white/30 uppercase text-center"
                    >Tyre</span
                >
                <span
                    class="w-20 text-[9px] font-black text-white/30 uppercase text-right"
                    >Time</span
                >
            </div>

            <!-- Table Body -->
            <div class="flex-1 overflow-y-auto custom-scrollbar p-2">
                {#each qualyResults as row, idx}
                    <div
                        class="flex items-center px-2 py-2.5 rounded-lg {row.driverId ===
                        driverId
                            ? 'bg-app-primary/10'
                            : 'hover:bg-white/5'} transition-colors"
                    >
                        <span
                            class="w-8 text-xs font-black {row.bestTime > 0
                                ? idx < 3
                                    ? 'text-app-primary'
                                    : 'text-white/80'
                                : 'text-white/30'}"
                        >
                            {row.bestTime > 0 ? idx + 1 : "-"}
                        </span>

                        <div class="flex-1 flex items-center gap-2 min-w-0">
                            <DriverAvatar
                                id={row.driverId}
                                seed={row.driverId}
                                gender={row.gender || "male"}
                                size={16}
                            />
                            <span
                                class="text-xs font-bold text-white truncate {row.driverId ===
                                driverId
                                    ? 'text-app-primary'
                                    : ''}"
                            >
                                {row.name}
                            </span>
                        </div>

                        <div class="w-12 flex justify-center">
                            {#if row.bestTime > 0}
                                <div
                                    class="w-3 h-3 rounded-full {row.compound ===
                                    'soft'
                                        ? 'bg-red-500'
                                        : row.compound === 'medium'
                                          ? 'bg-yellow-500'
                                          : row.compound === 'hard'
                                            ? 'bg-white'
                                            : 'bg-blue-500'}"
                                ></div>
                            {:else}
                                <span class="text-white/20">-</span>
                            {/if}
                        </div>

                        <div class="w-20 text-right">
                            <span
                                class="text-xs font-black italic {row.isDnf
                                    ? 'text-red-500'
                                    : row.bestTime > 0
                                      ? 'text-white'
                                      : 'text-white/30'}"
                            >
                                {formatTime(row.bestTime)}
                            </span>
                        </div>
                    </div>
                {/each}
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
