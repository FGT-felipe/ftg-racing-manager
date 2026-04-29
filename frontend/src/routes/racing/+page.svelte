<script lang="ts">
    import {
        Flag,
        Trophy,
        Timer,
        ChevronRight,
        LayoutDashboard,
    } from "lucide-svelte";
    import RaceStatusHero from "$lib/components/dashboard/RaceStatusHero.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import {
        timeService,
        RaceWeekStatus,
    } from "$lib/services/time_service.svelte";
    import { t } from "$lib/utils/i18n";

    // Paddock Panels
    import GaragePanel from "$lib/components/racing/GaragePanel.svelte";
    import RaceLivePanel from "$lib/components/racing/RaceLivePanel.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";

    import { fade } from "svelte/transition";

    $effect(() => {
        driverStore.init();
    });

    // If globalStatus exists in Firestore, use it (source of truth).
    // If missing, fall back to time-based status BUT map postRace -> practice,
    // because a missing globalStatus after the race means post-race processing
    // already ran and the user should see the Garage for next week prep.
    let weekStatus = $derived.by(() => {
        const firestoreStatus = teamStore.value.team?.weekStatus?.globalStatus;
        if (firestoreStatus) return firestoreStatus;
        
        const timeStatus = timeService.currentStatus;
        // After race is done and postRaceProcessing ran, show Garage not dead RaceLive
        if (timeStatus === RaceWeekStatus.POST_RACE) return "practice";
        return timeStatus || "practice";
    });
    let nextEvent = $derived(seasonStore.nextEvent);
</script>

<svelte:head>
    <title>Racing Paddock | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-4 md:p-8 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text flex flex-col gap-8 pb-32"
>
    <!-- Header/Navigation -->
    <div
        class="flex flex-col md:flex-row md:items-center justify-between gap-6"
    >
        <div class="flex items-center gap-4">
            <div
                class="w-12 h-12 rounded-2xl bg-app-primary flex items-center justify-center text-app-primary-foreground shadow-lg shadow-app-primary/20"
            >
                <Flag size={28} />
            </div>
            <div>
                <h1
                    class="text-3xl font-heading font-black tracking-tight uppercase italic leading-none"
                >
                    {t('racing_paddock_title')}
                </h1>
                <div class="flex items-center gap-2 mt-1">
                    <span
                        class="text-[10px] font-black uppercase tracking-[0.2em] text-app-text/40"
                        >{t('operation_center')}</span
                    >
                </div>
            </div>
        </div>

        {#if nextEvent}
            <div
                class="flex items-center gap-6 bg-app-text/5 border border-app-border rounded-2xl p-4 md:px-6"
                in:fade
            >
                <div
                    class="flex flex-col items-end border-r border-app-border pr-6"
                >
                    <span
                        class="text-[10px] font-black uppercase tracking-widest text-app-primary mb-1"
                        >{t('round_of', {
                            round: String((seasonStore.value.season?.calendar.findIndex(
                                (r) => r.id === nextEvent.id,
                            ) ?? 0) + 1),
                            total: String(seasonStore.value.season?.calendar.length ?? 9)
                        })}</span
                    >
                    <span
                        class="text-xl font-heading font-black italic uppercase leading-none text-app-text"
                    >
                        {nextEvent.trackName}
                    </span>
                </div>

                <div class="flex items-center gap-4">
                    <div class="text-3xl filter saturate-[0.8] drop-shadow-md">
                        {nextEvent.flagEmoji || "🏁"}
                    </div>
                    <div class="flex flex-col">
                        <span
                            class="text-sm font-black text-app-text leading-tight uppercase italic tabular-nums"
                        >
                            {nextEvent.trackName}
                        </span>
                        <div class="flex items-center gap-2 mt-1">
                            <div
                                class="flex items-center gap-1 text-[10px] font-bold text-app-text/40 uppercase"
                            >
                                <Timer size={12} class="text-app-primary" />
                                {t('laps_count', { n: String(nextEvent.totalLaps) })}
                            </div>
                            <span class="text-app-text/10">•</span>
                            <div
                                class="flex items-center gap-1 text-[10px] font-bold text-app-text/40 uppercase"
                            >
                                <span class="text-app-primary">
                                    {#if weekStatus.toLowerCase() === "practice"}
                                        {nextEvent.weatherPractice}
                                    {:else if weekStatus.toLowerCase() === "qualifying"}
                                        {nextEvent.weatherQualifying}
                                    {:else}
                                        {nextEvent.weatherRace}
                                    {/if}
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        {/if}
    </div>

    <!-- Dynamic Paddock Content -->
    <div class="min-h-[500px]">
        {#if seasonStore.isSeasonEnded}
            <!-- Season-ended gate: shown before any time-based status check -->
            <div class="flex flex-col items-center justify-center gap-6 py-20 text-center" in:fade>
                <div class="w-20 h-20 rounded-3xl bg-app-primary/10 border border-app-primary/20 flex items-center justify-center">
                    <Trophy size={40} class="text-app-primary" />
                </div>
                <div class="flex flex-col gap-2">
                    <h2 class="text-2xl font-heading font-black uppercase italic text-app-text tracking-tight">
                        {t('racing_preseason_title')}
                    </h2>
                    <p class="text-sm text-app-text/50 max-w-xs">
                        {t('racing_preseason_body')}
                    </p>
                </div>
            </div>
        {:else if ["practice", "qualifying", "racestrategy"].includes(weekStatus.toLowerCase())}
            <div in:fade>
                <GaragePanel currentWeekStatus={weekStatus} />
            </div>
        {:else if ["race", "postrace"].includes(weekStatus.toLowerCase())}
            <div in:fade>
                <RaceLivePanel />
            </div>
        {/if}
    </div>
</div>

<style>
    .font-heading {
        font-family: "Outfit", sans-serif;
    }
</style>
