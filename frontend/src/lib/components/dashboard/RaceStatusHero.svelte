<script lang="ts">
    import { seasonStore } from "$lib/stores/season.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import {
        timeService,
        RaceWeekStatus,
    } from "$lib/services/time_service.svelte";
    import {
        Flag,
        Trophy,
        Timer,
        Zap,
        Shield,
        Cpu,
        Fuel,
        CircleDot,
    } from "lucide-svelte";
    import { getWeatherIcon, getWeatherColor } from "$lib/utils/weather";
    import { onDestroy } from "svelte";

    import { circuitService } from "$lib/services/circuit_service.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
    import { t } from "$lib/utils/i18n";

    let nextEvent = $derived(seasonStore.nextEvent);
    let weekStatus = $derived(
        teamStore.value.team?.weekStatus?.globalStatus || "practice",
    );

    let circuitInfo = $derived(
        nextEvent
            ? circuitService.getCircuitProfile(nextEvent.circuitId)
            : null,
    );

    let componentTraits = $derived(
        circuitInfo ? circuitService.getComponentTraits(circuitInfo) : null
    );

    // Timer States
    let qualyTime = $state({ days: 0, hours: 0, minutes: 0, seconds: 0 });
    let raceTime = $state({ days: 0, hours: 0, minutes: 0, seconds: 0 });

    let timer: ReturnType<typeof setInterval>;

    function updateCountdowns() {
        const q = timeService.getTimeUntil(RaceWeekStatus.QUALIFYING);
        if (q) qualyTime = q;

        const r = timeService.getTimeUntil(RaceWeekStatus.RACE);
        if (r) raceTime = r;
    }

    $effect(() => {
        updateCountdowns();
        if (timer) clearInterval(timer);
        timer = setInterval(updateCountdowns, 1000);
    });

    onDestroy(() => {
        if (timer) clearInterval(timer);
    });

    let uiConfig = $derived.by(() => {
        const base = {
            colorPrefix: "text-app-primary",
            borderColor: "border-app-primary/30",
            bgGlow: "shadow-[0_0_25px_rgba(197,160,89,0.05)]",
            btnColor:
                "bg-transparent border border-app-primary text-app-primary hover:bg-app-primary/10",
            route: "/racing",
        };

        if (weekStatus === "qualifying") {
            return { ...base, btnLabel: t('btn_view_qualifying'), icon: Trophy };
        } else if (weekStatus === "raceStrategy" || weekStatus === "race") {
            return {
                ...base,
                btnLabel: weekStatus === "race" ? t('btn_go_to_race') : t('btn_set_race_strategy'),
                icon: Flag,
            };
        } else {
            return { ...base, btnLabel: t('btn_weekend_setup'), icon: Timer };
        }
    });

</script>

<div
    class="relative w-full overflow-hidden rounded-3xl border {uiConfig.borderColor} {uiConfig.bgGlow} bg-app-surface p-8 lg:p-10 transition-all duration-300"
>
    <!-- Abstract Background Element -->
    <div
        class="absolute -right-20 -top-20 w-80 h-80 bg-app-primary/5 blur-[100px] rounded-full"
    ></div>

    <div class="relative flex flex-col gap-8">
        <!-- Header: Event Info -->
        <div
            class="flex flex-col md:flex-row justify-between items-start gap-6"
        >
            <div class="flex flex-col gap-3">
                <div class="flex items-center gap-3">
                    <span
                        class="text-[10px] font-black tracking-[0.3em] text-app-primary font-heading uppercase"
                    >
                        {t('next_grand_prix')}
                    </span>
                    {#if weekStatus === "race"}
                        <div
                            class="flex items-center gap-2 bg-red-500/10 px-2 py-1 rounded-md border border-red-500/20"
                        >
                            <div
                                class="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse"
                            ></div>
                            <span
                                class="text-[9px] font-black tracking-widest text-red-500 uppercase"
                                >{t('live')}</span
                            >
                        </div>
                    {/if}
                </div>

                {#if seasonStore.value.loading}
                    <div
                        class="h-10 w-64 bg-app-border/20 rounded-lg animate-pulse"
                    ></div>
                {:else if nextEvent}
                    <div class="flex items-center gap-4">
                        <CountryFlag countryCode={nextEvent.countryCode} size="lg" />
                        <h2
                            class="text-4xl lg:text-5xl font-heading font-black tracking-tighter text-app-text uppercase italic"
                        >
                            {nextEvent.trackName}
                        </h2>
                    </div>
                {:else}
                    <h2
                        class="text-3xl font-heading font-black text-app-text/20 uppercase"
                    >
                        {t('no_event_scheduled')}
                    </h2>
                {/if}
            </div>

            <!-- Action Button -->
            <a
                href={uiConfig.route}
                class="group shrink-0 whitespace-nowrap px-8 py-4 rounded-xl font-black tracking-[2px] text-[10px] uppercase transition-all flex items-center justify-center gap-3 {uiConfig.btnColor} hover:shadow-[0_0_30px_rgba(197,160,89,0.2)]"
            >
                <uiConfig.icon
                    size={16}
                    strokeWidth={3}
                    class="shrink-0 transition-transform group-hover:scale-110"
                />
                {uiConfig.btnLabel}
            </a>
        </div>

        <div class="flex flex-col gap-8">
            <!-- Dual Timers -->
            <div class="grid grid-cols-2 gap-4">
                <!-- Qualy Timer -->
                <div
                    class="bg-app-text/5 border border-app-border rounded-2xl p-4 flex flex-col items-center gap-3"
                >
                    <div class="flex items-center gap-2">
                        <Trophy size={13} class="text-app-primary/60" />
                        <span
                            class="text-[9px] font-black tracking-[0.2em] text-app-text/40 uppercase"
                            >{t('qualifying')}</span
                        >
                    </div>
                    <div class="flex items-end gap-1">
                        <div class="flex flex-col items-center">
                            <span class="text-2xl font-mono font-black text-app-text leading-none">{String(qualyTime.days).padStart(2,'0')}</span>
                            <span class="text-[7px] font-black text-app-text/30 uppercase tracking-widest mt-1">D</span>
                        </div>
                        <span class="text-xl font-mono font-black text-app-primary/40 leading-none mb-2">:</span>
                        <div class="flex flex-col items-center">
                            <span class="text-2xl font-mono font-black text-app-text leading-none">{String(qualyTime.hours).padStart(2,'0')}</span>
                            <span class="text-[7px] font-black text-app-text/30 uppercase tracking-widest mt-1">H</span>
                        </div>
                        <span class="text-xl font-mono font-black text-app-primary/40 leading-none mb-2">:</span>
                        <div class="flex flex-col items-center">
                            <span class="text-2xl font-mono font-black text-app-text leading-none">{String(qualyTime.minutes).padStart(2,'0')}</span>
                            <span class="text-[7px] font-black text-app-text/30 uppercase tracking-widest mt-1">M</span>
                        </div>
                        <span class="text-xl font-mono font-black text-app-primary/40 leading-none mb-2">:</span>
                        <div class="flex flex-col items-center">
                            <span class="text-2xl font-mono font-black text-app-primary leading-none">{String(qualyTime.seconds).padStart(2,'0')}</span>
                            <span class="text-[7px] font-black text-app-text/30 uppercase tracking-widest mt-1">S</span>
                        </div>
                    </div>
                </div>

                <!-- Race Timer -->
                <div
                    class="bg-app-text/5 border border-app-border rounded-2xl p-4 flex flex-col items-center gap-3"
                >
                    <div class="flex items-center gap-2">
                        <Flag size={13} class="text-red-500/60" />
                        <span
                            class="text-[9px] font-black tracking-[0.2em] text-app-text/40 uppercase"
                            >{t('race_day')}</span
                        >
                    </div>
                    <div class="flex items-end gap-1">
                        <div class="flex flex-col items-center">
                            <span class="text-2xl font-mono font-black text-app-text leading-none">{String(raceTime.days).padStart(2,'0')}</span>
                            <span class="text-[7px] font-black text-app-text/30 uppercase tracking-widest mt-1">D</span>
                        </div>
                        <span class="text-xl font-mono font-black text-red-500/40 leading-none mb-2">:</span>
                        <div class="flex flex-col items-center">
                            <span class="text-2xl font-mono font-black text-app-text leading-none">{String(raceTime.hours).padStart(2,'0')}</span>
                            <span class="text-[7px] font-black text-app-text/30 uppercase tracking-widest mt-1">H</span>
                        </div>
                        <span class="text-xl font-mono font-black text-red-500/40 leading-none mb-2">:</span>
                        <div class="flex flex-col items-center">
                            <span class="text-2xl font-mono font-black text-app-text leading-none">{String(raceTime.minutes).padStart(2,'0')}</span>
                            <span class="text-[7px] font-black text-app-text/30 uppercase tracking-widest mt-1">M</span>
                        </div>
                        <span class="text-xl font-mono font-black text-red-500/40 leading-none mb-2">:</span>
                        <div class="flex flex-col items-center">
                            <span class="text-2xl font-mono font-black text-red-400 leading-none">{String(raceTime.seconds).padStart(2,'0')}</span>
                            <span class="text-[7px] font-black text-app-text/30 uppercase tracking-widest mt-1">S</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Circuit Intel + Forecast -->
            <div class="grid grid-cols-2 gap-4 items-stretch">

            <!-- Circuit Intel -->
            <div
                class="bg-app-text/5 border border-app-border rounded-3xl p-8 flex flex-col gap-6"
            >
                {#if seasonStore.value.loading}
                    <div
                        class="flex flex-col items-center justify-center h-full gap-4"
                    >
                        <div
                            class="w-6 h-6 border-2 border-app-primary border-t-transparent rounded-full animate-spin"
                        ></div>
                        <span
                            class="text-[10px] font-black uppercase text-app-text/40"
                            >{t('loading_intel')}</span
                        >
                    </div>
                {:else if nextEvent && circuitInfo}
                    <div class="flex items-center justify-between">
                        <span
                            class="text-[10px] font-black tracking-[0.3em] text-app-primary uppercase"
                            >{t('circuit_intel')}</span
                        >
                        <div class="flex items-center gap-2">
                            <span class="text-[10px] font-bold text-app-text/60"
                                >{nextEvent.totalLaps} {t('laps')}</span
                            >
                        </div>
                    </div>

                    <div class="grid grid-cols-3 gap-4">
                        <!-- Aero -->
                        <div class="flex flex-col items-center gap-2">
                            <div class="flex items-center justify-center gap-2 text-app-text/60">
                                <Cpu size={14} />
                                <span class="text-[9px] font-black uppercase tracking-widest">{t('aero')}</span>
                            </div>
                            {#if componentTraits}
                                <div class="relative group/trait w-full">
                                    <span
                                        class="inline-flex items-center px-2 py-1 rounded-lg text-[7px] font-black uppercase tracking-wide cursor-help transition-all w-full justify-center whitespace-nowrap
                                        {componentTraits.aero.label === 'High Downforce' ? 'bg-app-primary/15 text-app-primary border border-app-primary/20 shadow-[0_0_8px_rgba(197,160,89,0.1)]' : 'bg-blue-500/15 text-blue-400 border border-blue-500/20 shadow-[0_0_8px_rgba(59,130,246,0.1)]'}"
                                    >{t(componentTraits.aero.tooltipKey)}</span>
                                    <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-48 px-3 py-2 bg-app-bg border border-app-border rounded-lg shadow-xl opacity-0 invisible group-hover/trait:opacity-100 group-hover/trait:visible transition-all duration-200 z-50 pointer-events-none">
                                        <span class="text-[9px] text-app-text/80 leading-relaxed">{t('circuit_tooltip_' + componentTraits.aero.tooltipKey.replace('circuit_trait_', ''))}</span>
                                        <div class="absolute top-full left-1/2 -translate-x-1/2 w-2 h-2 bg-app-bg border-r border-b border-app-border rotate-45 -mt-1"></div>
                                    </div>
                                </div>
                            {/if}
                        </div>
                        <!-- Power -->
                        <div class="flex flex-col items-center gap-2">
                            <div class="flex items-center justify-center gap-2 text-app-text/60">
                                <Zap size={14} />
                                <span class="text-[9px] font-black uppercase tracking-widest">{t('power')}</span>
                            </div>
                            {#if componentTraits}
                                <div class="relative group/trait w-full">
                                    <span
                                        class="inline-flex items-center px-2 py-1 rounded-lg text-[7px] font-black uppercase tracking-wide cursor-help transition-all w-full justify-center whitespace-nowrap
                                        {componentTraits.power.label === 'Top Speed' ? 'bg-orange-500/15 text-orange-400 border border-orange-500/20 shadow-[0_0_8px_rgba(249,115,22,0.1)]' : 'bg-cyan-500/15 text-cyan-400 border border-cyan-500/20 shadow-[0_0_8px_rgba(6,182,212,0.1)]'}"
                                    >{t(componentTraits.power.tooltipKey)}</span>
                                    <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-48 px-3 py-2 bg-app-bg border border-app-border rounded-lg shadow-xl opacity-0 invisible group-hover/trait:opacity-100 group-hover/trait:visible transition-all duration-200 z-50 pointer-events-none">
                                        <span class="text-[9px] text-app-text/80 leading-relaxed">{t('circuit_tooltip_' + componentTraits.power.tooltipKey.replace('circuit_trait_', ''))}</span>
                                        <div class="absolute top-full left-1/2 -translate-x-1/2 w-2 h-2 bg-app-bg border-r border-b border-app-border rotate-45 -mt-1"></div>
                                    </div>
                                </div>
                            {/if}
                        </div>
                        <!-- Chassis -->
                        <div class="flex flex-col items-center gap-2">
                            <div class="flex items-center justify-center gap-2 text-app-text/60">
                                <Shield size={14} />
                                <span class="text-[9px] font-black uppercase tracking-widest">{t('chassis')}</span>
                            </div>
                            {#if componentTraits}
                                <div class="relative group/trait w-full">
                                    <span
                                        class="inline-flex items-center px-2 py-1 rounded-lg text-[7px] font-black uppercase tracking-wide cursor-help transition-all w-full justify-center whitespace-nowrap
                                        {componentTraits.chassis.label === 'Stiff' ? 'bg-red-500/15 text-red-400 border border-red-500/20 shadow-[0_0_8px_rgba(239,68,68,0.1)]' : 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/20 shadow-[0_0_8px_rgba(16,185,129,0.1)]'}"
                                    >{t(componentTraits.chassis.tooltipKey)}</span>
                                    <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-48 px-3 py-2 bg-app-bg border border-app-border rounded-lg shadow-xl opacity-0 invisible group-hover/trait:opacity-100 group-hover/trait:visible transition-all duration-200 z-50 pointer-events-none">
                                        <span class="text-[9px] text-app-text/80 leading-relaxed">{t('circuit_tooltip_' + componentTraits.chassis.tooltipKey.replace('circuit_trait_', ''))}</span>
                                        <div class="absolute top-full left-1/2 -translate-x-1/2 w-2 h-2 bg-app-bg border-r border-b border-app-border rotate-45 -mt-1"></div>
                                    </div>
                                </div>
                            {/if}
                        </div>
                    </div>

                    <div
                        class="flex flex-wrap justify-center gap-3 border-t border-app-border pt-6"
                    >
                        {#if circuitInfo.characteristics}
                            {#each Object.entries(circuitInfo.characteristics).filter(([key]) => {
                                const k = key.toLowerCase();
                                return k.includes('tyre') || k.includes('fuel');
                            }) as [key, value]}
                            {@const tooltipKey =
                                key.toLowerCase().includes('fuel') ? 'circuit_tooltip_fuel_consumption' :
                                key.toLowerCase().includes('tyre') ? 'circuit_tooltip_tyre_wear' : null
                            }
                            {@const badgeIcon = key.toLowerCase().includes('fuel') ? Fuel : key.toLowerCase().includes('tyre') ? CircleDot : null}
                            <div
                                class="relative px-3 py-1.5 bg-app-text/5 border border-app-border rounded-lg flex items-center gap-2 cursor-help group/badge"
                            >
                                {#if badgeIcon}
                                    <svelte:component this={badgeIcon} size={12} class="text-app-text/40 group-hover/badge:text-app-primary transition-colors shrink-0" />
                                {/if}
                                <span
                                    class="text-[8px] font-black text-app-text/40 uppercase tracking-tighter group-hover/badge:text-app-primary transition-colors"
                                    >{key}</span
                                >
                                <span class="text-[9px] font-bold text-app-text"
                                    >{value}</span
                                >
                                {#if tooltipKey}
                                    <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-56 px-3 py-2 bg-app-bg border border-app-border rounded-lg shadow-xl opacity-0 invisible group-hover/badge:opacity-100 group-hover/badge:visible transition-all duration-200 z-50 pointer-events-none">
                                        <span class="text-[9px] text-app-text/80 leading-relaxed">{t(tooltipKey)}</span>
                                        <div class="absolute top-full left-1/2 -translate-x-1/2 w-2 h-2 bg-app-bg border-r border-b border-app-border rotate-45 -mt-1"></div>
                                    </div>
                                {/if}
                            </div>
                            {/each}
                        {/if}
                    </div>
                {:else}
                    <div
                        class="flex flex-col items-center justify-center h-full opacity-20"
                    >
                        <Timer size={32} />
                        <span class="text-[10px] font-black uppercase mt-4"
                            >{t('standby')}</span
                        >
                    </div>
                {/if}
            </div>

            <!-- Forecast -->
            {#if nextEvent}
                {@const PracticeIcon = getWeatherIcon(nextEvent.weatherPractice)}
                {@const QualyIcon = getWeatherIcon(nextEvent.weatherQualifying)}
                {@const RaceIcon = getWeatherIcon(nextEvent.weatherRace)}

                <div class="bg-app-text/5 border border-app-border rounded-3xl p-8 flex flex-col gap-6">
                    <span
                        class="text-[10px] font-black tracking-[0.3em] text-app-primary uppercase"
                        >{t('forecast')}</span
                    >
                    <div class="flex items-center justify-around flex-1">
                        <div class="flex flex-col items-center gap-2">
                            <PracticeIcon
                                size={24}
                                class={getWeatherColor(nextEvent.weatherPractice)}
                            />
                            <span
                                class="text-[9px] font-black text-app-text/40 uppercase"
                                >{t('practice_short')}</span
                            >
                            <span
                                class="text-[11px] font-bold text-app-text"
                                >{nextEvent.weatherPractice}</span
                            >
                        </div>
                        <div class="w-px h-12 bg-app-border"></div>
                        <div class="flex flex-col items-center gap-2">
                            <QualyIcon
                                size={24}
                                class={getWeatherColor(nextEvent.weatherQualifying)}
                            />
                            <span
                                class="text-[9px] font-black text-app-text/40 uppercase"
                                >{t('qualifying_short')}</span
                            >
                            <span
                                class="text-[11px] font-bold text-app-text"
                                >{nextEvent.weatherQualifying}</span
                            >
                        </div>
                        <div class="w-px h-12 bg-app-border"></div>
                        <div class="flex flex-col items-center gap-2">
                            <RaceIcon
                                size={24}
                                class={getWeatherColor(nextEvent.weatherRace)}
                            />
                            <span
                                class="text-[9px] font-black text-app-text/40 uppercase"
                                >{t('race')}</span
                            >
                            <span
                                class="text-[11px] font-bold text-app-text"
                                >{nextEvent.weatherRace}</span
                            >
                        </div>
                    </div>
                </div>
            {/if}

            </div><!-- end grid Circuit Intel + Forecast -->
        </div>
    </div>
</div>
