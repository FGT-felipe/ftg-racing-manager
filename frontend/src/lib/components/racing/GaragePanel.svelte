<script lang="ts">
    import {
        Car,
        Timer,
        Flag,
        Trophy,
        AlertCircle,
        Lock,
        Activity,
        Sun,
        Cloud,
        CloudRain,
        Cpu,
        Zap,
        Shield,
        School,
        GraduationCap,
    } from "lucide-svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { youthAcademyStore } from "$lib/stores/youthAcademy.svelte";
    import { timeService } from "$lib/services/time_service.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { circuitService } from "$lib/services/circuit_service.svelte";
    import { fade, slide } from "svelte/transition";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
    import { t } from "$lib/utils/i18n";
    import { buildCurrentSessionId, isDriverStatusStale } from "$lib/utils/sessionGate";

    import PracticePanel from "./PracticePanel.svelte";
    import QualifyingSetupTab from "./tabs/QualifyingSetupTab.svelte";
    import RaceSetupTab from "./tabs/RaceSetupTab.svelte";

    let { currentWeekStatus } = $props<{ currentWeekStatus: string }>();

    // Derived states
    let team = $derived(teamStore.value.team);
    let drivers = $derived(driverStore.drivers);
    let nextEvent = $derived(seasonStore.nextEvent);
    let circuit = $derived(nextEvent ? circuitService.getCircuitProfile(nextEvent.circuitId) : null);
    let componentTraits = $derived(circuit ? circuitService.getComponentTraits(circuit) : null);

    // UI State
    let selectedDriverId = $state<string | null>(null);
    let isTraineeMode = $state(false);

    // Trainee derived state
    const activeTrainee = $derived(
        youthAcademyStore.selectedDrivers.find(d => d.isMarkedForPromotion) ??
        youthAcademyStore.selectedDrivers[0] ??
        null
    );

    const mainDriver = $derived(
        drivers.find((d: any) => d.role === 'main' || d.role === 'Main' || d.carIndex === 0) ?? drivers[0] ?? null
    );

    const traineePracticeUsed = $derived(youthAcademyStore.traineePracticeUsed);

    const canSendTrainee = $derived(
        !!activeTrainee &&
        !traineePracticeUsed &&
        currentWeekStatus === 'practice'
    );

    /** Accepts both legacy "Reserve" (capital) and normalized "reserve" (lowercase). */
    function isReserveRole(role: string | undefined | null): boolean {
        return role?.toLowerCase() === 'reserve';
    }

    $effect(() => {
        if (!selectedDriverId && drivers.length > 0) {
            selectedDriverId = drivers[0].id;
        }
    });
    let activeTab = $state<"practice" | "qualy" | "race">("practice");

    // Initialize youthAcademyStore here so the trainee button is available
    // even when the user navigates directly to /racing without visiting /academy first.
    $effect(() => {
        const teamId = teamStore.value.team?.id;
        if (teamId) youthAcademyStore.init(teamId);
    });

    // Initialization
    $effect(() => {
        if (drivers.length > 0 && !selectedDriverId) {
            // Default to first Main driver, or any driver
            const mainDriver =
                drivers.find((d: any) => d.role === "main" || d.role === "Main" || d.carIndex === 0) || drivers[0];
            if (mainDriver) selectedDriverId = mainDriver.id;
        } else if (drivers.length > 0 && selectedDriverId) {
            // Ensure selected driver still exists
            const stillExists = drivers.some((d) => d.id === selectedDriverId);
            if (!stillExists) selectedDriverId = drivers[0].id;
        }
    });
    
    // Auto-switch tabs if current one becomes locked
    $effect(() => {
        if (isQualyLocked && activeTab === "qualy") {
            // Logic for switching away from Qualy if needed? 
            // Actually, keep it simple for now as per instructions.
        }
    });

    let selectedDriver = $derived(
        drivers?.find((d: any) => d.id === selectedDriverId) || drivers?.[0],
    );

    // Session gate: driverSetups persists across rounds because post-race
    // processing doesn't clear it. Both lap counters below must honour
    // practice.sessionId to avoid showing R(N) state on R(N+1).
    const currentSessionId = $derived(
        buildCurrentSessionId(seasonStore.value.season?.id, nextEvent?.id),
    );

    let driverPracticeLaps = $derived.by(() => {
        if (!selectedDriverId) return 0;
        const ds = teamStore.value.team?.weekStatus?.driverSetups?.[selectedDriverId];
        if (isDriverStatusStale(ds, currentSessionId)) return 0;
        return ds?.practice?.laps || 0;
    });

    let driverQualyAttempts = $derived.by(() => {
        if (!selectedDriverId) return 0;
        const ds = teamStore.value.team?.weekStatus?.driverSetups?.[selectedDriverId];
        if (isDriverStatusStale(ds, currentSessionId)) return 0;
        return ds?.qualifyingAttempts || 0;
    });

    let isSaturdayAfter1PM = $derived.by(() => {
        try {
            const now = new Date();
            const bogota = new Intl.DateTimeFormat('en-US', {
                timeZone: 'America/Bogota',
                weekday: 'long',
                hour: 'numeric',
                hour12: false
            });
            const parts = bogota.formatToParts(now);
            const weekday = parts.find(p => p.type === 'weekday')?.value;
            const hourValue = parts.find(p => p.type === 'hour')?.value;
            const hour = parseInt(hourValue || '0');
            
            return weekday === 'Saturday' && hour >= 13;
        } catch (e: any) {
            console.error('[GaragePanel] COT check error:', e.message);
            return false;
        }
    });

    let isQualyLocked = $derived.by(() => {
        if (!selectedDriver) return true;
        if (isTraineeMode) return true;
        if (isReserveRole(selectedDriver.role)) return true;
        if (isSaturdayAfter1PM) return false;
        return driverPracticeLaps === 0;
    });

    let isRaceLocked = $derived.by(() => {
        if (!selectedDriver) return true;
        if (isTraineeMode) return true;
        if (isReserveRole(selectedDriver.role)) return true;
        if (isSaturdayAfter1PM) return false;
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

    function getWeatherIcon(condition: string) {
        if (!condition) return Sun;
        const c = condition.toLowerCase();
        if (c.includes("rain") || c.includes("wet")) return CloudRain;
        if (c.includes("cloud")) return Cloud;
        return Sun;
    }

    function getWeatherColor(condition: string) {
        if (!condition) return "text-yellow-400";
        const c = condition.toLowerCase();
        if (c.includes("rain") || c.includes("wet")) return "text-blue-400";
        if (c.includes("cloud")) return "text-slate-400";
        return "text-yellow-400";
    }
</script>

<div class="flex flex-col gap-6" in:fade>
    {#if circuit}
        <!-- CIRCUIT INTEL WIDGET (Premium & Compact) -->
        <div class="bg-app-surface ring-1 ring-app-primary/20 rounded-2xl p-4 flex flex-col md:flex-row gap-6 items-center shadow-2xl relative group">
            <div class="absolute inset-0 bg-gradient-to-r from-app-primary/5 to-transparent pointer-events-none rounded-2xl"></div>
            
            <div class="flex items-center gap-4 w-full md:w-auto shrink-0 relative">
                <div class="w-12 h-12 rounded-xl bg-app-primary/10 flex items-center justify-center shadow-inner border border-app-primary/20">
                    <CountryFlag countryCode={nextEvent?.countryCode || circuit.countryCode} size="sm" />
                </div>
                <div>
                    <h4 class="text-[9px] font-black uppercase tracking-[0.3em] text-app-primary leading-none mb-1">{t('circuit_intel')}</h4>
                    <p class="text-sm font-black italic text-app-text tracking-tight uppercase leading-tight">{nextEvent?.trackName || circuit.name}</p>
                </div>
            </div>

            <div class="flex flex-wrap flex-1 w-full gap-4 items-center md:justify-end relative">
                <!-- Component Trait Badges -->
                <div class="flex items-center gap-3">
                    <!-- Aero -->
                    <div class="flex flex-col items-center gap-1">
                        <div class="flex items-center gap-1.5 text-app-text/50">
                            <Cpu size={12} />
                            <span class="text-[7px] font-black uppercase tracking-widest">{t('aero')}</span>
                        </div>
                        {#if componentTraits}
                            <div class="relative group/trait">
                                <span
                                    class="inline-flex items-center px-2 py-0.5 rounded-md text-[7px] font-black uppercase tracking-wider cursor-help transition-all
                                    {componentTraits.aero.label === 'High Downforce' ? 'bg-app-primary/15 text-app-primary border border-app-primary/20 shadow-[0_0_6px_rgba(197,160,89,0.1)]' : 'bg-blue-500/15 text-blue-400 border border-blue-500/20 shadow-[0_0_6px_rgba(59,130,246,0.1)]'}"
                                >{t(componentTraits.aero.tooltipKey)}</span>
                                <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-44 px-3 py-2 bg-app-bg border border-app-border rounded-lg shadow-xl opacity-0 invisible group-hover/trait:opacity-100 group-hover/trait:visible transition-all duration-200 z-50 pointer-events-none">
                                    <span class="text-[8px] text-app-text/80 leading-relaxed">{t('circuit_tooltip_' + componentTraits.aero.tooltipKey.replace('circuit_trait_', ''))}</span>
                                    <div class="absolute top-full left-1/2 -translate-x-1/2 w-2 h-2 bg-app-bg border-r border-b border-app-border rotate-45 -mt-1"></div>
                                </div>
                            </div>
                        {/if}
                    </div>
                    <!-- Power -->
                    <div class="flex flex-col items-center gap-1">
                        <div class="flex items-center gap-1.5 text-app-text/50">
                            <Zap size={12} />
                            <span class="text-[7px] font-black uppercase tracking-widest">{t('power')}</span>
                        </div>
                        {#if componentTraits}
                            <div class="relative group/trait">
                                <span
                                    class="inline-flex items-center px-2 py-0.5 rounded-md text-[7px] font-black uppercase tracking-wider cursor-help transition-all
                                    {componentTraits.power.label === 'Top Speed' ? 'bg-orange-500/15 text-orange-400 border border-orange-500/20 shadow-[0_0_6px_rgba(249,115,22,0.1)]' : 'bg-cyan-500/15 text-cyan-400 border border-cyan-500/20 shadow-[0_0_6px_rgba(6,182,212,0.1)]'}"
                                >{t(componentTraits.power.tooltipKey)}</span>
                                <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-44 px-3 py-2 bg-app-bg border border-app-border rounded-lg shadow-xl opacity-0 invisible group-hover/trait:opacity-100 group-hover/trait:visible transition-all duration-200 z-50 pointer-events-none">
                                    <span class="text-[8px] text-app-text/80 leading-relaxed">{t('circuit_tooltip_' + componentTraits.power.tooltipKey.replace('circuit_trait_', ''))}</span>
                                    <div class="absolute top-full left-1/2 -translate-x-1/2 w-2 h-2 bg-app-bg border-r border-b border-app-border rotate-45 -mt-1"></div>
                                </div>
                            </div>
                        {/if}
                    </div>
                    <!-- Chassis -->
                    <div class="flex flex-col items-center gap-1">
                        <div class="flex items-center gap-1.5 text-app-text/50">
                            <Shield size={12} />
                            <span class="text-[7px] font-black uppercase tracking-widest">{t('chassis')}</span>
                        </div>
                        {#if componentTraits}
                            <div class="relative group/trait">
                                <span
                                    class="inline-flex items-center px-2 py-0.5 rounded-md text-[7px] font-black uppercase tracking-wider cursor-help transition-all
                                    {componentTraits.chassis.label === 'Stiff' ? 'bg-red-500/15 text-red-400 border border-red-500/20 shadow-[0_0_6px_rgba(239,68,68,0.1)]' : 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/20 shadow-[0_0_6px_rgba(16,185,129,0.1)]'}"
                                >{t(componentTraits.chassis.tooltipKey)}</span>
                                <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-44 px-3 py-2 bg-app-bg border border-app-border rounded-lg shadow-xl opacity-0 invisible group-hover/trait:opacity-100 group-hover/trait:visible transition-all duration-200 z-50 pointer-events-none">
                                    <span class="text-[8px] text-app-text/80 leading-relaxed">{t('circuit_tooltip_' + componentTraits.chassis.tooltipKey.replace('circuit_trait_', ''))}</span>
                                    <div class="absolute top-full left-1/2 -translate-x-1/2 w-2 h-2 bg-app-bg border-r border-b border-app-border rotate-45 -mt-1"></div>
                                </div>
                            </div>
                        {/if}
                    </div>
                </div>

                <div class="flex gap-4 border-l border-white/10 pl-6 shrink-0">
                    <div class="relative flex flex-col cursor-help group/tw">
                        <span class="text-[7px] font-black uppercase tracking-[0.2em] opacity-30 mb-0.5 group-hover/tw:text-app-primary group-hover/tw:opacity-100 transition-all">{t('tyre_wear')}</span>
                        <span class="text-[10px] font-black text-app-text/90 uppercase">{circuit.characteristics['Tyre Wear'] || 'Normal'}</span>
                        <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-48 px-3 py-2 bg-app-bg border border-app-border rounded-lg shadow-xl opacity-0 invisible group-hover/tw:opacity-100 group-hover/tw:visible transition-all duration-200 z-50 pointer-events-none">
                            <span class="text-[8px] text-app-text/80 leading-relaxed">{t('circuit_tooltip_tyre_wear')}</span>
                            <div class="absolute top-full left-1/2 -translate-x-1/2 w-2 h-2 bg-app-bg border-r border-b border-app-border rotate-45 -mt-1"></div>
                        </div>
                    </div>
                    <div class="relative flex flex-col cursor-help group/fc">
                        <span class="text-[7px] font-black uppercase tracking-[0.2em] opacity-30 mb-0.5 group-hover/fc:text-app-primary group-hover/fc:opacity-100 transition-all">{t('fuel_consumption')}</span>
                        <span class="text-[10px] font-black text-app-text/90 uppercase">{circuit.characteristics['Fuel Consumption'] || 'Normal'}</span>
                        <div class="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 w-52 px-3 py-2 bg-app-bg border border-app-border rounded-lg shadow-xl opacity-0 invisible group-hover/fc:opacity-100 group-hover/fc:visible transition-all duration-200 z-50 pointer-events-none">
                            <span class="text-[8px] text-app-text/80 leading-relaxed">{t('circuit_tooltip_fuel_consumption')}</span>
                            <div class="absolute top-full left-1/2 -translate-x-1/2 w-2 h-2 bg-app-bg border-r border-b border-app-border rotate-45 -mt-1"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    {/if}

    <!-- 1. COMPACT DRIVER SELECTOR -->
    <div class="flex flex-wrap gap-2">
        {#each drivers as driver: any}
            {@const isSelected = selectedDriverId === driver.id && !isTraineeMode}
            <button
                class="px-4 py-2 rounded-xl border transition-all text-xs font-bold uppercase tracking-widest flex items-center gap-2
                {isSelected
                    ? 'bg-app-primary text-app-primary-foreground border-app-primary'
                    : 'bg-app-text/40 border-app-border text-app-text/60 hover:bg-app-text/5 hover:border-app-border'}"
                onclick={() => {
                    selectedDriverId = driver.id;
                    isTraineeMode = false;
                    if (isReserveRole(driver.role) && activeTab !== "practice") {
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
                            <div class="h-full {getFitnessColor(driver.stats?.fitness || 100).replace('text-', 'bg-')}" style="width: {driver.stats?.fitness || 100}%"></div>
                        </div>
                        <div class="flex-1 h-full bg-black/10 rounded-full overflow-hidden">
                            <div class="h-full {getMoraleColor(driver.stats?.morale || 100).replace('text-', 'bg-')}" style="width: {driver.stats?.morale || 100}%"></div>
                        </div>
                    </div>
                </div>
            </button>
        {/each}

        <!-- Trainee practice button — only during practice window if team has a trainee -->
        {#if activeTrainee && currentWeekStatus === 'practice'}
            {@const traineeSelected = isTraineeMode}
            {@const slotUsed = !!traineePracticeUsed && traineePracticeUsed !== activeTrainee?.id}
            <button
                class="px-4 py-2 rounded-xl border transition-all text-xs font-bold uppercase tracking-widest flex items-center gap-2
                {slotUsed
                    ? 'bg-app-text/20 border-app-border text-app-text/30 cursor-not-allowed'
                    : traineeSelected
                      ? 'bg-emerald-600 text-white border-emerald-500 shadow-[0_0_12px_rgba(16,185,129,0.3)]'
                      : 'bg-emerald-900/30 border-emerald-700/40 text-emerald-400 hover:bg-emerald-900/50 hover:border-emerald-600/60'}"
                onclick={() => {
                    if (!slotUsed) {
                        isTraineeMode = true;
                        selectedDriverId = mainDriver?.id ?? selectedDriverId;
                        activeTab = 'practice';
                    }
                }}
                disabled={slotUsed}
                title={slotUsed ? t('academy_practice_slot_locked') : t('academy_practice_send_trainee')}
            >
                <GraduationCap size={16} />
                <div class="flex flex-col items-start gap-0.5 min-w-[60px]">
                    <div class="flex items-center gap-1.5 w-full">
                        <span class="truncate">{activeTrainee.name?.split(" ")[0] || "Trainee"}</span>
                        <span class="text-[7px] font-black {slotUsed ? 'opacity-30' : 'opacity-60'}">[T]</span>
                    </div>
                    <div class="text-[7px] font-black uppercase tracking-widest {slotUsed ? 'opacity-30' : 'opacity-60'}">
                        {slotUsed ? 'USED' : 'TRAINEE'}
                    </div>
                </div>
            </button>
        {/if}
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
                onclick={() => {
                    activeTab = "practice";
                }}
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
                        {#if nextEvent?.weatherPractice}
                            {@const Icon = getWeatherIcon(nextEvent.weatherPractice)}
                            <div class="ml-auto flex items-center gap-1.5 px-2 py-1 bg-black/5 rounded-lg border border-black/5">
                                <Icon 
                                    size={18} 
                                    class={getWeatherColor(nextEvent.weatherPractice)}
                                />
                                <span class="text-[10px] font-black uppercase tracking-widest {activeTab === 'practice' ? 'text-black/60' : 'text-app-text/60'}">
                                    {nextEvent.weatherPractice}
                                </span>
                            </div>
                        {/if}
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
                        {#if traineePracticeUsed && !isTraineeMode}
                            {t('academy_practice_slot_locked')}
                        {:else}
                            {t('session_laps', { n: driverPracticeLaps })}
                        {/if}
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
                      ? 'bg-app-qualifying text-black border-app-qualifying shadow-[0_0_20px_rgba(255,184,0,0.2)]'
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
                              : 'text-app-qualifying'}"
                    >
                        <Activity size={14} />
                        <span
                            class="text-[9px] font-black uppercase tracking-[0.2em] font-heading"
                            >Qualifying</span
                        >
                        {#if nextEvent?.weatherQualifying}
                            {@const Icon = getWeatherIcon(nextEvent.weatherQualifying)}
                            <div class="ml-auto flex items-center gap-1.5 px-2 py-1 rounded-lg border {activeTab === 'qualy' ? 'bg-black/5 border-black/5' : 'bg-white/5 border-white/5'}">
                                <Icon
                                    size={18}
                                    class={getWeatherColor(nextEvent.weatherQualifying)}
                                />
                                <span class="text-[10px] font-black uppercase tracking-widest {activeTab === 'qualy' ? 'text-black/60' : 'text-app-text/60'}">
                                    {nextEvent.weatherQualifying}
                                </span>
                            </div>
                        {/if}
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
                            {isReserveRole(selectedDriver.role)
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
                      ? 'bg-app-fastest text-app-text border-app-fastest shadow-[0_0_20px_rgba(224,64,251,0.2)]'
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
                              : 'text-app-fastest'}"
                    >
                        <Flag size={14} />
                        <span
                            class="text-[9px] font-black uppercase tracking-[0.2em] font-heading"
                            >{t('race_preparation')}</span
                        >
                        {#if nextEvent?.weatherRace}
                            {@const Icon = getWeatherIcon(nextEvent.weatherRace)}
                            <div class="ml-auto flex items-center gap-1.5 px-2 py-1 bg-white/5 rounded-lg border border-white/5">
                                <Icon 
                                    size={18} 
                                    class={getWeatherColor(nextEvent.weatherRace)}
                                />
                                <span class="text-[10px] font-black uppercase tracking-widest text-app-text/60">
                                    {nextEvent.weatherRace}
                                </span>
                            </div>
                        {/if}
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
                            {isReserveRole(selectedDriver.role)
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
                        <PracticePanel
                            driverId={selectedDriverId}
                            isTrainee={isTraineeMode}
                            trainee={isTraineeMode ? activeTrainee : null}
                            mainDriverId={isTraineeMode ? (mainDriver?.id ?? null) : null}
                        />
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
