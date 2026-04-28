<script lang="ts">
    import { fade } from 'svelte/transition';
    import { partsWearService } from '$lib/services/parts_wear_service.svelte';
    import { teamStore } from '$lib/stores/team.svelte';
    import { PARTS_ENGINE_REPAIR_COST_FLAT } from '$lib/constants/app_constants';
    import type { Part } from '$lib/types';
    import { t } from '$lib/utils/i18n';

    let {
        teamId,
        part,
        carIndex,
        onClose,
    }: {
        teamId: string;
        part: Part;
        carIndex: number;
        onClose: () => void;
    } = $props();

    let isLoading = $state(false);
    let errorMsg = $state<string | null>(null);

    const repairTarget = $derived(partsWearService.repairTarget(part));
    const budget = $derived(teamStore.value.team?.budget ?? 0);
    const remainingBudget = $derived(
        teamStore.value.team ? partsWearService.getRemainingRepairBudget(teamStore.value.team) : 0
    );
    const repairCost = PARTS_ENGINE_REPAIR_COST_FLAT;
    const budgetAfterRepair = $derived(budget - repairCost);
    const canAfford = $derived(budget >= repairCost && remainingBudget >= repairCost);

    async function handleConfirm() {
        if (isLoading || !canAfford) return;
        isLoading = true;
        errorMsg = null;
        try {
            await partsWearService.repairPart(teamId, carIndex, part.partType);
            onClose();
        } catch (e: unknown) {
            const msg = e instanceof Error ? e.message : String(e);
            if (msg === 'INSUFFICIENT_BUDGET') {
                errorMsg = t('repair_budget_insufficient');
            } else if (msg === 'REPAIR_BUDGET_EXCEEDED') {
                errorMsg = t('repair_budget_exceeded');
            } else {
                errorMsg = msg;
                console.error('[RepairModal:handleConfirm] repair failed:', e);
            }
        } finally {
            isLoading = false;
        }
    }
</script>

<!-- Overlay backdrop -->
<div
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm"
    transition:fade={{ duration: 200 }}
    role="dialog"
    aria-modal="true"
    aria-label={t(('part_' + part.partType) as any)}
>
    <!-- Modal card -->
    <div class="bg-app-surface border border-app-border rounded-2xl shadow-2xl w-full max-w-sm mx-4 p-6 space-y-5">
        <!-- Header -->
        <div class="flex items-center justify-between">
            <h2 class="text-sm font-black uppercase tracking-widest text-app-primary">
                {t(('part_' + part.partType) as any)}
            </h2>
            <button
                class="text-app-text/40 hover:text-app-text/80 transition-colors text-lg"
                onclick={onClose}
                aria-label={t('repair_cancel')}
            >
                ✕
            </button>
        </div>

        <!-- Info rows -->
        <div class="space-y-2 text-xs">
            <div class="flex justify-between items-center py-1 border-b border-app-border/40">
                <span class="text-app-text/60 uppercase tracking-wider">{t('car_condition')}</span>
                <span class="font-bold text-app-text">{part.condition}% → {repairTarget}%</span>
            </div>
            <div class="flex justify-between items-center py-1 border-b border-app-border/40">
                <span class="text-app-text/60 uppercase tracking-wider">{t('repair_cost')}</span>
                <span class="font-bold text-app-primary">
                    ${repairCost.toLocaleString()}
                </span>
            </div>
            <div class="flex justify-between items-center py-1 border-b border-app-border/40">
                <span class="text-app-text/60 uppercase tracking-wider">{t('budget_after_repair')}</span>
                <span class="font-bold {budgetAfterRepair >= 0 ? 'text-app-text' : 'text-red-400'}">
                    ${budgetAfterRepair.toLocaleString()}
                </span>
            </div>
            <div class="flex justify-between items-center py-1">
                <span class="text-app-text/60 uppercase tracking-wider">{t('repair_budget_remaining')}</span>
                <span class="font-bold {remainingBudget >= repairCost ? 'text-green-400' : 'text-red-400'}">
                    ${remainingBudget.toLocaleString()}
                </span>
            </div>
        </div>

        <!-- Error message -->
        {#if errorMsg}
            <p class="text-xs text-red-400 font-medium">{errorMsg}</p>
        {/if}

        <!-- Actions -->
        <div class="flex gap-3">
            <button
                class="flex-1 py-2 px-4 rounded-xl border border-app-border text-xs font-bold uppercase tracking-wider text-app-text/60 hover:text-app-text/90 transition-colors"
                onclick={onClose}
                disabled={isLoading}
            >
                {t('repair_cancel')}
            </button>
            <button
                class="flex-1 py-2 px-4 rounded-xl text-xs font-black uppercase tracking-wider transition-all
                    {canAfford && !isLoading
                        ? 'bg-app-primary text-app-primary-foreground hover:brightness-110 active:scale-95'
                        : 'bg-app-surface border border-app-border text-app-text/30 cursor-not-allowed'}"
                disabled={!canAfford || isLoading}
                onclick={handleConfirm}
            >
                {isLoading ? t('repair_in_progress') : t('repair_confirm')}
            </button>
        </div>
    </div>
</div>
