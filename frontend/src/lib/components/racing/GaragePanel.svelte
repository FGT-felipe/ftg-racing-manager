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
    import { fade, slide } from "svelte/transition";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";

    import PracticeSetupTab from "./tabs/PracticeSetupTab.svelte";
    import QualifyingSetupTab from "./tabs/QualifyingSetupTab.svelte";
    import RaceSetupTab from "./tabs/RaceSetupTab.svelte";

    let { currentWeekStatus } = $props<{ currentWeekStatus: string }>();

    // Derived states
    let team = $derived(teamStore.value.team);
    let drivers = $derived(driverStore.drivers);

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
    <!-- 1. COMPACT DRIVER SELECTOR -->
    <div class="flex flex-wrap gap-2">
        {#each drivers as driver: any}
            {@const isSelected = selectedDriverId === driver.id}
            <button
                class="px-4 py-2 rounded-xl border transition-all text-xs font-bold uppercase tracking-widest flex items-center gap-2
                {isSelected
                    ? 'bg-app-primary text-black border-app-primary'
                    : 'bg-black/40 border-app-border text-app-text/60 hover:bg-white/5 hover:border-white/20'}"
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
                        size={20}
                    />
                    {#if isSelected}
                        <div
                            class="absolute -top-1 -right-1 w-2 h-2 bg-black rounded-full border border-white/20"
                        ></div>
                    {/if}
                </div>
                {driver?.name?.split(" ")[0] || "Driver"}
                <span class="opacity-50 text-[8px]"
                    >[{driver.role?.charAt(0)}]</span
                >
            </button>
        {/each}
    </div>

    {#if selectedDriver}
        <!-- 2. ACTION CARDS (TABS) -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <!-- Practice Card -->
            <button
                id="practice-card"
                class="flex flex-col p-6 rounded-2xl border transition-all text-left group min-h-[160px] justify-between relative overflow-hidden
                {activeTab === 'practice'
                    ? 'bg-app-primary text-black border-app-primary shadow-[0_0_30px_rgba(197,160,89,0.3)]'
                    : 'bg-app-surface border-white/10 hover:border-white/20'}"
                onclick={() => (activeTab = "practice")}
            >
                <div class="relative z-10">
                    <div
                        class="flex items-center gap-2 mb-3 {activeTab ===
                        'practice'
                            ? 'text-black/60'
                            : 'text-app-primary'}"
                    >
                        <Timer size={18} />
                        <span
                            class="text-[11px] font-black uppercase tracking-[0.2em] font-heading"
                            >Free Practice</span
                        >
                    </div>
                    <h3
                        class="text-xl font-heading font-black uppercase italic {activeTab ===
                        'practice'
                            ? 'text-black'
                            : 'text-white'}"
                    >
                        PRACTICE <span class="opacity-50">SESSION</span>
                    </h3>
                </div>
                <div
                    class="text-[10px] font-bold uppercase tracking-widest mt-4 {activeTab ===
                    'practice'
                        ? 'text-black/70'
                        : 'text-app-text/40'}"
                >
                    {#if driverPracticeLaps > 0}
                        {driverPracticeLaps} LAPS RECORDED
                    {:else}
                        READY FOR TRACK
                    {/if}
                </div>
                {#if activeTab === "practice"}
                    <div class="absolute -bottom-2 -right-2 opacity-10">
                        <Timer size={80} />
                    </div>
                {/if}
            </button>

            <!-- Qualy Card -->
            <button
                id="qualy-card"
                class="flex flex-col p-6 rounded-2xl border transition-all text-left relative overflow-hidden min-h-[160px] justify-between
                {isQualyLocked
                    ? 'bg-black/50 border-white/5 cursor-not-allowed grayscale'
                    : activeTab === 'qualy'
                      ? 'bg-[#FFB800] text-black border-[#FFB800] shadow-[0_0_30px_rgba(255,184,0,0.3)]'
                      : 'bg-app-surface border-white/10 hover:border-white/20'}"
                onclick={() => {
                    if (!isQualyLocked) activeTab = "qualy";
                }}
                disabled={isQualyLocked}
            >
                <div class="relative z-10">
                    <div
                        class="flex items-center gap-2 mb-3 {isQualyLocked
                            ? 'text-white/20'
                            : activeTab === 'qualy'
                              ? 'text-black/60'
                              : 'text-[#FFB800]'}"
                    >
                        <Activity size={18} />
                        <span
                            class="text-[11px] font-black uppercase tracking-[0.2em] font-heading"
                            >Qualifying</span
                        >
                    </div>
                    <h3
                        class="text-xl font-heading font-black uppercase italic {isQualyLocked
                            ? 'text-white/20'
                            : activeTab === 'qualy'
                              ? 'text-black'
                              : 'text-white'}"
                    >
                        QUALY <span class="opacity-50">PACE</span>
                    </h3>
                </div>

                {#if isQualyLocked}
                    <div
                        class="absolute inset-0 flex flex-col items-center justify-center bg-black/60 z-20 backdrop-blur-[1px] p-4 text-center"
                    >
                        <Lock size={20} class="text-red-500 mb-2" />
                        <span
                            class="text-[9px] font-black uppercase tracking-widest text-red-500 max-w-[120px]"
                        >
                            {selectedDriver.role === "Reserve"
                                ? "RESERVE DRIVERS RESTRICTED"
                                : "PRACTICE REQUIRED TO UNLOCK"}
                        </span>
                    </div>
                {:else}
                    <div
                        class="text-[10px] font-bold uppercase tracking-widest mt-4 {activeTab ===
                        'qualy'
                            ? 'text-black/70'
                            : 'text-app-text/40'}"
                    >
                        GRID POSITIONING
                    </div>
                {/if}
                {#if activeTab === "qualy"}
                    <div
                        class="absolute -bottom-2 -right-2 opacity-10 text-black"
                    >
                        <Activity size={80} />
                    </div>
                {/if}
            </button>

            <!-- Race Card -->
            <button
                id="race-card"
                class="flex flex-col p-6 rounded-2xl border transition-all text-left relative overflow-hidden min-h-[160px] justify-between
                {isRaceLocked
                    ? 'bg-black/50 border-white/5 cursor-not-allowed grayscale'
                    : activeTab === 'race'
                      ? 'bg-[#E040FB] text-white border-[#E040FB] shadow-[0_0_30px_rgba(224,64,251,0.3)]'
                      : 'bg-app-surface border-white/10 hover:border-white/20'}"
                onclick={() => {
                    if (!isRaceLocked) activeTab = "race";
                }}
                disabled={isRaceLocked}
            >
                <div class="relative z-10">
                    <div
                        class="flex items-center gap-2 mb-3 {isRaceLocked
                            ? 'text-white/20'
                            : activeTab === 'race'
                              ? 'text-white/60'
                              : 'text-[#E040FB]'}"
                    >
                        <Flag size={18} />
                        <span
                            class="text-[11px] font-black uppercase tracking-[0.2em] font-heading"
                            >Race Preparation</span
                        >
                    </div>
                    <h3
                        class="text-xl font-heading font-black uppercase italic {isRaceLocked
                            ? 'text-white/20'
                            : 'text-white'}"
                    >
                        RACE <span class="opacity-50">STRATEGY</span>
                    </h3>
                </div>

                {#if isRaceLocked}
                    <div
                        class="absolute inset-0 flex flex-col items-center justify-center bg-black/60 z-20 backdrop-blur-[1px] p-4 text-center"
                    >
                        <Lock size={20} class="text-red-500 mb-2" />
                        <span
                            class="text-[9px] font-black uppercase tracking-widest text-red-500 max-w-[120px]"
                        >
                            {selectedDriver.role === "Reserve"
                                ? "RESERVE DRIVERS RESTRICTED"
                                : "PRACTICE REQUIRED TO UNLOCK"}
                        </span>
                    </div>
                {:else}
                    <div
                        class="text-[10px] font-bold uppercase tracking-widest mt-4 {activeTab ===
                        'race'
                            ? 'text-white/70'
                            : 'text-app-text/40'}"
                    >
                        SETUP & PIT STRATEGY
                    </div>
                {/if}
                {#if activeTab === "race"}
                    <div
                        class="absolute -bottom-2 -right-2 opacity-10 text-white"
                    >
                        <Flag size={80} />
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
                        <PracticeSetupTab driverId={selectedDriverId} />
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
