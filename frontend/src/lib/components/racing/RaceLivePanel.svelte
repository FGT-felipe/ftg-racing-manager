<script lang="ts">
    import { onMount } from "svelte";
    import { fade, slide, fly } from "svelte/transition";
    import {
        Flag,
        Timer,
        Zap,
        AlertTriangle,
        Shield,
        Gauge,
        User,
        ChevronRight,
        Activity,
        Thermometer,
        Wind,
    } from "lucide-svelte";
    import { db } from "$lib/firebase/config";
    import { doc, onSnapshot } from "firebase/firestore";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { circuitService } from "$lib/services/circuit_service.svelte";

    let results = $state<any[]>([]);
    let raceInfo = $state<any>(null);
    let isLoading = $state(true);

    const nextEvent = $derived(seasonStore.nextEvent);
    const circuit = $derived(
        nextEvent
            ? circuitService.getCircuitProfile(nextEvent.circuitId)
            : null,
    );

    onMount(() => {
        if (!nextEvent || !seasonStore.value.season) {
            isLoading = false;
            return;
        }

        const raceDocId = `${seasonStore.value.season.id}_${nextEvent.id}`;
        const unsub = onSnapshot(doc(db, "races", raceDocId), (snap) => {
            if (snap.exists()) {
                const data = snap.data();
                raceInfo = data;
                results = data.raceResults || [];
            }
            isLoading = false;
        });

        return () => unsub();
    });

    function formatGap(gap: number) {
        if (gap === 0) return "LEADER";
        if (gap >= 999) return "DNF";
        return `+${gap.toFixed(3)}s`;
    }
</script>

<div class="space-y-6">
    {#if isLoading}
        <div
            class="flex flex-col items-center justify-center py-20 gap-4 opacity-50"
        >
            <div
                class="w-10 h-10 border-4 border-red-500 border-t-transparent rounded-full animate-spin"
            ></div>
            <span
                class="text-[10px] font-black uppercase tracking-widest text-red-500"
                >Connecting to Race Control...</span
            >
        </div>
    {:else if !raceInfo || results.length === 0}
        <div
            in:fade
            class="bg-black/40 border border-red-500/20 rounded-2xl p-12 flex flex-col items-center justify-center text-center gap-8 min-h-[500px] relative overflow-hidden"
        >
            <div
                class="absolute inset-0 bg-red-500/5 animate-pulse pointer-events-none"
            ></div>
            <div class="flex items-center gap-8 relative z-10">
                <div
                    class="w-24 h-24 rounded-3xl bg-red-500/20 flex items-center justify-center text-red-500 border border-red-500/30"
                >
                    <Flag size={48} />
                </div>
                <div class="text-left">
                    <div class="flex items-center gap-2 mb-2">
                        <div
                            class="w-3 h-3 rounded-full bg-red-500 animate-pulse"
                        ></div>
                        <span
                            class="text-xs font-black text-red-500 uppercase tracking-widest leading-none"
                            >Awaiting Green Flag</span
                        >
                    </div>
                    <h3
                        class="font-black text-4xl lg:text-5xl uppercase italic text-white tracking-tighter"
                    >
                        Live Session Pending
                    </h3>
                </div>
            </div>
            <p class="max-w-xl text-white/40 text-sm font-medium relative z-10">
                Data stream from {circuit?.name || "the track"} is currently inactive.
                The broadcast will start once the race director confirms the session
                launch.
            </p>
            <div
                class="px-8 py-5 bg-black/40 rounded-2xl border border-white/5 relative z-10"
            >
                <p
                    class="text-[10px] font-black text-white/20 uppercase tracking-[0.2em] mb-1"
                >
                    Status
                </p>
                <p class="text-xl font-black italic text-white uppercase">
                    Waiting for Race Start
                </p>
            </div>
        </div>
    {:else}
        <!-- Real-time Leaderboard UI -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <!-- Left: Standings -->
            <div class="lg:col-span-8 space-y-4">
                <div
                    class="bg-app-surface border border-app-border rounded-2xl overflow-hidden shadow-2xl"
                >
                    <div
                        class="p-6 border-b border-white/5 bg-[#121212] flex items-center justify-between"
                    >
                        <div class="flex items-center gap-3">
                            <Activity size={18} class="text-red-500" />
                            <h3
                                class="font-black text-xs uppercase tracking-widest italic"
                            >
                                Live Leaderboard
                            </h3>
                        </div>
                        <div class="flex items-center gap-4">
                            <div class="text-right">
                                <p
                                    class="text-[9px] font-black text-white/30 uppercase leading-none mb-1"
                                >
                                    Lap
                                </p>
                                <p
                                    class="text-lg font-black italic text-white tabular-nums leading-none"
                                >
                                    {raceInfo.lapCount || 0} / {raceInfo.totalLaps ||
                                        "--"}
                                </p>
                            </div>
                        </div>
                    </div>

                    <div
                        class="divide-y divide-white/5 overflow-y-auto max-h-[600px] custom-scrollbar"
                    >
                        {#each results as row, i}
                            <div
                                in:slide
                                class="p-4 flex items-center gap-4 hover:bg-white/[0.02] transition-colors"
                            >
                                <div
                                    class="w-8 h-8 rounded bg-black/40 flex items-center justify-center font-black italic text-xs {i <
                                    3
                                        ? 'text-red-500'
                                        : 'text-white/20'}"
                                >
                                    {i + 1}
                                </div>

                                <div class="flex-1 min-w-0">
                                    <div class="flex items-center gap-2">
                                        <p
                                            class="text-[13px] font-black text-white truncate uppercase"
                                        >
                                            {row.driverName}
                                        </p>
                                        {#if row.isPitStop}
                                            <span
                                                class="px-1.5 py-0.5 rounded bg-blue-500/20 text-blue-400 text-[8px] font-black uppercase"
                                                >Pits</span
                                            >
                                        {/if}
                                    </div>
                                    <p
                                        class="text-[9px] font-bold text-white/30 uppercase tracking-widest"
                                    >
                                        {row.teamName}
                                    </p>
                                </div>

                                <div class="text-right">
                                    <p
                                        class="text-xs font-black italic text-white tabular-nums mb-1"
                                    >
                                        {row.lastLapTime
                                            ? row.lastLapTime.toFixed(3)
                                            : "--.---"}
                                    </p>
                                    <p
                                        class="text-[9px] font-bold {i === 0
                                            ? 'text-green-500'
                                            : 'text-white/40'} uppercase tabular-nums"
                                    >
                                        {formatGap(row.gapToLeader)}
                                    </p>
                                </div>
                            </div>
                        {/each}
                    </div>
                </div>
            </div>

            <!-- Right: Track Telemetry -->
            <div class="lg:col-span-4 space-y-6">
                <!-- Track Info -->
                <div
                    class="bg-app-surface border border-app-border rounded-2xl p-6 space-y-6"
                >
                    <div class="flex items-center gap-2">
                        <Gauge size={16} class="text-red-500" />
                        <h4
                            class="text-[10px] font-black text-white/40 uppercase tracking-widest"
                        >
                            Track Telemetry
                        </h4>
                    </div>

                    {#if circuit}
                        <div class="space-y-4">
                            {#each Object.entries(circuit.characteristics) as [key, val]}
                                <div
                                    class="flex items-center justify-between p-3 bg-black/20 rounded-xl border border-white/5"
                                >
                                    <span
                                        class="text-[10px] font-black text-white/30 uppercase"
                                        >{key}</span
                                    >
                                    <span
                                        class="text-xs font-black text-white italic"
                                        >{val}</span
                                    >
                                </div>
                            {/each}
                        </div>
                    {/if}
                </div>

                <!-- Weather/Conditions placeholder (literal) -->
                <div
                    class="bg-black/40 border border-white/5 rounded-2xl p-6 flex flex-col items-center justify-center text-center gap-4 aspect-square"
                >
                    <div
                        class="w-12 h-12 rounded-full border-2 border-green-500/20 flex items-center justify-center text-green-500"
                    >
                        <Activity size={24} />
                    </div>
                    <div>
                        <p
                            class="text-lg font-black text-white italic uppercase"
                        >
                            Session Live
                        </p>
                        <p
                            class="text-[9px] font-bold text-white/30 uppercase tracking-[0.2em] mt-1"
                        >
                            Telemetry Sync Active
                        </p>
                    </div>
                </div>
            </div>
        </div>
    {/if}
</div>

<style>
    .custom-scrollbar::-webkit-scrollbar {
        width: 4px;
    }
    .custom-scrollbar::-webkit-scrollbar-track {
        background: rgba(255, 255, 255, 0.05);
    }
    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: rgba(239, 68, 68, 0.2);
        border-radius: 10px;
    }
</style>
