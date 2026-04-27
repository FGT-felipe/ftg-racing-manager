<script lang="ts">
    import { partsStore } from '$lib/stores/parts.svelte';
    import { t } from '$lib/utils/i18n';

    let {
        partType,
        onRepair,
    }: {
        partType: string;
        onRepair: () => void;
    } = $props();

    const condition = $derived(partsStore.getCondition(partType));
    const tier = $derived(partsStore.getTier(partType));

    // Tier badge config — shape + color ensures colorblind safety (AC#2)
    const tierConfig = $derived.by(() => {
        switch (tier) {
            case 'green':  return { symbol: '●', colorClass: 'text-green-400',  label: t('condition_green') };
            case 'yellow': return { symbol: '▲', colorClass: 'text-yellow-400', label: t('condition_yellow') };
            case 'orange': return { symbol: '◆', colorClass: 'text-orange-400', label: t('condition_orange') };
            case 'red':    return { symbol: '✕', colorClass: 'text-red-400',    label: t('condition_red') };
        }
    });

    const canRepair = $derived(condition < 100);
</script>

<div class="flex items-center justify-between py-2 px-3 rounded-lg bg-app-surface/50 border border-app-border">
    <!-- Part name + tier badge -->
    <div class="flex items-center gap-2 min-w-0">
        <span class="text-lg {tierConfig.colorClass}" title={tierConfig.label} aria-label={tierConfig.label}>
            {tierConfig.symbol}
        </span>
        <span class="text-xs font-bold uppercase tracking-widest text-app-text/80 truncate pr-2">
            {t(partType as any)}
        </span>
    </div>

    <!-- Condition % -->
    <span class="text-xs font-black tabular-nums {tierConfig.colorClass} shrink-0 mx-3">
        {condition}%
    </span>

    <!-- Repair button (AC#3) -->
    <button
        class="shrink-0 px-3 py-1 rounded-lg text-xs font-bold uppercase tracking-wider transition-all
            {canRepair
                ? 'bg-app-primary text-app-primary-foreground hover:brightness-110 active:scale-95'
                : 'bg-app-surface border border-app-border text-app-text/30 cursor-not-allowed'}"
        disabled={!canRepair}
        onclick={() => canRepair && onRepair()}
    >
        {t('repair')}
    </button>
</div>
