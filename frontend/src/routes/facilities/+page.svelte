<script lang="ts">
    import { facilityStore } from "$lib/stores/facility.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { uiStore } from "$lib/stores/ui.svelte";
    import { FacilityType } from "$lib/types";
    import { t } from "$lib/utils/i18n";
    import { FACILITY_MAX_LEVEL } from "$lib/constants/economics";
    import {
        Building2,
        Wrench,
        GraduationCap,
        ShieldAlert,
        ChevronRight,
        TrendingUp,
        Lock,
        Users,
        Dumbbell,
        Search,
        Mic2,
        Gamepad2,
        Beaker,
        Flag,
        ArrowUpCircle,
    } from "lucide-svelte";
    import { goto } from "$app/navigation";
    import { fly } from "svelte/transition";

    // Facilities that have an upgrade button in the overview
    const UPGRADEABLE_FROM_OVERVIEW = new Set<FacilityType>([
        FacilityType.garage,
    ]);

    let upgradingType = $state<FacilityType | null>(null);

    async function handleUpgrade(type: FacilityType) {
        if (upgradingType) return;
        upgradingType = type;
        try {
            await facilityStore.upgradeFacility(type);
        } catch (e: unknown) {
            uiStore.alert((e as Error).message ?? "Upgrade failed", "Error", "danger");
        } finally {
            upgradingType = null;
        }
    }

    const facilityIcons: Record<string, any> = {
        [FacilityType.teamOffice]: Building2,
        [FacilityType.garage]: Wrench,
        [FacilityType.youthAcademy]: GraduationCap,
        [FacilityType.pressRoom]: Mic2,
        [FacilityType.scoutingOffice]: Search,
        [FacilityType.racingSimulator]: Gamepad2,
        [FacilityType.gym]: Dumbbell,
        [FacilityType.rdOffice]: Beaker,
        raceOperations: Flag,
    };

    const facilityConfigs: Record<string, any> = {
        [FacilityType.teamOffice]: {
            title: "Operations & Office",
            subtitle: "Team Identity & Contracts",
            color: "text-app-primary",
            bg: "bg-app-primary/5",
            path: "/facilities/office",
        },
        [FacilityType.garage]: {
            title: "Engineering",
            subtitle: "Car Parts & Technical Dev",
            color: "text-blue-400",
            bg: "bg-blue-400/5",
            path: "/facilities/engineering",
        },
        raceOperations: {
            title: "Race Operations",
            subtitle: "Weekend Setup & Strategy",
            color: "text-red-400",
            bg: "bg-red-400/5",
            path: "/racing",
            isVirtual: true,
        },
        [FacilityType.pressRoom]: {
            title: "Press & Media",
            subtitle: "PR and Sponsorships",
            color: "text-emerald-400",
            bg: "bg-emerald-400/5",
            path: "#",
        },
        [FacilityType.scoutingOffice]: {
            title: "Scouting Office",
            subtitle: "Driver Talent Search",
            color: "text-orange-400",
            bg: "bg-orange-400/5",
            path: "#",
        },
        [FacilityType.racingSimulator]: {
            title: "Racing Simulator",
            subtitle: "Driver Training & Data",
            color: "text-purple-400",
            bg: "bg-purple-400/5",
            path: "#",
        },
        [FacilityType.gym]: {
            title: "Physical Gym",
            subtitle: "Driver Fitness & Health",
            color: "text-red-400",
            bg: "bg-red-400/5",
            path: "#",
        },
        [FacilityType.rdOffice]: {
            title: "R&D Office",
            subtitle: "Future Tech & Innovation",
            color: "text-cyan-400",
            bg: "bg-cyan-400/5",
            path: "#",
        },
        [FacilityType.carMuseum]: {
            title: "Car Museum",
            subtitle: "Legacy and History",
            color: "text-amber-400",
            bg: "bg-amber-400/5",
            path: "#",
        },
    };

    // Card order including the virtual split
    const displayedCardIds = [
        FacilityType.teamOffice,
        FacilityType.garage,
        "raceOperations",
        FacilityType.pressRoom,
        FacilityType.scoutingOffice,
        FacilityType.racingSimulator,
        FacilityType.gym,
        FacilityType.rdOffice,
        FacilityType.carMuseum,
    ];

    let totalMaintenance = $derived(
        Object.values(facilityStore.facilities).reduce(
            (acc, f) => acc + (f.maintenanceCost || 0),
            0,
        ),
    );

    let avgLevel = $derived(
        Object.values(facilityStore.facilities).reduce(
            (acc, f) => acc + f.level,
            0,
        ) / 8,
    );

    let infrastructureRating = $derived(
        avgLevel >= 4 ? "Elite" : avgLevel >= 2 ? "Operational" : "Basic",
    );
</script>

<svelte:head>
    <title>High Headquarters | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-6 md:p-10 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text min-h-screen"
>
    <!-- Header Section -->
    <header class="flex flex-col gap-2 mb-12">
        <div class="flex items-center gap-3">
            <div class="p-2 rounded-lg bg-app-primary/10 text-app-primary">
                <ShieldAlert size={24} />
            </div>
            <span
                class="text-[10px] font-black tracking-[0.3em] text-app-primary/40 uppercase font-heading"
            >
                Infrastructure Control
            </span>
        </div>
        <div class="flex flex-wrap items-end justify-between gap-6">
            <h1
                class="text-4xl lg:text-5xl font-heading font-black tracking-tighter uppercase italic text-app-text mt-1"
            >
                High <span class="text-app-primary">Headquarters</span>
            </h1>

            <div
                class="flex items-center gap-6 px-6 py-3 bg-app-surface/50 border border-app-border rounded-2xl backdrop-blur-md"
            >
                <div class="flex flex-col">
                    <span
                        class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                        >Available Budget</span
                    >
                    <span class="text-lg font-black text-app-text"
                        >{teamStore.formattedBudget}</span
                    >
                </div>
                <div class="w-px h-8 bg-app-text/5"></div>
                <div class="flex flex-col">
                    <span
                        class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                        >Manager Role</span
                    >
                    <span
                        class="text-xs font-black text-app-primary uppercase italic"
                        >{managerStore.profile?.role || "Ex-Driver"}</span
                    >
                </div>
            </div>
        </div>
    </header>

    <!-- Navigation Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-16">
        {#each displayedCardIds as cardId, i}
            {@const config = facilityConfigs[cardId]}
            {#if config}
                {@const isVirtual = config.isVirtual}
                {@const facility = isVirtual
                    ? {
                          level:
                              facilityStore.facilities[FacilityType.garage]
                                  ?.level || 1,
                      }
                    : facilityStore.facilities[cardId as FacilityType]}

                {#if isVirtual || (facility && cardId !== FacilityType.youthAcademy)}
                    {@const isSoon =
                        !isVirtual &&
                        facility.level === 0 &&
                        !["teamOffice", "garage"].includes(cardId as any)}
                    {@const Icon = facilityIcons[cardId] || Building2}

                    <div
                        in:fly={{ y: 20, duration: 400, delay: i * 50 }}
                        class="group relative bg-app-surface border border-app-border rounded-3xl p-8 transition-all duration-300 hover:border-app-primary/30 hover:shadow-[0_20px_40px_rgba(0,0,0,0.3)] overflow-hidden {isSoon
                            ? 'opacity-50 grayscale'
                            : ''}"
                    >
                        <!-- Background Gradient Decoration -->
                        <div
                            class="absolute -right-10 -bottom-10 w-40 h-40 {config.bg} blur-3xl rounded-full transition-transform group-hover:scale-150"
                        ></div>

                        <div class="relative flex flex-col gap-6 h-full">
                            <div class="flex items-center justify-between">
                                <div
                                    class="p-4 rounded-2xl {config.bg} {config.color} transition-transform group-hover:scale-110"
                                >
                                    <Icon size={32} strokeWidth={2.5} />
                                </div>
                                <div class="flex items-center gap-4">
                                    <div class="text-right">
                                        <span
                                            class="text-[10px] font-black text-app-text/20 uppercase tracking-widest block"
                                            >Level</span
                                        >
                                        <span
                                            class="text-xl font-black text-app-text italic"
                                            >{facility.level}</span
                                        >
                                    </div>
                                    {#if !isSoon}
                                        <a
                                            href={config.path}
                                            class="text-app-text/10 group-hover:text-app-primary transition-colors"
                                        >
                                            <ChevronRight size={24} />
                                        </a>
                                    {/if}
                                </div>
                            </div>

                            <div class="flex flex-col gap-1">
                                <h2
                                    class="text-2xl font-black text-app-text uppercase tracking-tight group-hover:text-app-primary transition-colors"
                                >
                                    {config.title}
                                </h2>
                                <p class="text-sm font-medium text-app-text/40">
                                    {config.subtitle}
                                </p>
                            </div>

                            <div class="mt-auto pt-6 flex flex-col gap-4">
                                {#if !isSoon}
                                    <div
                                        class="flex items-center justify-between"
                                    >
                                        <div class="flex flex-col">
                                            <span
                                                class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                                                >Weekly Maintenance</span
                                            >
                                            <span
                                                class="text-sm font-black text-app-text"
                                            >
                                                {#if isVirtual}
                                                    Included in Garage
                                                {:else}
                                                    ${(
                                                        (facility.level *
                                                            15000) /
                                                        1000
                                                    ).toFixed(0)}k
                                                {/if}
                                            </span>
                                        </div>
                                    </div>

                                    {#if !isVirtual && UPGRADEABLE_FROM_OVERVIEW.has(cardId as FacilityType)}
                                        {@const canUpgrade = facilityStore.canUpgradeFacility(cardId as FacilityType)}
                                        {@const isMaxLevel = facility.level >= FACILITY_MAX_LEVEL}
                                        {@const upgradePrice = facilityStore.getUpgradePrice(cardId as FacilityType, facility.level)}
                                        {@const isUpgrading = upgradingType === cardId}

                                        {#if isMaxLevel}
                                            <div class="py-2 px-3 rounded-xl bg-app-primary/10 text-center">
                                                <span class="text-[9px] font-black text-app-primary uppercase tracking-widest">{t('max_level')}</span>
                                            </div>
                                        {:else if !canUpgrade}
                                            <div class="py-2 px-3 rounded-xl bg-app-surface border border-app-border text-center">
                                                <span class="text-[9px] font-black text-app-text/30 uppercase tracking-widest">{t('upgraded_this_season')}</span>
                                            </div>
                                        {:else}
                                            <button
                                                onclick={() => handleUpgrade(cardId as FacilityType)}
                                                disabled={isUpgrading}
                                                class="flex items-center justify-between w-full px-4 py-2.5 rounded-xl bg-blue-400/10 border border-blue-400/20 hover:bg-blue-400/20 hover:border-blue-400/40 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                                            >
                                                <span class="text-[10px] font-black text-blue-400 uppercase tracking-widest">
                                                    {isUpgrading ? "..." : t('upgrade_to_level', { level: facility.level + 1 })}
                                                </span>
                                                <span class="text-[10px] font-black text-blue-300">${(upgradePrice / 1_000_000).toFixed(1)}M</span>
                                            </button>
                                        {/if}
                                    {:else}
                                    <div class="flex items-center gap-2">
                                        <div
                                            class="h-1 w-8 bg-app-primary/20 rounded-full overflow-hidden"
                                        >
                                            <div
                                                class="h-full bg-app-primary w-0 group-hover:w-full transition-all duration-500"
                                            ></div>
                                        </div>
                                        <span
                                            class="text-[9px] font-black tracking-widest text-app-text/20 group-hover:text-app-text/40 uppercase"
                                        >
                                            Module Operational
                                        </span>
                                    </div>
                                    {/if}
                                {:else}
                                    <div
                                        class="py-3 text-center border border-app-border border-dashed rounded-2xl"
                                    >
                                        <span
                                            class="text-[9px] font-black text-app-text/10 uppercase tracking-widest"
                                            >Coming Soon</span
                                        >
                                    </div>
                                {/if}
                            </div>
                        </div>
                    </div>
                {/if}
            {/if}
        {/each}
    </div>

    <!-- Quick Status Footer -->
    <div
        class="mt-16 pt-8 border-t border-app-border flex flex-wrap gap-12 opacity-50"
    >
        <div class="flex flex-col gap-1">
            <span
                class="text-[9px] font-black uppercase tracking-widest text-app-text/40"
                >Infrastructure Status</span
            >
            <span class="text-sm font-bold text-app-text"
                >{infrastructureRating}</span
            >
        </div>
        <div class="flex flex-col gap-1">
            <span
                class="text-[9px] font-black uppercase tracking-widest text-app-text/40"
                >Weekly Maintenance</span
            >
            <span class="text-sm font-bold text-app-text"
                >${(totalMaintenance / 1000).toFixed(0)}k
                <span class="text-[10px] opacity-40">/wk</span></span
            >
        </div>
        <div class="flex flex-col gap-1">
            <span
                class="text-[9px] font-black uppercase tracking-widest text-app-text/40"
                >Mean Technology Lvl</span
            >
            <span class="text-sm font-bold text-app-text"
                >{avgLevel.toFixed(1)}</span
            >
        </div>
    </div>
</div>

<style>
    .font-heading {
        font-family: "Outfit", sans-serif;
    }
</style>
