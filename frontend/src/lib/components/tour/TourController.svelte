<script lang="ts">
    import { browser } from '$app/environment';
    import { page } from '$app/stores';
    import { goto } from '$app/navigation';
    import { tick } from 'svelte';
    import { tourStore } from '$lib/stores/tour.svelte';
    import { managerStore } from '$lib/stores/manager.svelte';
    import TourOverlay from './TourOverlay.svelte';
    import TourTooltip from './TourTooltip.svelte';

    let targetEl = $state<Element | null>(null);
    let targetRect = $state<DOMRect | null>(null);

    // Track previous isActive state to detect skip vs complete
    let prevIsActive = false;
    let pendingAction: 'skip' | 'complete' | null = null;

    // Keep targetRect in sync when the scroll container moves the element
    $effect(() => {
        if (!browser) return;
        const onScroll = () => {
            if (targetEl) targetRect = targetEl.getBoundingClientRect();
        };
        document.addEventListener('scroll', onScroll, { capture: true });
        return () => document.removeEventListener('scroll', onScroll, { capture: true });
    });

    // Scroll the nearest overflow-y-auto ancestor so the element is near the top
    // of the visible area (with padding). Avoids browser scrollIntoView quirks
    // where block:'center' can overshoot inside a fixed-height overflow container.
    function scrollToVisible(el: Element) {
        let container: Element | null = el.parentElement;
        while (container && container !== document.documentElement) {
            const overflow = window.getComputedStyle(container).overflowY;
            if (overflow === 'auto' || overflow === 'scroll') break;
            container = container.parentElement;
        }

        if (!container || container === document.documentElement) {
            el.scrollIntoView({ behavior: 'instant', block: 'start' });
            return;
        }

        const containerRect = container.getBoundingClientRect();
        const elRect = el.getBoundingClientRect();
        // Position relative to current scrollTop, then offset so element sits
        // 80px from the top of the container (leaves room for the tooltip).
        const relativeTop = elRect.top - containerRect.top + container.scrollTop;
        container.scrollTop = Math.max(0, relativeTop - 80);
    }

    async function resolveTarget() {
        if (!browser) return;

        const step = tourStore.currentStep;
        if (!step) {
            targetEl = null;
            targetRect = null;
            return;
        }

        // Navigate to the step's route if needed
        if ($page.url.pathname !== step.route) {
            await goto(step.route);
            await tick();
        }

        // Find target element — pick first with non-zero dimensions
        const matches = document.querySelectorAll(step.targetSelector);
        let found: Element | null = null;
        for (const el of Array.from(matches)) {
            const rect = el.getBoundingClientRect();
            if (rect.width > 0) {
                found = el;
                break;
            }
        }

        if (!found) {
            // Target missing — skip this step silently
            tourStore.next();
            return;
        }

        scrollToVisible(found);
        targetEl = found;
        targetRect = found.getBoundingClientRect();
    }

    $effect(() => {
        if (!browser) return;

        const isActive = tourStore.isActive;
        const stepIndex = tourStore.currentStepIndex;

        if (isActive) {
            prevIsActive = true;
            resolveTarget();
        } else if (prevIsActive && !isActive) {
            // Tour just ended — persist based on pending action
            prevIsActive = false;
            if (pendingAction === 'complete') {
                managerStore.persistTourComplete().catch((e: unknown) =>
                    console.error('[TourController:persistComplete] Failed', e)
                );
            } else {
                managerStore.persistTourDismiss().catch((e: unknown) =>
                    console.error('[TourController:persistDismiss] Failed', e)
                );
            }
            pendingAction = null;
            targetEl = null;
            targetRect = null;
        }
    });

    function handleNext() {
        if (tourStore.isLastStep) {
            pendingAction = 'complete';
        }
        tourStore.next();
    }

    function handleSkip() {
        pendingAction = 'skip';
        tourStore.skip();
    }

    function handlePrev() {
        tourStore.prev();
    }
</script>

{#if tourStore.isActive && tourStore.currentStep}
    <TourOverlay {targetEl} />
    <TourTooltip
        step={tourStore.currentStep}
        stepIndex={tourStore.currentStepIndex}
        totalSteps={tourStore.steps.length}
        {targetRect}
        isFirstStep={tourStore.isFirstStep}
        isLastStep={tourStore.isLastStep}
        onNext={handleNext}
        onPrev={handlePrev}
        onSkip={handleSkip}
    />
{/if}
