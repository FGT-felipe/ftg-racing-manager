<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { authStore } from "$lib/stores/auth.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { goto } from "$app/navigation";
    import { browser } from "$app/environment";
    import { Factory, Wallet } from "lucide-svelte";
    import RaceStatusHero from "$lib/components/dashboard/RaceStatusHero.svelte";
    import OfficeNews from "$lib/components/dashboard/OfficeNews.svelte";
    import StandingsCard from "$lib/components/dashboard/StandingsCard.svelte";

    let teamData = $derived(teamStore.value);
    let team = $derived(teamData.team);
    let user = $derived(authStore.user);

    // Helper for identifying race week status
    let weekStatusMode = $derived.by(() => {
        if (!team || !team.weekStatus) return "normal";
        const s = team.weekStatus.globalStatus || "practice";
        // Mapping from existing values to 'weekend' / 'normal'
        if (
            s === "practice" ||
            s === "qualifying" ||
            s === "raceStrategy" ||
            s === "race" ||
            s === "postRace"
        ) {
            return "weekend";
        }
        return "normal";
    });

    let statusText = $derived.by(() => {
        if (!team || !team.weekStatus) return "FACTORY OPERATIONS";
        const s = team.weekStatus.globalStatus;
        if (s === "practice") return "FREE PRACTICE";
        if (s === "qualifying") return "QUALIFYING";
        if (s === "raceStrategy") return "RACE PREPARATION";
        if (s === "race") return "RACE LIVE";
        if (s === "postRace") return "POST RACE";
        return "FACTORY OPERATIONS";
    });
</script>

<svelte:head>
    <title>Dashboard | FTG Racing Manager</title>
</svelte:head>

<div
    class="flex flex-col gap-6 p-6 lg:p-8 w-full max-w-[1200px] mx-auto animate-fade-in text-app-text"
>
    <!-- Loading state -->
    {#if teamData.loading || authStore.loading}
        <div class="flex items-center justify-center h-40">
            <div
                class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"
            ></div>
        </div>
    {:else if team}
        <!-- Grid Layout for Dashboard Main View -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 w-full items-start">
            <!-- Left/Center Col: Main Ops -->
            <div class="lg:col-span-2 flex flex-col gap-8">
                <RaceStatusHero />

                <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                    <OfficeNews />

                    <!-- Quick Tasks (Checklist) -->
                    <section class="flex flex-col gap-6">
                        <h3
                            class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2"
                        >
                            Priority Tasks
                        </h3>
                        <div
                            class="bg-app-surface border border-white/5 rounded-2xl p-8 flex flex-col gap-5"
                        >
                            <!-- Item 1: Practice -->
                            <div class="flex items-center gap-4">
                                <div
                                    class="w-5 h-5 rounded-full border flex items-center justify-center shrink-0 transition-all {team
                                        ?.weekStatus?.practiceCompleted
                                        ? 'bg-app-primary/10 border-app-primary text-app-primary shadow-[0_0_10px_rgba(197,160,89,0.2)]'
                                        : 'border-white/10 bg-black/20 text-transparent'}"
                                >
                                    <span class="text-[10px] font-black">✓</span
                                    >
                                </div>
                                <span
                                    class="text-[11px] font-bold tracking-[0.15em] uppercase transition-colors {team
                                        ?.weekStatus?.practiceCompleted
                                        ? 'text-app-text'
                                        : 'text-app-text/30'}"
                                >
                                    Practice Program
                                </span>
                            </div>

                            <!-- Item 2: Qualifying -->
                            <div class="flex items-center gap-4">
                                <div
                                    class="w-5 h-5 rounded-full border flex items-center justify-center shrink-0 transition-all {team
                                        ?.weekStatus?.qualifyingCompleted
                                        ? 'bg-app-primary/10 border-app-primary text-app-primary shadow-[0_0_10px_rgba(197,160,89,0.2)]'
                                        : 'border-white/10 bg-black/20 text-transparent'}"
                                >
                                    <span class="text-[10px] font-black">✓</span
                                    >
                                </div>
                                <span
                                    class="text-[11px] font-bold tracking-[0.15em] uppercase transition-colors {team
                                        ?.weekStatus?.qualifyingCompleted
                                        ? 'text-app-text'
                                        : 'text-app-text/30'}"
                                >
                                    Qualifying Setup
                                </span>
                            </div>

                            <!-- Item 3: Race Strategy -->
                            <div class="flex items-center gap-4">
                                <div
                                    class="w-5 h-5 rounded-full border flex items-center justify-center shrink-0 transition-all {team
                                        ?.weekStatus?.strategySet
                                        ? 'bg-app-primary/10 border-app-primary text-app-primary shadow-[0_0_10px_rgba(197,160,89,0.2)]'
                                        : 'border-white/10 bg-black/20 text-transparent'}"
                                >
                                    <span class="text-[10px] font-black">✓</span
                                    >
                                </div>
                                <span
                                    class="text-[11px] font-bold tracking-[0.15em] uppercase transition-colors {team
                                        ?.weekStatus?.strategySet
                                        ? 'text-app-text'
                                        : 'text-app-text/30'}"
                                >
                                    Race Strategy
                                </span>
                            </div>
                        </div>
                    </section>
                </div>
            </div>

            <!-- Right Col: Financials & Status -->
            <div class="flex flex-col gap-8 w-full">
                <section class="flex flex-col gap-6">
                    <h3
                        class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2"
                    >
                        Financial Overview
                    </h3>
                    <div
                        class="bg-app-surface border border-white/5 rounded-2xl p-8 flex flex-col gap-6"
                    >
                        <div class="flex items-center justify-between">
                            <div class="flex flex-col gap-1">
                                <span
                                    class="text-[9px] font-black text-white/30 uppercase tracking-widest"
                                    >Available Budget</span
                                >
                                <span class="text-2xl font-black text-white">
                                    ${((team?.budget || 0) / 1000000).toFixed(
                                        2,
                                    )}M
                                </span>
                            </div>
                            <div
                                class="p-3 rounded-xl bg-app-primary/10 text-app-primary"
                            >
                                <Wallet size={20} />
                            </div>
                        </div>

                        <div
                            class="flex flex-col gap-4 border-t border-white/5 pt-6"
                        >
                            <div
                                class="flex items-center justify-between text-[10px] font-bold uppercase tracking-wider"
                            >
                                <span class="text-white/40"
                                    >Active Sponsors</span
                                >
                                <span class="text-app-primary"
                                    >{Object.keys(team?.sponsors || {}).length} /
                                    5</span
                                >
                            </div>
                            <div
                                class="w-full bg-white/5 h-1.5 rounded-full overflow-hidden"
                            >
                                <div
                                    class="bg-app-primary h-full rounded-full transition-all duration-500"
                                    style="width: {(Object.keys(
                                        team?.sponsors || {},
                                    ).length /
                                        5) *
                                        100}%"
                                ></div>
                            </div>
                        </div>

                        <a
                            href="/management"
                            class="text-center py-3 rounded-lg border border-white/5 text-[10px] font-black uppercase tracking-widest text-white/40 hover:bg-white/5 hover:text-white transition-all mt-2"
                        >
                            Manage Finances
                        </a>
                    </div>
                </section>

                <StandingsCard />
            </div>
        </div>
    {/if}
</div>
