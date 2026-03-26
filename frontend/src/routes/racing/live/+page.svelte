<script lang="ts">
    import { fade, fly } from "svelte/transition";
    import { 
        Zap, 
        Trophy, 
        Activity, 
        History, 
        ChevronRight, 
        Flag,
        LayoutDashboard
    } from "lucide-svelte";
    import QualifyingPanel from "$lib/components/racing/QualifyingPanel.svelte";
    import RaceLivePanel from "$lib/components/racing/RaceLivePanel.svelte";
    import ResultsPanel from "$lib/components/racing/ResultsPanel.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { t } from "$lib/utils/i18n";
    import { circuitService } from "$lib/services/circuit_service.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";

    let activeTab = $state<"qualy" | "race" | "results">("qualy");

    const tabs = [
        { id: "qualy" as const, label: t('tab_qualy_live'), icon: Trophy, color: "text-app-primary" },
        { id: "race" as const, label: t('tab_live_race'), icon: Flag, color: "text-red-500" },
        { id: "results" as const, label: t('tab_last_results'), icon: History, color: "text-blue-400" }
    ];

    let nextEvent = $derived(seasonStore.nextEvent);
</script>

<svelte:head>
    <title>Live Race Center | FTG Racing Manager</title>
</svelte:head>

<div class="p-6 md:p-10 w-full max-w-[1400px] mx-auto flex flex-col gap-10 pb-32">
    <!-- Header Section -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
        <div class="flex items-center gap-5">
            <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-red-600 to-red-900 flex items-center justify-center text-white shadow-xl shadow-red-500/20 border border-white/10">
                <Activity size={32} />
            </div>
            <div>
                <h1 class="text-3xl lg:text-4xl font-heading font-black tracking-tighter uppercase italic text-app-text leading-none">
                    {t('live_center_title')}
                </h1>
                <div class="flex items-center gap-2 mt-2">
                    <span class="text-[10px] font-black uppercase tracking-[0.3em] text-app-text/40">{t('live_telemetry_label')}</span>
                    <div class="w-2 h-2 rounded-full bg-red-600 animate-pulse"></div>
                </div>
            </div>
        </div>

        {#if nextEvent}
            <div class="flex items-center gap-4 px-6 py-4 bg-app-surface border border-app-border rounded-2xl shadow-lg">
                <CountryFlag countryCode={circuitService.getCircuitProfile(nextEvent.circuitId || '').countryCode} size="lg" />
               <div class="flex flex-col">
                   <span class="text-[10px] font-black uppercase tracking-widest text-app-text/40 leading-none mb-1">{t('current_venue_label')}</span>
                   <span class="text-sm font-black uppercase italic text-app-text">{nextEvent.trackName}</span>
               </div>
            </div>
        {/if}
    </div>

    <!-- Navigation Tabs -->
    <div class="flex flex-wrap gap-3">
        {#each tabs as tab}
            <button
                onclick={() => activeTab = tab.id}
                class="flex items-center gap-3 px-6 py-4 rounded-2xl border transition-all duration-300 group
                {activeTab === tab.id 
                    ? 'bg-app-surface border-app-primary shadow-[0_0_20px_rgba(197,160,89,0.1)]' 
                    : 'bg-app-surface/40 border-app-border hover:border-app-text/20 hover:bg-app-surface/60 opacity-60 hover:opacity-100'}"
            >
                <div class="{activeTab === tab.id ? tab.color : 'text-app-text/40'} transition-colors group-hover:scale-110 duration-300">
                    <tab.icon size={20} />
                </div>
                <span class="text-xs font-black uppercase tracking-widest {activeTab === tab.id ? 'text-app-text' : 'text-app-text/40'}">
                    {tab.label}
                </span>
                {#if activeTab === tab.id}
                    <div in:fade class="w-1.5 h-1.5 rounded-full {tab.color.replace('text', 'bg')}"></div>
                {/if}
            </button>
        {/each}
    </div>

    <!-- Main Content Area -->
    <div class="relative bg-app-surface/50 border border-app-border rounded-3xl p-6 lg:p-10 shadow-2xl overflow-hidden min-h-[600px]">
        <!-- Watermark Background -->
        <div class="absolute -bottom-20 -right-20 opacity-[0.02] text-app-text pointer-events-none transition-all duration-700"
             style="transform: scale({activeTab === 'qualy' ? 1 : 1.2}) rotate({activeTab === 'race' ? '-10deg' : '0deg'})">
            {#if activeTab === 'qualy'}
                <Trophy size={400} />
            {:else if activeTab === 'race'}
                <Flag size={400} />
            {:else}
                <History size={400} />
            {/if}
        </div>

        <div class="relative z-10">
            {#key activeTab}
                <div in:fly={{ y: 20, duration: 500 }} out:fade={{ duration: 200 }}>
                    {#if activeTab === "qualy"}
                        <div class="space-y-8">
                            <div class="flex items-center gap-3 border-b border-app-border pb-6">
                                <Trophy class="text-app-primary" size={24} />
                                <h2 class="text-xl font-heading font-black uppercase italic">{t('qualifying_session_title')}</h2>
                            </div>
                            <QualifyingPanel />
                        </div>
                    {:else if activeTab === "race"}
                        <div class="space-y-8">
                            <div class="flex items-center gap-3 border-b border-app-border pb-6">
                                <Flag class="text-red-500" size={24} />
                                <h2 class="text-xl font-heading font-black uppercase italic">{t('live_grand_prix_title')}</h2>
                            </div>
                            <RaceLivePanel />
                        </div>
                    {:else if activeTab === "results"}
                        <div class="space-y-8">
                            <div class="flex items-center gap-3 border-b border-app-border pb-6">
                                <History class="text-blue-400" size={24} />
                                <h2 class="text-xl font-heading font-black uppercase italic">{t('last_weekend_archives_title')}</h2>
                            </div>
                            <ResultsPanel />
                        </div>
                    {/if}
                </div>
            {/key}
        </div>
    </div>
</div>

<style>
    :global(.font-heading) {
        font-family: "Outfit", sans-serif;
    }
</style>
