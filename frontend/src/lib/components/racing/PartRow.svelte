<script lang="ts">
    import type { Part } from '$lib/types';
    import { partsStore } from '$lib/stores/parts.svelte';
    import { partsWearService } from '$lib/services/parts_wear_service.svelte';
    import { teamStore } from '$lib/stores/team.svelte';
    import { PARTS_ENGINE_REPAIR_COST_FLAT } from '$lib/constants/app_constants';
    import { t } from '$lib/utils/i18n';

    let {
        part,
        onRepair,
        isRepairLocked = false,
    }: {
        part: Part;
        onRepair: () => void;
        isRepairLocked?: boolean;
    } = $props();

    const tier = $derived(partsStore.getTier(part.partType));
    const repairTarget = $derived(partsWearService.repairTarget(part));
    const remainingBudget = $derived(
        teamStore.value.team ? partsWearService.getRemainingRepairBudget(teamStore.value.team) : 0
    );

    const tierConfig = $derived.by(() => {
        switch (tier) {
            case 'green':  return { symbol: '●', colorClass: 'text-green-400',  label: t('condition_green') };
            case 'yellow': return { symbol: '▲', colorClass: 'text-yellow-400', label: t('condition_yellow') };
            case 'orange': return { symbol: '◆', colorClass: 'text-orange-400', label: t('condition_orange') };
            case 'red':    return { symbol: '✕', colorClass: 'text-red-400',    label: t('condition_red') };
        }
    });

    const cooldownLeft = $derived(part.repairCooldownRoundsLeft ?? 0);
    const inCooldown = $derived(cooldownLeft > 0);
    const canRepair = $derived(part.condition < repairTarget);
    const budgetSufficient = $derived(remainingBudget >= PARTS_ENGINE_REPAIR_COST_FLAT);
    const repairDisabled = $derived(!canRepair || !budgetSufficient || isRepairLocked || inCooldown);
</script>

<div class="flex items-center justify-between py-2 px-3 rounded-lg bg-app-surface/50 border border-app-border">
    <!-- Part name + tier badge -->
    <div class="flex items-center gap-2 min-w-0">
        <span class="text-lg {tierConfig.colorClass}" title={tierConfig.label} aria-label={tierConfig.label}>
            {tierConfig.symbol}
        </span>
        <span class="text-xs font-bold uppercase tracking-widest text-app-text/80 truncate pr-2">
            {t(('part_' + part.partType) as any)}
        </span>
    </div>

    <!-- Condition % -->
    <span class="text-xs font-black tabular-nums {tierConfig.colorClass} shrink-0 mx-2">
        {part.condition}%
    </span>

    <!-- Cooldown badge -->
    {#if inCooldown}
        <span class="shrink-0 px-2 py-0.5 rounded-md text-[9px] font-bold uppercase tracking-wider bg-app-text/5 text-app-text/40 border border-app-border mx-1">
            {t('repair_cooldown_label', { rounds: cooldownLeft })}
        </span>
    {/if}

    <!-- Repair button -->
    <button
        class="shrink-0 px-3 py-1 rounded-lg text-xs font-bold uppercase tracking-wider transition-all
            {!repairDisabled
                ? 'bg-app-primary text-app-primary-foreground hover:brightness-110 active:scale-95'
                : 'bg-app-surface border border-app-border text-app-text/30 cursor-not-allowed'}"
        disabled={repairDisabled}
        title={isRepairLocked ? t('repair_locked_parc_ferme') : inCooldown ? t('repair_cooldown_label', { rounds: cooldownLeft }) : !canRepair ? '' : !budgetSufficient ? t('repair_budget_exceeded') : ''}
        onclick={() => !repairDisabled && onRepair()}
    >
        {t('repair')}
    </button>
</div>
