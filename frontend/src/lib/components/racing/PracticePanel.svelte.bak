<script lang="ts">
    import { db } from "$lib/firebase/config";
    import { doc, updateDoc, addDoc, collection, serverTimestamp } from "firebase/firestore";
    import { teamStore } from "$lib/stores/team.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { setupStore, type PracticeHistoryItem } from "$lib/stores/setup.svelte";
    import {
        raceService,
    } from "$lib/services/race_service.svelte";
    import {
        practiceService,
        type PracticeRunResult,
    } from "$lib/services/practice_service.svelte";
    import { MAX_PRACTICE_LAPS_PER_DRIVER, PRACTICE_SESSION_COST } from "$lib/constants/app_constants";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { universeStore } from "$lib/stores/universe.svelte";
    import { circuitService } from "$lib/services/circuit_service.svelte";
    import {
        type CarSetup,
        TyreCompound,
        DriverStyle,
        type Driver,
    } from "$lib/types";
    import {
        Timer,
        Zap,
        Wind,
        Navigation,
        AlertTriangle,
        CheckCircle2,
        History,
        Info,
        ChevronRight,
        Flag,
        Bolt,
        Smile,
    } from "lucide-svelte";
    import { onMount, untrack } from "svelte";
    import { fade, slide } from "svelte/transition";
    import { t, type TranslationKey } from "$lib/utils/i18n";

    let { driverId = null } = $props<{ driverId: string | null }>();

    // Local state
    let setup = $state<CarSetup>({
        frontWing: 50,
        rearWing: 50,
        suspension: 50,
        gearRatio: 50,
        tyreCompound: TyreCompound.medium,
        pitStops: [TyreCompound.hard],
        initialFuel: 50,
        pitStopFuel: [50],
        qualifyingStyle: DriverStyle.normal,
        raceStyle: DriverStyle.normal,
        pitStopStyles: [DriverStyle.normal],
    });

    let currentDriverStyle = $state<DriverStyle>(DriverStyle.normal);
    let isSimulating = $state(false);
    let lastResult = $state<PracticeRunResult | null>(null);
    let lapsToRun = $state(1);
    let competitorTimes = $state<Array<{ teamName: string; driverName: string; time: number | null; tyre: string | null; totalLaps: number; driverId: string }>>([]);
    let telemetryTab = $state<'history' | 'standings'>('history');

    // Derived states
    const teamDrivers = $derived(driverStore.drivers);
    const driver = $derived(teamDrivers.find((d: any) => d.id === driverId));
    const nextEvent = $derived(seasonStore.nextEvent);
    const circuit = $derived(nextEvent ? circuitService.getCircuitProfile(nextEvent.circuitId) : null);
    
    const driverPracticeLaps = $derived.by(() => {
        if (!driverId) return 0;
        return (
            teamStore.value.team?.weekStatus?.driverSetups?.[driverId]
                ?.practice?.laps || 0
        );
    });

    // History Logic (Matching PracticeSetupTab.svelte)
    const practiceHistory = $derived(driver ? setupStore.getHistoryByDriver(driver.id) : []);

    const legacyPracticeRuns = $derived.by(() => {
        const team = teamStore.value.team;
        if (!driver || !team?.weekStatus?.driverSetups) return [];
        const driverSetup = team.weekStatus.driverSetups[driver.id] || {};
        return driverSetup.practiceRuns || [];
    });

    const combinedHistory = $derived.by(() => {
        const base = practiceHistory as PracticeHistoryItem[];
        if (!driver) return base;

        const legacy: PracticeHistoryItem[] = (legacyPracticeRuns || []).map(
            (run: any, idx: number) => ({
                id: `legacy-${idx}`,
                driverId: driver.id,
                lapTime: run.time,
                setupUsed: run.setupUsed,
                feedback: [],
                setupConfidence: 0,
                isCrashed: !!run.isCrashed,
                timestamp: null,
            }),
        );

        return [...base, ...legacy];
    });

    const enrichedHistory = $derived.by(() => {
        const combined = combinedHistory as PracticeHistoryItem[];
        if (!driver || !circuit || !teamStore.value.team) return combined;

        // Sort by timestamp if available, or keep as is (newest first usually)
        // We'll reverse it to number them 1, 2, 3... and then reverse back for display
        const reversed = [...combined].reverse();
        
        const enriched = reversed.map((entry, idx) => {
            let item = { ...entry };
            if (!item.feedback || item.feedback.length === 0) {
                if (item.setupUsed) {
                    const sim = practiceService.simulatePracticeRun(
                        circuit,
                        teamStore.value.team!,
                        driver,
                        item.setupUsed,
                        nextEvent?.weatherPractice || "Sunny",
                    );
                    item.feedback = sim.driverFeedback.concat(sim.tyreFeedback);
                    item.setupConfidence = sim.setupConfidence;
                    if (item.isCrashed === undefined) item.isCrashed = sim.isCrashed;
                }
            }
            // Add sequential lap number (1-based)
            return { ...item, lapIndex: idx + 1 };
        });

        return enriched.reverse();
    });

    const globalStandings = $derived.by(() => {
        if (competitorTimes.length === 0) return [];
        
        const leaderTime = competitorTimes.find(c => c.time !== null)?.time || null;
        return competitorTimes.map((s, idx) => ({
            ...s,
            position: idx + 1,
            gap: (s.time !== null && leaderTime !== null) ? s.time - leaderTime : null
        }));
    });

    $effect(() => {
        if (globalStandings.length > 0) {
            console.log('[PracticePanel] UI Standings data synchronized. Entries:', globalStandings.length);
        } else {
            console.log('[PracticePanel] UI Standings data is currently empty.');
        }
    });

    // Reactivity check for store synchronization
    $effect(() => {
        const team = teamStore.value.team;
        const uniLoading = universeStore.value.loading;
        const teamLoading = teamStore.value.loading;
        const seasonLoading = seasonStore.value.loading;
        const season = seasonStore.value.season;
        
        const lId = team?.leagueId;
        const sId = team?.currentSeasonId;
        const tId = team?.id;

        console.log('[PracticePanel] Data synchronization check:', { 
            hasTeam: !!team, 
            teamLoading, 
            uniLoading,
            seasonLoading,
            hasSeason: !!season,
            teamId: tId, 
            leagueId: lId, 
            seasonId: sId 
        });

        if (team && !teamLoading && !uniLoading && !seasonLoading) {
            console.log('[PracticePanel] All stores synced. Triggering refreshStandings.');
            refreshStandings();
        }
    });

    onMount(() => {
        if (teamStore.value.team?.id) {
            setupStore.init(teamStore.value.team.id);
        }
        // Force an initial refresh if stores are already ready
        if (teamStore.value.team && !teamStore.value.loading && !universeStore.value.loading && !seasonStore.value.loading) {
            refreshStandings();
        }
    });

    async function refreshStandings() {
        const team = teamStore.value.team;
        const season = seasonStore.value.season;
        const event = nextEvent;

        if (!team || !season || !event) {
            console.log('[PracticePanel] refreshStandings: Aborting.', { 
                hasTeam: !!team, 
                hasSeason: !!season, 
                hasEvent: !!event 
            });
            return;
        }

        // 1. Determine ALL team IDs in the current league (needed for the driver query)
        const league = universeStore.getLeagueByTeamId(team.id);
        const teamIds = league?.teams?.map((t: any) => t.id) || [];
        const teamNames: Record<string, string> = {};
        league?.teams?.forEach((t: any) => {
            teamNames[t.id] = t.name;
        });

        console.log('[PracticePanel] refreshStandings: Preparation:', {
            leagueName: league?.name,
            teamIdsCount: teamIds.length,
            teamIds: teamIds
        });

        if (teamIds.length === 0) {
            console.warn('[PracticePanel] refreshStandings: No teams found in league. Standing down.');
            return;
        }

        // 2. Format Session ID (matches race results pattern)
        const sessionId = `${season.id}_${event.id}`;
        
        console.log('[PracticePanel] refreshStandings: Fetching for session:', sessionId, 'with teamIds:', teamIds);

        const times = await raceService.getCompetitorPracticeTimes(sessionId, teamIds, teamNames);
        console.log(`[PracticePanel] refreshStandings: Received ${times.length} entries.`);
        if (times.length > 0) {
            console.table(times.slice(0, 5));
        }
        competitorTimes = times;
    }

    // Restore setup and lastResult from weekStatus or history when driver changes
    $effect(() => {
        if (driverId) {
            untrack(() => {
                const team = teamStore.value.team;
                if (team?.weekStatus?.driverSetups?.[driverId]?.practice) {
                    const savedSetup = team.weekStatus.driverSetups[driverId].practice;
                    setup = { ...setup, ...savedSetup };
                    
                    // Initialize lastResult from saved best lap for Pit Board persistence
                    if (savedSetup.bestLapTime) {
                        lastResult = {
                            lapTime: savedSetup.bestLapTime,
                            driverFeedback: [],
                            tyreFeedback: [],
                            setupConfidence: savedSetup.setupConfidence || 0.5,
                            setupUsed: { ...setup },
                            isCrashed: false
                        };
                    } else {
                        lastResult = null;
                    }
                } else {
                    const hist = setupStore.getHistoryByDriver(driverId);
                    if (hist.length > 0) {
                        setup = { ...setup, ...hist[0].setupUsed };
                    }
                    lastResult = null;
                }
            });
        }
    });

    // Sync lastResult with history if not currently simulating
    $effect(() => {
        if (!isSimulating && driverId && enrichedHistory.length > 0) {
            const latest = enrichedHistory[0];
            if (latest.feedback && latest.feedback.length > 0) {
                lastResult = {
                    lapTime: latest.lapTime,
                    driverFeedback: latest.feedback || [],
                    tyreFeedback: [],
                    setupConfidence: latest.setupConfidence,
                    setupUsed: latest.setupUsed,
                    isCrashed: !!latest.isCrashed
                };
            }
        }
    });

    async function runPractice() {
        const currentDriver = driver;
        const currentCircuit = circuit;
        const team = teamStore.value.team;
        if (!currentDriver || !currentCircuit || !team) {
            isSimulating = false;
            return;
        }

        isSimulating = true;

        // One-time cost check: $10,000 per driver per weekend
        const weekStatus = team.weekStatus || {};
        const practicePaid = weekStatus.practicePaid || {};
        const hasPaid = practicePaid[currentDriver.id];

        if (!hasPaid) {
            if (team.budget < PRACTICE_SESSION_COST) {
                alert(t('insufficient_funds') || "Insufficient funds ($10,000 required)");
                isSimulating = false;
                return;
            }

            // Pay the fee
            try {
                const teamRef = doc(db, "teams", team.id);
                const txRef = collection(db, "teams", team.id, "transactions");

                await updateDoc(teamRef, {
                    budget: team.budget - PRACTICE_SESSION_COST,
                    [`weekStatus.practicePaid.${currentDriver.id}`]: true
                });

                await addDoc(txRef, {
                    description: t('practice_fee_description', { name: currentDriver.name }) || `Track access fee for ${currentDriver.name}`,
                    amount: -PRACTICE_SESSION_COST,
                    date: serverTimestamp(),
                    type: "PRACTICE"
                });
            } catch (err) {
                console.error("Error paying practice fee:", err);
                alert("Error processing payment.");
                isSimulating = false;
                return;
            }
        }

        // Limit check
        const driverSetupCheck = weekStatus.driverSetups?.[currentDriver.id] || {};
        const driverSetupLaps = driverSetupCheck.practice?.laps || 0;

        if (driverSetupLaps + lapsToRun > MAX_PRACTICE_LAPS_PER_DRIVER) {
            alert(t('laps_remaining', { count: Math.max(0, MAX_PRACTICE_LAPS_PER_DRIVER - driverSetupLaps) }) || `Maximum of ${MAX_PRACTICE_LAPS_PER_DRIVER} laps reached.`);
            isSimulating = false;
            return;
        }

        const setupToRun = { ...setup, qualifyingStyle: currentDriverStyle };

        try {
            for (let i = 0; i < lapsToRun; i++) {
                const result = practiceService.simulatePracticeRun(
                    currentCircuit,
                    team,
                    currentDriver,
                    setupToRun,
                    nextEvent?.weatherPractice || "Sunny",
                );
                lastResult = result;

                const sessionId = `${seasonStore.value.season?.id}_${nextEvent?.id}`;

                await practiceService.savePracticeRun(
                    teamStore.value.team!,
                    currentDriver.id,
                    result,
                    setupToRun,
                    sessionId
                );

                // Refresh global standings after a run
                await refreshStandings();

                // Wait for visual feedback
                await new Promise((r) => setTimeout(r, 600));
                if (result.isCrashed) break;
            }

            // Update stamina/morale (like in PracticeSetupTab)
            const staminaCost = lapsToRun * 1;
            let moralePenalty = 0;
            if (lastResult) {
                if (lastResult.isCrashed) moralePenalty = 5;
                else if (lastResult.setupConfidence < 0.60) moralePenalty = 2;
                else if (lastResult.setupConfidence > 0.85) moralePenalty = -1;
            }

            const driverRef = doc(db, "drivers", currentDriver.id);
            const currentStats = currentDriver.stats || {};
            await updateDoc(driverRef, {
                "stats.stamina": Math.max(0, (currentStats.stamina || 100) - staminaCost),
                "stats.morale": Math.max(0, Math.min(100, (currentStats.morale || 100) - moralePenalty)),
            });

        } catch (e) {
            console.error(e);
        }

        isSimulating = false;
    }

    async function copyToQualifying() {
        if (!driver || !teamStore.value.team) return;
        try {
            const teamRef = doc(db, "teams", teamStore.value.team.id);
            await updateDoc(teamRef, {
                [`weekStatus.driverSetups.${driver.id}.qualifying`]: { ...setup },
            });
            alert("✓ " + t('set_qualy'));
        } catch (e) { console.error(e); }
    }

    async function copyToRace() {
        if (!driver || !teamStore.value.team) return;
        try {
            const teamRef = doc(db, "teams", teamStore.value.team.id);
            await updateDoc(teamRef, {
                [`weekStatus.driverSetups.${driver.id}.race`]: { ...setup },
            });
            alert("✓ " + t('set_race'));
        } catch (e) { console.error(e); }
    }

    function getConfidenceColor(conf: number) {
        if (conf > 0.9) return "text-emerald-400";
        if (conf > 0.7) return "text-emerald-500/80";
        if (conf > 0.4) return "text-yellow-400";
        return "text-red-400";
    }

    function formatDisplayDate(ts: any) {
        if (!ts) return t('session_label') || 'SESSION';
        try {
            const date = ts.toDate ? ts.toDate() : new Date(ts);
            return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        } catch (e) {
            return t('session_label') || 'SESSION';
        }
    }

    function formatTime(seconds: number) {
        if (seconds >= 999) return "DNF";
        const mins = Math.floor(seconds / 60);
        const secs = (seconds % 60).toFixed(3);
        const parts = secs.split('.');
        return `${mins}:${parts[0].padStart(2, '0')}.${parts[1]}`;
    }

    const styleConfigs = [
        { id: DriverStyle.defensive, icon: ChevronRight, color: "text-blue-400", label: "defensive" as TranslationKey },
        { id: DriverStyle.normal, icon: Zap, color: "text-emerald-400", label: "normal" as TranslationKey },
        { id: DriverStyle.offensive, icon: Zap, color: "text-orange-400", label: "offensive" as TranslationKey },
        { id: DriverStyle.mostRisky, icon: Zap, color: "text-red-500", label: "risky" as TranslationKey },
    ];

    function getMoraleColor(val: number) {
        if (val >= 75) return "bg-emerald-500";
        if (val >= 40) return "bg-yellow-500";
        return "bg-red-500";
    }

    function getStaminaColor(val: number) {
        if (val >= 75) return "bg-cyan-500";
        if (val >= 40) return "bg-emerald-500";
        return "bg-yellow-500";
    }
</script>

<div class="grid grid-cols-1 lg:grid-cols-12 gap-5" in:fade>
    <!-- LEFT: Setup & Controls (7 Cols) -->
    <div class="lg:col-span-7 space-y-5">
        <!-- DRIVER STATUS CARD (New for parity) -->
        {#if driver}
            <div class="bg-app-surface border border-app-border rounded-xl p-4 flex items-center justify-between gap-6 shadow-sm">
                <div class="flex-1 space-y-2">
                    <div class="flex justify-between items-center text-[9px] font-black uppercase tracking-wider text-app-text/40">
                        <div class="flex items-center gap-1.5"><Bolt size={10} class="text-emerald-400" /> {t('fitness')}</div>
                        <span class="text-app-text">{driver.stats?.stamina || 100}%</span>
                    </div>
                    <div class="h-1.5 w-full bg-app-text/5 rounded-full overflow-hidden">
                        <div class="h-full {getStaminaColor(driver.stats?.stamina || 100)}" style="width: {driver.stats?.stamina || 100}%"></div>
                    </div>
                </div>
                <div class="flex-1 space-y-2">
                    <div class="flex justify-between items-center text-[9px] font-black uppercase tracking-wider text-app-text/40">
                        <div class="flex items-center gap-1.5"><Smile size={10} class="text-yellow-400" /> {t('morale')}</div>
                        <span class="text-app-text">{driver.stats?.morale || 100}%</span>
                    </div>
                    <div class="h-1.5 w-full bg-app-text/5 rounded-full overflow-hidden">
                        <div class="h-full {getMoraleColor(driver.stats?.morale || 100)}" style="width: {driver.stats?.morale || 100}%"></div>
                    </div>
                </div>
                <div class="flex-1 space-y-2">
                    <div class="flex justify-between items-center text-[9px] font-black uppercase tracking-wider text-app-text/40">
                        <div class="flex items-center gap-1.5"><History size={10} class="text-app-primary" /> {t('laps_available')}</div>
                        <span class="text-app-text">{driverPracticeLaps} / 50</span>
                    </div>
                    <div class="h-1.5 w-full bg-app-text/5 rounded-full overflow-hidden">
                        <div class="h-full bg-app-primary" style="width: {(driverPracticeLaps/50)*100}%"></div>
                    </div>
                </div>
            </div>
        {/if}

        <!-- SETUP CARD -->
        <div class="bg-app-surface border border-app-border rounded-2xl p-5 shadow-xl relative overflow-hidden">
            <div class="flex items-center justify-between mb-6">
                <h3 class="font-black text-[10px] text-app-text/60 uppercase tracking-[0.2em]">{t('practice_setup')}</h3>
                <div class="flex gap-2">
                    <button onclick={copyToQualifying} class="px-3 py-1.5 rounded-lg border border-app-primary/20 bg-app-primary/5 text-app-primary text-[9px] font-black uppercase hover:bg-app-primary hover:text-black transition-all flex items-center gap-1.5">
                        <Timer size={12} /> {t('set_qualy')}
                    </button>
                    <button onclick={copyToRace} class="px-3 py-1.5 rounded-lg border border-[#E040FB]/20 bg-[#E040FB]/5 text-[#E040FB] text-[9px] font-black uppercase hover:bg-[#E040FB] hover:text-white transition-all flex items-center gap-1.5">
                        <Flag size={12} /> {t('set_race')}
                    </button>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-5">
                {#each [
                    { label: t('front_wing'), field: "frontWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400" },
                    { label: t('rear_wing'), field: "rearWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400" },
                    { label: t('suspension'), field: "suspension" as keyof CarSetup, icon: Navigation, color: "text-purple-400" },
                    { label: t('gear_ratio'), field: "gearRatio" as keyof CarSetup, icon: Zap, color: "text-orange-400" }
                ] as item}
                    <div class="space-y-2 group">
                        <div class="flex justify-between items-center text-[10px] font-black uppercase">
                            <div class="flex items-center gap-2 {item.color}"><item.icon size={12} /> {item.label}</div>
                            <span class="text-app-text font-mono">{setup[item.field]}</span>
                        </div>
                        <input type="range" min="0" max="100" bind:value={setup[item.field]} class="w-full h-1.5 bg-app-text/5 rounded-full accent-emerald-500 cursor-pointer" />
                    </div>
                {/each}
            </div>

            <div class="mt-8 space-y-3">
                <span class="text-[9px] font-black text-app-text/30 uppercase tracking-widest">{t('tyre_compound')}</span>
                <div class="grid grid-cols-4 gap-2">
                    {#each [TyreCompound.soft, TyreCompound.medium, TyreCompound.hard, TyreCompound.wet] as tc}
                        <button onclick={() => (setup.tyreCompound = tc)} class="py-2.5 rounded-xl border text-[9px] font-black uppercase transition-all flex flex-col items-center gap-1.5 {setup.tyreCompound === tc ? 'bg-app-primary border-app-primary text-black' : 'bg-app-text/5 border-app-border text-app-text/30 hover:bg-app-text/10'}">
                            <div class="w-2 h-2 rounded-full {tc === 'soft' ? 'bg-red-500' : tc === 'medium' ? 'bg-yellow-500' : tc === 'hard' ? 'bg-white' : 'bg-blue-500'} shadow-sm"></div>
                            {tc}
                        </button>
                    {/each}
                </div>
            </div>
        </div>

        <!-- AGGRESSION & ACTION -->
        <div class="bg-app-surface border border-app-border rounded-2xl p-5 flex flex-col md:flex-row gap-6 items-center shadow-xl">
            <div class="flex-1 w-full space-y-3">
                <h4 class="text-[9px] font-black text-app-text/30 uppercase tracking-widest">{t('driving_aggression')}</h4>
                <div class="flex gap-2">
                    {#each styleConfigs as style}
                        <button onclick={() => (currentDriverStyle = style.id)} class="flex-1 py-3 rounded-xl border flex items-center justify-center transition-all {currentDriverStyle === style.id ? 'bg-emerald-500/10 border-emerald-500/50 ' + style.color : 'bg-app-text/5 border-transparent text-app-text/20 hover:text-app-text/40'}" title={t(style.label)}>
                            <style.icon size={16} />
                        </button>
                    {/each}
                </div>
            </div>
            
            <div class="flex-1 w-full space-y-3">
                <h4 class="text-[9px] font-black text-app-text/30 uppercase tracking-widest">{t('laps')}</h4>
                <div class="flex gap-2">
                    <div class="flex-1 bg-app-text/5 rounded-xl p-1 flex gap-1">
                        {#each [1, 3, 5] as laps}
                            <button onclick={() => (lapsToRun = laps)} class="flex-1 py-2 rounded-lg text-[10px] font-black uppercase transition-all {lapsToRun === laps ? 'bg-emerald-500 text-black' : 'text-app-text/30 hover:text-app-text/50'}">
                                {laps}
                            </button>
                        {/each}
                    </div>
                    <button disabled={isSimulating || !driver} onclick={runPractice} class="flex-[1.5] py-3 bg-app-primary text-black font-black uppercase tracking-widest text-[11px] rounded-xl hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 disabled:scale-100 flex items-center justify-center gap-2 shadow-lg shadow-app-primary/20">
                        {#if isSimulating}<div class="w-3 h-3 border-2 border-black border-t-transparent rounded-full animate-spin"></div>{/if}
                        {isSimulating ? t('simulating_laps') : t('start_practice')}
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- RIGHT: Telemetry & Standings (5 Cols) -->
    <div class="lg:col-span-5 space-y-5">
        <!-- GLOBAL LEADERBOARD CARD -->
        <div class="bg-app-surface border border-app-border rounded-xl p-4 shadow-xl">
            <div class="flex items-center justify-between mb-4">
                <span class="text-[10px] font-black text-app-primary uppercase tracking-widest italic">{t('standings')}</span>
                <div class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
            </div>
            
            <div class="grid grid-cols-12 gap-2 px-1 mb-2 text-[8px] font-black uppercase text-app-text/20 tracking-tighter">
                <div class="col-span-1">#</div>
                <div class="col-span-4 text-left">{t('driver')}</div>
                <div class="col-span-3 text-right">{t('best_lap')}</div>
                <div class="col-span-2 text-right">{t('total_laps')}</div>
                <div class="col-span-2 text-right">{t('gap')}</div>
            </div>

            <div class="space-y-1.5 max-h-[260px] overflow-y-auto custom-scrollbar pr-1">
                {#if globalStandings.length === 0}
                    <p class="text-[10px] text-app-text/20 italic p-4 text-center">{t('waiting_competitors')}</p>
                {:else}
                    {#each globalStandings as s}
                        {@const isPlayerDriver = teamDrivers.some(d => d.id === s.driverId)}
                        {@const hasTime = s.time !== null}
                        {@const isLeader = s.position === 1 && hasTime}
                        <div class="grid grid-cols-12 gap-2 px-2 py-2 rounded-lg border transition-all items-center 
                            {isLeader ? 'bg-app-primary border-app-primary text-black' : 
                            isPlayerDriver ? (hasTime ? 'bg-app-primary/10 border-app-primary/30' : 'bg-app-primary/5 border-app-primary/10 opacity-70') : 
                            (hasTime ? 'bg-app-text/2 border-transparent' : 'bg-app-text/2 border-transparent opacity-40 grayscale')}">
                            
                            <div class="col-span-1 text-[9px] font-black {isLeader ? 'text-black' : (s.position <= 3 && hasTime ? 'text-app-primary' : 'text-app-text/30')}">P{s.position}</div>
                            
                            <div class="col-span-4 flex flex-col min-w-0">
                                <span class="text-[9px] font-bold truncate {isLeader ? 'text-black' : 'text-app-text'}">{s.driverName}</span>
                                <span class="text-[7px] font-black uppercase {isLeader ? 'text-black/50' : 'opacity-30'} truncate">{s.teamName}</span>
                            </div>
                            
                            <div class="col-span-3 text-right flex items-center justify-end gap-2">
                                <span class="text-[10px] font-black font-mono {isLeader ? 'text-black' : 'text-app-text'}">{hasTime ? formatTime(s.time!) : '--:--.---'}</span>
                                {#if s.tyre}
                                    <div class="w-4 h-4 rounded-full border flex items-center justify-center text-[8px] font-black 
                                        {s.tyre === 'soft' ? 'bg-red-500 border-red-700 text-white' : 
                                         s.tyre === 'medium' ? 'bg-yellow-500 border-yellow-700 text-black' : 
                                         s.tyre === 'hard' ? 'bg-white border-gray-300 text-black' : 
                                         'bg-blue-500 border-blue-700 text-white'} {isLeader ? 'ring-1 ring-black/20' : ''}"
                                         title={s.tyre.toUpperCase()}>
                                        {s.tyre[0].toUpperCase()}
                                    </div>
                                {:else}
                                    <div class="w-4 h-4 rounded-full border border-app-text/10 bg-app-text/5"></div>
                                {/if}
                            </div>
                            
                            <div class="col-span-2 text-right text-[9px] font-black {isLeader ? 'text-black/40' : 'text-app-text/40'}">{s.totalLaps}</div>
                            
                            <div class="col-span-2 text-right text-[8px] font-black {isLeader || (s.gap === 0 && hasTime) ? 'text-black' : 'text-app-text/30'} font-mono">
                                {s.gap === null ? '--' : s.gap === 0 ? 'LEADER' : `+${s.gap.toFixed(3)}`}
                            </div>
                        </div>
                    {/each}
                {/if}
            </div>
        </div>

        <!-- PIT BOARD (Status) -->
        <div class="bg-app-surface border border-app-border rounded-xl p-5 shadow-xl flex flex-col justify-between h-[110px]">
            <div class="flex items-center justify-between">
                <span class="text-[10px] font-black text-emerald-400 uppercase tracking-widest italic">{t('pit_board')}</span>
                <div class="text-[11px] font-black italic {isSimulating ? 'text-emerald-400' : 'text-app-text/40'}">
                    {isSimulating ? t('track_status_live') : lastResult ? t('garage_status_debrief') : t('track_status_pits_open')}
                </div>
            </div>
            <div class="flex items-end justify-between">
                <div class="space-y-1">
                    <div class="flex items-center gap-3">
                        <p class="text-[20px] font-black italic text-app-text font-mono leading-none">{lastResult ? formatTime(lastResult.lapTime) : "--:--.---"}</p>
                        {#if lastResult?.setupUsed?.tyreCompound}
                            <div class="w-5 h-5 rounded-full border flex items-center justify-center text-[10px] font-black 
                                {lastResult.setupUsed.tyreCompound === 'soft' ? 'bg-red-500 border-red-700 text-white' : 
                                 lastResult.setupUsed.tyreCompound === 'medium' ? 'bg-yellow-500 border-yellow-700 text-black' : 
                                 lastResult.setupUsed.tyreCompound === 'hard' ? 'bg-white border-gray-300 text-black' : 
                                 'bg-blue-500 border-blue-700 text-white'} shadow-sm">
                                {lastResult.setupUsed.tyreCompound[0].toUpperCase()}
                            </div>
                        {/if}
                    </div>
                    <p class="text-[9px] font-bold text-app-text/30 uppercase tracking-tighter">
                        {t('last_outing_result')} {#if lastResult}• <span class="{getConfidenceColor(lastResult.setupConfidence)}">{t('confidence_label')} {(lastResult.setupConfidence*100).toFixed(0)}%</span>{/if}
                    </p>
                </div>
                {#if lastResult?.isCrashed}
                    <div class="px-2 py-1 rounded bg-red-500 text-white text-[9px] font-black uppercase animate-bounce">{t('accident_label')}</div>
                {/if}
            </div>
        </div>

        <!-- UNIFIED HISTORY -->
        <div class="bg-app-surface border border-app-border rounded-2xl flex flex-col h-[400px] shadow-2xl overflow-hidden">
            <div class="bg-app-text/2 border-b border-app-border px-4 py-3">
                <h3 class="text-[10px] font-black text-app-primary uppercase tracking-[0.2em]">{t('lap_history')}</h3>
            </div>

            <div class="flex-1 overflow-y-auto p-4 custom-scrollbar">
                <div class="space-y-3">
                    {#if enrichedHistory.length === 0}
                        <div class="py-10 text-center text-app-text/20 text-[10px] italic">{t('no_laps_recorded')}</div>
                    {:else}
                        {@const validLaps = enrichedHistory.filter(h => !h.isCrashed && h.lapTime > 0)}
                        {@const bestTime = validLaps.length > 0 ? Math.min(...validLaps.map(h => h.lapTime)) : 0}
                        {#each enrichedHistory as lap, i}
                            {@const lapDriver = teamDrivers.find(d => d.id === lap.driverId)}
                            <div class="p-3 rounded-xl border transition-all {lap.lapTime === bestTime && !lap.isCrashed ? 'bg-[#E040FB]/5 border-[#E040FB]/30' : 'bg-app-text/2 border-transparent hover:border-app-text/10'}">
                                <div class="flex items-center justify-between mb-2">
                                    <div class="flex flex-col">
                                        <div class="flex items-center gap-2">
                                            <span class="text-[9px] font-black text-app-primary uppercase">{t('lap_number', { n: (lap as any).lapIndex })}</span>
                                            <span class="text-[13px] font-black font-mono {lap.lapTime === bestTime && !lap.isCrashed ? 'text-[#E040FB]' : 'text-app-text'}">{formatTime(lap.lapTime)}</span>
                                            {#if lap.setupUsed?.tyreCompound}
                                                <div class="w-3.5 h-3.5 rounded-full border flex items-center justify-center text-[7px] font-black 
                                                    {lap.setupUsed.tyreCompound === 'soft' ? 'bg-red-500 border-red-700 text-white' : 
                                                     lap.setupUsed.tyreCompound === 'medium' ? 'bg-yellow-500 border-yellow-700 text-black' : 
                                                     lap.setupUsed.tyreCompound === 'hard' ? 'bg-white border-gray-300 text-black' : 
                                                     'bg-blue-500 border-blue-700 text-white'}">
                                                    {lap.setupUsed.tyreCompound[0].toUpperCase()}
                                                </div>
                                            {/if}
                                            {#if lap.isCrashed}<span class="text-[8px] bg-red-500 px-1 rounded font-black text-white">DNF</span>{/if}
                                        </div>
                                        <div class="flex items-center gap-1.5 opacity-40">
                                            <span class="text-[8px] font-black uppercase text-app-text">{lapDriver?.name || 'Unknown'}</span>
                                            <span class="text-[8px]">•</span>
                                            <span class="text-[8px] font-black text-app-text uppercase">{t('confidence_label')} {(lap.setupConfidence * 100).toFixed(0)}%</span>
                                        </div>
                                    </div>
                                    <div class="text-right">
                                        <div class="text-[8px] font-black text-app-text/30 uppercase italic">{formatDisplayDate(lap.timestamp)}</div>
                                    </div>
                                </div>
                                
                                <div class="mt-2 space-y-1 border-t border-app-text/5 pt-2">
                                    {#if lap.feedback && lap.feedback.length > 0}
                                        {#each lap.feedback as msg}
                                            <div class="text-[10px] italic text-app-text/70 leading-tight flex gap-2 items-start bg-app-text/0 hover:bg-app-text/5 p-1 rounded transition-colors">
                                                <span class="text-app-primary font-bold mt-0.5">•</span>
                                                <span>{msg}</span>
                                            </div>
                                        {/each}
                                    {:else if !lap.isCrashed}
                                        <div class="text-[10px] italic text-emerald-500/60 leading-tight flex gap-2 items-start p-1">
                                            <CheckCircle2 size={10} class="mt-0.5" />
                                            <span>{t('balance_good')}</span>
                                        </div>
                                    {/if}
                                </div>
                            </div>
                        {/each}
                    {/if}
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    .custom-scrollbar::-webkit-scrollbar { width: 3px; }
    .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
    .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(197, 160, 89, 0.2); border-radius: 10px; }
    .no-scrollbar::-webkit-scrollbar { display: none; }
    .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
