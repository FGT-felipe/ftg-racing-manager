<script lang="ts">
    import { fade } from 'svelte/transition';
    import { browser } from '$app/environment';
    import type { TourStep } from '$lib/stores/tour.svelte';
    import { t } from '$lib/utils/i18n';

    let {
        step,
        stepIndex,
        totalSteps,
        targetRect,
        onNext,
        onPrev,
        onSkip,
        isFirstStep,
        isLastStep,
    }: {
        step: TourStep;
        stepIndex: number;
        totalSteps: number;
        targetRect: DOMRect | null;
        onNext: () => void;
        onPrev: () => void;
        onSkip: () => void;
        isFirstStep: boolean;
        isLastStep: boolean;
    } = $props();

    let tooltipEl: HTMLDivElement | undefined = $state();
    let tooltipStyle = $state('position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);');

    function computePosition() {
        if (!browser || !tooltipEl || !targetRect) {
            tooltipStyle = 'position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);';
            return;
        }

        const tooltipRect = tooltipEl.getBoundingClientRect();
        const margin = 12;
        const { top: rTop, left: rLeft, right: rRight, bottom: rBottom, width: rW, height: rH } = targetRect;

        let top: number;
        let left: number;

        if (step.position === 'bottom') {
            top = rBottom + margin;
            left = rLeft + rW / 2 - tooltipRect.width / 2;
        } else if (step.position === 'top') {
            top = rTop - tooltipRect.height - margin;
            left = rLeft + rW / 2 - tooltipRect.width / 2;
        } else if (step.position === 'right') {
            top = rTop + rH / 2 - tooltipRect.height / 2;
            left = rRight + margin;
        } else {
            top = rTop + rH / 2 - tooltipRect.height / 2;
            left = rLeft - tooltipRect.width - margin;
        }

        // Clamp to viewport
        top = Math.max(8, Math.min(top, window.innerHeight - tooltipRect.height - 8));
        left = Math.max(8, Math.min(left, window.innerWidth - tooltipRect.width - 8));

        tooltipStyle = `position: fixed; top: ${top}px; left: ${left}px;`;
    }

    $effect(() => {
        // Recompute when target rect or step changes
        targetRect;
        step;
        if (browser) {
            // Wait one tick for tooltip to render and get its own dimensions
            setTimeout(computePosition, 0);
        }
    });

    const progressText = $derived(
        t('tour_progress')
            .replace('{current}', String(stepIndex + 1))
            .replace('{total}', String(totalSteps))
    );
</script>

<div
    bind:this={tooltipEl}
    style={tooltipStyle}
    class="z-[9999] w-[320px] max-w-[calc(100vw-16px)] bg-app-surface border border-app-primary/50 rounded-xl p-4 shadow-2xl"
    transition:fade={{ duration: 200 }}
>
    <!-- Progress -->
    <p class="text-xs text-app-text/50 font-medium mb-2 uppercase tracking-wider">
        {progressText}
    </p>

    <!-- Title -->
    <h3 class="text-app-primary font-bold text-base mb-1">
        {t(step.titleKey)}
    </h3>

    <!-- Description -->
    <p class="text-app-text/80 text-sm leading-relaxed mb-4">
        {t(step.descriptionKey)}
    </p>

    <!-- Buttons -->
    <div class="flex items-center justify-between gap-2">
        <button
            onclick={onSkip}
            class="text-xs text-app-text/50 hover:text-app-text transition-colors underline-offset-2 hover:underline"
        >
            {t('tour_nav_skip')}
        </button>

        <div class="flex items-center gap-2">
            {#if !isFirstStep}
                <button
                    onclick={onPrev}
                    class="px-3 py-1.5 text-xs font-semibold rounded-lg border border-app-primary/40 text-app-primary hover:bg-app-primary/10 transition-colors"
                >
                    {t('tour_nav_prev')}
                </button>
            {/if}

            <button
                onclick={onNext}
                class="px-4 py-1.5 text-xs font-bold rounded-lg bg-app-primary text-black hover:brightness-110 transition-all"
            >
                {isLastStep ? t('tour_nav_finish') : t('tour_nav_next')}
            </button>
        </div>
    </div>
</div>
