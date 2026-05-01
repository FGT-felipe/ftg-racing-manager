<script lang="ts">
    import { browser } from '$app/environment';

    let { targetEl }: { targetEl: Element | null } = $props();

    let spotlightStyle = $state('');

    function recalc() {
        if (!targetEl) {
            spotlightStyle = '';
            return;
        }
        const rect = targetEl.getBoundingClientRect();
        const pad = 8;
        spotlightStyle = [
            `top: ${rect.top - pad}px`,
            `left: ${rect.left - pad}px`,
            `width: ${rect.width + pad * 2}px`,
            `height: ${rect.height + pad * 2}px`,
        ].join('; ');
    }

    $effect(() => {
        if (!browser) return;
        recalc();

        const onResize = () => recalc();
        window.addEventListener('resize', onResize);
        return () => window.removeEventListener('resize', onResize);
    });

    // Recalculate whenever targetEl changes
    $effect(() => {
        targetEl;
        if (browser) recalc();
    });
</script>

<!-- Full-screen dim layer — pointer-events none so scroll still works -->
<div
    class="fixed inset-0 z-[9997] pointer-events-none"
    style="background: transparent;"
></div>

{#if targetEl && spotlightStyle}
    <!-- Spotlight cutout using box-shadow trick -->
    <div
        class="fixed rounded-lg pointer-events-none z-[9998]"
        style="{spotlightStyle}; box-shadow: 0 0 0 9999px rgba(0,0,0,0.6);"
    ></div>
{:else}
    <!-- Full backdrop when no target -->
    <div class="fixed inset-0 bg-black/60 z-[9998] pointer-events-none"></div>
{/if}
