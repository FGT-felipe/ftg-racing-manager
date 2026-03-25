<script lang="ts">
    import { fade, fly } from "svelte/transition";
    import { Sparkles, X, Zap, Wrench, TrendingUp, Palette } from "lucide-svelte";
    import { t } from "$lib/utils/i18n";
    import { CHANGELOG, LATEST_VERSION } from "$lib/constants/changelog";
    import type { ChangelogEntryType } from "$lib/constants/changelog";

    let { isOpen = $bindable(false), onSeen }: { isOpen: boolean; onSeen?: () => void } = $props();

    $effect(() => {
        if (isOpen && onSeen) {
            onSeen();
        }
    });

    function getTypeIcon(type: ChangelogEntryType) {
        switch (type) {
            case "feature":     return Zap;
            case "fix":         return Wrench;
            case "improvement": return TrendingUp;
            case "ui":          return Palette;
        }
    }

    function getTypeLabel(type: ChangelogEntryType): string {
        switch (type) {
            case "feature":     return t("changelog_type_feature");
            case "fix":         return t("changelog_type_fix");
            case "improvement": return t("changelog_type_improvement");
            case "ui":          return t("changelog_type_ui");
        }
    }

    function getTypeIconClass(type: ChangelogEntryType): string {
        switch (type) {
            case "feature":     return "text-blue-400";
            case "fix":         return "text-red-400";
            case "improvement": return "text-green-400";
            case "ui":          return "text-fuchsia-400";
        }
    }
</script>

{#if isOpen}
    <!-- Backdrop -->
    <button
        onclick={() => (isOpen = false)}
        class="fixed inset-0 bg-app-text/40 z-40 md:hidden backdrop-blur-sm cursor-default"
        in:fade={{ duration: 200 }}
        aria-label="Close changelog"
    ></button>

    <div
        class="absolute top-[64px] right-2 md:right-8 w-[400px] max-h-[80vh] bg-app-surface border border-app-border rounded-2xl shadow-2xl z-50 flex flex-col overflow-hidden"
        in:fly={{ y: -10, duration: 200 }}
        out:fade={{ duration: 150 }}
    >
        <!-- Header -->
        <div class="p-4 border-b border-app-border flex items-center justify-between bg-app-text/20 shrink-0">
            <div class="flex items-center gap-2">
                <Sparkles size={16} class="text-app-primary" />
                <h3 class="text-xs font-black uppercase tracking-widest text-app-text">
                    {t("whats_new")}
                </h3>
                <span class="px-2 py-0.5 rounded-full bg-app-primary/20 border border-app-primary/30 text-[9px] font-black text-app-primary">
                    {LATEST_VERSION}
                </span>
            </div>
            <button
                onclick={() => (isOpen = false)}
                class="text-app-text/40 hover:text-app-text transition-colors"
                aria-label="Close"
            >
                <X size={16} />
            </button>
        </div>

        <!-- Content — latest version only -->
        <div class="p-4">
            <ul class="flex flex-col gap-2">
                {#each CHANGELOG[0].entries as entry}
                    {@const Icon = getTypeIcon(entry.type)}
                    {@const typeLabel = getTypeLabel(entry.type)}
                    <li class="flex items-start gap-2.5">
                        <div
                            class="shrink-0 mt-0.5 {getTypeIconClass(entry.type)}"
                            title={typeLabel}
                        >
                            <Icon size={13} strokeWidth={2.5} />
                        </div>
                        <p
                            class="text-[11px] text-app-text/70 leading-snug"
                            title={typeLabel}
                        >
                            {t(entry.textKey)}
                        </p>
                    </li>
                {/each}
            </ul>
        </div>

        <!-- Footer -->
        <div class="shrink-0 border-t border-app-border px-4 py-3 bg-app-text/10">
            <a
                href="/whats-new"
                target="_blank"
                rel="noopener noreferrer"
                class="flex items-center justify-center gap-1.5 text-[11px] font-bold text-app-primary/70 hover:text-app-primary transition-colors"
                aria-label={t("changelog_view_all")}
            >
                {t("changelog_view_all")}
                <svg xmlns="http://www.w3.org/2000/svg" width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                    <path d="M7 7h10v10"/><path d="M7 17 17 7"/>
                </svg>
            </a>
        </div>
    </div>
{/if}

