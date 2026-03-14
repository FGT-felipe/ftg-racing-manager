<script lang="ts">
    import { getFlagEmoji, getFlagUrl } from "$lib/utils/country";

    let { countryCode, size = "md", customClass = "" } = $props<{
        countryCode: string | null | undefined;
        size?: "xs" | "sm" | "md" | "lg" | "xl";
        customClass?: string;
    }>();

    const sizeClasses: Record<string, string> = {
        xs: "w-3",
        sm: "w-4",
        md: "w-6",
        lg: "w-10",
        xl: "w-16"
    };

    const emojiSizes: Record<string, string> = {
        xs: "text-[10px]",
        sm: "text-xs",
        md: "text-base",
        lg: "text-2xl",
        xl: "text-5xl"
    };

    let flagUrl = $derived(getFlagUrl(countryCode));
    let emoji = $derived(getFlagEmoji(countryCode));
</script>

{#if flagUrl}
    <img 
        src={flagUrl} 
        alt={countryCode || 'Flag'} 
        class="h-auto rounded-sm border border-white/10 shadow-sm {sizeClasses[size]} {customClass}"
    />
{:else}
    <span class="not-italic inline-flex items-center justify-center {emojiSizes[size]} {customClass}">
        {emoji}
    </span>
{/if}
