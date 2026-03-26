<script lang="ts">
    import { CalendarDays, ChevronLeft, CheckCircle, Clock } from "lucide-svelte";
    import { t } from "$lib/utils/i18n";
    import { fly } from "svelte/transition";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { circuitService } from "$lib/services/circuit_service.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";

    let season = $derived(seasonStore.value.season);
    let loading = $derived(seasonStore.value.loading);
    let calendar = $derived(season?.calendar ?? []);

    function getDifficultyColor(difficulty: number): string {
        if (difficulty > 0.7) return "bg-red-500";
        if (difficulty > 0.4) return "bg-orange-400";
        return "bg-green-400";
    }

    function formatDate(date: Date | string | null): string {
        if (!date) return "—";
        const d = date instanceof Date ? date : new Date(date);
        if (isNaN(d.getTime())) return "—";
        return d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
    }

    function isCurrentRound(cal: any[], index: number, event: any): boolean {
        if (event.isCompleted) return false;
        return index === 0 || cal[index - 1]?.isCompleted;
    }
</script>

<svelte:head>
    <title>Race Calendar | FTG Racing Manager</title>
</svelte:head>

<div class="p-6 md:p-10 w-full max-w-[1400px] mx-auto text-app-text min-h-screen">

    <!-- Breadcrumb -->
    <nav class="flex items-center gap-2 mb-8 opacity-40 hover:opacity-100 transition-opacity">
        <a href="/season" class="flex items-center gap-1 text-[10px] font-black uppercase tracking-widest text-app-text">
            <ChevronLeft size={14} /> Season
        </a>
    </nav>

    <!-- Header -->
    <header class="flex flex-col gap-2 mb-12">
        <div class="flex items-center gap-3">
            <div class="p-2 rounded-lg bg-app-primary/10 text-app-primary">
                <CalendarDays size={24} />
            </div>
            <span class="text-[10px] font-black tracking-[0.3em] text-app-primary/60 uppercase font-heading">
                {#if season}Season {season.year}{:else}Season{/if}
            </span>
        </div>
        <h1 class="text-4xl lg:text-5xl font-heading font-black tracking-tighter uppercase italic text-app-text mt-1">
            Race <span class="text-app-primary">Calendar</span>
        </h1>
    </header>

    <!-- Loading Skeleton -->
    {#if loading}
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {#each Array(9) as _}
                <div class="bg-app-surface border border-app-border rounded-3xl p-6 h-72 animate-pulse"></div>
            {/each}
        </div>

    <!-- Empty -->
    {:else if calendar.length === 0}
        <div class="flex flex-col items-center justify-center h-64 text-center opacity-30 gap-4">
            <CalendarDays size={48} strokeWidth={1} />
            <p class="text-sm font-black uppercase tracking-widest">{t('calendar_no_events')}</p>
        </div>

    <!-- Calendar Grid -->
    {:else}
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {#each calendar as event, i}
                {@const circuit = circuitService.getCircuitProfile(event.circuitId ?? '')}
                {@const isCurrent = isCurrentRound(calendar, i, event)}
                {@const round = i + 1}

                <div
                    in:fly={{ y: 20, duration: 400, delay: i * 40 }}
                    class="group relative rounded-3xl p-6 overflow-hidden transition-all duration-300 border
                    {isCurrent
                        ? 'bg-app-primary/5 border-app-primary/40 shadow-[0_0_30px_rgba(0,0,0,0.05)]'
                        : event.isCompleted
                          ? 'bg-app-surface border-app-border opacity-60'
                          : 'bg-app-surface border-app-border hover:border-app-primary/30'}"
                >
                    <!-- Round watermark -->
                    <span class="absolute right-2 top-0 text-[72px] font-black leading-none text-app-text/[0.04] select-none pointer-events-none">
                        R{round}
                    </span>

                    <div class="relative flex flex-col gap-4 h-full">
                        <!-- Top row: flag + status -->
                        <div class="flex items-center justify-between">
                            <CountryFlag countryCode={circuit.countryCode} size="lg" />
                            {#if event.isCompleted}
                                <div class="flex items-center gap-1 text-green-500">
                                    <CheckCircle size={16} />
                                    <span class="text-[9px] font-black uppercase tracking-wider">{t('event_status_done')}</span>
                                </div>
                            {:else if isCurrent}
                                <div class="px-2 py-1 bg-app-primary text-app-primary-foreground rounded-md text-[8px] font-black uppercase tracking-widest">{t('event_status_upcoming')}</div>
                            {:else}
                                <div class="flex items-center gap-1 text-app-text/30">
                                    <Clock size={12} />
                                    <span class="text-[9px] font-black uppercase tracking-wider">{t('event_status_scheduled')}</span>
                                </div>
                            {/if}
                        </div>

                        <!-- Track Name + Date -->
                        <div>
                            <h3 class="text-sm font-black text-app-text uppercase tracking-tight leading-tight line-clamp-2 {isCurrent ? 'text-app-primary' : ''}">
                                {event.trackName}
                            </h3>
                            <p class="text-[10px] text-app-text/40 mt-1">{formatDate(event.date)}</p>
                        </div>

                        <div class="h-px bg-app-border"></div>

                        <!-- Circuit intel rows -->
                        <div class="flex flex-col gap-2">
                            <div class="flex items-center justify-between text-[9px]">
                                <span class="font-black uppercase tracking-widest text-app-text/40">{t('laps')}</span>
                                <span class="font-bold text-app-text">{event.totalLaps ?? circuit.laps}</span>
                            </div>
                            {#if circuit.characteristics}
                                <div class="flex items-center justify-between text-[9px]">
                                    <span class="font-black uppercase tracking-widest text-app-text/40">{t('circuit_tyre_wear_label')}</span>
                                    <span class="font-bold text-app-text">{circuit.characteristics['Tyre Wear'] ?? 'N/A'}</span>
                                </div>
                                <div class="flex items-center justify-between text-[9px]">
                                    <span class="font-black uppercase tracking-widest text-app-text/40">{t('circuit_fuel_label')}</span>
                                    <span class="font-bold text-app-text">{circuit.characteristics['Fuel Consumption'] ?? 'N/A'}</span>
                                </div>
                            {/if}
                        </div>

                        <!-- Difficulty Bar -->
                        <div class="flex flex-col gap-2 mt-auto">
                            <div class="flex items-center justify-between text-[8px] font-black uppercase tracking-widest text-app-text/30">
                                <span>{t('circuit_difficulty_label')}</span>
                                <span>{(circuit.difficulty * 10).toFixed(0)}/10</span>
                            </div>
                            <div class="h-1 w-full bg-app-text/10 rounded-full overflow-hidden">
                                <div class="h-full rounded-full {getDifficultyColor(circuit.difficulty)}" style="width: {circuit.difficulty * 100}%"></div>
                            </div>
                        </div>
                    </div>
                </div>
            {/each}
        </div>

        <!-- Season Progress Footer -->
        {@const completed = calendar.filter((r: any) => r.isCompleted).length}
        <div class="mt-16 pt-8 border-t border-app-border flex flex-wrap gap-12 opacity-50">
            <div class="flex flex-col gap-1">
                <span class="text-[9px] font-black uppercase tracking-widest text-app-text/50">{t('season_progress_completed')}</span>
                <span class="text-sm font-bold text-app-text">{completed} / {calendar.length}</span>
            </div>
            <div class="flex flex-col gap-1">
                <span class="text-[9px] font-black uppercase tracking-widest text-app-text/50">{t('season_progress_remaining')}</span>
                <span class="text-sm font-bold text-app-text">{calendar.length - completed}</span>
            </div>
        </div>
    {/if}
</div>
