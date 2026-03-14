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
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
    import { circuitService } from "$lib/services/circuit_service.svelte";
    import { flip } from "svelte/animate";
    import { t } from "$lib/utils/i18n";

    let results = $state<any[]>([]);
    let raceInfo = $state<any>(null);
    let events = $state<any[]>([]);
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
                // Sort events by lap descending
                events = (data.events || []).sort((a: any, b: any) => b.lap - a.lap);
            }
            isLoading = false;
        });

        return () => unsub();
    });

    function formatGap(gap: number) {
        if (gap === 0) return t("leader");
        if (gap >= 999) return t("dnf");
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
                >{t('connecting_race_control')}</span
            >
        </div>
    {:else if !raceInfo || results.length === 0}
        <div
            in:fade
            class="bg-app-surface/60 backdrop-blur-xl border border-app-border rounded-3xl p-12 flex flex-col items-center justify-center text-center gap-10 min-h-[500px] relative overflow-hidden shadow-2xl"
        >
            <div
                class="absolute inset-0 bg-primary-color/5 animate-pulse pointer-events-none"
            ></div>
            <div class="flex flex-col items-center gap-6 relative z-10">
                <div
                    class="w-24 h-24 rounded-3xl bg-app-error/10 flex items-center justify-center text-app-error border border-app-error/20 shadow-lg"
                >
                    <Flag size={48} />
                </div>
                <div class="flex flex-col items-center">
                    <div class="flex items-center gap-2.5 mb-4 bg-app-error/10 px-4 py-1.5 rounded-full border border-app-error/20">
                        <div
                            class="w-2 h-2 rounded-full bg-app-error animate-pulse"
                        ></div>
                        <span
                            class="text-[10px] font-black text-app-error uppercase tracking-[0.2em] leading-none"
                            >{t('awaiting_green_flag')}</span
                        >
                    </div>
                    <h3
                        class="font-black text-4xl lg:text-6xl uppercase italic text-app-text tracking-tighter leading-[0.9]"
                    >
                        {t('live_leaderboard')} <span class="text-app-error">{t('dnf')}</span>
                    </h3>
                </div>
            </div>
            <p class="max-w-md text-app-text/60 text-sm font-medium leading-relaxed relative z-10">
                {t('stream_inactive', { name: circuit?.name || "the track" })}
                {t('broadcast_start_wait')}
            </p>
            <div
                class="px-10 py-6 bg-app-surface border border-app-border rounded-2xl relative z-10 shadow-xl group hover:scale-105 transition-transform duration-300"
            >
                <p
                    class="text-[9px] font-black text-app-text/30 uppercase tracking-[0.3em] mb-2"
                >
                    {t('status')}
                </p>
                <p class="text-2xl font-black italic text-app-text uppercase tracking-tight">
                    {t('waiting_race_start')}
                </p>
            </div>
        </div>
    {:else}
        <!-- Real-time Leaderboard UI -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
            <!-- Left: Standings (reduced to col-span-5) -->
            <div class="lg:col-span-5 space-y-4">
                <div
                    class="bg-app-surface border border-app-border rounded-2xl overflow-hidden shadow-2xl"
                >
                    <div
                        class="p-6 border-b border-app-border bg-app-surface flex items-center justify-between"
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
                                    class="text-[9px] font-black text-app-text/30 uppercase leading-none mb-1"
                                >
                                    Lap
                                </p>
                                <p
                                    class="text-lg font-black italic text-app-text tabular-nums leading-none"
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
                        {#each results as row, i (row.driverId)}
                            <div
                                in:slide
                                animate:flip={{ duration: 400 }}
                                class="p-4 flex items-center gap-4 hover:bg-white/[0.02] transition-colors"
                            >
                                <div
                                    class="w-8 h-8 rounded bg-app-text/40 flex items-center justify-center font-black italic text-xs {i <
                                    3
                                        ? 'text-red-500'
                                        : 'text-app-text/20'}"
                                >
                                    {i + 1}
                                </div>

                                <div class="flex-1 min-w-0">
                                    <div class="flex items-center gap-2">
                                        <p
                                            class="text-[13px] font-black text-app-text truncate uppercase"
                                        >
                                            {row.driverName}
                                        </p>
                                        <CountryFlag countryCode={row.countryCode} size="xs" />
                                        {#if row.isPitStop}
                                            <span
                                                class="px-1.5 py-0.5 rounded bg-blue-500/20 text-blue-400 text-[8px] font-black uppercase"
                                                >Pits</span
                                            >
                                        {/if}
                                    </div>
                                    <p
                                        class="text-[9px] font-bold text-app-text/30 uppercase tracking-widest"
                                    >
                                        {row.teamName}
                                    </p>
                                </div>

                                <div class="text-right">
                                    <p
                                        class="text-xs font-black italic text-app-text tabular-nums mb-1"
                                    >
                                        {row.lastLapTime
                                            ? row.lastLapTime.toFixed(3)
                                            : "--.---"}
                                    </p>
                                    <p
                                        class="text-[9px] font-bold {i === 0
                                            ? 'text-green-500'
                                            : 'text-app-text/40'} uppercase tabular-nums"
                                    >
                                        {formatGap(row.gapToLeader)}
                                    </p>
                                </div>
                            </div>
                        {/each}
                    </div>
                </div>
            </div>

            <!-- Middle: Live Ticker Feed -->
            <div class="lg:col-span-4 space-y-4">
                <div class="bg-app-surface border border-app-border rounded-2xl overflow-hidden shadow-2xl flex flex-col h-full max-h-[670px]">
                    <div class="p-6 border-b border-app-border bg-app-surface flex items-center gap-3">
                        <Zap size={18} class="text-yellow-500" />
                        <h3 class="font-black text-xs uppercase tracking-widest italic text-app-text flex-1">
                            {t('race_control_feed')}
                        </h3>
                        <div class="w-2 h-2 rounded-full bg-red-500 animate-pulse"></div>
                    </div>
                    
                    <div class="flex-1 overflow-y-auto p-4 space-y-3 custom-scrollbar">
                        {#if events.length === 0}
                            <div class="h-full flex flex-col items-center justify-center text-app-text/20">
                                <Activity size={32} class="mb-4 opacity-50" />
                                <span class="text-[10px] font-black uppercase tracking-widest">{t('awaiting_events')}</span>
                            </div>
                        {:else}
                            {#each events as ev (ev.lap + '-' + ev.driverId + '-' + ev.type)}
                                <div class="bg-app-text/20 border-l-2 p-3 rounded-r-lg {ev.type === 'overtake' ? 'border-blue-500' : ev.type === 'accident' ? 'border-red-500' : ev.type === 'pitstop' ? 'border-yellow-500' : 'border-app-border'}">
                                    <div class="flex items-center gap-2 mb-1">
                                        <span class="text-[9px] font-black uppercase tracking-widest text-app-text/40">LAP {ev.lap}</span>
                                        <span class="text-[9px] font-black uppercase {ev.type === 'overtake' ? 'text-blue-400' : ev.type === 'accident' ? 'text-red-400' : ev.type === 'pitstop' ? 'text-yellow-400' : 'text-app-text/60'} px-1.5 py-0.5 rounded bg-app-text/5">
                                            {ev.type}
                                        </span>
                                    </div>
                                    <p class="text-xs font-medium text-app-text/80 leading-snug">
                                        {ev.message}
                                    </p>
                                </div>
                            {/each}
                        {/if}
                    </div>
                </div>
            </div>

            <!-- Right: Track Telemetry (reduced to 3) -->
            <div class="lg:col-span-3 space-y-6">
                <!-- Track Info -->
                <div
                    class="bg-app-surface border border-app-border rounded-2xl p-6 space-y-6"
                >
                    <div class="flex items-center gap-2">
                        <Gauge size={16} class="text-red-500" />
                        <h4
                            class="text-[10px] font-black text-app-text/40 uppercase tracking-widest"
                        >
                            {t('track_telemetry')}
                        </h4>
                    </div>

                    {#if circuit && circuit.characteristics}
                        <div class="space-y-4">
                            {#each Object.entries(circuit.characteristics) as [key, val]}
                                <div
                                    class="flex items-center justify-between p-3 bg-app-text/20 rounded-xl border border-app-border"
                                >
                                    <span
                                        class="text-[10px] font-black text-app-text/30 uppercase"
                                        >{key}</span
                                    >
                                    <span
                                        class="text-xs font-black text-app-text italic"
                                        >{val}</span
                                    >
                                </div>
                            {/each}
                        </div>
                    {/if}
                </div>

                <!-- Weather/Conditions placeholder (literal) -->
                <div
                    class="bg-app-text/40 border border-app-border rounded-2xl p-6 flex flex-col items-center justify-center text-center gap-4 aspect-square"
                >
                    <div
                        class="w-12 h-12 rounded-full border-2 border-green-500/20 flex items-center justify-center text-green-500"
                    >
                        <Activity size={24} />
                    </div>
                    <div>
                        <p
                            class="text-lg font-black text-app-text italic uppercase"
                        >
                            {t('session_live')}
                        </p>
                        <p
                            class="text-[9px] font-bold text-app-text/30 uppercase tracking-[0.2em] mt-1"
                        >
                            {t('telemetry_sync_active')}
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
