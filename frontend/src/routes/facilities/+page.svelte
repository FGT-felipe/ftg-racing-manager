<script lang="ts">
    import { facilityStore } from "$lib/stores/facility.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { FacilityType } from "$lib/types";
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
    } from "lucide-svelte";
    import { goto } from "$app/navigation";
    import { fly } from "svelte/transition";

    const facilityIcons: Record<string, any> = {
        [FacilityType.teamOffice]: Building2,
        [FacilityType.garage]: Wrench,
        [FacilityType.youthAcademy]: GraduationCap,
        [FacilityType.pressRoom]: Mic2,
        [FacilityType.scoutingOffice]: Search,
        [FacilityType.racingSimulator]: Gamepad2,
        [FacilityType.gym]: Dumbbell,
        [FacilityType.rdOffice]: Beaker,
    };

    const navigationItems = [
        {
            id: "office",
            title: "Operations & Office",
            subtitle: "Team Identity & Contracts",
            icon: Building2,
            color: "text-app-primary",
            bg: "bg-app-primary/5",
            path: "/facilities/office",
            type: FacilityType.teamOffice,
        },
        {
            id: "garage",
            title: "Engineering & Garage",
            subtitle: "Performance & Maintenance",
            icon: Wrench,
            color: "text-blue-400",
            bg: "bg-blue-400/5",
            path: "/facilities/garage",
            type: FacilityType.garage,
        },
    ];

    const facilityBonuses: Record<string, (level: number) => string> = {
        [FacilityType.teamOffice]: (lvl) => `+${lvl * 5}% Sponsor payout`,
        [FacilityType.garage]: (lvl) => `+${lvl * 2}% Reliability bonus`,
    };

    async function handleUpgrade(type: FacilityType) {
        try {
            await facilityStore.upgradeFacility(type);
        } catch (e: any) {
            alert(e.message);
        }
    }

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
                class="text-4xl lg:text-5xl font-heading font-black tracking-tighter uppercase italic text-white mt-1"
            >
                High <span class="text-app-primary">Headquarters</span>
            </h1>

            <div
                class="flex items-center gap-6 px-6 py-3 bg-app-surface/50 border border-white/5 rounded-2xl backdrop-blur-md"
            >
                <div class="flex flex-col">
                    <span
                        class="text-[9px] font-black text-white/20 uppercase tracking-widest"
                        >Available Budget</span
                    >
                    <span class="text-lg font-black text-white"
                        >{teamStore.formattedBudget}</span
                    >
                </div>
                <div class="w-px h-8 bg-white/5"></div>
                <div class="flex flex-col">
                    <span
                        class="text-[9px] font-black text-white/20 uppercase tracking-widest"
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
        {#each Object.values(FacilityType) as type, i}
            {@const facility = facilityStore.facilities[type]}
            {#if facility && type !== FacilityType.youthAcademy}
                {@const config = {
                    [FacilityType.teamOffice]: {
                        title: "Operations & Office",
                        subtitle: "Team Identity & Contracts",
                        color: "text-app-primary",
                        bg: "bg-app-primary/5",
                        path: "/facilities/office",
                    },
                    [FacilityType.garage]: {
                        title: "Engineering & Garage",
                        subtitle: "Performance & Maintenance",
                        color: "text-blue-400",
                        bg: "bg-blue-400/5",
                        path: "/facilities/garage",
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
                }[type]}

                {#if config}
                    {@const isSoon =
                        facility.level === 0 &&
                        !["teamOffice", "garage"].includes(type)}
                    {@const price = facilityStore.getUpgradePrice(
                        type,
                        facility.level,
                    )}
                    {@const canAfford =
                        (teamStore.value.team?.budget ?? 0) >= price}
                    {@const Icon = facilityIcons[type] || Building2}

                    <div
                        in:fly={{ y: 20, duration: 400, delay: i * 50 }}
                        class="group relative bg-app-surface border border-white/5 rounded-3xl p-8 transition-all duration-300 hover:border-app-primary/30 hover:shadow-[0_20px_40px_rgba(0,0,0,0.3)] overflow-hidden {isSoon
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
                                            class="text-[10px] font-black text-white/20 uppercase tracking-widest block"
                                            >Level</span
                                        >
                                        <span
                                            class="text-xl font-black text-white italic"
                                            >{facility.level}</span
                                        >
                                    </div>
                                    {#if !isSoon}
                                        <a
                                            href={config.path}
                                            class="text-white/10 group-hover:text-app-primary transition-colors"
                                        >
                                            <ChevronRight size={24} />
                                        </a>
                                    {/if}
                                </div>
                            </div>

                            <div class="flex flex-col gap-1">
                                <h2
                                    class="text-2xl font-black text-white uppercase tracking-tight group-hover:text-app-primary transition-colors"
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
                                                class="text-[9px] font-black text-white/20 uppercase tracking-widest"
                                                >Next Upgrade</span
                                            >
                                            <span
                                                class="text-sm font-black {canAfford
                                                    ? 'text-white'
                                                    : 'text-red-500'}"
                                            >
                                                {price > 0
                                                    ? `$${(price / 1000000).toFixed(1)}M`
                                                    : "MAX LEVEL"}
                                            </span>
                                        </div>
                                        <button
                                            onclick={() => handleUpgrade(type)}
                                            disabled={price === 0 || !canAfford}
                                            class="px-4 py-2 bg-white/5 hover:bg-app-primary hover:text-black rounded-xl text-[9px] font-black uppercase tracking-widest transition-all disabled:opacity-0"
                                        >
                                            Upgrade
                                        </button>
                                    </div>

                                    <div class="flex items-center gap-2">
                                        <div
                                            class="h-1 w-8 bg-app-primary/20 rounded-full overflow-hidden"
                                        >
                                            <div
                                                class="h-full bg-app-primary w-0 group-hover:w-full transition-all duration-500"
                                            ></div>
                                        </div>
                                        <span
                                            class="text-[9px] font-black tracking-widest text-white/20 group-hover:text-white/40 uppercase"
                                        >
                                            Module Operational
                                        </span>
                                    </div>
                                {:else}
                                    <div
                                        class="py-3 text-center border border-white/5 border-dashed rounded-2xl"
                                    >
                                        <span
                                            class="text-[9px] font-black text-white/10 uppercase tracking-widest"
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
        class="mt-16 pt-8 border-t border-white/5 flex flex-wrap gap-12 opacity-50"
    >
        <div class="flex flex-col gap-1">
            <span
                class="text-[9px] font-black uppercase tracking-widest text-app-text/40"
                >Infrastructure Status</span
            >
            <span class="text-sm font-bold text-white"
                >{infrastructureRating}</span
            >
        </div>
        <div class="flex flex-col gap-1">
            <span
                class="text-[9px] font-black uppercase tracking-widest text-app-text/40"
                >Weekly Maintenance</span
            >
            <span class="text-sm font-bold text-white"
                >${(totalMaintenance / 1000).toFixed(0)}k
                <span class="text-[10px] opacity-40">/wk</span></span
            >
        </div>
        <div class="flex flex-col gap-1">
            <span
                class="text-[9px] font-black uppercase tracking-widest text-app-text/40"
                >Mean Technology Lvl</span
            >
            <span class="text-sm font-bold text-white"
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
