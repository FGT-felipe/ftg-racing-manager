<script lang="ts">
    import { seasonStore } from '$lib/stores/season.svelte';
    import { universeStore } from '$lib/stores/universe.svelte';
    import { teamStore } from '$lib/stores/team.svelte';
    import { SEASON_PRIZE_TABLE, DRIVERS_CHAMPION_TEAM_BONUS } from '$lib/constants/season';
    import { t } from '$lib/utils/i18n';
    import { Trophy, X, Wallet } from 'lucide-svelte';
    import { fade, scale } from 'svelte/transition';

    let { onDismiss }: { onDismiss: () => void } = $props();

    let playerTeamId = $derived(teamStore.value.team?.id ?? '');
    let allTeams = $derived(universeStore.getAllTeamStandings(playerTeamId));
    let champion = $derived(universeStore.getDriversChampion(playerTeamId));
    let playerRow = $derived(allTeams.find(t => t.id === playerTeamId));
    let playerPrize = $derived(playerRow ? (SEASON_PRIZE_TABLE[playerRow.position - 1] ?? 0) : 0);
    let playerIsChampTeam = $derived(champion?.teamId === playerTeamId);
    let seasonYear = $derived(seasonStore.value.season?.year ?? new Date().getFullYear());
    let isLoading = $derived(universeStore.value.loading);

    function handleKeydown(e: KeyboardEvent) {
        if (e.key === 'Escape') onDismiss();
    }

    function formatMoney(amount: number): string {
        if (amount >= 1_000_000) return `$${(amount / 1_000_000).toFixed(1)}M`;
        if (amount >= 1_000) return `$${(amount / 1_000).toFixed(0)}K`;
        return `$${amount}`;
    }
</script>

<svelte:window onkeydown={handleKeydown} />

<!-- Backdrop -->
<div
    class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
    transition:fade={{ duration: 200 }}
>
    <!-- Modal card -->
    <div
        class="relative w-full max-w-2xl max-h-[90vh] overflow-y-auto bg-app-surface border border-app-border rounded-2xl shadow-2xl flex flex-col"
        transition:scale={{ duration: 200, start: 0.95 }}
    >
        <!-- Header -->
        <div class="flex items-center justify-between px-6 py-5 border-b border-app-border">
            <div class="flex items-center gap-3">
                <div class="p-2 rounded-xl bg-app-primary/10 text-app-primary">
                    <Trophy size={20} />
                </div>
                <h2 class="text-base font-black uppercase tracking-widest text-app-text font-heading">
                    {t('season_summary_title').replace('{year}', String(seasonYear))}
                </h2>
            </div>
            <button
                onclick={onDismiss}
                class="p-2 rounded-lg text-app-text/40 hover:text-app-text hover:bg-app-text/5 transition-all"
                aria-label={t('season_summary_close')}
            >
                <X size={18} />
            </button>
        </div>

        {#if isLoading}
            <!-- Loading state -->
            <div class="flex items-center justify-center py-20">
                <div class="flex flex-col items-center gap-4">
                    <div class="w-8 h-8 border-4 border-app-primary border-t-transparent rounded-full animate-spin"></div>
                    <p class="text-xs text-app-text/50 uppercase tracking-widest font-heading">{t('season_summary_loading')}</p>
                </div>
            </div>
        {:else}
            <div class="flex flex-col gap-6 p-6">

                <!-- Constructors Championship -->
                <section>
                    <h3 class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/60 font-heading mb-3">
                        {t('season_summary_constructors')}
                    </h3>
                    <div class="flex flex-col gap-1">
                        {#each allTeams as team (team.id)}
                            {@const prize = SEASON_PRIZE_TABLE[team.position - 1] ?? 0}
                            {@const isPlayer = team.id === playerTeamId}
                            <div class="flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all
                                {isPlayer ? 'bg-app-primary/10 border-l-2 border-app-primary' : 'border-l-2 border-transparent hover:bg-app-text/5'}">
                                <!-- Position badge -->
                                <div class="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0
                                    {team.position === 1 ? 'bg-app-primary text-app-primary-foreground' : 'bg-app-text/10 text-app-text/60'}">
                                    <span class="text-[10px] font-black font-heading">P{team.position}</span>
                                </div>
                                <!-- Team name -->
                                <span class="flex-1 text-sm font-semibold truncate
                                    {isPlayer ? 'text-app-primary' : 'text-app-text'}">
                                    {team.name}
                                </span>
                                <!-- Points -->
                                <span class="text-xs text-app-text/50 font-mono tabular-nums w-16 text-right">
                                    {team.seasonPoints ?? 0} {t('season_summary_pts')}
                                </span>
                                <!-- Prize -->
                                <span class="text-xs font-bold text-app-text/70 font-mono tabular-nums w-14 text-right">
                                    {formatMoney(prize)}
                                </span>
                            </div>
                        {/each}
                    </div>
                </section>

                <!-- Drivers Champion -->
                {#if champion}
                    <section class="bg-app-primary/5 border border-app-primary/20 rounded-xl p-4">
                        <div class="flex items-center gap-3">
                            <div class="p-2 rounded-lg bg-app-primary/15 text-app-primary flex-shrink-0">
                                <Trophy size={16} />
                            </div>
                            <div class="flex flex-col gap-0.5 flex-1 min-w-0">
                                <span class="text-[9px] font-black uppercase tracking-[0.3em] text-app-primary/60 font-heading">
                                    {t('season_summary_champion')}
                                </span>
                                <span class="text-sm font-black text-app-primary truncate">
                                    {champion.name}
                                </span>
                                <span class="text-xs text-app-text/50 truncate">
                                    {champion.teamName ?? ''}
                                </span>
                            </div>
                            <div class="flex flex-col items-end gap-0.5 flex-shrink-0">
                                <span class="text-lg font-black text-app-primary font-mono tabular-nums">
                                    {champion.seasonPoints ?? 0}
                                </span>
                                <span class="text-[9px] text-app-text/40 uppercase tracking-widest font-heading">
                                    {t('season_summary_pts')}
                                </span>
                            </div>
                        </div>
                    </section>
                {/if}

                <!-- Your Season -->
                {#if playerRow}
                    <section>
                        <h3 class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/60 font-heading mb-3">
                            {t('season_summary_your_season')}
                        </h3>
                        <div class="bg-app-text/3 border border-app-border rounded-xl p-4 flex flex-col gap-3">
                            <div class="grid grid-cols-3 gap-4">
                                <div class="flex flex-col gap-1">
                                    <span class="text-[9px] text-app-text/40 uppercase tracking-widest font-heading">Position</span>
                                    <span class="text-xl font-black text-app-primary font-heading">P{playerRow.position}</span>
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span class="text-[9px] text-app-text/40 uppercase tracking-widest font-heading">{t('season_summary_pts')}</span>
                                    <span class="text-xl font-black text-app-text">{playerRow.seasonPoints ?? 0}</span>
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span class="text-[9px] text-app-text/40 uppercase tracking-widest font-heading">{t('season_summary_prize')}</span>
                                    <span class="text-xl font-black text-app-text">{formatMoney(playerPrize)}</span>
                                </div>
                            </div>
                            {#if playerIsChampTeam}
                                <div class="flex items-center gap-2 pt-2 border-t border-app-primary/20">
                                    <Trophy size={12} class="text-app-primary flex-shrink-0" />
                                    <span class="text-xs font-bold text-app-primary">
                                        {t('season_summary_drivers_bonus')}
                                    </span>
                                    <span class="ml-auto text-xs font-black text-app-primary">
                                        +{formatMoney(DRIVERS_CHAMPION_TEAM_BONUS)}
                                    </span>
                                </div>
                            {/if}
                        </div>
                    </section>
                {/if}

                <!-- CTAs -->
                <div class="flex gap-3 pt-2">
                    <a
                        href="/management/finances"
                        onclick={onDismiss}
                        class="flex-1 flex items-center justify-center gap-2 py-3 rounded-xl bg-app-primary text-app-primary-foreground text-[11px] font-black uppercase tracking-widest font-heading hover:opacity-90 transition-opacity"
                    >
                        <Wallet size={14} />
                        {t('season_summary_view_finances')}
                    </a>
                    <button
                        onclick={onDismiss}
                        class="flex-1 py-3 rounded-xl border border-app-border text-[11px] font-black uppercase tracking-widest font-heading text-app-text/50 hover:bg-app-text/5 hover:text-app-text transition-all"
                    >
                        {t('season_summary_close')}
                    </button>
                </div>
            </div>
        {/if}
    </div>
</div>
