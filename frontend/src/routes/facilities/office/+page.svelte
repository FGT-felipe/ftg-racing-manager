<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { notificationStore } from "$lib/stores/notifications.svelte";
    import { uiStore } from "$lib/stores/ui.svelte";
    import { newsStore } from "$lib/stores/news.svelte";
    import {
        Trophy,
        Mail,
        Edit3,
        X,
        BarChart3,
        Info,
        CheckCircle,
        AlertTriangle,
    } from "lucide-svelte";
    import { getRoleById } from "$lib/constants/manager";
    import { t } from "$lib/utils/i18n";

    let isEditingName = $state(false);
    let newName = $state("");
    let isSavingName = $state(false);

    // Initialize stores
    driverStore.init();
    newsStore.init();

    let news = $derived(newsStore.items);

    // Season Form chart data
    const seasonFormData = $derived(
        [...(teamStore.value.team?.seasonForm ?? [])].sort((a, b) => a.round - b.round)
    );
    const seasonFormMaxPos = $derived(
        seasonFormData.length > 0 ? Math.max(...seasonFormData.map(e => e.position)) : 10
    );

    // Stats calculation
    const constructorsTrophies = $derived(
        [...(teamStore.value.team?.seasonHistory ?? [])]
            .filter(s => s.isConstructorsChampion)
            .sort((a, b) => b.year - a.year)
    );

    const teamStats = $derived({
        titles: constructorsTrophies.length,
        wins:
            (driverStore.carADriver?.wins || 0) +
            (driverStore.carBDriver?.wins || 0),
        podiums:
            (driverStore.carADriver?.podiums || 0) +
            (driverStore.carBDriver?.podiums || 0),
        poles:
            (driverStore.carADriver?.poles || 0) +
            (driverStore.carBDriver?.poles || 0),
        races:
            (driverStore.carADriver?.races || 0) +
            (driverStore.carBDriver?.races || 0),
    });

    const managerAge = $derived.by(() => {
        if (!managerStore.profile?.birthDate) return null;
        try {
            const birth = new Date(managerStore.profile.birthDate);
            const now = new Date();
            let age = now.getFullYear() - birth.getFullYear();
            const m = now.getMonth() - birth.getMonth();
            if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) {
                age--;
            }
            return age;
        } catch (e) {
            return null;
        }
    });

    const managerRole = $derived.by(() => {
        const bgId = managerStore.profile?.backgroundId || "ex_driver";
        return getRoleById(bgId);
    });

    $effect(() => {
        newName = teamStore.value.team?.name || "";
    });

    async function handleRename() {
        if (!newName.trim() || newName === teamStore.value.team?.name) {
            isEditingName = false;
            return;
        }

        isSavingName = true;
        try {
            await teamStore.renameTeam(newName);
            notificationStore.addNotification({
                title: "Team Renamed",
                message: `Identity updated to ${newName}.`,
                type: "SUCCESS",
            });
            isEditingName = false;
        } catch (e: any) {
            uiStore.alert(e.message, 'Error', 'danger');
        } finally {
            isSavingName = false;
        }
    }


    function formatDate(date: Date) {
        return (
            date.toLocaleDateString(undefined, {
                day: "numeric",
                month: "short",
            }) +
            " " +
            date.toLocaleTimeString(undefined, {
                hour: "2-digit",
                minute: "2-digit",
            })
        );
    }
</script>

<svelte:head>
    <title>Team Office | FTG Racing Manager</title>
</svelte:head>

<div class="p-4 md:p-8 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text">
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">

        <!-- Column A: Team Identity + Manager -->
        <div class="flex flex-col gap-6">

            <!-- Team Identity Card -->
            <div class="bg-app-surface border border-app-border rounded-2xl p-6 shadow-xl relative overflow-hidden group">
                <div class="absolute top-0 right-0 w-32 h-32 bg-app-primary/5 rounded-full -mr-16 -mt-16 blur-3xl group-hover:bg-app-primary/10 transition-all duration-700"></div>

                <div class="flex items-center justify-between mb-6 relative">
                    <span class="text-[10px] font-black uppercase tracking-widest text-app-primary">
                        {t('office_team_identity_label')}
                    </span>
                    {#if !isEditingName}
                        <button
                            onclick={() => (isEditingName = true)}
                            class="p-2 hover:bg-app-text/5 rounded-lg text-app-text/30 hover:text-app-primary transition-all"
                        >
                            <Edit3 size={14} />
                        </button>
                    {/if}
                </div>

                {#if isEditingName}
                    <div class="space-y-4 animate-in fade-in slide-in-from-top-2 duration-300">
                        <div class="space-y-1.5">
                            <label for="team-name" class="text-[10px] font-bold text-app-text/40 uppercase ml-1">
                                {t('office_new_name_label')}
                            </label>
                            <input
                                id="team-name"
                                type="text"
                                bind:value={newName}
                                class="w-full bg-app-text/5 border border-app-border rounded-xl px-4 py-3 font-black text-app-text focus:outline-none focus:border-app-primary/50 transition-all"
                                placeholder={t('office_team_name_placeholder')}
                            />
                        </div>
                        <div class="flex gap-2">
                            <button
                                onclick={handleRename}
                                disabled={isSavingName}
                                class="flex-1 py-2.5 bg-app-primary text-app-primary-foreground font-black uppercase text-[10px] tracking-widest rounded-lg hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50"
                            >
                                {isSavingName ? t('saving') : t('confirm')}
                            </button>
                            <button
                                onclick={() => { isEditingName = false; newName = teamStore.value.team?.name || ""; }}
                                class="px-3 bg-app-text/5 text-app-text/40 font-black uppercase text-[10px] tracking-widest rounded-lg hover:bg-app-text/10 transition-all"
                            >
                                <X size={16} />
                            </button>
                        </div>
                    </div>
                {:else}
                    <h2 class="text-3xl font-black text-app-text uppercase tracking-tight mb-2 truncate">
                        {teamStore.value.team?.name}
                    </h2>
                {/if}

                <div class="mt-6 pt-6 border-t border-app-border/30">
                    <div class="flex items-center gap-3 p-3 bg-app-text/5 rounded-xl border border-app-border/30">
                        <div class="w-8 h-8 rounded-lg bg-amber-500/10 flex items-center justify-center">
                            <Info size={14} class="text-amber-500" />
                        </div>
                        <div class="flex flex-col">
                            <span class="text-[9px] font-bold text-app-text/30 uppercase">{t('office_renaming_policy_label')}</span>
                            <span class="text-[11px] font-bold text-app-text/60">
                                {teamStore.value.team?.nameChangeCount === 0 ? t('office_first_change_free') : "Cost: $500,000"}
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Manager Card -->
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
                                    {managerRole?.title || managerStore.profile?.role || "Manager"}
                                </span>
                                {#if managerAge}
                                    <span class="text-[9px] font-bold text-app-text/40 uppercase bg-white/5 px-2 py-0.5 rounded border border-white/5">
                                        {managerAge} Years
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
                                {managerStore.profile?.reputation && managerStore.profile.reputation > 80 ? "Elite Executive" : "Regional Lead"}
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

        <!-- Column B: Season Form + Career Stats + Trophy Cabinet -->
        <div class="flex flex-col gap-6">

            <!-- Season Form Chart -->
            <div class="bg-app-surface border border-app-border rounded-2xl p-6">
                <div class="flex items-center gap-2 mb-4">
                    <BarChart3 size={16} class="text-app-primary" />
                    <h3 class="text-xs font-black uppercase text-app-text tracking-widest">
                        {t('office_season_form_header')}
                    </h3>
                </div>
                {#if seasonFormData.length === 0}
                    <p class="text-[11px] text-app-text/30 italic text-center py-6">
                        {t('office_season_form_empty')}
                    </p>
                {:else}
                    {@const W = 380}
                    {@const H = 140}
                    {@const padL = 30}
                    {@const padR = 16}
                    {@const padT = 20}
                    {@const padB = 24}
                    {@const chartW = W - padL - padR}
                    {@const chartH = H - padT - padB}
                    {@const n = seasonFormData.length}
                    {@const maxPos = Math.max(seasonFormMaxPos, 2)}
                    {@const xOf = (i: number) => padL + (n === 1 ? chartW / 2 : (i / (n - 1)) * chartW)}
                    {@const yOf = (pos: number) => padT + ((pos - 1) / (maxPos - 1)) * chartH}
                    {@const pts = seasonFormData.map((e, i) => `${xOf(i)},${yOf(e.position)}`).join(' ')}
                    {@const lastEntry = seasonFormData[n - 1]}

                    <svg viewBox="0 0 {W} {H}" class="w-full" aria-hidden="true">
                        <!-- Y-axis grid lines: one per position -->
                        {#each Array.from({ length: maxPos }, (_, k) => k + 1) as pos}
                            <line
                                x1={padL} y1={yOf(pos)}
                                x2={W - padR} y2={yOf(pos)}
                                stroke="currentColor"
                                stroke-width={pos === 1 ? 0.75 : 0.4}
                                stroke-dasharray={pos === 1 ? '' : '2 4'}
                                class={pos === 1 ? 'text-app-primary/20' : 'text-app-border/20'}
                            />
                        {/each}

                        <!-- Y-axis labels: P1 at top, Pmax at bottom, mid if space -->
                        <text x={padL - 5} y={yOf(1) + 3.5} text-anchor="end"
                            font-size="7" fill="currentColor" class="text-app-primary/60">P1</text>
                        <text x={padL - 5} y={yOf(maxPos) + 3.5} text-anchor="end"
                            font-size="7" fill="currentColor" class="text-app-text/30">P{maxPos}</text>
                        {#if maxPos >= 4}
                            {@const mid = Math.round(maxPos / 2)}
                            <text x={padL - 5} y={yOf(mid) + 3.5} text-anchor="end"
                                font-size="7" fill="currentColor" class="text-app-text/25">P{mid}</text>
                        {/if}

                        <!-- Line -->
                        <polyline
                            points={pts}
                            fill="none"
                            stroke="currentColor"
                            stroke-width="1.5"
                            stroke-linejoin="round"
                            stroke-linecap="round"
                            class="text-app-primary/70"
                        />

                        <!-- Dots + R-labels below -->
                        {#each seasonFormData as entry, i}
                            {@const cx = xOf(i)}
                            {@const cy = yOf(entry.position)}
                            {@const isLast = i === n - 1}
                            <!-- Dot -->
                            <circle cx={cx} cy={cy} r={isLast ? 4.5 : 2.5}
                                fill="currentColor"
                                class={isLast ? 'text-app-primary' : 'text-app-primary/55'} />
                            {#if isLast}
                                <circle cx={cx} cy={cy} r="8"
                                    fill="none" stroke="currentColor" stroke-width="1"
                                    class="text-app-primary/25" />
                                <!-- Current position callout above last dot -->
                                <text x={cx} y={cy - 12} text-anchor="middle"
                                    font-size="8" font-weight="bold" fill="currentColor"
                                    class="text-app-primary">P{entry.position}</text>
                            {/if}
                            <!-- Round label below x-axis -->
                            <text x={cx} y={H - 2} text-anchor="middle"
                                font-size="7" fill="currentColor" class="text-app-text/30">
                                R{entry.round}
                            </text>
                        {/each}
                    </svg>
                {/if}
            </div>

            <!-- Career Stats -->
            <div class="bg-app-surface border border-app-border rounded-2xl p-6">
                <div class="flex items-center gap-2 mb-6">
                    <Trophy size={16} class="text-app-primary" />
                    <h3 class="text-xs font-black uppercase text-app-text tracking-widest">
                        {t('office_career_stats_header')}
                    </h3>
                </div>
                <div class="grid grid-cols-2 gap-4">
                    <div class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30">
                        <span class="text-[9px] font-bold text-app-text/30 uppercase block mb-1">{t('stat_titles')}</span>
                        <span class="text-2xl font-black text-app-primary italic">{teamStats.titles}</span>
                    </div>
                    <div class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30">
                        <span class="text-[9px] font-bold text-app-text/30 uppercase block mb-1">{t('wins')}</span>
                        <span class="text-2xl font-black text-app-text italic">{teamStats.wins}</span>
                    </div>
                    <div class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30">
                        <span class="text-[9px] font-bold text-app-text/30 uppercase block mb-1">{t('podiums')}</span>
                        <span class="text-2xl font-black text-app-text italic">{teamStats.podiums}</span>
                    </div>
                    <div class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30">
                        <span class="text-[9px] font-bold text-app-text/30 uppercase block mb-1">{t('races')}</span>
                        <span class="text-2xl font-black text-app-text/20 italic">{teamStats.races}</span>
                    </div>
                </div>
            </div>

            <!-- Trophy Cabinet -->
            <div class="bg-app-surface border border-app-border rounded-2xl p-6">
                <div class="flex items-center gap-2 mb-4">
                    <Trophy size={16} class="text-app-primary" />
                    <h3 class="text-xs font-black uppercase text-app-text tracking-widest">
                        {t('office_trophy_cabinet_header')}
                    </h3>
                </div>
                {#if constructorsTrophies.length > 0}
                    <div class="flex flex-col gap-2">
                        {#each constructorsTrophies as trophy (trophy.seasonId)}
                            <div class="flex items-center gap-3 px-3 py-2.5 rounded-xl bg-app-primary/5 border border-app-primary/20">
                                <Trophy size={14} class="text-app-primary flex-shrink-0" />
                                <div class="flex flex-col gap-0">
                                    <span class="text-xs font-black text-app-primary">{trophy.year}</span>
                                    <span class="text-[9px] text-app-text/50 uppercase tracking-widest font-heading">
                                        {t('office_trophy_constructors_champion')}
                                    </span>
                                </div>
                            </div>
                        {/each}
                    </div>
                {:else}
                    <p class="text-[11px] text-app-text/30 italic text-center py-4">
                        {t('office_trophy_cabinet_empty')}
                    </p>
                {/if}
            </div>
        </div>

        <!-- Column C: Last Race Debrief + Official Communications -->
        <div class="flex flex-col gap-6">

            <!-- Last Race Debrief -->
            {#if teamStore.value.team?.lastRaceDebrief}
                <div class="bg-gradient-to-br from-app-surface to-black border-l-4 border-app-primary border-t border-r border-b border-app-border rounded-2xl p-6 shadow-2xl">
                    <div class="flex items-center gap-3 mb-6">
                        <div class="p-2 bg-app-primary text-app-primary-foreground rounded-lg">
                            <BarChart3 size={18} />
                        </div>
                        <h3 class="text-sm font-black uppercase text-app-text tracking-widest">
                            {t('office_race_debrief_header')}
                        </h3>
                        <span class="ml-auto text-[10px] font-bold text-app-text/30 uppercase bg-app-text/5 px-2 py-1 rounded">
                            {t('office_official_report_badge')}
                        </span>
                    </div>
                    {#if teamStore.value.team?.lastRaceResult}
                        <div class="bg-app-text/40 border border-app-border/50 rounded-xl p-4 mb-6 font-mono text-[12px] text-app-text/70 leading-relaxed">
                            {teamStore.value.team.lastRaceResult}
                        </div>
                    {/if}
                    <p class="text-[14px] text-app-text/80 leading-relaxed font-medium pl-2">
                        {teamStore.value.team.lastRaceDebrief}
                    </p>
                </div>
            {/if}

            <!-- Official Communications -->
            <div class="flex flex-col gap-4">
                <div class="flex items-center gap-2 px-2">
                    <Mail size={16} class="text-app-primary" />
                    <h3 class="text-xs font-black uppercase text-app-text tracking-[0.2em]">
                        {t('office_communications_header')}
                    </h3>
                </div>
                <div class="flex flex-col gap-3 overflow-y-auto custom-scrollbar max-h-[480px] pr-1">
                    {#if news.length === 0}
                        <div class="p-12 text-center bg-app-surface border border-app-border border-dashed rounded-2xl text-app-text/20">
                            <Mail size={32} class="mx-auto mb-4 opacity-50" />
                            <p class="text-[10px] font-black uppercase tracking-widest">
                                {t('office_no_communications')}
                            </p>
                        </div>
                    {:else}
                        {#each news as item}
                            <div class="bg-app-surface border border-app-border rounded-2xl p-6 hover:border-app-primary/30 transition-all group shadow-sm">
                                <div class="flex justify-between items-start mb-3">
                                    <h4 class="font-black text-app-text uppercase group-hover:text-app-primary transition-colors">
                                        {item.title}
                                    </h4>
                                    <span class="text-[10px] font-mono text-app-text/20">{formatDate(item.timestamp)}</span>
                                </div>
                                <p class="text-[13px] text-app-text/60 leading-relaxed">{item.message}</p>
                            </div>
                        {/each}
                    {/if}
                </div>
            </div>
        </div>

    </div>
</div>

<style>
    :global(.animate-spin) {
        animation: spin 1s linear infinite;
    }

    @keyframes spin {
        from {
            transform: rotate(0deg);
        }
        to {
            transform: rotate(360deg);
        }
    }
</style>
