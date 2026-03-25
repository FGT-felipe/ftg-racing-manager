<script lang="ts">
    import { fly } from "svelte/transition";
    import { Sparkles, Zap, Wrench, TrendingUp, Palette } from "lucide-svelte";
    import { t } from "$lib/utils/i18n";
    import { CHANGELOG, LATEST_VERSION } from "$lib/constants/changelog";
    import type { ChangelogEntryType } from "$lib/constants/changelog";

    const CHUNK = 4;

    let visibleCount = $state(CHUNK);
    let sentinel = $state<HTMLDivElement | null>(null);

    $effect(() => {
        if (!sentinel) return;

        const observer = new IntersectionObserver(
            (entries) => {
                if (entries[0].isIntersecting && visibleCount < CHANGELOG.length) {
                    visibleCount = Math.min(visibleCount + CHUNK, CHANGELOG.length);
                }
            },
            { rootMargin: "200px" }
        );

        observer.observe(sentinel);
        return () => observer.disconnect();
    });

    let visibleReleases = $derived(CHANGELOG.slice(0, visibleCount));
    let hasMore = $derived(visibleCount < CHANGELOG.length);

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

    function getTypeBadgeClass(type: ChangelogEntryType): string {
        switch (type) {
            case "feature":     return "bg-blue-400/10 text-blue-400/80 border border-blue-400/20";
            case "fix":         return "bg-red-400/10 text-red-400/80 border border-red-400/20";
            case "improvement": return "bg-green-400/10 text-green-400/80 border border-green-400/20";
            case "ui":          return "bg-fuchsia-400/10 text-fuchsia-400/80 border border-fuchsia-400/20";
        }
    }
</script>

<svelte:head>
    <title>{t("whats_new")} — FTG Racing Manager</title>
</svelte:head>

<div class="h-screen flex flex-col bg-app-bg text-app-text font-poppins overflow-hidden">

    <!-- Header -->
    <div class="shrink-0 px-6 py-4 border-b border-app-border bg-app-surface flex items-center gap-3">
        <div class="p-2 rounded-xl bg-app-primary/10 border border-app-primary/20">
            <Sparkles size={16} class="text-app-primary" />
        </div>
        <h1 class="text-sm font-black uppercase tracking-widest text-app-text">
            {t("whats_new")}
        </h1>
        <span class="px-2 py-0.5 rounded-full bg-app-primary/20 border border-app-primary/30 text-[9px] font-black text-app-primary">
            {LATEST_VERSION}
        </span>
    </div>

    <!-- Scrollable content -->
    <div class="flex-1 overflow-y-auto custom-scrollbar px-4 py-6 md:px-8">
        <div class="max-w-2xl mx-auto flex flex-col gap-5">

            {#each visibleReleases as release, i (release.version)}
                <div
                    class="bg-app-surface border border-app-border rounded-2xl overflow-hidden"
                    in:fly={{ y: 8, duration: 250 }}
                >
                    <!-- Version header -->
                    <div class="px-5 py-3 border-b border-app-border bg-app-text/10 flex items-center gap-3">
                        <span class="text-[13px] font-black uppercase tracking-widest text-app-primary">
                            {release.version}
                        </span>
                        <div class="flex-1 h-px bg-app-border/40"></div>
                        <span class="text-[10px] text-app-text/30 font-mono">
                            {release.date}
                        </span>
                        {#if i === 0}
                            <span class="px-2 py-0.5 rounded bg-app-primary/10 border border-app-primary/20 text-[9px] font-black uppercase tracking-widest text-app-primary/70">
                                {t("changelog_latest")}
                            </span>
                        {/if}
                    </div>

                    <!-- Entries -->
                    <ul class="flex flex-col">
                        {#each release.entries as entry, j}
                            {@const Icon = getTypeIcon(entry.type)}
                            {@const typeLabel = getTypeLabel(entry.type)}
                            <li class="flex items-start gap-3 px-5 py-3 {j > 0 ? 'border-t border-app-border/10' : ''}">
                                <div
                                    class="shrink-0 mt-0.5 {getTypeIconClass(entry.type)}"
                                    title={typeLabel}
                                    aria-hidden="true"
                                >
                                    <Icon size={13} strokeWidth={2.5} />
                                </div>
                                <p class="flex-1 text-[12px] text-app-text/70 leading-snug">
                                    {t(entry.textKey)}
                                </p>
                                <span class="shrink-0 px-1.5 py-0.5 rounded text-[9px] font-bold uppercase tracking-wider {getTypeBadgeClass(entry.type)}">
                                    {typeLabel}
                                </span>
                            </li>
                        {/each}
                    </ul>
                </div>
            {/each}

            <!-- Sentinel para lazy load -->
            {#if hasMore}
                <div bind:this={sentinel} class="py-4 flex justify-center">
                    <div class="w-4 h-4 border-2 border-app-primary/30 border-t-app-primary rounded-full animate-spin"></div>
                </div>
            {/if}

        </div>
    </div>

</div>
