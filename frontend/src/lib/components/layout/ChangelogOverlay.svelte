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

    function getTypeBadgeClass(type: ChangelogEntryType): string {
        switch (type) {
            case "feature":     return "bg-blue-500/15 text-blue-400 border border-blue-500/20";
            case "fix":         return "bg-red-500/15 text-red-400 border border-red-500/20";
            case "improvement": return "bg-green-500/15 text-green-400 border border-green-500/20";
            case "ui":          return "bg-fuchsia-500/15 text-fuchsia-400 border border-fuchsia-500/20";
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

        <!-- Content -->
        <div class="flex-1 overflow-y-auto custom-scrollbar">
            {#each CHANGELOG as release, i}
                <div class="p-4 {i < CHANGELOG.length - 1 ? 'border-b border-app-border/50' : ''}">
                    <!-- Version header -->
                    <div class="flex items-center gap-3 mb-3">
                        <span class="text-[11px] font-black uppercase tracking-widest text-app-primary">
                            {release.version}
                        </span>
                        <div class="flex-1 h-px bg-app-border/50"></div>
                        <span class="text-[9px] text-app-text/30 font-mono">
                            {release.date}
                        </span>
                        {#if i === 0}
                            <span class="px-1.5 py-0.5 rounded bg-app-primary/10 text-[8px] font-black uppercase tracking-widest text-app-primary/70">
                                {t("changelog_latest")}
                            </span>
                        {:else}
                            <span class="px-1.5 py-0.5 rounded bg-app-text/5 text-[8px] font-black uppercase tracking-widest text-app-text/30">
                                {t("changelog_previous")}
                            </span>
                        {/if}
                    </div>

                    <!-- Entries -->
                    <ul class="flex flex-col gap-2">
                        {#each release.entries as entry}
                            {@const Icon = getTypeIcon(entry.type)}
                            <li class="flex items-start gap-2.5">
                                <div class="shrink-0 mt-0.5 {getTypeIconClass(entry.type)}">
                                    <Icon size={13} strokeWidth={2.5} />
                                </div>
                                <div class="flex-1 min-w-0 flex items-start gap-2">
                                    <span class="shrink-0 px-1.5 py-0.5 rounded text-[8px] font-black uppercase tracking-wider {getTypeBadgeClass(entry.type)}">
                                        {getTypeLabel(entry.type)}
                                    </span>
                                    <p class="text-[11px] text-app-text/70 leading-snug">
                                        {t(entry.textKey)}
                                    </p>
                                </div>
                            </li>
                        {/each}
                    </ul>
                </div>
            {/each}
        </div>
    </div>
{/if}

<style>
    .custom-scrollbar::-webkit-scrollbar {
        width: 4px;
    }
    .custom-scrollbar::-webkit-scrollbar-track {
        background: rgba(255, 255, 255, 0.05);
    }
    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: rgba(var(--primary-color-rgb), 0.2);
        border-radius: 10px;
    }
</style>
