<script lang="ts">
    import { onMount } from "svelte";
    import { fade, slide, fly } from "svelte/transition";
    import { Timer, Trophy, User, Activity, CheckCircle2, AlertCircle } from "lucide-svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { universeStore } from "$lib/stores/universe.svelte";
    import { timeService, RaceWeekStatus } from "$lib/services/time_service.svelte";
    import { raceService } from "$lib/services/race_service.svelte";
    import { t } from "$lib/utils/i18n";
    import { driverStore } from '$lib/stores/driver.svelte';

    // State
    let results = $state<any[]>([]);
    let liveGrid = $state<any[]>([]);
    let isLoading = $state(true);
    let isLive = $state(false);
    let isError = $state(false);
    let timeLeft = $state("");
    let hadData = false;

    // Derived
    let isComplete = $derived(results.length > 0);
    let userTeamId = $derived(teamStore.value?.team?.id);
    const nextEvent = $derived(seasonStore.nextEvent);

    let allSetupsSent = $derived.by(() => {
        const setups = teamStore.value.team?.weekStatus?.driverSetups || {};
        const mainDrivers = driverStore.drivers.filter((d: any) => d.carIndex === 0 || d.carIndex === 1);
        if (mainDrivers.length === 0) return true;
        return mainDrivers.every((d: any) => setups[d.id]?.isSetupSent === true);
    });

    let livePoleTime = $derived(liveGrid.find((r: any) => !r.isCrashed)?.lapTime ?? 0);

    // Real-time subscription — replaces one-shot loadQualyData()
    $effect(() => {
        const season = seasonStore.value.season;
        if (!season || !nextEvent) {
            isLoading = false;
            return;
        }
        const raceDocId = `${season.id}_${nextEvent.id}`;
        const unsub = raceService.subscribeToRace(raceDocId, (data) => {
            isLoading = false;
            if (!data) {
                if (hadData) {
                    isError = true;
                    console.error('[QualifyingPanel:subscribe] Snapshot returned null after data was received — possible Firestore error');
                }
                results = [];
                liveGrid = [];
                isLive = false;
                return;
            }
            hadData = true;
            isError = false;
            results = data.qualifyingResults ?? [];
            liveGrid = data.qualyGridLive ?? [];
            isLive = data.qualySimStatus === 'running' || liveGrid.length > 0;
        });
        return unsub;
    });

    // Countdown timer to next qualifying session
    onMount(() => {
        const timer = setInterval(() => {
            const qualyCountdown = timeService.getTimeUntil(RaceWeekStatus.QUALIFYING);
            if (!qualyCountdown) {
                timeLeft = "00:00";
                return;
            }
            const days = qualyCountdown.days;
            const hours = qualyCountdown.hours;
            const mins = qualyCountdown.minutes;
            const secs = qualyCountdown.seconds;
            if (days > 0) {
                timeLeft = `${days}d ${hours.toString().padStart(2, "0")}:${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
            } else if (hours > 0) {
                timeLeft = `${hours.toString().padStart(2, "0")}:${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
            } else {
                timeLeft = `${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
            }
        }, 1000);
        return () => clearInterval(timer);
    });

    /**
     * Formats a lap time in seconds to mm:ss.ms format.
     * @param seconds - Raw lap time in seconds.
     * @returns Formatted string like "1:16.234" or "—" for invalid values.
     */
    function formatLapTime(seconds: number): string {
        if (seconds === 0 || !isFinite(seconds) || seconds >= 999) return "—";
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        const secsStr = secs.toFixed(3).padStart(6, '0');
        if (mins > 0) {
            return `${mins}:${secsStr}`;
        }
        return secsStr;
    }

    /**
     * Formats the gap to pole position.
     * @param gap - Gap in seconds to the pole time.
     * @param index - Grid position index (0-based).
     * @returns Formatted gap string.
     */
    function formatGap(gap: number, index: number): string {
        if (index === 0) return "";
        if (!isFinite(gap) || gap >= 999) return "DNF";
        return `+${gap.toFixed(3)}s`;
    }

    /**
     * Checks if a driver row belongs to the logged-in manager's team.
     * @param row - The qualifying result row.
     * @returns True if the driver belongs to the user's team.
     */
    function isUserDriver(row: any): boolean {
        return !!userTeamId && row.teamId === userTeamId;
    }

    /**
     * Computes the gap string for a live grid row relative to current provisional pole.
     * @param row - Live grid row.
     * @param index - Current position index (0-based).
     */
    function formatLiveGap(row: any, index: number): string {
        if (index === 0 || row.isCrashed) return "";
        if (!isFinite(row.lapTime) || row.lapTime >= 999) return "DNF";
        const gap = row.lapTime - livePoleTime;
        return `+${gap.toFixed(3)}s`;
    }
</script>

<div class="space-y-6">
    {#if !allSetupsSent && !isComplete && !isLive}
        <div in:fade class="flex items-start gap-3 px-5 py-4 bg-yellow-500/10 border border-yellow-500/30 rounded-2xl">
            <span class="text-yellow-400 text-lg leading-none mt-0.5">⚠</span>
            <div class="flex flex-col gap-0.5">
                <p class="text-xs font-black uppercase tracking-widest text-yellow-400">Qualifying Setup Pending</p>
                <p class="text-[11px] text-yellow-300/70 font-medium leading-snug">
                    Drivers without a submitted qualifying setup will lose extra <strong>Fitness</strong> and <strong>Morale</strong> during qualifying.
                    Go to <a href="/racing" class="underline underline-offset-2">Practice</a> and send a setup for each driver.
                </p>
            </div>
        </div>
    {/if}

    {#if isError}
        <div in:fade class="flex items-center gap-3 p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400">
            <AlertCircle size={16} class="shrink-0" />
            <span class="text-[11px] font-bold">{t('qualy_error_loading_results')}</span>
        </div>
    {/if}

    {#if isLoading}
        <div class="flex flex-col items-center justify-center py-20 gap-4 opacity-50">
            <div class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"></div>
            <span class="text-[10px] font-black uppercase tracking-widest text-app-primary">{t('analyzing_telemetry')}</span>
        </div>

    {:else if isComplete}
        <!-- ═══ OFFICIAL FINAL GRID ═══ -->
        <div in:slide class="bg-app-surface border border-app-border rounded-2xl overflow-hidden shadow-2xl">
            <div class="p-6 border-b border-app-border bg-app-surface flex items-center justify-between">
                <div class="flex items-center gap-3">
                    <Trophy size={18} class="text-app-primary" />
                    <h3 class="font-black text-xs uppercase tracking-widest italic">{t('official_classification')}</h3>
                </div>
                <span class="text-[9px] font-black uppercase tracking-widest text-emerald-400 flex items-center gap-1.5">
                    <CheckCircle2 size={12} />
                    {t('qualy_sim_complete')}
                </span>
            </div>
            <div class="divide-y divide-white/5">
                {#each results as row, i}
                    {@const isPole = i === 0 && !row.isCrashed}
                    {@const isUser = isUserDriver(row)}
                    <div
                        id="qualy-row-{i}"
                        class="p-4 flex items-center gap-4 transition-colors
                            {isPole ? 'qualy-pole-row' : ''}
                            {isUser && !isPole ? 'bg-app-primary/8' : ''}
                            {!isPole && !isUser ? 'hover:bg-white/[0.02]' : ''}"
                    >
                        <!-- Position Badge -->
                        <div class="w-8 h-8 rounded-lg flex items-center justify-center font-black italic text-xs
                            {isPole ? 'bg-app-pole/20 text-app-pole' : ''}
                            {!isPole && i < 3 ? 'bg-app-text/40 text-app-primary' : ''}
                            {!isPole && i >= 3 && isUser ? 'bg-app-primary/10 text-app-primary' : ''}
                            {!isPole && i >= 3 && !isUser ? 'bg-app-text/40 text-app-text/20' : ''}">
                            {i + 1}
                        </div>
                        <!-- Driver Info -->
                        <div class="flex-1 min-w-0">
                            <div class="flex items-center gap-2">
                                <CountryFlag countryCode={row.countryCode || universeStore.getDriverById(row.driverId)?.countryCode} size="xs" />
                                <p class="text-[13px] font-black truncate uppercase
                                    {isPole ? 'text-app-pole' : ''}
                                    {!isPole && isUser ? 'text-app-primary' : ''}
                                    {!isPole && !isUser ? 'text-app-text' : ''}">
                                    {row.driverName}
                                </p>
                                {#if isPole}
                                    <span class="px-1.5 py-0.5 rounded bg-app-pole/20 text-app-pole font-black text-[8px] uppercase tracking-widest">POLE</span>
                                {/if}
                                {#if isUser}
                                    <User size={10} class="{isPole ? 'text-app-pole' : 'text-app-primary'} opacity-60" />
                                {/if}
                            </div>
                            <p class="text-[9px] font-bold uppercase tracking-widest
                                {isPole ? 'text-app-pole/50' : ''}
                                {!isPole && isUser ? 'text-app-primary/50' : ''}
                                {!isPole && !isUser ? 'text-app-text/30' : ''}">
                                {row.teamName}
                            </p>
                        </div>
                        <!-- Lap Time -->
                        <div class="text-right">
                            <p class="text-sm font-black italic tabular-nums {isPole ? 'text-app-pole' : 'text-app-primary'}">
                                {row.isCrashed ? 'DNF' : formatLapTime(row.lapTime)}
                            </p>
                            {#if i > 0 && !row.isCrashed}
                                <p class="text-[9px] font-bold text-app-text/30 tabular-nums italic">{formatGap(row.gap, i)}</p>
                            {/if}
                            {#if row.isCrashed}
                                <p class="text-[8px] font-bold text-app-error/60 uppercase italic">Crashed</p>
                            {/if}
                        </div>
                    </div>
                {/each}
            </div>
        </div>

    {:else if isLive}
        <!-- ═══ LIVE TIMING SCREEN ═══ -->
        <div in:fade class="bg-app-surface border border-app-border rounded-2xl overflow-hidden shadow-2xl">
            <!-- Live header -->
            <div class="p-5 border-b border-app-border flex items-center justify-between bg-gradient-to-r from-red-950/30 to-transparent">
                <div class="flex items-center gap-3">
                    <div class="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse shadow-[0_0_8px_rgba(239,68,68,0.8)]"></div>
                    <span class="text-xs font-black uppercase tracking-widest text-red-400">{t('qualy_live_header')}</span>
                </div>
                <div class="flex items-center gap-2 text-app-text/50">
                    <Activity size={14} class="animate-pulse" />
                    <span class="text-[10px] font-black uppercase tracking-widest">
                        {t('qualy_live_drivers_count', { n: String(liveGrid.length) })}
                    </span>
                </div>
            </div>

            <!-- Live rows — keyed each so Svelte animates position changes -->
            <div class="divide-y divide-white/5">
                {#each liveGrid as row, i (row.driverId)}
                    {@const isProvisionalPole = i === 0 && !row.isCrashed}
                    {@const isUser = isUserDriver(row)}
                    <div
                        in:fly={{ y: 16, duration: 400 }}
                        class="p-4 flex items-center gap-4 transition-all duration-500
                            {isProvisionalPole ? 'qualy-pole-row' : ''}
                            {isUser && !isProvisionalPole ? 'bg-app-primary/8' : ''}
                            {!isProvisionalPole && !isUser ? 'hover:bg-white/[0.02]' : ''}"
                    >
                        <!-- Position Badge -->
                        <div class="w-8 h-8 rounded-lg flex items-center justify-center font-black italic text-xs transition-all duration-300
                            {isProvisionalPole ? 'bg-app-pole/20 text-app-pole' : ''}
                            {!isProvisionalPole && i < 3 ? 'bg-app-text/40 text-app-primary' : ''}
                            {!isProvisionalPole && i >= 3 && isUser ? 'bg-app-primary/10 text-app-primary' : ''}
                            {!isProvisionalPole && i >= 3 && !isUser ? 'bg-app-text/40 text-app-text/20' : ''}">
                            {i + 1}
                        </div>
                        <!-- Driver Info -->
                        <div class="flex-1 min-w-0">
                            <div class="flex items-center gap-2">
                                <CountryFlag countryCode={row.countryCode || universeStore.getDriverById(row.driverId)?.countryCode} size="xs" />
                                <p class="text-[13px] font-black truncate uppercase
                                    {isProvisionalPole ? 'text-app-pole' : ''}
                                    {!isProvisionalPole && isUser ? 'text-app-primary' : ''}
                                    {!isProvisionalPole && !isUser ? 'text-app-text' : ''}">
                                    {row.driverName}
                                </p>
                                {#if isProvisionalPole}
                                    <span class="px-1.5 py-0.5 rounded bg-app-pole/10 text-app-pole/70 font-black text-[8px] uppercase tracking-widest border border-app-pole/20">
                                        {t('qualy_provisional_pole')}
                                    </span>
                                {/if}
                                {#if isUser}
                                    <User size={10} class="{isProvisionalPole ? 'text-app-pole' : 'text-app-primary'} opacity-60" />
                                {/if}
                            </div>
                            <p class="text-[9px] font-bold uppercase tracking-widest
                                {isProvisionalPole ? 'text-app-pole/50' : ''}
                                {!isProvisionalPole && isUser ? 'text-app-primary/50' : ''}
                                {!isProvisionalPole && !isUser ? 'text-app-text/30' : ''}">
                                {row.teamName}
                            </p>
                        </div>
                        <!-- Lap Time -->
                        <div class="text-right">
                            <p class="text-sm font-black italic tabular-nums {isProvisionalPole ? 'text-app-pole' : 'text-app-primary'}">
                                {row.isCrashed ? 'DNF' : formatLapTime(row.lapTime)}
                            </p>
                            {#if i > 0 && !row.isCrashed}
                                <p class="text-[9px] font-bold text-app-text/30 tabular-nums italic">{formatLiveGap(row, i)}</p>
                            {/if}
                            {#if row.isCrashed}
                                <p class="text-[8px] font-bold text-app-error/60 uppercase italic">Crashed</p>
                            {/if}
                        </div>
                    </div>
                {/each}

                {#if liveGrid.length === 0}
                    <div class="p-10 flex flex-col items-center gap-3 text-app-text/30">
                        <Activity size={24} class="animate-pulse" />
                        <span class="text-[10px] font-black uppercase tracking-widest">{t('waiting_backend_sim')}</span>
                    </div>
                {/if}
            </div>
        </div>

    {:else}
        <!-- ═══ PENDING / COUNTDOWN ═══ -->
        <div
            in:fade
            class="bg-app-surface/60 backdrop-blur-xl border border-app-border rounded-3xl p-12 flex flex-col items-center justify-center text-center gap-10 shadow-2xl relative overflow-hidden"
        >
            <div class="absolute inset-0 bg-app-primary/5 animate-pulse pointer-events-none"></div>

            <div class="flex flex-col items-center gap-6 relative z-10">
                <div class="w-20 h-20 rounded-2xl bg-app-primary/10 flex items-center justify-center text-app-primary border border-app-primary/20 shadow-lg">
                    <Timer size={40} />
                </div>
                <div class="max-w-md space-y-4">
                    <h3 class="font-black text-4xl lg:text-5xl uppercase italic text-app-text tracking-tighter leading-[0.9]">
                        {timeService.currentStatus === RaceWeekStatus.QUALIFYING ? t('session') + ' ' + t('qualifying_in_progress') : t('qualifying_pending')}
                    </h3>
                    <p class="text-app-text/60 text-sm font-medium leading-relaxed">
                        {timeService.currentStatus === RaceWeekStatus.QUALIFYING
                            ? t('session_running_wait')
                            : t('delegate_preparing')}
                    </p>
                </div>
            </div>

            <div class="px-10 py-6 bg-app-surface border border-app-border rounded-2xl flex flex-col items-center min-w-[240px] shadow-xl relative z-10 group hover:scale-105 transition-transform duration-300">
                <span class="text-[10px] font-black text-app-primary uppercase tracking-[0.3em] mb-3 font-mono opacity-80">{t('time_until_race')}</span>
                <span class="text-5xl font-black text-app-text tabular-nums font-mono italic tracking-tighter">{timeLeft}</span>
            </div>
        </div>
    {/if}
</div>

<style>
    .qualy-pole-row {
        background: linear-gradient(
            90deg,
            color-mix(in srgb, var(--pole-color) 12%, transparent) 0%,
            transparent 100%
        );
        border-left: 3px solid var(--pole-color);
    }
</style>
