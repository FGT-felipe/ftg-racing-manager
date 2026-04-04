<script lang="ts">
    import { untrack } from "svelte";
    import { fade, slide } from "svelte/transition";
    import { Trophy, History, Flag, Activity } from "lucide-svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { raceService } from "$lib/services/race_service.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
    import { t } from "$lib/utils/i18n";
    import { universeStore } from "$lib/stores/universe.svelte";

    let lastResults = $state<any>(null);
    let isLoading = $state(true);
    let lastEvent = $state<any>(null);
    let userTeamId = $derived(teamStore.value?.team?.id);

    function getOrdinal(n: number) {
        const s = ["th", "st", "nd", "rd"];
        const v = n % 100;
        return n + (s[(v - 20) % 10] || s[v] || s[0]);
    }

    const teamSummary = $derived.by(() => {
        if (!lastResults?.raceResults || !userTeamId) return null;
        
        // Sum points for all teams to determine ranking
        const teamPointsMap: Record<string, number> = {};
        lastResults.raceResults.forEach((r: any) => {
            if (!r.teamId) return;
            teamPointsMap[r.teamId] = (teamPointsMap[r.teamId] || 0) + (r.pts || 0);
        });

        const sortedTeams = Object.entries(teamPointsMap)
            .sort((a, b) => b[1] - a[1])
            .map(([id]) => id);

        const rank = sortedTeams.indexOf(userTeamId) + 1;
        const totalTeams = sortedTeams.length;
        const points = teamPointsMap[userTeamId] || 0;
        
        return { 
            rank: rank > 0 ? getOrdinal(rank) : '—', 
            totalTeams,
            points 
        };
    });

    async function loadLastResults() {
        const season = seasonStore.value.season;
        if (!season?.id) { isLoading = false; return; }

        try {
            // Derive the last race ID from nextEvent (e.g. nextEvent=r5 → last=r4).
            // This avoids any dependency on isCompleted flags in the calendar.
            const nextId = seasonStore.nextEvent?.id; // e.g. 'r5', or null if all done
            let lastRoundId: string;
            if (nextId) {
                const n = parseInt(nextId.replace('r', ''));
                if (n <= 1) { isLoading = false; return; } // no previous race yet
                lastRoundId = `r${n - 1}`;
            } else {
                // All races done — find the highest round that exists
                // by checking the calendar length as a hint
                const cal = season.calendar || [];
                lastRoundId = `r${cal.length}`;
            }

            const data = await raceService.getRaceDataByRound(season.id, lastRoundId);

            if (data) {
                const calendar = season.calendar || [];
                lastEvent = calendar.find(e => e.id === lastRoundId) || {
                    id: lastRoundId,
                    trackName: data.trackName || '—',
                    totalLaps: data.totalLaps || 50
                };

                // Normalize qualy field: old docs may only have qualyGrid, new ones have both
                const qualifyingResults = data.qualifyingResults?.length > 0
                    ? data.qualifyingResults
                    : (data.qualyGrid || []);
                const normalizedData = { ...data, qualifyingResults };

                // Robust mapping: Use raceResults if exists, otherwise map finalPositions
                if (normalizedData.raceResults && Array.isArray(normalizedData.raceResults)) {
                    lastResults = normalizedData;
                } else if (normalizedData.finalPositions) {
                    const POINT_SYSTEM = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
                    const leaderId = Object.keys(normalizedData.finalPositions).find(k => normalizedData.finalPositions[k] === 1);
                    const leaderTime = leaderId ? (normalizedData.totalTimes?.[leaderId] || 0) : 0;

                    const mappedRaceResults = Object.entries(normalizedData.finalPositions)
                        .map(([driverId, position]: [string, any]) => {
                            const qInfo = normalizedData.qualifyingResults?.find((q: any) => q.driverId === driverId);
                            const universeDriver = universeStore.getDriverById(driverId);
                            const posInt = parseInt(position);
                            const pts = posInt <= POINT_SYSTEM.length ? POINT_SYSTEM[posInt - 1] : 0;
                            const isDnf = normalizedData.dnfs?.includes(driverId);
                            const driverTime = normalizedData.totalTimes?.[driverId] || 0;
                            const laps = lastEvent?.totalLaps || 50;

                            return {
                                driverId,
                                driverName: qInfo?.driverName || universeDriver?.name || "Unknown Driver",
                                countryCode: qInfo?.countryCode || universeDriver?.countryCode,
                                teamId: qInfo?.teamId || universeDriver?.teamId,
                                teamName: qInfo?.teamName || "Privateer",
                                position: isDnf ? 999 : posInt,
                                pts,
                                gapToLeader: driverTime - leaderTime,
                                isDnf,
                                lastLapTime: driverTime / laps
                            };
                        })
                        .sort((a, b) => a.position - b.position);

                    lastResults = {
                        ...normalizedData,
                        raceResults: mappedRaceResults,
                        fast_lap_time: normalizedData.fast_lap_time,
                        fast_lap_driver: normalizedData.fast_lap_driver
                    };
                } else {
                    lastResults = normalizedData;
                }
            }
        } catch (e) {
            console.error('[ResultsPanel:loadLastResults] Failed:', e);
        } finally {
            isLoading = false;
        }
    }

    // Use $effect instead of onMount so the load fires when seasonStore becomes
    // available — onMount fires once at mount time, but the season snapshot may
    // arrive later. A plain boolean guard prevents double-execution.
    let _loadStarted = false;
    $effect(() => {
        const season = seasonStore.value.season;
        if (season && !_loadStarted) {
            _loadStarted = true;
            untrack(() => loadLastResults());
        }
    });

    function formatTime(seconds: number) {
        if (!seconds || seconds === 0 || !isFinite(seconds)) return "—";
        const hours = Math.floor(seconds / 3600);
        const mins = Math.floor((seconds % 3600) / 60);
        const secs = (seconds % 60).toFixed(3);
        
        if (hours > 0) {
            return `${hours}h ${mins}m ${secs}s`;
        }
        if (mins > 0) {
            return `${mins}:${secs.padStart(6, '0')}`;
        }
        return `${secs}s`;
    }

    function formatGap(gap: number) {
        if (gap === 0) return t('results_leader');
        if (gap >= 999 || isNaN(gap)) return t('results_dnf');
        return `+${gap.toFixed(3)}s`;
    }

    const fallbackObjectives: Record<string, string> = {
        'titans_oil': "Finish Top 3",
        'global_tech': "Both in Points",
        'zenith_sky': "Race Win",
        'fast_logistics': "Finish Top 10",
        'spark_energy': "Fastest Lap",
        'eco_pulse': "Finish Race",
        'local_drinks': "Finish Race",
        'micro_chips': "Improve Grid",
        'nitro_gear': "Overtake 3 Cars"
    };

    function translateObjective(desc: string | undefined | null) {
        if (!desc) return "";
        const mapping: Record<string, any> = {
            "Finish Top 3": "finish_top_3",
            "Both in Points": "both_in_points",
            "Race Win": "race_win",
            "Finish Top 10": "finish_top_10",
            "Fastest Lap": "fastest_lap",
            "Finish Race": "finish_race",
            "Improve Grid": "improve_grid",
            "Overtake 3 Cars": "overtake_3_cars",
            "Pole Position": "pole_position"
        };
        const key = mapping[desc] || desc;
        return t(key as any);
    }

    const sponsorObjectives = $derived.by(() => {
        if (!teamStore.value.team?.sponsors || !lastResults) return [];
        const activeSponsors = Object.values(teamStore.value.team.sponsors);
        
        return activeSponsors.map(s => {
            const desc = s.objectiveDescription || fallbackObjectives[s.sponsorId] || "";
            let isMet = false;
            let targetPos = 99;
            let type: 'qualy' | 'race' = 'race';

            if (desc.includes("Pole")) {
                type = 'qualy';
                targetPos = 1;
                isMet = lastResults.qualifyingResults?.some((r: any) => r.teamId === userTeamId && lastResults.qualifyingResults.indexOf(r) === 0);
            } else if (desc.includes("Win")) {
                targetPos = 1;
                isMet = lastResults.raceResults?.some((r: any) => r.teamId === userTeamId && r.position === 1);
            } else if (desc.includes("Top 3")) {
                targetPos = 3;
                isMet = lastResults.raceResults?.some((r: any) => r.teamId === userTeamId && r.position <= 3);
            } else if (desc.includes("Top 10")) {
                targetPos = 10;
                isMet = lastResults.raceResults?.some((r: any) => r.teamId === userTeamId && r.position <= 10);
            } else if (desc.includes("Both in Points")) {
                targetPos = 10;
                const inPoints = lastResults.raceResults?.filter((r: any) => r.teamId === userTeamId && r.position <= 10);
                isMet = (inPoints?.length >= 2);
            } else if (desc.includes("Fastest Lap")) {
                isMet = lastResults.fast_lap_driver && lastResults.raceResults?.some((r: any) => r.teamId === userTeamId && r.driverId === lastResults.fast_lap_driver);
                targetPos = 1;
            } else if (desc.includes("Improve Grid")) {
                const qualyMap = new Map(lastResults.qualifyingResults?.map((r: any, idx: number) => [r.driverId, idx + 1]) || []);
                isMet = lastResults.raceResults?.some((r: any) => {
                    if (r.teamId !== userTeamId) return false;
                    const qPos = qualyMap.get(r.driverId);
                    return qPos && r.position < qPos;
                });
                targetPos = 10; 
            } else if (desc.includes("Finish Race")) {
                targetPos = 20; 
                isMet = lastResults.raceResults?.some((r: any) => r.teamId === userTeamId && !r.isDnf);
            } else if (desc.includes("Overtake")) {
                const qualyMap = new Map(lastResults.qualifyingResults?.map((r: any, idx: number) => [r.driverId, idx + 1]) || []);
                isMet = lastResults.raceResults?.some((r: any) => {
                    const qPos = qualyMap.get(r.driverId);
                    if (qPos === undefined) return false;
                    return ((qPos as number) - (r.position as number)) >= 3;
                });
                targetPos = 10;
            }

            return { ...s, isMet, targetPos, type, objectiveDescription: desc };
        });
    });

    const fastestLapObjective = $derived.by(() => {
        return sponsorObjectives.find(o => (o.objectiveDescription || "").includes("Fastest Lap"));
    });

    const ribbonObjectives = $derived(sponsorObjectives.filter(o => !o.objectiveDescription?.includes("Fastest Lap")));

    function getRibbonForPos(pos: number, type: 'qualy' | 'race') {
        return ribbonObjectives.filter(o => o.targetPos === pos && o.type === type);
    }
</script>

<div class="space-y-6">
    {#if isLoading}
        <div class="flex flex-col items-center justify-center py-20 gap-4 opacity-50">
            <div class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"></div>
            <span class="text-[10px] font-black uppercase tracking-widest text-app-primary">{t('results_retrieving_data')}</span>
        </div>
    {:else if !lastResults || (!lastResults.qualifyingResults && !lastResults.raceResults)}
        <div class="bg-app-surface border border-app-border rounded-2xl p-12 flex flex-col items-center justify-center text-center gap-6 shadow-xl opacity-50">
            <History size={40} class="text-app-text/20" />
            <div class="max-w-md space-y-2">
                <h3 class="font-black text-xl uppercase italic text-app-text tracking-tight">{t('results_no_data_title')}</h3>
                <p class="text-app-text/40 text-sm font-medium">{t('results_no_data_desc')}</p>
            </div>
        </div>
    {:else}
        <div in:fade class="space-y-8">
            <!-- Header for Results -->
            <div class="flex items-center justify-between">
                <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-xl bg-app-primary/10 flex items-center justify-center text-app-primary border border-app-primary/20">
                        <History size={20} />
                    </div>
                    <div>
                        <h3 class="font-black text-sm uppercase tracking-widest italic text-app-text leading-none">{t('results_last_event_header')}</h3>
                        <p class="text-[10px] font-bold text-app-primary uppercase tracking-widest mt-1">
                            {lastEvent?.trackName || 'Unknown Track'} • Round {lastEvent?.id?.toString().replace('r', '') || '—'}
                        </p>
                    </div>
                </div>

                {#if teamSummary}
                    <div class="text-right" in:fade>
                        <p class="text-[10px] font-black uppercase tracking-widest text-app-text/30 leading-none mb-1">{t('results_constructor_position')}</p>
                        <div class="flex items-center justify-end gap-2">
                            <span class="text-xl font-black italic text-app-text uppercase leading-none">{teamSummary.rank}</span>
                            <div class="flex flex-col items-start">
                                <span class="text-[9px] font-black uppercase text-app-text/20 leading-none mb-0.5">of {teamSummary.totalTeams} Teams</span>
                                <span class="text-[10px] font-black italic text-app-primary leading-none">{teamSummary.points} {t('results_pts_result')}</span>
                            </div>
                        </div>
                    </div>
                {/if}
            </div>

            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
                <!-- Qualifying Results -->
                <div class="bg-app-surface border border-app-border rounded-2xl overflow-hidden shadow-2xl">
                    <div class="p-4 border-b border-app-border bg-app-surface flex items-center gap-3">
                        <Trophy size={16} class="text-app-primary" />
                        <h4 class="font-black text-[10px] uppercase tracking-widest italic">{t('results_qualifying_header')}</h4>
                    </div>
                    <div class="divide-y divide-white/5 max-h-[400px] overflow-y-auto custom-scrollbar">
                        {#if lastResults.qualifyingResults && lastResults.qualifyingResults.length > 0}
                            {#each lastResults.qualifyingResults as row, i}
                                <div class="p-3 flex items-center gap-4 transition-colors {row.teamId === userTeamId ? 'bg-app-primary/5' : 'hover:bg-white/[0.02]'}">
                                    <div class="w-6 h-6 rounded bg-app-text/10 flex items-center justify-center font-black italic text-[10px] {i < 3 ? 'text-app-primary' : (row.teamId === userTeamId ? 'text-app-primary' : 'text-app-text/20')}">
                                        {i + 1}
                                    </div>
                                    <div class="flex-1 min-w-0">
                                        <div class="flex items-center gap-2">
                                            <p class="text-[11px] font-black {row.teamId === userTeamId ? 'text-app-primary' : 'text-app-text'} truncate uppercase">{row.driverName}</p>
                                            <CountryFlag countryCode={row.countryCode || universeStore.getDriverById(row.driverId)?.countryCode} size="xs" />
                                        </div>
                                        <p class="text-[8px] font-bold {row.teamId === userTeamId ? 'text-app-primary/60' : 'text-app-text/30'} uppercase tracking-widest">{row.teamName}</p>
                                    </div>
                                    <div class="text-right">
                                        <p class="text-xs font-black italic text-app-primary tabular-nums">{formatTime(row.lapTime)}</p>
                                    </div>
                                </div>
                                {#each getRibbonForPos(i + 1, 'qualy') as ribbon}
                                    <div class="px-4 py-2 flex items-center justify-between border-y {ribbon.isMet ? 'bg-app-success/10 border-app-success/20' : 'bg-app-error/10 border-app-error/20'}" in:slide>
                                        <div class="flex items-center gap-3">
                                            <span class="text-[9px] font-black uppercase tracking-[0.2em] {ribbon.isMet ? 'text-app-success' : 'text-app-error'}">{ribbon.sponsorName}</span>
                                            <div class="w-1 h-3 w-[2px] rounded-full {ribbon.isMet ? 'bg-app-success/40' : 'bg-app-error/40'}"></div>
                                            <span class="text-[10px] font-black italic text-app-text/50 uppercase tracking-tight">{translateObjective(ribbon.objectiveDescription)}</span>
                                        </div>
                                        <span class="text-[9px] font-black uppercase tracking-widest {ribbon.isMet ? 'text-app-success' : 'text-app-error'} px-2 py-0.5 rounded {ribbon.isMet ? 'bg-app-success/10' : 'bg-app-error/10'}">
                                            {t(ribbon.isMet ? 'objective_met' : 'objective_failed', { desc: translateObjective(ribbon.objectiveDescription) })}
                                        </span>
                                    </div>
                                {/each}
                            {/each}
                        {:else}
                            <div class="p-8 text-center text-app-text/20 text-[10px] uppercase font-black tracking-widest">{t('results_no_qualy_data')}</div>
                        {/if}
                    </div>
                </div>

                <!-- Race Results -->
                <div class="bg-app-surface border border-app-border rounded-2xl overflow-hidden shadow-2xl">
                    <div class="p-4 border-b border-app-border bg-app-surface flex items-center justify-between">
                        <div class="flex items-center gap-3">
                            <Flag size={16} class="text-red-500" />
                            <h4 class="font-black text-[10px] uppercase tracking-widest italic">{t('results_race_header')}</h4>
                        </div>
                        {#if lastResults?.fast_lap_time}
                            <div class="flex items-center gap-4">
                                <div class="flex items-center gap-2 px-3 py-1 bg-white/[0.03] border border-white/5 rounded-full">
                                    <span class="text-[9px] font-bold text-app-text/40 uppercase tracking-tighter">{t('results_fastest_lap_label')}</span>
                                    <span class="text-[10px] font-black text-app-text italic">
                                        {formatTime(lastResults.fast_lap_time)}
                                    </span>
                                    <span class="text-[10px] font-black text-app-primary/60 uppercase text-[8px] truncate max-w-[80px]">
                                        {(lastResults.raceResults?.find((r: any) => r.driverId === lastResults.fast_lap_driver)?.driverName) || "Unknown"}
                                    </span>
                                </div>
                                {#if fastestLapObjective}
                                    <div class="flex items-center gap-1.5 px-2 py-0.5 rounded border {fastestLapObjective.isMet ? 'bg-app-success/10 border-app-success/20 text-app-success' : 'bg-app-error/10 border-app-error/20 text-app-error'}">
                                        <div class="w-1.5 h-1.5 rounded-full {fastestLapObjective.isMet ? 'bg-app-success' : 'bg-app-error'} animate-pulse"></div>
                                        <span class="text-[8px] font-black uppercase tracking-widest">{t('results_objective_label')}</span>
                                    </div>
                                {/if}
                            </div>
                        {/if}
                    </div>
                    <div class="divide-y divide-white/5 max-h-[400px] overflow-y-auto custom-scrollbar">
                        {#if lastResults.raceResults && lastResults.raceResults.length > 0}
                            {#each lastResults.raceResults as row, i}
                                <div class="p-3 flex items-center gap-4 transition-colors {row.teamId === userTeamId ? 'bg-app-primary/5' : 'hover:bg-white/[0.02]'}">
                                    <div class="w-6 h-6 rounded bg-app-text/10 flex items-center justify-center font-black italic text-[10px] {row.isDnf ? 'text-red-500' : (i < 3 ? 'text-red-500' : (row.teamId === userTeamId ? 'text-app-primary' : 'text-app-text/20'))}">
                                        {row.isDnf ? t('results_dnf') : i + 1}
                                    </div>
                                    <div class="flex-1 min-w-0">
                                        <div class="flex items-center gap-2">
                                            <p class="text-[11px] font-black {row.teamId === userTeamId ? 'text-app-primary' : 'text-app-text'} truncate uppercase">{row.driverName}</p>
                                            <CountryFlag countryCode={row.countryCode || universeStore.getDriverById(row.driverId)?.countryCode} size="xs" />
                                            {#if row.pts > 0}
                                                <span class="px-1.5 py-0.5 rounded bg-red-500/20 text-red-500 font-black text-[8px] italic">+{row.pts} PTS</span>
                                            {/if}
                                        </div>
                                        <p class="text-[8px] font-bold {row.teamId === userTeamId ? 'text-app-primary/60' : 'text-app-text/30'} uppercase tracking-widest">{row.teamName}</p>
                                    </div>
                                    <div class="text-right">
                                        <p class="text-xs font-black italic text-app-text tabular-nums">
                                            {row.isDnf ? t('results_dnf') : (i === 0 ? formatTime(lastResults.totalTimes?.[row.driverId]) : formatGap(row.gapToLeader))}
                                        </p>
                                        {#if row.isDnf}
                                            <p class="text-[8px] font-bold text-red-500/50 uppercase italic">{t('results_retired')}</p>
                                        {:else}
                                            <p class="text-[8px] font-bold text-app-text/30 uppercase tabular-nums">
                                                {lastResults.fast_lap_driver === row.driverId ? t('results_fastest_lap_badge') : `${t('results_best_lap_prefix')} ${formatTime(row.lastLapTime)}`}
                                            </p>
                                        {/if}
                                    </div>
                                </div>
                                {#each getRibbonForPos(i + 1, 'race') as ribbon}
                                    <div class="px-4 py-2 flex items-center justify-between border-y {ribbon.isMet ? 'bg-app-success/10 border-app-success/20' : 'bg-app-error/10 border-app-error/20'}" in:slide>
                                        <div class="flex items-center gap-3">
                                            <span class="text-[9px] font-black uppercase tracking-[0.2em] {ribbon.isMet ? 'text-app-success' : 'text-app-error'}">{ribbon.sponsorName}</span>
                                            <div class="w-1 h-3 w-[2px] rounded-full {ribbon.isMet ? 'bg-app-success/40' : 'bg-app-error/40'}"></div>
                                            <span class="text-[10px] font-black italic text-app-text/50 uppercase tracking-tight">{translateObjective(ribbon.objectiveDescription)}</span>
                                        </div>
                                        <span class="text-[9px] font-black uppercase tracking-widest {ribbon.isMet ? 'text-app-success' : 'text-app-error'} px-2 py-0.5 rounded {ribbon.isMet ? 'bg-app-success/10' : 'bg-app-error/10'}">
                                            {t(ribbon.isMet ? 'objective_met' : 'objective_failed', { desc: translateObjective(ribbon.objectiveDescription) })}
                                        </span>
                                    </div>
                                {/each}
                            {/each}
                        {:else}
                            <div class="p-8 text-center text-app-text/20 text-[10px] uppercase font-black tracking-widest">{t('results_no_race_data')}</div>
                        {/if}
                    </div>
                </div>
            </div>
        </div>
    {/if}
</div>

<style>
    .custom-scrollbar::-webkit-scrollbar { width: 3px; }
    .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
    .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(var(--primary-color-rgb), 0.2); border-radius: 10px; }
</style>
