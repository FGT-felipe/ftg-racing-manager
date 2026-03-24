<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { authStore } from "$lib/stores/auth.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
    import { goto } from "$app/navigation";
    import { browser } from "$app/environment";
    import { Factory, Wallet } from "lucide-svelte";
    import { t } from "$lib/utils/i18n";
    import RaceStatusHero from "$lib/components/dashboard/RaceStatusHero.svelte";
    import OfficeNews from "$lib/components/dashboard/OfficeNews.svelte";
    import StandingsCard from "$lib/components/dashboard/StandingsCard.svelte";
    import PreparationChecklist from "$lib/components/dashboard/PreparationChecklist.svelte";

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
    class="flex flex-col gap-10 p-6 lg:p-8 w-full max-w-[1400px] mx-auto animate-fade-in text-app-text"
>
    <!-- Loading state -->
    {#if teamData.loading || authStore.loading}
        <div class="flex items-center justify-center h-40">
            <div
                class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"
            ></div>
        </div>
    {:else if team}
        {@const nameParts = team.name.split(" ")}
        <!-- Dashboard Header Section -->
        <header class="flex flex-col gap-2">
            <div class="flex items-center gap-3">
                <div class="flex items-center gap-2">
                    <span
                        class="text-[10px] font-black tracking-[0.3em] text-app-primary/40 uppercase font-heading"
                    >
                        Welcome {managerStore.profile ? `${managerStore.profile.firstName} ${managerStore.profile.lastName}` : (authStore.user?.displayName || "Manager")}
                    </span>
                    {#if managerStore.profile}
                        <CountryFlag countryCode={managerStore.profile.country || managerStore.profile.nationality} size="xs" />
                    {/if}
                </div>
            </div>
            <h1
                class="text-4xl lg:text-5xl font-heading font-black tracking-tighter uppercase italic text-app-text mt-1"
            >
                {#if nameParts.length > 1}
                    {nameParts[0]}
                    <span class="text-app-primary"
                        >{nameParts.slice(1).join(" ")}</span
                    >
                {:else}
                    <span class="text-app-primary">{team.name}</span>
                {/if}
            </h1>
        </header>

        <!-- Grid Layout for Dashboard Main View -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 w-full items-start">
            <!-- Left/Center Col: Main Ops -->
            <div class="lg:col-span-2 flex flex-col gap-8">
                <RaceStatusHero />

                <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                    <OfficeNews />

                    <!-- Priority Tasks (Dynamic Checklist) -->
                    <PreparationChecklist />
                </div>
            </div>

            <!-- Right Col: Financials & Status -->
            <div class="flex flex-col gap-8 w-full">
                <section class="flex flex-col gap-6">
                    <h3
                        class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2"
                    >
                        {t('financial_overview')}
                    </h3>
                    <div
                        class="bg-app-surface border border-app-border rounded-2xl p-8 flex flex-col gap-6"
                    >
                        <div class="flex items-center justify-between">
                            <div class="flex flex-col gap-1">
                                <span
                                    class="text-[9px] font-black text-app-text/30 uppercase tracking-widest"
                                    >Available Budget</span
                                >
                                <span class="text-2xl font-black text-app-text">
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
                            class="flex flex-col gap-4 border-t border-app-border pt-6"
                        >
                            <div
                                class="flex items-center justify-between text-[10px] font-bold uppercase tracking-wider"
                            >
                                <span class="text-app-text/40"
                                    >Active Sponsors</span
                                >
                                <span class="text-app-primary"
                                    >{Object.keys(team?.sponsors || {}).length} /
                                    5</span
                                >
                            </div>
                            <div
                                class="w-full bg-app-text/5 h-1.5 rounded-full overflow-hidden"
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
                            class="text-center py-3 rounded-lg border border-app-border text-[10px] font-black uppercase tracking-widest text-app-text/40 hover:bg-app-text/5 hover:text-app-text transition-all mt-2"
                        >
                            {t('manage_finances')}
                        </a>
                    </div>
                </section>

                <StandingsCard />
            </div>
        </div>
    {/if}
</div>
