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
    import { formatMoney } from "$lib/utils/format";
    import { facilityStore } from "$lib/stores/facility.svelte";
    import { FacilityType } from "$lib/types";
    import { FACILITY_MAX_LEVEL } from "$lib/constants/economics";
    import {
        Wrench,
        Zap,
        Wind,
        Navigation,
        ShieldCheck,
        ArrowUpCircle,
        Lock,
        TrendingUp,
        Cpu,
    } from "lucide-svelte";
    import InstructionCard from "$lib/components/layout/InstructionCard.svelte";
    import CarSchematic from "$lib/components/dashboard/CarSchematic.svelte";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import DriverStars from "$lib/components/DriverStars.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
    import { formatDriverName } from "$lib/utils/driver";

    let selectedCar = $state(0);

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

    // Upgrade part cards (4 stats)
    const upgradeParts = ['aero', 'powertrain', 'chassis', 'reliability'] as const;

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
        powertrain: "Increases acceleration and top speed. Essential for long straights.",
        chassis: "Improves handling and tyre management. Vital for technical circuits.",
        reliability: "Reduces the risk of mechanical failures and performance degradation.",
    };

    async function handleUpgrade(partKey: string) {
        if (timeService.isSetupLocked) return;
        try {
            await carStore.upgradePart(selectedCar, partKey);
        } catch (e: any) {
            uiStore.alert(e.message, 'Error', 'danger');
        }
    }

    driverStore.init();

    const currentCarStats = $derived(
        carStore.carStats[selectedCar.toString()] || {
            aero: 1,
            powertrain: 1,
            chassis: 1,
            reliability: 1,
        },
    );
    const upgradeCount = $derived(teamStore.value.team?.weekStatus?.upgradesThisWeek || 0);
    const maxUpgrades = $derived(managerStore.profile?.role === "engineer" ? 2 : 1);
    const isLocked = $derived(timeService.isSetupLocked);
    const isRepairLocked = $derived(timeService.isRepairLocked);
    const isLastRound = $derived(!!(teamStore.value.team?.weekStatus?.['isLastRound'] as boolean | undefined));
    const carConditionPct = $derived(partsStore.carConditionPct);
    const carConditionTier = $derived(partsStore.carConditionTier);

    // Engine wear part (separate from upgrade stats)
    const engineCondition = $derived(partsStore.getCondition('engine'));
    const engineTier = $derived(partsStore.getTier('engine'));

    // Facility upgrade
    const garageFacility = $derived(facilityStore.facilities[FacilityType.garage]);
    const garageLevel = $derived(garageFacility?.level ?? 1);
    const garageIsMaxLevel = $derived(garageLevel >= FACILITY_MAX_LEVEL);
    const garageCanUpgrade = $derived(facilityStore.canUpgradeFacility(FacilityType.garage));
    const garageUpgradePrice = $derived(facilityStore.getUpgradePrice(FacilityType.garage, garageLevel));
    let garageUpgrading = $state(false);

    async function handleFacilityUpgrade() {
        if (garageUpgrading) return;
        garageUpgrading = true;
        try {
            await facilityStore.upgradeFacility(FacilityType.garage);
        } catch (e: unknown) {
            uiStore.alert((e as Error).message ?? "Upgrade failed", "Error", "danger");
        } finally {
            garageUpgrading = false;
        }
    }

    // PartRow parts: all except engine (engine is now a card)
    const rowParts = $derived(partsStore.allParts.filter(p => p.partType !== 'engine'));

    const DRIVING_STATS = ["braking", "cornering", "smoothness", "overtaking", "consistency", "adaptability"];

    function calcStars(driver: { stats?: Record<string, number>; potential?: number } | null) {
        if (!driver?.stats) return 1;
        let sum = 0, count = 0;
        for (const s of DRIVING_STATS) {
            if (driver.stats[s] !== undefined) { sum += driver.stats[s]; count++; }
        }
        if (count === 0) return 1;
        return Math.min(Math.max(Math.ceil((sum / count) / 4.0), 1), driver.potential ?? 5);
    }

    const activeDriver = $derived(selectedCar === 0 ? driverStore.carADriver : driverStore.carBDriver);
    const activeDriverStars = $derived(calcStars(activeDriver));
</script>

<svelte:head>
    <title>Engineering | FTG Racing Manager</title>
</svelte:head>

<div class="p-4 md:p-8 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text">

    <!-- Header -->
    <InstructionCard
        icon={Wrench}
        title="Engineering Department"
        description="Develop your car parts to gain a competitive edge. Upgrades are permanent for the season and prices increase exponentially (Fibonacci). Focus on areas that suit the upcoming circuit."
    >
        {#snippet extraContent()}
            <div class="flex flex-wrap items-center gap-6 mt-2">
                <div class="flex flex-col">
                    <span class="text-[10px] font-bold text-app-text/40 uppercase tracking-widest">Available Budget</span>
                    <span class="text-2xl font-black text-app-text">{teamStore.formattedBudget}</span>
                </div>
                <div class="h-10 w-px bg-app-border/50 hidden md:block"></div>
                <div class="flex flex-col">
                    <span class="text-[10px] font-bold text-app-text/40 uppercase tracking-widest">Weekly Limit</span>
                    <div class="flex items-center gap-1.5 mt-0.5">
                        <div class="flex gap-1">
                            {#each Array(maxUpgrades) as _, i}
                                <div class="w-2.5 h-2.5 rounded-full {i < upgradeCount ? 'bg-orange-500 shadow-[0_0_8px_rgba(249,115,22,0.5)]' : 'bg-app-text/10'}"></div>
                            {/each}
                        </div>
                        <span class="text-xs font-bold text-app-text/60 ml-1">{upgradeCount}/{maxUpgrades}</span>
                    </div>
                </div>
                {#if managerStore.profile?.role === "bureaucrat"}
                    <div class="px-3 py-1 bg-red-500/10 border border-red-500/20 rounded-full">
                        <span class="text-[10px] font-black text-red-400 uppercase">Bureaucrat: 2-week cooldown</span>
                    </div>
                {/if}
                {#if managerStore.profile?.role === "engineer"}
                    <div class="ml-auto px-3 py-1 bg-orange-500/10 border border-orange-500/20 rounded-full flex items-center gap-2">
                        <ArrowUpCircle size={12} class="text-orange-400" />
                        <span class="text-[10px] font-black text-orange-400 uppercase">Lead Engineer Bonus: +1 Upgrade Slot</span>
                    </div>
                {/if}
            </div>
        {/snippet}
    </InstructionCard>

    <!-- Engineering Facility bar -->
    <div class="mt-6 bg-app-surface border border-app-border rounded-2xl p-5 flex flex-wrap items-center justify-between gap-4">
        <div class="flex items-center gap-4">
            <div class="p-3 rounded-xl bg-blue-400/10 text-blue-400">
                <TrendingUp size={20} />
            </div>
            <div class="flex flex-col">
                <span class="text-[9px] font-black text-app-text/30 uppercase tracking-widest">{t('upgrade_facility')}</span>
                <span class="text-base font-black text-app-text">{t('engineering_facility_level', { level: garageLevel })}</span>
            </div>
            <div class="flex flex-col ml-4">
                <span class="text-[9px] font-black text-app-text/30 uppercase tracking-widest">{t('repair_ceiling_label')}</span>
                <span class="text-sm font-black text-blue-400">{partsWearService.getGarageRepairTarget(garageLevel)}%</span>
            </div>
            <div class="flex flex-col">
                <span class="text-[9px] font-black text-app-text/30 uppercase tracking-widest">{t('repair_budget_cap_label')}</span>
                <span class="text-sm font-black text-blue-400">{formatMoney(partsWearService.getRepairCap({ facilities: { garage: { level: garageLevel } } }))}/round</span>
            </div>
        </div>
        {#if garageIsMaxLevel}
            <div class="px-4 py-2 rounded-xl bg-app-primary/10 border border-app-primary/20">
                <span class="text-[9px] font-black text-app-primary uppercase tracking-widest">{t('max_level')}</span>
            </div>
        {:else if !garageCanUpgrade}
            <div class="px-4 py-2 rounded-xl bg-app-surface border border-app-border">
                <span class="text-[9px] font-black text-app-text/30 uppercase tracking-widest">{t('upgraded_this_season')}</span>
            </div>
        {:else}
            <button
                onclick={handleFacilityUpgrade}
                disabled={garageUpgrading}
                class="flex items-center gap-3 px-5 py-2.5 rounded-xl bg-blue-400/10 border border-blue-400/20 hover:bg-blue-400/20 hover:border-blue-400/40 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            >
                <ArrowUpCircle size={16} class="text-blue-400" />
                <div class="flex flex-col items-start">
                    <span class="text-[10px] font-black text-blue-400 uppercase tracking-widest">
                        {garageUpgrading ? "..." : t('upgrade_to_level', { level: garageLevel + 1 })}
                    </span>
                    <span class="text-[9px] text-blue-300/60">{formatMoney(garageUpgradePrice)}</span>
                </div>
            </button>
        {/if}
    </div>

    <!-- Row 1: Car selector + Status Analysis -->
    <div class="mt-8 grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Car selector -->
        <div class="flex flex-col gap-4">
            <div class="bg-app-surface border border-app-border rounded-2xl p-2 flex gap-1">
                <button
                    class="flex-1 py-3 rounded-xl font-black uppercase tracking-widest text-sm transition-all {selectedCar === 0 ? 'bg-app-primary text-app-primary-foreground' : 'text-app-text/40 hover:bg-app-text/5'}"
                    onclick={() => (selectedCar = 0)}>Car A</button
                >
                <button
                    class="flex-1 py-3 rounded-xl font-black uppercase tracking-widest text-sm transition-all {selectedCar === 1 ? 'bg-app-primary text-app-primary-foreground' : 'text-app-text/40 hover:bg-app-text/5'}"
                    onclick={() => (selectedCar = 1)}>Car B</button
                >
            </div>

            </div>

        <!-- Status Analysis: schematic + driver inline row -->
        <div class="lg:col-span-2 bg-app-surface border border-app-border rounded-2xl p-5 flex flex-col gap-4">
            <span class="text-[10px] font-bold text-app-text/40 uppercase tracking-[0.2em]">Status Analysis</span>
            <CarSchematic
                stats={currentCarStats}
                carLabel={selectedCar === 0 ? "Car A" : "Car B"}
                condition={carConditionPct}
                conditionTier={carConditionTier}
            />
            {#if activeDriver}
                <div class="flex items-center gap-3 border-t border-app-border/40 pt-3">
                    <div class="w-7 h-7 rounded-full bg-app-text/5 border border-app-border overflow-hidden flex-shrink-0">
                        <DriverAvatar id={activeDriver.id} gender={activeDriver.gender} class="w-full h-full" />
                    </div>
                    <div class="flex items-center gap-2 min-w-0">
                        <CountryFlag countryCode={activeDriver.countryCode} size="sm" />
                        <span class="text-xs font-black text-app-text uppercase truncate tracking-tight">{formatDriverName(activeDriver.name)}</span>
                    </div>
                    <div class="ml-auto flex-shrink-0">
                        <DriverStars currentStars={activeDriverStars} maxStars={activeDriver.potential} size={10} />
                    </div>
                </div>
            {:else}
                <div class="border-t border-app-border/40 pt-3 text-center text-app-text/20 text-[10px] font-bold uppercase">
                    No driver assigned
                </div>
            {/if}
        </div>
    </div>

    <!-- Row 2: 5 part cards -->
    {#if isLastRound}
        <div class="mt-6 flex items-center gap-2 px-3 py-2 rounded-lg bg-amber-500/10 border border-amber-500/20">
            <span class="text-[9px] font-black uppercase tracking-widest text-amber-400">{t('repair_final_round_badge')}</span>
        </div>
    {/if}
    {#if isRepairLocked}
        <div class="mt-3 flex items-center gap-2 px-3 py-2 rounded-lg bg-red-500/10 border border-red-500/20">
            <Lock size={12} class="text-red-400 shrink-0" />
            <span class="text-[9px] font-black uppercase tracking-widest text-red-400">{t('repair_locked_parc_ferme')}</span>
        </div>
    {/if}

    <div class="mt-6 grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-5 gap-4">

        <!-- 4 upgrade + wear cards -->
        {#each upgradeParts as partKey}
            {@const level = currentCarStats[partKey] || 1}
            {@const cost = carStore.getUpgradeCost(level)}
            {@const canAfford = (teamStore.value.team?.budget ?? 0) >= cost}
            {@const limitReached = upgradeCount >= maxUpgrades}
            {@const PartIcon = partIcons[partKey]}
            {@const wearPartId = partWearMap[partKey]}
            {@const wearCondition = wearPartId ? partsStore.getCondition(wearPartId) : 100}
            {@const wearTier = wearPartId ? partsStore.getTier(wearPartId) : 'green'}

            <div class="bg-app-surface border border-app-border rounded-2xl p-5 flex flex-col justify-between group transition-all hover:border-app-primary/30">
                <div>
                    <div class="flex items-center justify-between mb-3">
                        <div class="p-2.5 bg-app-text/5 rounded-xl {partColors[partKey]} group-hover:bg-app-primary/10 transition-colors">
                            <PartIcon size={20} />
                        </div>
                        <div class="text-right">
                            <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-widest block">Lvl</span>
                            <span class="text-xl font-black text-app-text italic">{level}</span>
                        </div>
                    </div>
                    <h4 class="text-sm font-heading font-black uppercase text-app-text tracking-tight mb-1">{partKey}</h4>
                    <p class="text-[11px] text-app-text/50 leading-relaxed mb-4">{partDescriptions[partKey]}</p>
                </div>

                <div class="space-y-3">
                    {#if wearPartId}
                        <div class="flex items-center gap-2 border-t border-app-border/50 pt-3">
                            <div class="flex-1">
                                <div class="flex justify-between items-center mb-1">
                                    <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-[0.1em]">{t('car_condition')}</span>
                                    <span class="text-xs font-black tabular-nums {tierTextColors[wearTier]}">{wearCondition}%</span>
                                </div>
                                <div class="h-1.5 rounded-full bg-app-text/10 overflow-hidden">
                                    <div class="h-full rounded-full transition-all {tierBarColors[wearTier]}" style="width: {wearCondition}%"></div>
                                </div>
                            </div>
                            <button
                                class="shrink-0 px-2.5 py-1.5 rounded-lg text-[10px] font-bold uppercase tracking-wider transition-all
                                    {wearCondition < 100
                                        ? 'bg-app-primary text-app-primary-foreground hover:brightness-110 active:scale-95'
                                        : 'bg-app-surface border border-app-border text-app-text/30 cursor-not-allowed'}"
                                disabled={wearCondition >= 100 || isRepairLocked}
                                onclick={() => { repairPart = partsStore.getPart(wearPartId); showRepairModal = true; }}
                            >
                                {t('repair')}
                            </button>
                        </div>
                    {/if}

                    <div class="flex justify-between items-end {wearPartId ? '' : 'border-t border-app-border/50 pt-3'}">
                        <div class="flex flex-col">
                            <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-[0.1em]">Next Upgrade</span>
                            <span class="text-sm font-black {canAfford ? 'text-app-text' : 'text-red-400'}">
                                {level >= 20 ? "MAX" : formatMoney(cost)}
                            </span>
                        </div>
                        <div class="text-right">
                            <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-[0.1em]">Progress</span>
                            <span class="text-sm font-black text-app-text/20">LVL {level + 1}</span>
                        </div>
                    </div>

                    {#if isLocked}
                        <div class="bg-red-500/10 border border-red-500/20 rounded-xl p-3 flex items-center gap-2">
                            <Lock size={14} class="text-red-400" />
                            <p class="text-[10px] font-bold text-red-400 uppercase tracking-widest">Parc Fermé — Locked</p>
                        </div>
                    {:else}
                        <button
                            class="w-full py-3 rounded-xl bg-app-primary text-app-primary-foreground font-black uppercase tracking-[0.15em] text-[10px] hover:scale-[1.02] active:scale-95 transition-all disabled:bg-app-border disabled:text-app-text/20 disabled:scale-100"
                            disabled={level >= 20 || !canAfford || limitReached}
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

        <!-- Engine card (wear only — no upgrade) -->
        <div class="bg-app-surface border border-app-border rounded-2xl p-5 flex flex-col justify-between group transition-all hover:border-orange-400/30">
            <div>
                <div class="flex items-center justify-between mb-3">
                    <div class="p-2.5 bg-orange-400/10 rounded-xl text-orange-400 group-hover:bg-orange-400/20 transition-colors">
                        <Cpu size={20} />
                    </div>
                    <span class="text-[9px] font-bold text-app-text/20 uppercase tracking-widest">Wear only</span>
                </div>
                <h4 class="text-sm font-heading font-black uppercase text-app-text tracking-tight mb-1">Engine</h4>
                <p class="text-[11px] text-app-text/50 leading-relaxed mb-4">Physical engine unit. Degrades each race and scales your powertrain performance. Cannot be upgraded — select a supplier each season.</p>
            </div>

            <div class="space-y-3">
                <div class="flex items-center gap-2 border-t border-app-border/50 pt-3">
                    <div class="flex-1">
                        <div class="flex justify-between items-center mb-1">
                            <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-[0.1em]">{t('car_condition')}</span>
                            <span class="text-xs font-black tabular-nums {tierTextColors[engineTier]}">{engineCondition}%</span>
                        </div>
                        <div class="h-1.5 rounded-full bg-app-text/10 overflow-hidden">
                            <div class="h-full rounded-full transition-all {tierBarColors[engineTier]}" style="width: {engineCondition}%"></div>
                        </div>
                    </div>
                    <button
                        class="shrink-0 px-2.5 py-1.5 rounded-lg text-[10px] font-bold uppercase tracking-wider transition-all
                            {engineCondition < 100 && !isRepairLocked
                                ? 'bg-app-primary text-app-primary-foreground hover:brightness-110 active:scale-95'
                                : 'bg-app-surface border border-app-border text-app-text/30 cursor-not-allowed'}"
                        disabled={engineCondition >= 100 || isRepairLocked}
                        onclick={() => { repairPart = partsStore.getPart('engine'); showRepairModal = true; }}
                    >
                        {t('repair')}
                    </button>
                </div>

                <!-- Supplier placeholder (issue #131) -->
                <div class="border-t border-app-border/50 pt-3">
                    <span class="text-[9px] font-bold text-app-text/20 uppercase tracking-widest">Supplier — Coming Soon</span>
                </div>
            </div>
        </div>
    </div>

    <!-- Secondary wear rows: gearbox, brakes, wings, suspension -->
    {#if rowParts.length > 0}
        <div class="mt-8">
            <div class="space-y-2">
                {#each rowParts as part (part.partType)}
                    <PartRow
                        {part}
                        {isRepairLocked}
                        onRepair={() => { repairPart = part; showRepairModal = true; }}
                    />
                {/each}
            </div>
        </div>
    {/if}
</div>

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
