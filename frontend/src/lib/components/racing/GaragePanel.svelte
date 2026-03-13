<script lang="ts">
    import {
        Car,
        Timer,
        Flag,
        Trophy,
        AlertCircle,
        Lock,
        Activity,
    } from "lucide-svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { timeService } from "$lib/services/time_service.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { circuitService } from "$lib/services/circuit_service.svelte";
    import { fade, slide } from "svelte/transition";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
    import { t } from "$lib/utils/i18n";

    import PracticePanel from "./PracticePanel.svelte";
    import QualifyingSetupTab from "./tabs/QualifyingSetupTab.svelte";
    import RaceSetupTab from "./tabs/RaceSetupTab.svelte";

    let { currentWeekStatus } = $props<{ currentWeekStatus: string }>();

    // Derived states
    let team = $derived(teamStore.value.team);
    let drivers = $derived(driverStore.drivers);
    let nextEvent = $derived(seasonStore.nextEvent);
    let circuit = $derived(nextEvent ? circuitService.getCircuitProfile(nextEvent.circuitId) : null);

    // UI State
    let selectedDriverId = $state<string | null>(null);

    $effect(() => {
        if (!selectedDriverId && drivers.length > 0) {
            selectedDriverId = drivers[0].id;
        }
    });
    let activeTab = $state<"practice" | "qualy" | "race">("practice");

    // Initialization
    $effect(() => {
        if (drivers.length > 0 && !selectedDriverId) {
            // Default to first Main driver, or any driver
            const mainDriver =
                drivers.find((d: any) => d.role === "Main") || drivers[0];
            if (mainDriver) selectedDriverId = mainDriver.id;
        } else if (drivers.length > 0 && selectedDriverId) {
            // Ensure selected driver still exists
            const stillExists = drivers.some((d) => d.id === selectedDriverId);
            if (!stillExists) selectedDriverId = drivers[0].id;
        }
    });

    let selectedDriver = $derived(
        drivers?.find((d: any) => d.id === selectedDriverId) || drivers?.[0],
    );

    let driverPracticeLaps = $derived.by(() => {
        if (!selectedDriverId) return 0;
        return (
            teamStore.value.team?.weekStatus?.driverSetups?.[selectedDriverId]
                ?.practice?.laps || 0
        );
    });

    let isQualyLocked = $derived.by(() => {
        if (!selectedDriver) return true;
        if (selectedDriver.role === "Reserve") return true;
        return driverPracticeLaps === 0;
    });

    let isRaceLocked = $derived.by(() => {
        if (!selectedDriver) return true;
        if (selectedDriver.role === "Reserve") return true;
        return driverPracticeLaps === 0;
    });

    function getMoraleColor(morale: number) {
        if (morale >= 80) return "text-emerald-400";
        if (morale >= 50) return "text-yellow-400";
        return "text-red-400";
    }

    function getFitnessColor(fitness: number) {
        if (fitness >= 80) return "text-emerald-400";
        if (fitness >= 40) return "text-yellow-400";
        return "text-red-400";
    }
</script>

<div class="flex flex-col gap-6" in:fade>
    {#if circuit}
        <!-- CIRCUIT INTEL WIDGET (Premium & Compact) -->
        <div class="bg-app-surface ring-1 ring-app-primary/20 rounded-2xl p-4 flex flex-col md:flex-row gap-6 items-center shadow-2xl relative overflow-hidden group">
            <div class="absolute inset-0 bg-gradient-to-r from-app-primary/5 to-transparent pointer-events-none"></div>
            
            <div class="flex items-center gap-4 w-full md:w-auto shrink-0 relative">
                <div class="w-12 h-12 rounded-xl bg-app-primary/10 flex items-center justify-center shadow-inner border border-app-primary/20">
                    <CountryFlag countryCode={circuit.countryCode} size="sm" />
                </div>
                <div>
                    <h4 class="text-[9px] font-black uppercase tracking-[0.3em] text-app-primary leading-none mb-1">Circuit Intel</h4>
                    <p class="text-sm font-black italic text-app-text tracking-tight uppercase truncate max-w-[180px]">{circuit.name}</p>
                </div>
            </div>

            <div class="flex flex-wrap flex-1 w-full gap-6 items-center md:justify-end relative">
                {#each [
                    { label: 'Aero', val: circuit.aeroWeight, color: 'text-cyan-400' },
                    { label: 'Power', val: circuit.powertrainWeight, color: 'text-orange-400' },
                    { label: 'Chassis', val: circuit.chassisWeight, color: 'text-purple-400' }
                ] as stat}
                    <div class="flex-1 min-w-[70px] max-w-[90px] space-y-1.5">
                        <div class="flex justify-between text-[8px] font-black uppercase tracking-widest opacity-40">
                            <span>{stat.label}</span>
                            <span class={stat.color}>{Math.round(stat.val * 100)}%</span>
                        </div>
                        <div class="w-full h-1 bg-white/5 rounded-full overflow-hidden">
                            <div class="h-full bg-current {stat.color.replace('text-', 'bg-')}" style="width: {stat.val * 100}%"></div>
                        </div>
                    </div>
                {/each}

                <div class="flex gap-4 border-l border-white/10 pl-6 shrink-0">
                    <div class="flex flex-col">
                        <span class="text-[7px] font-black uppercase tracking-[0.2em] opacity-30 mb-0.5">{t('tyre_wear')}</span>
                        <span class="text-[10px] font-black text-app-text/90 uppercase">{circuit.characteristics['Tyre Wear'] || 'Normal'}</span>
                    </div>
                    <div class="flex flex-col">
                        <span class="text-[7px] font-black uppercase tracking-[0.2em] opacity-30 mb-0.5">{t('fuel_consumption')}</span>
                        <span class="text-[10px] font-black text-app-text/90 uppercase">{circuit.characteristics['Fuel Consumption'] || 'Normal'}</span>
                    </div>
                </div>
            </div>
        </div>
    {/if}

    <!-- 1. COMPACT DRIVER SELECTOR -->
    <div class="flex flex-wrap gap-2">
        {#each drivers as driver: any}
            {@const isSelected = selectedDriverId === driver.id}
            <button
                class="px-4 py-2 rounded-xl border transition-all text-xs font-bold uppercase tracking-widest flex items-center gap-2
                {isSelected
                    ? 'bg-app-primary text-app-primary-foreground border-app-primary'
                    : 'bg-app-text/40 border-app-border text-app-text/60 hover:bg-app-text/5 hover:border-app-border'}"
                onclick={() => {
                    selectedDriverId = driver.id;
                    if (driver.role === "Reserve" && activeTab !== "practice") {
                        activeTab = "practice";
                    }
                }}
            >
                <div class="relative">
                    <DriverAvatar
                        id={driver.id}
                        seed={driver.id}
                        gender={driver.gender}
                        size={22}
                    />
                    {#if isSelected}
                        <div
                            class="absolute -top-1 -right-1 w-2 h-2 bg-app-bg rounded-full border border-app-border"
                        ></div>
                    {/if}
                </div>
                <div class="flex flex-col items-start gap-0.5 min-w-[60px]">
                    <div class="flex items-center gap-1.5 w-full">
                         <span class="truncate">{driver?.name?.split(" ")[0] || "Driver"}</span>
                         <span class="opacity-30 text-[7px] font-black">[{driver.role?.charAt(0)}]</span>
                    </div>
                    <!-- Tiny Status Bars -->
                    <div class="flex gap-1 w-full h-0.5">
                        <div class="flex-1 h-full bg-black/10 rounded-full overflow-hidden">
                            <div class="h-full {getFitnessColor(driver.stats?.stamina || 100).replace('text-', 'bg-')}" style="width: {driver.stats?.stamina || 100}%"></div>
                        </div>
                        <div class="flex-1 h-full bg-black/10 rounded-full overflow-hidden">
                            <div class="h-full {getMoraleColor(driver.stats?.morale || 100).replace('text-', 'bg-')}" style="width: {driver.stats?.morale || 100}%"></div>
                        </div>
                    </div>
                </div>
            </button>
        {/each}
    </div>

    {#if selectedDriver}
        <!-- 2. ACTION CARDS (TABS - Compacted) -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
            <!-- Practice Card -->
            <button
                id="practice-card"
                class="flex flex-col p-4 rounded-xl border transition-all text-left group min-h-[110px] justify-between relative overflow-hidden
                {activeTab === 'practice'
                    ? 'bg-app-primary text-app-primary-foreground border-app-primary shadow-[0_0_20px_rgba(197,160,89,0.2)]'
                    : 'bg-app-surface border-app-border hover:border-app-border'}"
                onclick={() => (activeTab = "practice")}
            >
                <div class="relative z-10">
                    <div
                        class="flex items-center gap-2 mb-1.5 {activeTab ===
                        'practice'
                            ? 'text-black/60'
                            : 'text-app-primary'}"
                    >
                        <Timer size={14} />
                        <span
                            class="text-[9px] font-black uppercase tracking-[0.2em] font-heading"
                            >Free Practice</span
                        >
                    </div>
                    <h3
                        class="text-base font-heading font-black uppercase italic {activeTab ===
                        'practice'
                            ? 'text-black'
                            : 'text-app-text'}"
                    >
                        PRACTICE <span class="opacity-50">SESSION</span>
                    </h3>
                </div>
                    <div
                        class="text-[9px] font-black uppercase tracking-widest mt-2 {activeTab ===
                        'practice'
                            ? 'text-black/80'
                            : 'text-app-primary/60'}"
                    >
                        {t('session_laps', { n: driverPracticeLaps })}
                    </div>
                {#if activeTab === "practice"}
                    <div class="absolute -bottom-1 -right-1 opacity-10">
                        <Timer size={50} />
                    </div>
                {/if}
            </button>

            <!-- Qualy Card -->
            <button
                id="qualy-card"
                class="flex flex-col p-4 rounded-xl border transition-all text-left relative overflow-hidden min-h-[110px] justify-between
                {isQualyLocked
                    ? 'bg-app-text/50 border-app-border cursor-not-allowed grayscale'
                    : activeTab === 'qualy'
                      ? 'bg-[#FFB800] text-black border-[#FFB800] shadow-[0_0_20px_rgba(255,184,0,0.2)]'
                      : 'bg-app-surface border-app-border hover:border-app-border'}"
                onclick={() => {
                    if (!isQualyLocked) activeTab = "qualy";
                }}
                disabled={isQualyLocked}
            >
                <div class="relative z-10">
                    <div
                        class="flex items-center gap-2 mb-1.5 {isQualyLocked
                            ? 'text-app-text/20'
                            : activeTab === 'qualy'
                              ? 'text-black/60'
                              : 'text-[#FFB800]'}"
                    >
                        <Activity size={14} />
                        <span
                            class="text-[9px] font-black uppercase tracking-[0.2em] font-heading"
                            >Qualifying</span
                        >
                    </div>
                    <h3
                        class="text-base font-heading font-black uppercase italic {isQualyLocked
                            ? 'text-app-text/20'
                            : activeTab === 'qualy'
                              ? 'text-black'
                              : 'text-app-text'}"
                    >
                        QUALY <span class="opacity-50">PACE</span>
                    </h3>
                </div>

                {#if isQualyLocked}
                    <div
                        class="absolute inset-0 flex flex-col items-center justify-center bg-app-text/60 z-20 backdrop-blur-[1px] p-2 text-center"
                    >
                        <Lock size={16} class="text-red-500 mb-1" />
                        <span
                            class="text-[8px] font-black uppercase tracking-widest text-red-500 max-w-[100px]"
                        >
                            {selectedDriver.role === "Reserve"
                                ? "RESERVE DRIVERS RESTRICTED"
                                : "PRACTICE REQUIRED"}
                        </span>
                    </div>
                {:else}
                    <div
                        class="text-[8px] font-bold uppercase tracking-widest mt-2 {activeTab ===
                        'qualy'
                            ? 'text-black/70'
                            : 'text-app-text/40'}"
                    >
                        GRID POSITIONING
                    </div>
                {/if}
                {#if activeTab === "qualy"}
                    <div
                        class="absolute -bottom-1 -right-1 opacity-10 text-black"
                    >
                        <Activity size={50} />
                    </div>
                {/if}
            </button>

            <!-- Race Card -->
            <button
                id="race-card"
                class="flex flex-col p-4 rounded-xl border transition-all text-left relative overflow-hidden min-h-[110px] justify-between
                {isRaceLocked
                    ? 'bg-app-text/50 border-app-border cursor-not-allowed grayscale'
                    : activeTab === 'race'
                      ? 'bg-[#E040FB] text-app-text border-[#E040FB] shadow-[0_0_20px_rgba(224,64,251,0.2)]'
                      : 'bg-app-surface border-app-border hover:border-app-border'}"
                onclick={() => {
                    if (!isRaceLocked) activeTab = "race";
                }}
                disabled={isRaceLocked}
            >
                <div class="relative z-10">
                    <div
                        class="flex items-center gap-2 mb-1.5 {isRaceLocked
                            ? 'text-app-text/20'
                            : activeTab === 'race'
                              ? 'text-app-text/60'
                              : 'text-[#E040FB]'}"
                    >
                        <Flag size={14} />
                        <span
                            class="text-[9px] font-black uppercase tracking-[0.2em] font-heading"
                            >Race Preparation</span
                        >
                    </div>
                    <h3
                        class="text-base font-heading font-black uppercase italic {isRaceLocked
                            ? 'text-app-text/20'
                            : 'text-app-text'}"
                    >
                        RACE <span class="opacity-50">STRATEGY</span>
                    </h3>
                </div>

                {#if isRaceLocked}
                    <div
                        class="absolute inset-0 flex flex-col items-center justify-center bg-app-text/60 z-20 backdrop-blur-[1px] p-2 text-center"
                    >
                        <Lock size={16} class="text-red-500 mb-1" />
                        <span
                            class="text-[8px] font-black uppercase tracking-widest text-red-500 max-w-[100px]"
                        >
                            {selectedDriver.role === "Reserve"
                                ? "RESERVE DRIVERS RESTRICTED"
                                : "PRACTICE REQUIRED"}
                        </span>
                    </div>
                {:else}
                    <div
                        class="text-[8px] font-bold uppercase tracking-widest mt-2 {activeTab ===
                        'race'
                            ? 'text-app-text/70'
                            : 'text-app-text/40'}"
                    >
                        SETUP & STRATEGY
                    </div>
                {/if}
                {#if activeTab === "race"}
                    <div
                        class="absolute -bottom-1 -right-1 opacity-10 text-app-text"
                    >
                        <Flag size={50} />
                    </div>
                {/if}
            </button>
        </div>

        <!-- 3. ACTIVE TAB CONTENT -->
        <div
            class="mt-2 bg-app-surface border border-app-border rounded-2xl p-4 md:p-6 shadow-2xl overflow-hidden min-h-[500px]"
        >
            {#key activeTab}
                <div in:fade={{ duration: 200 }}>
                    {#if activeTab === "practice"}
                        <PracticePanel driverId={selectedDriverId} />
                    {:else if activeTab === "qualy"}
                        <QualifyingSetupTab driverId={selectedDriverId} />
                    {:else if activeTab === "race"}
                        <RaceSetupTab driverId={selectedDriverId} />
                    {/if}
                </div>
            {/key}
        </div>
    {/if}
</div>
