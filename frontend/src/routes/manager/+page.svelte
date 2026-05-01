<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { Trophy, CheckCircle, AlertTriangle } from "lucide-svelte";
    import { getRoleById } from "$lib/constants/manager";
    import { t } from "$lib/utils/i18n";
    import { computeCareerTotals } from "./career";

    const team = $derived(teamStore.value.team);

    const careerTotals = $derived(team ? computeCareerTotals(team) : { titles: 0, wins: 0, podiums: 0, poles: 0, races: 0 });
    const seasonHistory = $derived([...(team?.seasonHistory ?? [])].sort((a, b) => b.year - a.year));

    const managerAge = $derived.by(() => {
        if (!managerStore.profile?.birthDate) return null;
        try {
            const birth = new Date(managerStore.profile.birthDate);
            const now = new Date();
            let age = now.getFullYear() - birth.getFullYear();
            const m = now.getMonth() - birth.getMonth();
            if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) age--;
            return age;
        } catch {
            return null;
        }
    });

    const managerRole = $derived.by(() => {
        const bgId = managerStore.profile?.backgroundId || "ex_driver";
        return getRoleById(bgId);
    });
</script>

<svelte:head>
    <title>{t('manager_page_title')} | FTG Racing Manager</title>
</svelte:head>

<div class="p-4 md:p-8 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text">
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">

        <!-- Column A: Manager Identity Card -->
        <div class="flex flex-col gap-6">
            <div class="bg-app-surface border border-app-border rounded-2xl overflow-hidden relative group shadow-lg">
                <div class="p-6 border-b border-app-border bg-app-text/5 flex items-center justify-between">
                    <div class="flex items-center gap-4">
                        <div class="w-16 h-16 rounded-2xl bg-app-primary text-app-primary-foreground border-4 border-app-primary/20 flex items-center justify-center font-heading font-black text-2xl italic shadow-inner shrink-0">
                            {managerStore.profile?.firstName?.[0] || "M"}
                        </div>
                        <div class="flex flex-col gap-1 min-w-0">
                            <h4 class="text-xl font-black text-app-text uppercase tracking-tighter italic truncate leading-none">
                                {managerStore.profile?.firstName} {managerStore.profile?.lastName}
                            </h4>
                            <div class="flex flex-wrap items-center gap-2">
                                <span class="text-[9px] font-black text-app-primary border border-app-primary/30 uppercase tracking-widest px-2 py-0.5 bg-app-primary/10 rounded">
                                    {managerRole?.title || managerStore.profile?.role || t('manager_role_fallback')}
                                </span>
                                {#if managerAge}
                                    <span class="text-[9px] font-bold text-app-text/40 uppercase bg-white/5 px-2 py-0.5 rounded border border-white/5">
                                        {managerAge} {t('years')}
                                    </span>
                                {/if}
                                {#if managerStore.profile?.nationality}
                                    <div class="flex items-center gap-1.5 px-2 py-0.5 bg-white/5 rounded border border-white/5">
                                        <img
                                            src="https://flagcdn.com/w20/{managerStore.profile.nationality.toLowerCase()}.png"
                                            alt={managerStore.profile.nationality}
                                            class="w-3.5 h-2.5 object-cover rounded-[1px]"
                                            onerror={(e) => (e.currentTarget as HTMLImageElement).style.display = 'none'}
                                        />
                                        <span class="text-[9px] font-bold text-app-text/60 uppercase">{managerStore.profile.nationality}</span>
                                    </div>
                                {/if}
                            </div>
                        </div>
                    </div>
                </div>

                <div class="p-6 space-y-6">
                    <div class="space-y-4">
                        <div class="flex items-center justify-between">
                            <h5 class="text-[10px] font-black text-app-text/30 uppercase tracking-[0.2em]">{t('office_management_edge_label')}</h5>
                            <span class="text-[10px] font-black text-app-primary/40 uppercase italic">{managerRole?.title}</span>
                        </div>
                        <div class="grid grid-cols-1 gap-3">
                            {#if managerRole?.pros}
                                {#each managerRole.pros as pro}
                                    <div class="flex items-start gap-2.5 group/pro">
                                        <div class="mt-0.5 p-0.5 bg-emerald-500/20 rounded border border-emerald-500/30">
                                            <CheckCircle size={10} class="text-emerald-400" />
                                        </div>
                                        <span class="text-[11px] font-bold text-app-text/80 leading-tight group-hover/pro:text-app-text transition-colors">{pro}</span>
                                    </div>
                                {/each}
                            {/if}
                            {#if managerRole?.cons}
                                {#each managerRole.cons as con}
                                    <div class="flex items-start gap-2.5 group/con">
                                        <div class="mt-0.5 p-0.5 bg-red-500/20 rounded border border-red-500/30">
                                            <AlertTriangle size={10} class="text-red-400" />
                                        </div>
                                        <span class="text-[11px] font-bold text-app-text/40 leading-tight group-hover/con:text-app-text/60 transition-colors uppercase italic">{con}</span>
                                    </div>
                                {/each}
                            {/if}
                        </div>
                    </div>

                    <div class="pt-6 border-t border-app-border/40 grid grid-cols-2 gap-4">
                        <div class="bg-white/[0.02] border border-app-border/40 rounded-2xl p-4 flex flex-col gap-1">
                            <span class="text-[8px] font-bold text-app-text/20 uppercase tracking-widest">{t('office_global_ranking_label')}</span>
                            <span class="text-sm font-black text-app-text uppercase tracking-tight italic">
                                {managerStore.profile?.reputation && managerStore.profile.reputation > 80 ? t('reputation_tier_elite') : t('reputation_tier_regional')}
                            </span>
                        </div>
                        <div class="bg-white/[0.02] border border-app-border/40 rounded-2xl p-4 flex flex-col gap-1">
                            <span class="text-[8px] font-bold text-app-text/20 uppercase tracking-widest">Reputation</span>
                            <div class="flex items-center justify-between">
                                <span class="text-xl font-black text-app-text font-mono tracking-tighter">{managerStore.profile?.reputation || 50}</span>
                                <Trophy size={14} class="text-yellow-400 opacity-50" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Column B: Career Stats -->
        <div class="flex flex-col gap-6">
            <div class="bg-app-surface border border-app-border rounded-2xl p-6">
                <div class="flex items-center gap-2 mb-6">
                    <Trophy size={16} class="text-app-primary" />
                    <h3 class="text-xs font-black uppercase text-app-text tracking-widest">
                        {t('office_career_stats_header')}
                    </h3>
                </div>
                <div class="grid grid-cols-2 gap-4">
                    <div class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30 col-span-2">
                        <span class="text-[9px] font-bold text-app-text/30 uppercase block mb-1">{t('stat_titles')}</span>
                        <span class="text-3xl font-black text-app-primary italic">{careerTotals.titles}</span>
                    </div>
                    <div class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30">
                        <span class="text-[9px] font-bold text-app-text/30 uppercase block mb-1">{t('wins')}</span>
                        <span class="text-2xl font-black text-app-text italic">{careerTotals.wins}</span>
                    </div>
                    <div class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30">
                        <span class="text-[9px] font-bold text-app-text/30 uppercase block mb-1">{t('podiums')}</span>
                        <span class="text-2xl font-black text-app-text italic">{careerTotals.podiums}</span>
                    </div>
                    <div class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30">
                        <span class="text-[9px] font-bold text-app-text/30 uppercase block mb-1">{t('poles')}</span>
                        <span class="text-2xl font-black text-app-text italic">{careerTotals.poles}</span>
                    </div>
                    <div class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30">
                        <span class="text-[9px] font-bold text-app-text/30 uppercase block mb-1">{t('races')}</span>
                        <span class="text-2xl font-black text-app-text/60 italic">{careerTotals.races}</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Column C: Season History -->
        <div class="flex flex-col gap-6">
            <div class="bg-app-surface border border-app-border rounded-2xl p-6">
                <div class="flex items-center gap-2 mb-6">
                    <Trophy size={16} class="text-app-primary" />
                    <h3 class="text-xs font-black uppercase text-app-text tracking-widest">
                        {t('manager_season_history_header')}
                    </h3>
                </div>

                {#if seasonHistory.length === 0}
                    <p class="text-xs text-app-text/40 italic">{t('manager_history_empty')}</p>
                {:else}
                    <div class="overflow-x-auto">
                        <table class="w-full text-left">
                            <thead>
                                <tr class="border-b border-app-border/40">
                                    <th class="pb-2 pr-3 font-black text-[9px] text-app-text/30 uppercase tracking-widest">{t('year')}</th>
                                    <th class="pb-2 pr-3 font-black text-[9px] text-app-text/30 uppercase tracking-widest">{t('team')}</th>
                                    <th class="pb-2 pr-3 font-black text-[9px] text-app-text/30 uppercase tracking-widest">{t('pos')}</th>
                                    <th class="pb-2 pr-3 font-black text-[9px] text-app-text/30 uppercase tracking-widest">{t('col_pts_abbr')}</th>
                                    <th class="pb-2 pr-3 font-black text-[9px] text-app-text/30 uppercase tracking-widest">{t('races')}</th>
                                    <th class="pb-2 pr-3 font-black text-[9px] text-app-text/30 uppercase tracking-widest">{t('wins')}</th>
                                    <th class="pb-2 pr-3 font-black text-[9px] text-app-text/30 uppercase tracking-widest">{t('podiums')}</th>
                                    <th class="pb-2 pr-3 font-black text-[9px] text-app-text/30 uppercase tracking-widest">{t('poles')}</th>
                                    <th class="pb-2 font-black text-[9px] text-app-text/30 uppercase tracking-widest">{t('manager_season_title_col')}</th>
                                </tr>
                            </thead>
                            <tbody>
                                {#each seasonHistory as entry (entry.seasonId)}
                                    <tr class="border-b border-app-border/20 hover:bg-app-text/[0.02] transition-colors">
                                        <td class="py-2.5 pr-3 font-bold text-xs text-app-text">{entry.year}</td>
                                        <td class="py-2.5 pr-3 font-bold text-xs text-app-text/70 truncate max-w-[80px]">{entry.teamName ?? '—'}</td>
                                        <td class="py-2.5 pr-3 font-black text-xs text-app-primary">{entry.constructorsPosition}</td>
                                        <td class="py-2.5 pr-3 font-bold text-xs text-app-text/80">{entry.points}</td>
                                        <td class="py-2.5 pr-3 font-bold text-xs text-app-text/60">{entry.races}</td>
                                        <td class="py-2.5 pr-3 font-bold text-xs text-app-text/60">{entry.wins}</td>
                                        <td class="py-2.5 pr-3 font-bold text-xs text-app-text/60">{entry.podiums}</td>
                                        <td class="py-2.5 pr-3 font-bold text-xs text-app-text/60">{entry.poles ?? '—'}</td>
                                        <td class="py-2.5">
                                            {#if entry.isConstructorsChampion}
                                                <Trophy size={12} class="text-yellow-400" aria-label={t('manager_season_title_col')} />
                                            {/if}
                                        </td>
                                    </tr>
                                {/each}
                            </tbody>
                        </table>
                    </div>
                {/if}
            </div>
        </div>

    </div>
</div>
