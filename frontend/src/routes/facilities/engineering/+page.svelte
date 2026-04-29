<script lang="ts">
    import { carStore } from "$lib/stores/car.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { timeService } from "$lib/services/time_service.svelte";
    import { uiStore } from "$lib/stores/ui.svelte";
    import RepairModal from "$lib/components/racing/RepairModal.svelte";
    import PartRow from "$lib/components/racing/PartRow.svelte";
    import { partsStore } from "$lib/stores/parts.svelte";
    import { partsWearService } from "$lib/services/parts_wear_service.svelte";
    import type { Part } from "$lib/types";
    import { t } from "$lib/utils/i18n";
    import {
        Wrench,
        Zap,
        Wind,
        Navigation,
        ShieldCheck,
        Info,
        ArrowUpCircle,
        History,
        Lock,
    } from "lucide-svelte";
    import InstructionCard from "$lib/components/layout/InstructionCard.svelte";
    import CarSchematic from "$lib/components/dashboard/CarSchematic.svelte";
    import DriverSmallCard from "$lib/components/dashboard/DriverSmallCard.svelte";

    let selectedCar = $state(0); // 0 for Car A, 1 for Car B

    // Parts wear
    let showRepairModal = $state(false);
    let repairPart = $state<Part | null>(null);

    let _loadedPartsKey = '';
    $effect(() => {
        const teamId = teamStore.value.team?.id;
        if (!teamId) return;
        const key = `${teamId}_${selectedCar}`;
        if (key === _loadedPartsKey) return;
        _loadedPartsKey = key;
        partsWearService.seedEngineIfMissing(teamId, selectedCar).catch((e) =>
            console.error('[Engineering] seedEngineIfMissing failed:', e)
        );
        const cleanup = partsStore.init(teamId, selectedCar);
        return cleanup;
    });

    // Maps upgrade card key → wear part id
    const partWearMap: Record<string, string> = {
        aero: 'aero',
        powertrain: 'engine',
        chassis: 'chassis',
        reliability: 'reliability',
    };

    const tierTextColors: Record<string, string> = {
        green: 'text-green-400',
        yellow: 'text-yellow-400',
        orange: 'text-orange-400',
        red: 'text-red-400',
    };
    const tierBarColors: Record<string, string> = {
        green: 'bg-green-500',
        yellow: 'bg-yellow-500',
        orange: 'bg-orange-500',
        red: 'bg-red-500',
    };

    const partIcons: Record<string, any> = {
        aero: Wind,
        powertrain: Zap,
        chassis: Navigation,
        reliability: ShieldCheck,
    };

    const partColors: Record<string, string> = {
        aero: "text-cyan-400",
        powertrain: "text-orange-400",
        chassis: "text-purple-400",
        reliability: "text-emerald-400",
    };

    const partDescriptions: Record<string, string> = {
        aero: "Reduces drag and increases downforce. Critical for high-speed corners.",
        powertrain:
            "Increases acceleration and top speed. Essential for long straights.",
        chassis:
            "Improves handling and tyre management. Vital for technical circuits.",
        reliability:
            "Reduces the risk of mechanical failures and performance degradation.",
    };

    async function handleUpgrade(partKey: string) {
        if (timeService.isSetupLocked) return;
        try {
            await carStore.upgradePart(selectedCar, partKey);
        } catch (e: any) {
            uiStore.alert(e.message, 'Error', 'danger');
        }
    }

    // Initialize stores
    driverStore.init();

    const currentCarStats = $derived(
        carStore.carStats[selectedCar.toString()] || {
            aero: 1,
            powertrain: 1,
            chassis: 1,
            reliability: 1,
        },
    );
    const upgradeCount = $derived(
        teamStore.value.team?.weekStatus?.upgradesThisWeek || 0,
    );
    const maxUpgrades = $derived(
        managerStore.profile?.role === "engineer" ? 2 : 1,
    );
    const isLocked = $derived(timeService.isSetupLocked);
    const isRepairLocked = $derived(timeService.isRepairLocked);
    const isLastRound = $derived(!!(teamStore.value.team?.weekStatus?.['isLastRound'] as boolean | undefined));
    const carConditionPct = $derived(partsStore.carConditionPct);
    const carConditionTier = $derived(partsStore.carConditionTier);
</script>

<svelte:head>
    <title>Engineering | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-4 md:p-8 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text"
>
    <InstructionCard
        icon={Wrench}
        title="Engineering Department"
        description="Develop your car parts to gain a competitive edge. Focus on different areas of performance based on upcoming circuit requirements. Remember that upgrades are limited by budget and your technical staff's weekly capacity."
    >
        {#snippet extraContent()}
            <div class="flex flex-wrap items-center gap-6 mt-2">
                <div class="flex flex-col">
                    <span
                        class="text-[10px] font-bold text-app-text/40 uppercase tracking-widest"
                        >Available Budget</span
                    >
                    <span class="text-2xl font-black text-app-text"
                        >{teamStore.formattedBudget}</span
                    >
                </div>
                <div class="h-10 w-px bg-app-border/50 hidden md:block"></div>
                <div class="flex flex-col">
                    <span
                        class="text-[10px] font-bold text-app-text/40 uppercase tracking-widest"
                        >Weekly Limit</span
                    >
                    <div class="flex items-center gap-1.5 mt-0.5">
                        <div class="flex gap-1">
                            {#each Array(maxUpgrades) as _, i}
                                <div
                                    class="w-2.5 h-2.5 rounded-full {i <
                                    upgradeCount
                                        ? 'bg-orange-500 shadow-[0_0_8px_rgba(249,115,22,0.5)]'
                                        : 'bg-app-text/10'}"
                                ></div>
                            {/each}
                        </div>
                        <span class="text-xs font-bold text-app-text/60 ml-1"
                            >{upgradeCount}/{maxUpgrades}</span
                        >
                    </div>
                </div>
                {#if managerStore.profile?.role === "engineer"}
                    <div
                        class="ml-auto px-3 py-1 bg-orange-500/10 border border-orange-500/20 rounded-full flex items-center gap-2"
                    >
                        <ArrowUpCircle size={12} class="text-orange-400" />
                        <span
                            class="text-[10px] font-black text-orange-400 uppercase"
                            >Lead Engineer Bonus: +1 Upgrade Slot</span
                        >
                    </div>
                {/if}
            </div>
        {/snippet}
    </InstructionCard>

    <div class="mt-10 grid grid-cols-1 lg:grid-cols-12 gap-8">
        <!-- Left: Car Selector & Schematics -->
        <div class="lg:col-span-4 space-y-6">
            <div
                class="bg-app-surface border border-app-border rounded-2xl p-2 flex gap-1"
            >
                <button
                    class="flex-1 py-3 rounded-xl font-black uppercase tracking-widest text-sm transition-all {selectedCar ===
                    0
                        ? 'bg-app-primary text-app-primary-foreground'
                        : 'text-app-text/40 hover:bg-app-text/5'}"
                    onclick={() => (selectedCar = 0)}>Car A</button
                >
                <button
                    class="flex-1 py-3 rounded-xl font-black uppercase tracking-widest text-sm transition-all {selectedCar ===
                    1
                        ? 'bg-app-primary text-app-primary-foreground'
                        : 'text-app-text/40 hover:bg-app-text/5'}"
                    onclick={() => (selectedCar = 1)}>Car B</button
                >
            </div>

            <div class="space-y-4">
                <h3
                    class="text-[10px] font-bold text-app-text/40 uppercase tracking-[0.2em] px-2 flex items-center gap-2"
                >
                    <Info size={12} />
                    Status Analysis
                </h3>
                <CarSchematic
                    stats={currentCarStats}
                    carLabel={selectedCar === 0 ? "Car A" : "Car B"}
                />

                {#if selectedCar === 0 && driverStore.carADriver}
                    <DriverSmallCard
                        driver={driverStore.carADriver}
                        carIndex={0}
                    />
                {:else if selectedCar === 1 && driverStore.carBDriver}
                    <DriverSmallCard
                        driver={driverStore.carBDriver}
                        carIndex={1}
                    />
                {:else}
                    <div
                        class="p-4 border border-app-border border-dashed rounded-xl text-center text-app-text/30 text-[10px] font-bold uppercase"
                    >
                        No driver assigned to this car
                    </div>
                {/if}
            </div>

            <div
                class="bg-app-surface border border-app-border rounded-2xl p-5"
            >
                <div class="flex items-center gap-2 mb-4">
                    <History size={16} class="text-app-primary" />
                    <h3 class="text-xs font-black uppercase text-app-text">
                        R&D Policy
                    </h3>
                </div>
                <ul class="space-y-3">
                    <li
                        class="flex items-start gap-2 text-[11px] text-app-text/60"
                    >
                        <div
                            class="w-1.5 h-1.5 rounded-full bg-app-primary mt-1 shrink-0"
                        ></div>
                        Upgrades are permanent for the current season.
                    </li>
                    <li
                        class="flex items-start gap-2 text-[11px] text-app-text/60"
                    >
                        <div
                            class="w-1.5 h-1.5 rounded-full bg-app-primary mt-1 shrink-0"
                        ></div>
                        Upgrade prices increase exponentially (Fibonacci).
                    </li>
                    {#if managerStore.profile?.role === "bureaucrat"}
                        <li
                            class="flex items-start gap-2 text-[11px] text-red-400"
                        >
                            <div
                                class="w-1.5 h-1.5 rounded-full bg-red-400 mt-1 shrink-0"
                            ></div>
                            Bureaucrat: 2-week cooldown between upgrades.
                        </li>
                    {/if}
                </ul>
            </div>
        </div>

        <!-- Right: Upgrade Panel -->
        <div class="lg:col-span-8">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                {#each Object.keys(partIcons) as partKey}
                    {@const level = currentCarStats[partKey] || 1}
                    {@const cost = carStore.getUpgradeCost(level)}
                    {@const canAfford =
                        (teamStore.value.team?.budget ?? 0) >= cost}
                    {@const limitReached = upgradeCount >= maxUpgrades}
                    {@const PartIcon = partIcons[partKey]}
                    {@const wearPartId = partWearMap[partKey]}
                    {@const wearCondition = wearPartId ? partsStore.getCondition(wearPartId) : 100}
                    {@const wearTier = wearPartId ? partsStore.getTier(wearPartId) : 'green'}

                    <div
                        class="bg-app-surface border border-app-border rounded-2xl p-6 flex flex-col justify-between group transition-all hover:border-app-primary/30"
                    >
                        <div>
                            <div class="flex items-center justify-between mb-4">
                                <div
                                    class="p-3 bg-app-text/5 rounded-xl {partColors[
                                        partKey
                                    ]} group-hover:bg-app-primary/10 transition-colors"
                                >
                                    <PartIcon size={24} />
                                </div>
                                <div class="text-right">
                                    <span
                                        class="text-[10px] font-bold text-app-text/30 uppercase tracking-widest block"
                                        >Lvl</span
                                    >
                                    <span
                                        class="text-2xl font-black text-app-text italic"
                                        >{level}</span
                                    >
                                </div>
                            </div>
                            <h4
                                class="text-lg font-heading font-black uppercase text-app-text tracking-tight mb-2"
                            >
                                {partKey}
                            </h4>
                            <p
                                class="text-[12px] text-app-text/60 leading-relaxed mb-6"
                            >
                                {partDescriptions[partKey]}
                            </p>
                        </div>

                        <div class="space-y-4">
                            {#if wearPartId}
                                <div class="flex items-center gap-3 border-t border-app-border/50 pt-4">
                                    <div class="flex-1">
                                        <div class="flex justify-between items-center mb-1.5">
                                            <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-[0.1em]">{t('car_condition')}</span>
                                            <span class="text-xs font-black tabular-nums {tierTextColors[wearTier]}">{wearCondition}%</span>
                                        </div>
                                        <div class="h-1.5 rounded-full bg-app-text/10 overflow-hidden">
                                            <div
                                                class="h-full rounded-full transition-all {tierBarColors[wearTier]}"
                                                style="width: {wearCondition}%"
                                            ></div>
                                        </div>
                                    </div>
                                    <button
                                        class="shrink-0 px-3 py-1.5 rounded-lg text-xs font-bold uppercase tracking-wider transition-all
                                            {wearCondition < 100
                                                ? 'bg-app-primary text-app-primary-foreground hover:brightness-110 active:scale-95'
                                                : 'bg-app-surface border border-app-border text-app-text/30 cursor-not-allowed'}"
                                        disabled={wearCondition >= 100}
                                        onclick={() => { repairPart = partsStore.getPart(wearPartId); showRepairModal = true; }}
                                    >
                                        {t('repair')}
                                    </button>
                                </div>
                            {/if}
                            <div
                                class="flex justify-between items-end {wearPartId ? '' : 'border-t border-app-border/50 pt-4'}"
                            >
                                <div class="flex flex-col">
                                    <span
                                        class="text-[9px] font-bold text-app-text/30 uppercase tracking-[0.1em]"
                                        >Next Upgrade</span
                                    >
                                    <span
                                        class="text-base font-black {canAfford
                                            ? 'text-app-text'
                                            : 'text-red-400'}"
                                    >
                                        {level >= 20
                                            ? "MAX REACHED"
                                            : `$${(cost / 1000).toFixed(0)}k`}
                                    </span>
                                </div>
                                <div class="text-right">
                                    <span
                                        class="text-[9px] font-bold text-app-text/30 uppercase tracking-[0.1em]"
                                        >Progress</span
                                    >
                                    <span
                                        class="text-base font-black text-app-text/20"
                                        >LVL {level + 1}</span
                                    >
                                </div>
                            </div>

                            {#if isLocked}
                                <div
                                    class="bg-red-500/10 border border-red-500/20 rounded-xl p-4 flex items-center gap-3"
                                >
                                    <Lock size={16} class="text-red-400" />
                                    <p
                                        class="text-[10px] font-bold text-red-400 uppercase tracking-widest leading-relaxed"
                                    >
                                        Parc Fermé: Engineering Locked until
                                        after the race.
                                    </p>
                                </div>
                            {:else}
                                <button
                                    class="w-full py-3.5 rounded-xl bg-app-primary text-app-primary-foreground font-black uppercase tracking-[0.15em] text-xs hover:scale-[1.02] active:scale-95 transition-all disabled:bg-app-border disabled:text-app-text/20 disabled:scale-100"
                                    disabled={level >= 20 ||
                                        !canAfford ||
                                        limitReached}
                                    onclick={() => handleUpgrade(partKey)}
                                >
                                    {#if level >= 20}
                                        Maximum Level
                                    {:else if !canAfford}
                                        Insufficient Funds
                                    {:else if limitReached}
                                        Weekly Limit Reached
                                    {:else}
                                        Authorize Development
                                    {/if}
                                </button>
                            {/if}
                        </div>
                    </div>
                {/each}
            </div>
        </div>
    </div>
</div>

{#if partsStore.allParts.length > 0}
    <div class="mt-8 p-4 md:p-8 max-w-[1400px] mx-auto">
        <!-- Parts condition section header -->
        <div class="flex items-center justify-between mb-4">
            <div class="flex items-center gap-3">
                <h3 class="text-[10px] font-black uppercase tracking-[0.25em] text-app-text/50">
                    {t('garage_car_condition_label')}
                </h3>
                <!-- Car Condition summary badge -->
                <span class="text-xs font-black tabular-nums
                    {carConditionTier === 'green' ? 'text-green-400' : carConditionTier === 'yellow' ? 'text-yellow-400' : carConditionTier === 'orange' ? 'text-orange-400' : 'text-red-400'}">
                    {carConditionPct}%
                </span>
            </div>
            <!-- Repair budget widget -->
            {#if teamStore.value.team}
                {@const remaining = partsWearService.getRemainingRepairBudget(teamStore.value.team)}
                <span class="text-[9px] font-bold uppercase tracking-widest text-app-text/40">
                    {t('repair_budget_remaining')}:
                    <span class="font-black {remaining > 0 ? 'text-app-text/70' : 'text-red-400'}">
                        ${remaining.toLocaleString()}
                    </span>
                </span>
            {/if}
        </div>

        <!-- Final round badge -->
        {#if isLastRound}
            <div class="mb-3 flex items-center gap-2 px-3 py-2 rounded-lg bg-amber-500/10 border border-amber-500/20">
                <span class="text-[9px] font-black uppercase tracking-widest text-amber-400">
                    {t('repair_final_round_badge')}
                </span>
            </div>
        {/if}

        <!-- Repair lock warning -->
        {#if isRepairLocked}
            <div class="mb-3 flex items-center gap-2 px-3 py-2 rounded-lg bg-red-500/10 border border-red-500/20">
                <Lock size={12} class="text-red-400 shrink-0" />
                <span class="text-[9px] font-black uppercase tracking-widest text-red-400">
                    {t('repair_locked_parc_ferme')}
                </span>
            </div>
        {/if}

        <div class="space-y-2">
            {#each partsStore.allParts as part (part.partType)}
                <PartRow
                    {part}
                    {isRepairLocked}
                    onRepair={() => { repairPart = part; showRepairModal = true; }}
                />
            {/each}
        </div>
    </div>
{/if}

{#if showRepairModal && teamStore.value.team && repairPart}
    <RepairModal
        teamId={teamStore.value.team.id}
        part={repairPart}
        carIndex={selectedCar}
        {isRepairLocked}
        {isLastRound}
        onClose={() => { showRepairModal = false; repairPart = null; }}
    />
{/if}

<style>
    .font-heading {
        font-family: "Outfit", sans-serif;
    }
</style>
