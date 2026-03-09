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
        Cloud,
        Sun,
        CloudRain,
    } from "lucide-svelte";
    import { onDestroy } from "svelte";

    let nextEvent = $derived(seasonStore.nextEvent);
    let weekStatus = $derived(
        teamStore.value.team?.weekStatus?.globalStatus || "practice",
    );

    // Enhanced Circuit Data matching Flutter's CircuitService
    const CIRCUITS: Record<string, any> = {
        mexico: {
            aero: 0.4,
            powertrain: 0.4,
            chassis: 0.2,
            characteristics: {
                "Top Speed": "High",
                "Tyre Wear": "Medium",
                "Fuel Consumption": "Normal",
            },
        },
        vegas: {
            aero: 0.2,
            powertrain: 0.6,
            chassis: 0.2,
            characteristics: {
                "Top Speed": "Very High",
                "Tyre Wear": "Low",
                "Fuel Consumption": "High",
            },
        },
        interlagos: {
            aero: 0.3,
            powertrain: 0.3,
            chassis: 0.4,
            characteristics: {
                Elevation: "Significant",
                Weather: "Unpredictable",
                "Tyre Wear": "High",
            },
        },
        miami: {
            aero: 0.4,
            powertrain: 0.3,
            chassis: 0.3,
            characteristics: {
                Surface: "Smooth",
                "Top Speed": "High",
                "Tyre Wear": "Normal",
            },
        },
        san_pablo_street: {
            aero: 0.2,
            powertrain: 0.2,
            chassis: 0.6,
            characteristics: {
                Type: "Street",
                Bumpy: "Yes",
                "Tyre Wear": "High",
            },
        },
        indianapolis: {
            aero: 0.3,
            powertrain: 0.4,
            chassis: 0.3,
            characteristics: {
                "Oval Section": "Partial",
                "Top Speed": "Very High",
                "Tyre Wear": "Medium",
            },
        },
        montreal: {
            aero: 0.2,
            powertrain: 0.4,
            chassis: 0.4,
            characteristics: {
                Braking: "Heavy",
                Kerbs: "Aggressive",
                "Fuel Consumption": "High",
            },
        },
        texas: {
            aero: 0.5,
            powertrain: 0.2,
            chassis: 0.3,
            characteristics: {
                "S-Curves": "Technical",
                Elevation: "Extreme",
                "Tyre Wear": "Very High",
            },
        },
        buenos_aires: {
            aero: 0.3,
            powertrain: 0.2,
            chassis: 0.5,
            characteristics: {
                Technical: "Very",
                "Top Speed": "Medium",
                "Tyre Wear": "Medium",
            },
        },
    };

    let circuitInfo = $derived(
        nextEvent
            ? CIRCUITS[nextEvent.circuitId] || {
                  aero: 0.33,
                  powertrain: 0.34,
                  chassis: 0.33,
                  characteristics: { General: "Standard Circuit" },
              }
            : null,
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
            return { ...base, btnLabel: "VIEW QUALIFYING", icon: Trophy };
        } else if (weekStatus === "raceStrategy" || weekStatus === "race") {
            return {
                ...base,
                btnLabel:
                    weekStatus === "race" ? "GO TO RACE" : "SET RACE STRATEGY",
                icon: Flag,
            };
        } else {
            return { ...base, btnLabel: "WEEKEND SETUP", icon: Timer };
        }
    });

    function getWeatherIcon(condition: string) {
        condition = condition.toLowerCase();
        if (condition.includes("rain") || condition.includes("wet"))
            return CloudRain;
        if (condition.includes("cloud")) return Cloud;
        return Sun;
    }

    function getWeatherColor(condition: string) {
        condition = condition.toLowerCase();
        if (condition.includes("rain") || condition.includes("wet"))
            return "text-blue-400";
        if (condition.includes("cloud")) return "text-slate-400";
        return "text-yellow-400";
    }
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
                        Next Grand Prix
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
                                >LIVE</span
                            >
                        </div>
                    {/if}
                </div>

                {#if seasonStore.value.loading}
                    <div
                        class="h-10 w-64 bg-white/5 rounded-lg animate-pulse"
                    ></div>
                {:else if nextEvent}
                    <div class="flex items-center gap-4">
                        <span class="text-4xl filter drop-shadow-md"
                            >{nextEvent.flagEmoji}</span
                        >
                        <h2
                            class="text-4xl lg:text-5xl font-heading font-black tracking-tighter text-white uppercase italic"
                        >
                            {nextEvent.trackName}
                        </h2>
                    </div>
                {:else}
                    <h2
                        class="text-3xl font-heading font-black text-white/20 uppercase"
                    >
                        No Event Scheduled
                    </h2>
                {/if}
            </div>

            <!-- Action Button -->
            <a
                href={uiConfig.route}
                class="group w-full md:w-auto px-8 py-4 rounded-xl font-black tracking-[2px] text-[10px] uppercase transition-all flex items-center justify-center gap-3 {uiConfig.btnColor} hover:shadow-[0_0_30px_rgba(197,160,89,0.2)]"
            >
                <uiConfig.icon
                    size={16}
                    strokeWidth={3}
                    class="transition-transform group-hover:scale-110"
                />
                {uiConfig.btnLabel}
            </a>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-10">
            <!-- Left: Timers & Weather -->
            <div class="flex flex-col gap-8">
                <!-- Dual Timers -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <!-- Qualy Timer -->
                    <div
                        class="bg-black/20 border border-white/5 rounded-2xl p-4 flex flex-col gap-3"
                    >
                        <div class="flex items-center justify-between">
                            <span
                                class="text-[9px] font-black tracking-[0.2em] text-white/30 uppercase"
                                >Qualifying</span
                            >
                            <Trophy size={14} class="text-app-primary/40" />
                        </div>
                        <div class="flex items-baseline gap-1">
                            <span
                                class="text-xl font-mono font-black text-white"
                                >{qualyTime.days}d {qualyTime.hours}h {qualyTime.minutes}m
                                {qualyTime.seconds}s</span
                            >
                        </div>
                    </div>

                    <!-- Race Timer -->
                    <div
                        class="bg-black/20 border border-white/5 rounded-2xl p-4 flex flex-col gap-3"
                    >
                        <div class="flex items-center justify-between">
                            <span
                                class="text-[9px] font-black tracking-[0.2em] text-white/30 uppercase"
                                >Race Day</span
                            >
                            <Flag size={14} class="text-red-500/40" />
                        </div>
                        <div class="flex items-baseline gap-1">
                            <span
                                class="text-xl font-mono font-black text-white"
                                >{raceTime.days}d {raceTime.hours}h {raceTime.minutes}m
                                {raceTime.seconds}s</span
                            >
                        </div>
                    </div>
                </div>

                <!-- Weather Intel -->
                {#if nextEvent}
                    {@const PracticeIcon = getWeatherIcon(
                        nextEvent.weatherPractice,
                    )}
                    {@const QualyIcon = getWeatherIcon(
                        nextEvent.weatherQualifying,
                    )}
                    {@const RaceIcon = getWeatherIcon(nextEvent.weatherRace)}

                    <div class="flex flex-col gap-4">
                        <span
                            class="text-[9px] font-black tracking-[0.3em] text-white/20 uppercase"
                            >Forecast</span
                        >
                        <div class="flex items-center gap-6">
                            <div class="flex items-center gap-3">
                                <PracticeIcon
                                    size={18}
                                    class={getWeatherColor(
                                        nextEvent.weatherPractice,
                                    )}
                                />
                                <div class="flex flex-col">
                                    <span
                                        class="text-[8px] font-black text-white/20 uppercase"
                                        >Pract.</span
                                    >
                                    <span
                                        class="text-[10px] font-bold text-white"
                                        >{nextEvent.weatherPractice}</span
                                    >
                                </div>
                            </div>
                            <div class="w-px h-6 bg-white/5"></div>
                            <div class="flex items-center gap-3">
                                <QualyIcon
                                    size={18}
                                    class={getWeatherColor(
                                        nextEvent.weatherQualifying,
                                    )}
                                />
                                <div class="flex flex-col">
                                    <span
                                        class="text-[8px] font-black text-white/20 uppercase"
                                        >Qualy</span
                                    >
                                    <span
                                        class="text-[10px] font-bold text-white"
                                        >{nextEvent.weatherQualifying}</span
                                    >
                                </div>
                            </div>
                            <div class="w-px h-6 bg-white/5"></div>
                            <div class="flex items-center gap-3">
                                <RaceIcon
                                    size={18}
                                    class={getWeatherColor(
                                        nextEvent.weatherRace,
                                    )}
                                />
                                <div class="flex flex-col">
                                    <span
                                        class="text-[8px] font-black text-white/20 uppercase"
                                        >Race</span
                                    >
                                    <span
                                        class="text-[10px] font-bold text-white"
                                        >{nextEvent.weatherRace}</span
                                    >
                                </div>
                            </div>
                        </div>
                    </div>
                {/if}
            </div>

            <!-- Right: Circuit Intel & Characteristics -->
            <div
                class="bg-white/5 border border-white/5 rounded-3xl p-8 flex flex-col gap-6"
            >
                {#if seasonStore.value.loading}
                    <div
                        class="flex flex-col items-center justify-center h-full gap-4"
                    >
                        <div
                            class="w-6 h-6 border-2 border-app-primary border-t-transparent rounded-full animate-spin"
                        ></div>
                        <span
                            class="text-[10px] font-black uppercase text-white/20"
                            >Loading Intel...</span
                        >
                    </div>
                {:else if nextEvent && circuitInfo}
                    <div class="flex items-center justify-between">
                        <span
                            class="text-[10px] font-black tracking-[0.3em] text-app-primary uppercase"
                            >Circuit Intel</span
                        >
                        <div class="flex items-center gap-2">
                            <span class="text-[10px] font-bold text-white/40"
                                >{nextEvent.totalLaps} Laps</span
                            >
                        </div>
                    </div>

                    <div class="grid grid-cols-3 gap-6">
                        <div class="flex flex-col gap-2">
                            <div class="flex items-center gap-2 text-white/60">
                                <Cpu size={14} />
                                <span
                                    class="text-[8px] font-black uppercase tracking-widest"
                                    >Aero</span
                                >
                            </div>
                            <div
                                class="h-1 w-full bg-white/10 rounded-full overflow-hidden"
                            >
                                <div
                                    class="h-full bg-app-primary"
                                    style="width: {circuitInfo.aero * 100}%"
                                ></div>
                            </div>
                        </div>
                        <div class="flex flex-col gap-2">
                            <div class="flex items-center gap-2 text-white/60">
                                <Zap size={14} />
                                <span
                                    class="text-[8px] font-black uppercase tracking-widest"
                                    >Power</span
                                >
                            </div>
                            <div
                                class="h-1 w-full bg-white/10 rounded-full overflow-hidden"
                            >
                                <div
                                    class="h-full bg-blue-400"
                                    style="width: {circuitInfo.powertrain *
                                        100}%"
                                ></div>
                            </div>
                        </div>
                        <div class="flex flex-col gap-2">
                            <div class="flex items-center gap-2 text-white/60">
                                <Shield size={14} />
                                <span
                                    class="text-[8px] font-black uppercase tracking-widest"
                                    >Chassis</span
                                >
                            </div>
                            <div
                                class="h-1 w-full bg-white/10 rounded-full overflow-hidden"
                            >
                                <div
                                    class="h-full bg-green-400"
                                    style="width: {circuitInfo.chassis * 100}%"
                                ></div>
                            </div>
                        </div>
                    </div>

                    <div
                        class="flex flex-wrap gap-3 border-t border-white/5 pt-6"
                    >
                        {#each Object.entries(circuitInfo.characteristics) as [key, value]}
                            <div
                                class="px-3 py-1.5 bg-white/5 border border-white/5 rounded-lg flex items-center gap-2"
                            >
                                <span
                                    class="text-[8px] font-black text-white/20 uppercase tracking-tighter"
                                    >{key}</span
                                >
                                <span class="text-[9px] font-bold text-white"
                                    >{value}</span
                                >
                            </div>
                        {/each}
                    </div>
                {:else}
                    <div
                        class="flex flex-col items-center justify-center h-full opacity-20"
                    >
                        <Timer size={32} />
                        <span class="text-[10px] font-black uppercase mt-4"
                            >Standby</span
                        >
                    </div>
                {/if}
            </div>
        </div>
    </div>
</div>
