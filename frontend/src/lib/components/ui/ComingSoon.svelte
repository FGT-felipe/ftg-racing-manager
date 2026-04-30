<script lang="ts">
    import { Clock } from "lucide-svelte";
    import { t } from "$lib/utils/i18n";

    interface Props {
        description?: string;
    }

    let { description = "" }: Props = $props();
</script>

<div class="flex flex-col items-center justify-center py-10 px-4 text-center gap-4">
    <div class="flex items-center gap-2 px-3 py-1.5 bg-app-primary/10 border border-app-primary/20 rounded-full">
        <Clock size={11} class="text-app-primary" />
        <span class="text-[10px] font-black text-app-primary uppercase tracking-[0.2em]">{t('coming_soon')}</span>
    </div>
    {#if description}
        <p class="text-[12px] text-app-text/40 leading-relaxed max-w-[240px]">{description}</p>
    {/if}
</div>
