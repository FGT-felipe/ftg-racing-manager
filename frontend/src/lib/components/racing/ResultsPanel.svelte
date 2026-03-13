<script lang="ts">
    import { onMount } from "svelte";
    import { fade, slide } from "svelte/transition";
    import { Trophy, History, Flag, Activity } from "lucide-svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { db } from "$lib/firebase/config";
    import { doc, getDoc } from "firebase/firestore";

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
        if (!seasonStore.value.season) return;

        const calendar = seasonStore.value.season.calendar || [];
        // Find the most recent completed event
        const completedEvents = [...calendar]
            .filter(e => e.isCompleted)
            .sort((a, b) => {
                const idA = parseInt(a.id?.toString().replace('r', '') || '0');
                const idB = parseInt(b.id?.toString().replace('r', '') || '0');
                return idB - idA;
            });

        if (completedEvents.length === 0) {
            isLoading = false;
            return;
        }

        lastEvent = completedEvents[0];
        
        try {
            const raceDocId = `${seasonStore.value.season.id}_${lastEvent.id}`;
            const raceRef = doc(db, "races", raceDocId);
            const raceSnap = await getDoc(raceRef);

            if (raceSnap.exists()) {
                const data = raceSnap.data();
                
                // Robust mapping: Use raceResults if exists, otherwise map finalPositions
                if (data.raceResults && Array.isArray(data.raceResults)) {
                    lastResults = data;
                } else if (data.finalPositions) {
                    const POINT_SYSTEM = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
                    const leaderId = Object.keys(data.finalPositions).find(k => data.finalPositions[k] === 1);
                    const leaderTime = leaderId ? (data.totalTimes?.[leaderId] || 0) : 0;

                    const mappedRaceResults = Object.entries(data.finalPositions)
                        .map(([driverId, position]: [string, any]) => {
                            // Find metadata from qualifyingResults which usually has the names
                            const qInfo = data.qualifyingResults?.find((q: any) => q.driverId === driverId);
                            const posInt = parseInt(position);
                            const pts = posInt <= POINT_SYSTEM.length ? POINT_SYSTEM[posInt - 1] : 0;
                            const isDnf = data.dnfs?.includes(driverId);
                            const driverTime = data.totalTimes?.[driverId] || 0;
                            // Use totalLaps from event or approximate from typical race length (70 laps)
                            const laps = lastEvent.totalLaps || 50; 

                            return {
                                driverId,
                                driverName: qInfo?.driverName || "Unknown Driver",
                                teamId: qInfo?.teamId,
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
                        ...data,
                        raceResults: mappedRaceResults
                    };
                } else {
                    lastResults = data;
                }
            }
        } catch (e) {
            console.error("Error loading last results:", e);
        } finally {
            isLoading = false;
        }
    }

    onMount(() => {
        loadLastResults();
    });

    function formatTime(seconds: number) {
        if (!seconds || seconds === 0 || !isFinite(seconds)) return "—";
        const mins = Math.floor(seconds / 60);
        const secs = (seconds % 60).toFixed(3);
        if (mins > 0) {
            return `${mins}:${secs.padStart(6, '0')}`;
        }
        return `${secs}s`;
    }

    function formatGap(gap: number) {
        if (gap === 0) return "LEADER";
        if (gap >= 999 || isNaN(gap)) return "DNF";
        return `+${gap.toFixed(3)}s`;
    }
</script>

<div class="space-y-6">
    {#if isLoading}
        <div class="flex flex-col items-center justify-center py-20 gap-4 opacity-50">
            <div class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"></div>
            <span class="text-[10px] font-black uppercase tracking-widest text-app-primary">Retrieving Historical Data...</span>
        </div>
    {:else if !lastResults || (!lastResults.qualifyingResults && !lastResults.raceResults)}
        <div class="bg-app-surface border border-app-border rounded-2xl p-12 flex flex-col items-center justify-center text-center gap-6 shadow-xl opacity-50">
            <History size={40} class="text-app-text/20" />
            <div class="max-w-md space-y-2">
                <h3 class="font-black text-xl uppercase italic text-app-text tracking-tight">No Historical Data</h3>
                <p class="text-app-text/40 text-sm font-medium">The season hasn't yielded any official results yet. Complete your first race weekend to see historical telemetry here.</p>
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
                        <h3 class="font-black text-sm uppercase tracking-widest italic text-app-text leading-none">Last Event Archives</h3>
                        <p class="text-[10px] font-bold text-app-primary uppercase tracking-widest mt-1">
                            {lastEvent?.trackName || 'Unknown Track'} • Round {lastEvent?.id?.toString().replace('r', '') || '—'}
                        </p>
                    </div>
                </div>

                {#if teamSummary}
                    <div class="text-right" in:fade>
                        <p class="text-[10px] font-black uppercase tracking-widest text-app-text/30 leading-none mb-1">Constructor Position</p>
                        <div class="flex items-center justify-end gap-2">
                            <span class="text-xl font-black italic text-app-text uppercase leading-none">{teamSummary.rank}</span>
                            <div class="flex flex-col items-start">
                                <span class="text-[9px] font-black uppercase text-app-text/20 leading-none mb-0.5">of {teamSummary.totalTeams} Teams</span>
                                <span class="text-[10px] font-black italic text-app-primary leading-none">{teamSummary.points} PTS RESULT</span>
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
                        <h4 class="font-black text-[10px] uppercase tracking-widest italic">Qualifying Classification</h4>
                    </div>
                    <div class="divide-y divide-white/5 max-h-[400px] overflow-y-auto custom-scrollbar">
                        {#if lastResults.qualifyingResults && lastResults.qualifyingResults.length > 0}
                            {#each lastResults.qualifyingResults as row, i}
                                <div class="p-3 flex items-center gap-4 transition-colors {row.teamId === userTeamId ? 'bg-app-primary/5' : 'hover:bg-white/[0.02]'}">
                                    <div class="w-6 h-6 rounded bg-app-text/10 flex items-center justify-center font-black italic text-[10px] {i < 3 ? 'text-app-primary' : (row.teamId === userTeamId ? 'text-app-primary' : 'text-app-text/20')}">
                                        {i + 1}
                                    </div>
                                    <div class="flex-1 min-w-0">
                                        <p class="text-[11px] font-black {row.teamId === userTeamId ? 'text-app-primary' : 'text-app-text'} truncate uppercase">{row.driverName}</p>
                                        <p class="text-[8px] font-bold {row.teamId === userTeamId ? 'text-app-primary/60' : 'text-app-text/30'} uppercase tracking-widest">{row.teamName}</p>
                                    </div>
                                    <div class="text-right">
                                        <p class="text-xs font-black italic text-app-primary tabular-nums">{formatTime(row.lapTime)}</p>
                                    </div>
                                </div>
                            {/each}
                        {:else}
                            <div class="p-8 text-center text-app-text/20 text-[10px] uppercase font-black tracking-widest">No Qualy Data Found</div>
                        {/if}
                    </div>
                </div>

                <!-- Race Results -->
                <div class="bg-app-surface border border-app-border rounded-2xl overflow-hidden shadow-2xl">
                    <div class="p-4 border-b border-app-border bg-app-surface flex items-center gap-3">
                        <Flag size={16} class="text-red-500" />
                        <h4 class="font-black text-[10px] uppercase tracking-widest italic">Race Results</h4>
                    </div>
                    <div class="divide-y divide-white/5 max-h-[400px] overflow-y-auto custom-scrollbar">
                        {#if lastResults.raceResults && lastResults.raceResults.length > 0}
                            {#each lastResults.raceResults as row, i}
                                <div class="p-3 flex items-center gap-4 transition-colors {row.teamId === userTeamId ? 'bg-app-primary/5' : 'hover:bg-white/[0.02]'}">
                                    <div class="w-6 h-6 rounded bg-app-text/10 flex items-center justify-center font-black italic text-[10px] {i < 3 ? 'text-red-500' : (row.teamId === userTeamId ? 'text-app-primary' : 'text-app-text/20')}">
                                        {row.isDnf ? 'R' : i + 1}
                                    </div>
                                    <div class="flex-1 min-w-0">
                                        <div class="flex items-center gap-2">
                                            <p class="text-[11px] font-black {row.teamId === userTeamId ? 'text-app-primary' : 'text-app-text'} truncate uppercase">{row.driverName}</p>
                                            {#if row.pts > 0}
                                                <span class="px-1.5 py-0.5 rounded bg-red-500/20 text-red-500 font-black text-[8px] italic">+{row.pts} PTS</span>
                                            {/if}
                                        </div>
                                        <p class="text-[8px] font-bold {row.teamId === userTeamId ? 'text-app-primary/60' : 'text-app-text/30'} uppercase tracking-widest">{row.teamName}</p>
                                    </div>
                                    <div class="text-right">
                                        <p class="text-xs font-black italic text-app-text tabular-nums">{formatGap(row.gapToLeader)}</p>
                                        {#if row.isDnf}
                                            <p class="text-[8px] font-bold text-red-500/50 uppercase italic">Retired</p>
                                        {:else}
                                            <p class="text-[8px] font-bold text-app-text/30 uppercase tabular-nums">Best: {formatTime(row.lastLapTime || row.bestLapTime)}</p>
                                        {/if}
                                    </div>
                                </div>
                            {/each}
                        {:else}
                            <div class="p-8 text-center text-app-text/20 text-[10px] uppercase font-black tracking-widest">No Race Data Found</div>
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
    .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(197, 160, 89, 0.2); border-radius: 10px; }
</style>
