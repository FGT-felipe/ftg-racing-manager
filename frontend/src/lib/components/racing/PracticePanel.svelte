<script lang="ts">
    import { carSetupService } from "$lib/services/car_setup_service.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { youthAcademyStore } from "$lib/stores/youthAcademy.svelte";
    import { setupStore, type PracticeHistoryItem } from "$lib/stores/setup.svelte";
    import {
        raceService,
    } from "$lib/services/race_service.svelte";
    import {
        practiceService,
        type PracticeRunResult,
    } from "$lib/services/practice_service.svelte";
    import { MAX_PRACTICE_LAPS_PER_DRIVER, PRACTICE_SESSION_COST } from "$lib/constants/app_constants";
    import { MORALE_DEFAULT, ACADEMY_PRACTICE_XP_PER_LAP, ACADEMY_PRACTICE_STAT_THRESHOLD } from "$lib/constants/economics";
    import { uiStore } from "$lib/stores/ui.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { universeStore } from "$lib/stores/universe.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
import { circuitService } from "$lib/services/circuit_service.svelte";
    import {
        type CarSetup,
        TyreCompound,
        DriverStyle,
        type Driver,
        type YoungDriver,
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
        MessageSquare,
        Target,
        Activity,
        Lock,
    } from "lucide-svelte";
    import { onMount, untrack } from "svelte";
    import { fade, slide } from "svelte/transition";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import Typewriter from "$lib/components/ui/Typewriter.svelte";
    import { t, type TranslationKey } from "$lib/utils/i18n";
    import { formatDriverName } from "$lib/utils/driver";

    let { driverId = null, isTrainee = false, trainee = null, mainDriverId = null } = $props();

    /**
     * Builds a synthetic Driver shape from a YoungDriver so it can be passed
     * to simulatePracticeRun(). Uses carIndex=0 (main car slot).
     * Feedback stat is degraded (60% of baseSkill) to reflect the trainee's
     * limited circuit knowledge.
     */
    function traineeAsDriver(tr: YoungDriver, teamId: string): Driver {
        const s = tr.stats ?? {};
        return {
            id: tr.id,
            teamId,
            carIndex: 0,
            name: tr.name,
            age: tr.age,
            gender: tr.gender === 'M' ? 'male' : 'female',
            countryCode: tr.countryCode,
            role: 'reserve',
            salary: tr.salary,
            contractYearsRemaining: 0,
            potential: tr.potentialStars,
            currentStars: 1,
            specialty: tr.specialty ?? null,
            stats: {
                braking:      s['braking']      ?? tr.baseSkill,
                cornering:    s['cornering']     ?? tr.baseSkill,
                focus:        s['focus']         ?? tr.baseSkill,
                fitness:      s['fitness']       ?? 80,
                adaptability: s['adaptability']  ?? tr.baseSkill,
                consistency:  s['consistency']   ?? tr.baseSkill,
                smoothness:   s['smoothness']    ?? tr.baseSkill,
                overtaking:   s['overtaking']    ?? tr.baseSkill,
                feedback:     Math.max(1, Math.floor(tr.baseSkill * 0.6)),
                morale:       s['morale']        ?? MORALE_DEFAULT,
            },
            traits: [],
            statPotentials: {},
            weeklyGrowth: {},
            points: 0, championships: 0, races: 0, wins: 0, podiums: 0, poles: 0,
            seasonPoints: 0, seasonRaces: 0, seasonWins: 0, seasonPodiums: 0, seasonPoles: 0,
            form: 0, championshipForm: [], marketValue: 0, currentHighestBid: 0,
            negotiationAttempts: 0, isTransferListed: false, statusTitle: 'Trainee',
        } as unknown as Driver;
    }

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
    let pitBoardMessages = $state<string[]>([]);
    let lapsToRun = $state(1);
    let driverDialogue = $state<string | null>(null);
    let competitorTimes = $state<Array<{ teamName: string; driverName: string; time: number | null; tyre: string | null; totalLaps: number; driverId: string }>>([]);
    let telemetryTab = $state<'history' | 'standings'>('history');

    // Derived states
    const teamDrivers = $derived(driverStore.drivers);
    const driver = $derived(teamDrivers.find((d: any) => d.id === driverId));
    const nextEvent = $derived(seasonStore.nextEvent);
    const circuit = $derived(nextEvent ? circuitService.getCircuitProfile(nextEvent.circuitId) : null);
    
    /** Unique ID for this race-weekend session, e.g. "S2_r6". */
    const currentSessionId = $derived(
        seasonStore.value.season && nextEvent
            ? `${seasonStore.value.season.id}_${nextEvent.id}`
            : null
    );

    /**
     * Returns true if the saved practice data belongs to the current race round.
     * A missing sessionId is treated as stale (prior-round data) because every
     * practice write from v1.5+ tags the session. This prevents R(N) state from
     * leaking into R(N+1) when post-race processing doesn't clear driverSetups.
     */
    function isCurrentSession(practiceData: any): boolean {
        if (!practiceData) return false;
        if (!currentSessionId) return false;
        if (!practiceData.sessionId) return false; // missing tag → previous-round data
        return practiceData.sessionId === currentSessionId;
    }

    const driverPracticeLaps = $derived.by(() => {
        if (!driverId) return 0;
        const pd = teamStore.value.team?.weekStatus?.driverSetups?.[driverId]?.practice;
        if (!isCurrentSession(pd)) return 0;
        return pd?.laps || 0;
    });

    const enrichedHistory = $derived.by(() => {
        if (!driver || !teamStore.value.team) return [];
        const team = teamStore.value.team;
        const driverSetup = team.weekStatus?.driverSetups?.[driver.id] || {};
        // Session gate: practiceRuns[] is not cleared between rounds, so read
        // it only when the session matches the current round.
        if (!isCurrentSession(driverSetup.practice)) return [];
        const hist = setupStore.getHistoryByDriver(driver.id);
        const legacy = (driverSetup.practiceRuns || []).map((run: any, idx: number) => ({
            id: `legacy-${idx}`,
            driverId: driver.id,
            lapTime: run.time,
            setupUsed: run.setupUsed,
            feedback: [],
            setupConfidence: 0,
            isCrashed: !!run.isCrashed,
            timestamp: null,
        }));
        const combined = [...hist, ...legacy];
        return combined.reverse(); // Simplified for now
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

    const isSaturdayAfter1PM = $derived.by(() => {
        try {
            const now = new Date();
            const bogota = new Intl.DateTimeFormat('en-US', {
                timeZone: 'America/Bogota',
                weekday: 'long',
                hour: 'numeric',
                hour12: false
            });
            const parts = bogota.formatToParts(now);
            const weekday = parts.find(p => p.type === 'weekday')?.value;
            const hourValue = parts.find(p => p.type === 'hour')?.value;
            const hour = parseInt(hourValue || '0');
            
            return weekday === 'Saturday' && hour >= 13;
        } catch (e: any) {
            console.error('[PracticePanel] COT check error:', e.message);
            return false;
        }
    });

    const driverQualyAttempts = $derived.by(() => {
        if (!driverId) return 0;
        const driverSetup = teamStore.value.team?.weekStatus?.driverSetups?.[driverId];
        if (!driverSetup) return 0;
        // Gate on session: if practice data is stale, qualifying attempts are too
        if (!isCurrentSession(driverSetup.practice)) return 0;
        return driverSetup.qualifyingAttempts || 0;
    });

    const traineePracticeUsed = $derived(teamStore.value.team?.weekStatus?.traineePracticeUsed ?? null);

    const isPracticeLocked = $derived(
        driverQualyAttempts > 0 ||
        isSaturdayAfter1PM ||
        (!isTrainee && !!traineePracticeUsed && (driver?.carIndex === 0 || driver?.role === 'main' || driver?.role === 'Main'))
    );

    async function refreshStandings() {
        const team = teamStore.value.team;
        const season = seasonStore.value.season;
        const event = nextEvent;
        if (!team || !season || !event) return;

        const league = universeStore.getLeagueByTeamId(team.id);
        const teamIds = league?.teams?.map((t: any) => t.id) || [];
        const teamNames: Record<string, string> = {};
        league?.teams?.forEach((t: any) => { teamNames[t.id] = t.name; });

        if (teamIds.length === 0) return;
        const sessionId = `${season.id}_${event.id}`;
        const times = await raceService.getCompetitorPracticeTimes(sessionId, teamIds, teamNames);
        competitorTimes = times;
    }

    $effect(() => {
        if (teamStore.value.team && !teamStore.value.loading && !universeStore.value.loading && !seasonStore.value.loading) {
            refreshStandings();
        }
    });

    onMount(() => {
        if (teamStore.value.team?.id) {
            setupStore.init(teamStore.value.team.id);
        }
    });

    $effect(() => {
        if (driverId) {
            untrack(() => {
                const team = teamStore.value.team;
                const savedSetup = team?.weekStatus?.driverSetups?.[driverId]?.practice;
                // Only restore setup if it belongs to the current race round
                if (savedSetup && isCurrentSession(savedSetup)) {
                    setup = { ...setup, ...savedSetup };
                }
            });
        }
    });

    $effect(() => {
        if (driverId && !isSimulating) {
            const team = teamStore.value.team;
            if (!team) return;

            const practiceData = team.weekStatus?.driverSetups?.[driverId]?.practice;

            // Ignore data from previous race rounds — their setup hints target the wrong circuit
            if (!isCurrentSession(practiceData)) {
                lastResult = null;
                return;
            }

            if (practiceData?.lastResult || practiceData?.sessionFeedback) {
                lastResult = {
                    lapTime: practiceData.lastResult?.lapTime || 0,
                    setupConfidence: practiceData.lastResult?.setupConfidence || 0,
                    isCrashed: practiceData.lastResult?.isCrashed || false,
                    setupUsed: practiceData.lastResult?.setupUsed || setup,
                    setupHints: practiceData.lastResult?.setupHints,
                    driverFeedback: practiceData.sessionFeedback || [],
                    tyreFeedback: []
                };
            } else {
                lastResult = null;
            }
        }
    });

    async function runPractice() {
        const team = teamStore.value.team;
        const currentCircuit = circuit;
        if (!currentCircuit || !team) return;

        const currentDriver = isTrainee && trainee
            ? traineeAsDriver(trainee, team.id)
            : driver;

        if (!currentDriver) return;

        isSimulating = true;
        const weekStatus = team.weekStatus || {};
        const practicePaid = weekStatus.practicePaid || {};
        const hasPaid = practicePaid[currentDriver.id];

        if (!hasPaid) {
            if (team.budget < PRACTICE_SESSION_COST) {
                uiStore.alert(t('insufficient_funds'), t('insufficient_funds'), 'danger');
                isSimulating = false;
                return;
            }
            try {
                await carSetupService.payPracticeFee(team.id, team.budget, currentDriver.id, currentDriver.name);
            } catch (err) { console.error('[PracticePanel:runPractice] Fee error:', err); isSimulating = false; return; }
        }

        const setupToRun = { ...setup, qualifyingStyle: currentDriverStyle };
        const sessionFeedbackSet = new Set<string>();
        const sessionLapTimes: number[] = [];
        let bestSessionResult: PracticeRunResult | null = null;
        
        driverDialogue = t('leaving_pits');
        pitBoardMessages = [driverDialogue];
        
        try {
            for (let i = 0; i < lapsToRun; i++) {
                // Narrative: Start of lap
                pitBoardMessages = [`Lap ${i+1}: Pushing hard...`, ...pitBoardMessages].slice(0, 50);
                await new Promise((r) => setTimeout(r, 600));

                const result = practiceService.simulatePracticeRun(currentCircuit, team, currentDriver, setupToRun, nextEvent?.weatherPractice || "Sunny");
                
                // Narrative: Sectors
                const s1Time = (result.lapTime / 3) + (Math.random() * 0.5 - 0.25);
                const s2Time = (result.lapTime / 3) + (Math.random() * 0.5 - 0.25);
                
                pitBoardMessages = [`Sector 1: ${s1Time.toFixed(3)}s`, ...pitBoardMessages].slice(0, 50);
                await new Promise((r) => setTimeout(r, 800));
                
                pitBoardMessages = [`Sector 2: ${s2Time.toFixed(3)}s`, ...pitBoardMessages].slice(0, 50);
                await new Promise((r) => setTimeout(r, 800));

                // Collection for summary
                sessionLapTimes.push(result.lapTime);

                // Aggregate unique feedback messages for the session but DO NOT show yet!
                result.driverFeedback.forEach(f => sessionFeedbackSet.add(f));
                result.tyreFeedback.forEach(f => sessionFeedbackSet.add(f));
                
                if (!bestSessionResult || (result.lapTime < bestSessionResult.lapTime && !result.isCrashed)) {
                    bestSessionResult = result;
                }

                // Show lap time in pit board
                const crashSuffix = result.isCrashed ? " - CRASHED" : "";
                pitBoardMessages = [`L${i+1} COMPLETED: ${formatTime(result.lapTime)}${crashSuffix}`, ...pitBoardMessages].slice(0, 50);

                // Wait for the lap to "finish"
                await new Promise((r) => setTimeout(r, 1200));
                if (result.isCrashed) break;
            }

            // Save ONCE per session with aggregated results
            if (bestSessionResult) {
                driverDialogue = t('returning_pits_good');
                pitBoardMessages = [driverDialogue, ...pitBoardMessages].slice(0, 50);
                
                // Add a small "debrief" delay before showing the final result with new feedback
                await new Promise((r) => setTimeout(r, 1000));
                pitBoardMessages = ["Debriefing with engineers...", ...pitBoardMessages].slice(0, 50);
                await new Promise((r) => setTimeout(r, 1500));

                // ADD STINT SUMMARY to Pit Board
                const bestTime = Math.min(...sessionLapTimes);
                const summaryMessages = [
                    "--- STINT SUMMARY ---",
                    ...sessionLapTimes.map((t, idx) => `Lap ${idx + 1}: ${formatTime(t)}${t === bestTime ? ' (BEST)' : ''}`),
                    "---------------------"
                ].reverse();
                
                pitBoardMessages = [...summaryMessages, ...pitBoardMessages].slice(0, 100);

                const sessionResult = {
                    ...bestSessionResult,
                    driverFeedback: Array.from(sessionFeedbackSet)
                };

                // NOW we update lastResult to trigger the speech bubble
                lastResult = sessionResult;

                if (isTrainee && trainee && mainDriverId) {
                    await youthAcademyStore.runTraineePractice(
                        trainee.id,
                        mainDriverId,
                        sessionResult,
                        setupToRun,
                        lapsToRun
                    );
                } else {
                    const sessionId = `${seasonStore.value.season?.id}_${nextEvent?.id}`;
                    await practiceService.savePracticeRun(
                        teamStore.value.team!,
                        currentDriver.id,
                        sessionResult,
                        setupToRun,
                        sessionId,
                        lapsToRun,
                        currentDriver.stats
                    );
                }
                await refreshStandings();
            }
        } catch (e) { console.error(e); }
        isSimulating = false;
        setTimeout(() => { driverDialogue = null; }, 5000);
    }

    async function copyToQualifying() {
        if (!driver || !teamStore.value.team) return;
        try {
            await carSetupService.saveQualyResult(
                teamStore.value.team.id,
                driver.id,
                {
                    [`weekStatus.driverSetups.${driver.id}.qualifying`]: { ...setup },
                    [`weekStatus.driverSetups.${driver.id}.isSetupSent`]: true,
                },
                false,
            );
            uiStore.alert(t('set_qualy'), t('copy_practice_to_qualy'), 'success');
        } catch (e) { console.error('[PracticePanel:copyToQualifying] Error:', e); }
    }

    async function copyToRace() {
        if (!driver || !teamStore.value.team) return;
        try {
            await carSetupService.saveRaceSetup(teamStore.value.team.id, driver.id, setup);
            uiStore.alert(t('set_race'), t('copy_practice_to_race'), 'success');
        } catch (e) { console.error('[PracticePanel:copyToRace] Error:', e); }
    }

    function getConfidenceColor(conf: number) {
        if (conf > 0.9) return "text-emerald-400";
        if (conf > 0.7) return "text-emerald-500/80";
        if (conf > 0.4) return "text-yellow-400";
        return "text-red-400";
    }

    function formatTime(seconds: number) {
        if (seconds >= 999) return "DNF";
        const mins = Math.floor(seconds / 60);
        const secs = (seconds % 60).toFixed(3);
        const parts = secs.split('.');
        return `${mins}:${parts[0].padStart(2, '0')}.${parts[1]}`;
    }

    const traineeXpEarned = $derived(lapsToRun * ACADEMY_PRACTICE_XP_PER_LAP);
    const traineeStatEligible = $derived(
        !!lastResult && lapsToRun >= ACADEMY_PRACTICE_STAT_THRESHOLD && !lastResult.isCrashed
    );
    const traineeFitnessDisplay = $derived(
        isTrainee && trainee
            ? Math.round(((trainee.stats?.['fitness'] ?? 80)) * 10) / 10
            : Math.round((driver?.stats?.fitness || 100) * 10) / 10
    );
    const traineeMoraleDisplay = $derived(
        isTrainee && trainee
            ? (trainee.stats?.['morale'] ?? MORALE_DEFAULT)
            : (driver?.stats?.morale ?? MORALE_DEFAULT)
    );

    const styleConfigs = $derived.by(() => {
        const base = [
            { id: DriverStyle.defensive, icon: ChevronRight, color: "text-blue-400", label: "defensive" as TranslationKey },
            { id: DriverStyle.normal, icon: Zap, color: "text-emerald-400", label: "normal" as TranslationKey },
            { id: DriverStyle.offensive, icon: Zap, color: "text-orange-400", label: "offensive" as TranslationKey },
        ];

        if (managerStore.profile?.role === "ex_driver") {
            base.push({ id: DriverStyle.mostRisky, icon: Zap, color: "text-red-500", label: "risky" as TranslationKey });
        }

        return base;
    });
</script>

<div class="grid grid-cols-1 lg:grid-cols-12 gap-5" in:fade>
    <!-- LEFT: Setup & Controls (7 Cols) -->
    <div class="lg:col-span-7 space-y-5">
        {#if isTrainee && trainee}
            <div class="flex items-center gap-3 px-4 py-3 rounded-xl bg-emerald-900/30 border border-emerald-700/40 text-emerald-300">
                <Info size={14} class="shrink-0" />
                <span class="text-[10px] font-black uppercase tracking-widest">{t('academy_practice_feedback_note')}</span>
            </div>
        {/if}
        {#if !isTrainee && traineePracticeUsed && (driver?.carIndex === 0 || driver?.role === 'main' || driver?.role === 'Main')}
            <div class="flex items-center gap-3 px-4 py-3 rounded-xl bg-amber-900/30 border border-amber-700/40 text-amber-300">
                <Lock size={14} class="shrink-0" />
                <span class="text-[10px] font-black uppercase tracking-widest">{t('academy_practice_slot_locked')}</span>
            </div>
        {/if}
        {#if driver}
            <div class="space-y-3">
                <div class="bg-app-surface border border-app-border rounded-2xl p-6 shadow-2xl relative overflow-hidden group min-h-[160px] flex flex-col justify-center">
                    <div class="absolute top-0 right-0 w-32 h-32 bg-app-primary/5 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl pointer-events-none"></div>

                    <div class="flex items-start gap-6 relative">
                        <!-- BIG AVATAR -->
                        <div class="shrink-0 relative">
                            <div class="w-16 h-16 rounded-2xl bg-app-primary/10 border border-app-primary/20 flex items-center justify-center overflow-hidden shadow-inner ring-4 ring-app-primary/5">
                                <DriverAvatar
                                    id={isTrainee && trainee ? trainee.id : driver.id}
                                    seed={isTrainee && trainee ? trainee.id : driver.id}
                                    gender={isTrainee && trainee ? (trainee.gender === 'M' ? 'male' : 'female') : driver.gender}
                                    size={64}
                                />
                            </div>
                            <div class="absolute -bottom-1 -right-1 w-5 h-5 rounded-full bg-emerald-500 border-2 border-app-surface ring-1 ring-emerald-500/20 {isSimulating ? 'animate-pulse' : ''}"></div>
                        </div>

                        <!-- CONVERSATION BUBBLE -->
                        <div class="flex-1 space-y-3">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap-2">
                                    <span class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary leading-none">{isTrainee && trainee ? formatDriverName(trainee.name) : formatDriverName(driver.name)}</span>
                                    {#if isTrainee}<span class="px-1.5 py-0.5 rounded text-[7px] font-black uppercase tracking-widest bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">TRAINEE</span>{/if}
                                </div>
                                <div class="flex items-center gap-4 text-[9px] font-black uppercase text-app-text/30">
                                    <div class="flex items-center gap-1.5"><Bolt size={10} class="text-emerald-400" /> {traineeFitnessDisplay}%</div>
                                    <div class="flex items-center gap-1.5"><Smile size={10} class="text-yellow-400" /> {traineeMoraleDisplay}%</div>
                                </div>
                            </div>
                            {#if isSimulating}
                                <div in:fade class="text-[10px] font-black italic text-app-primary/60 uppercase tracking-widest animate-pulse flex items-center gap-2 mb-2">
                                    <div class="w-1.5 h-1.5 rounded-full bg-app-primary animate-ping"></div>
                                    {t('simulating_current_lap') || 'Simulating...'}
                                </div>
                                {#if driverDialogue}
                                    <div in:fade class="bg-app-text/5 rounded-2xl rounded-tl-none p-4 relative border border-white/5 mb-4 shadow-lg shadow-app-primary/5">
                                        <div class="absolute -left-2 top-0 w-2 h-2 bg-app-text/5 border-l border-t border-white/5" style="clip-path: polygon(100% 0, 0 0, 100% 100%);"></div>
                                        <p class="text-[11px] font-bold italic leading-relaxed text-app-text/90 flex gap-2">
                                            <span class="text-app-primary">“</span>
                                            <Typewriter text={driverDialogue} />
                                            <span class="text-app-primary">”</span>
                                        </p>
                                    </div>
                                {/if}
                            {:else if lastResult}
                                <div in:fade class="bg-app-text/5 rounded-2xl rounded-tl-none p-4 relative border border-white/5">
                                    <div class="absolute -left-2 top-0 w-2 h-2 bg-app-text/5 border-l border-t border-white/5" style="clip-path: polygon(100% 0, 0 0, 100% 100%);"></div>
                                    <div class="space-y-2">
                                        {#if lastResult.driverFeedback?.length}
                                            {#each lastResult.driverFeedback as msg}
                                                <p class="text-[11px] font-bold italic leading-relaxed text-app-text/90 flex gap-2">
                                                    <span class="text-app-primary">“</span>
                                                    <Typewriter text={msg} />
                                                    <span class="text-app-primary">”</span>
                                                </p>
                                            {/each}
                                        {:else}
                                            <p class="text-[11px] font-bold italic leading-relaxed text-app-text/60 flex gap-2">
                                                <span class="text-app-primary">“</span>
                                                <Typewriter text={t('balance_good')} />
                                                <span class="text-app-primary">”</span>
                                            </p>
                                        {/if}
                                    </div>
                                </div>
                            {:else if !isSimulating}
                                <p class="text-[11px] font-black italic text-app-text/20 uppercase tracking-widest leading-relaxed flex gap-2">
                                    <span class="text-app-primary/40">“</span>
                                    <Typewriter text={t('awaiting_orders')} />
                                    <span class="text-app-primary/40">”</span>
                                </p>
                            {/if}
                        </div>
                    <!-- Trainee XP / stat reward preview -->
                    {#if isTrainee && trainee && lastResult && !isSimulating}
                        <div in:fade class="mt-4 pt-4 border-t border-white/5 flex flex-wrap gap-3">
                            <div class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-900/30 border border-emerald-700/30 text-emerald-400">
                                <Target size={11} />
                                <span class="text-[9px] font-black uppercase tracking-widest">{t('academy_practice_xp_earned', { xp: String(traineeXpEarned) })}</span>
                            </div>
                            {#if traineeStatEligible}
                                <div class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-cyan-900/30 border border-cyan-700/30 text-cyan-400">
                                    <Activity size={11} />
                                    <span class="text-[9px] font-black uppercase tracking-widest">{t('academy_practice_stat_gained', { stat: 'lowest stat' })}</span>
                                </div>
                            {/if}
                        </div>
                    {/if}
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
                    <button onclick={copyToRace} class="px-3 py-1.5 rounded-lg border border-app-fastest/20 bg-app-fastest/5 text-app-fastest text-[9px] font-black uppercase hover:bg-app-fastest hover:text-white transition-all flex items-center gap-1.5">
                        <Flag size={12} /> {t('set_race')}
                    </button>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-5">
                {#each [
                    { label: t('front_wing'), field: "frontWing" as const, icon: Wind, color: "text-cyan-400" },
                    { label: t('rear_wing'), field: "rearWing" as const, icon: Wind, color: "text-cyan-400" },
                    { label: t('suspension'), field: "suspension" as const, icon: Navigation, color: "text-purple-400" },
                    { label: t('gear_ratio'), field: "gearRatio" as const, icon: Zap, color: "text-orange-400" }
                ] as item}
                    <div class="space-y-2 group">
                        <div class="flex justify-between items-center text-[10px] font-black uppercase">
                            <div class="flex items-center gap-2 {item.color}"><item.icon size={12} /> {item.label}</div>
                            <span class="text-app-text font-mono">{setup[item.field]}</span>
                        </div>
                        <div class="relative h-6 flex items-center">
                            {#if lastResult?.setupHints?.[item.field]}
                                {@const hint = lastResult.setupHints[item.field]}
                                <div 
                                    class="absolute h-1.5 bg-app-fastest/30 rounded-full blur-[1px] border-x border-app-fastest/50 transition-all duration-500"
                                    style="left: {hint.min}%; width: {hint.max - hint.min}%"
                                    title="Estimated ideal range"
                                ></div>
                            {/if}
                            <input 
                                type="range" 
                                min="0" 
                                max="100" 
                                bind:value={setup[item.field]} 
                                class="w-full h-1 bg-app-text/10 rounded-full accent-emerald-500 cursor-pointer appearance-none hover:bg-app-text/20 transition-all z-10" 
                            />
                        </div>
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
                    <button 
                        disabled={isSimulating || !driver || isPracticeLocked} 
                        onclick={runPractice} 
                        class="flex-[1.5] py-3 bg-app-primary text-black font-black uppercase tracking-widest text-[11px] rounded-xl hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 disabled:scale-100 flex items-center justify-center gap-2 shadow-lg shadow-app-primary/20"
                    >
                        {#if isSimulating}
                            {t('simulating_laps')}
                        {:else if isPracticeLocked}
                            {isSaturdayAfter1PM ? "PRACTICE EXPIRED" : "QUALY STARTED"}
                        {:else}
                            {t('start_practice')}
                        {/if}
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!-- RIGHT: Telemetry & Standings (5 Cols) -->
    <div class="lg:col-span-5 space-y-5">
        <!-- Global Standings Table -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl flex flex-col overflow-hidden shadow-xl"
        >
            <div
                class="bg-app-primary/10 border-b border-app-primary/20 px-4 py-3 flex items-center justify-between"
            >
                <div class="flex items-center gap-2">
                    <Flag size={14} class="text-app-primary" />
                    <span
                        class="text-[10px] font-black uppercase tracking-widest text-app-primary"
                        >{t('standings')}</span
                    >
                </div>
                <button 
                    onclick={refreshStandings}
                    class="text-[9px] font-black uppercase text-app-text/40 hover:text-app-primary transition-colors flex items-center gap-1"
                >
                    <Activity size={10} />
                    Sync
                </button>
            </div>

            <!-- Table Header -->
            <div class="flex px-4 py-2 bg-app-text/5 border-b border-app-border">
                <span class="w-8 text-[9px] font-black text-app-text/30 uppercase"
                    >Pos</span
                >
                <span
                    class="flex-1 text-[9px] font-black text-app-text/30 uppercase"
                    >{t('driver')} / {t('team')}</span
                >
                <span
                    class="w-12 text-[9px] font-black text-app-text/30 uppercase text-center"
                    >Tyre</span
                >
                <span
                    class="w-20 text-[9px] font-black text-app-text/30 uppercase text-right"
                    >{t('best_lap')}</span
                >
                <span
                    class="w-16 text-[9px] font-black text-app-text/30 uppercase text-right"
                    >{t('gap')}</span
                >
            </div>

            <!-- Table Body -->
            <div class="flex-1 overflow-y-auto custom-scrollbar p-2 max-h-[300px]">
                {#if competitorTimes.length === 0}
                    <div class="p-8 text-center opacity-20">
                        <Activity size={24} class="mx-auto mb-2" />
                        <p class="text-[9px] font-black uppercase tracking-widest text-app-text">{t('waiting_competitors')}</p>
                    </div>
                {:else}
                    {#each globalStandings as row}
                        <div
                            class="flex items-center px-2 py-2.5 rounded-lg {row.driverId ===
                            driverId
                                ? 'bg-app-primary/10 border border-app-primary/20'
                                : 'hover:bg-app-text/5'} transition-colors group"
                        >
                            <span
                                class="w-8 text-xs font-black {row.time !== null
                                    ? row.position <= 3
                                        ? 'text-app-primary'
                                        : 'text-app-text/80'
                                    : 'text-app-text/30'}"
                            >
                                {row.position}.
                            </span>

                            <div class="flex-1 min-w-0">
                                <div class="flex items-center gap-2">
                                    <span
                                        class="text-xs font-bold text-app-text truncate {row.driverId ===
                                        driverId
                                            ? 'text-app-primary'
                                            : 'group-hover:text-app-primary/80 transition-colors'}"
                                    >
                                        {row.driverName}
                                    </span>
                                </div>
                                <div class="text-[9px] font-medium text-app-text/40 uppercase tracking-tight">
                                    {row.teamName}
                                </div>
                            </div>

                            <div class="w-12 flex justify-center">
                                {#if row.tyre}
                                    <div
                                        class="w-2.5 h-2.5 rounded-full {row.tyre ===
                                        'soft'
                                            ? 'bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.4)]'
                                            : row.tyre === 'medium'
                                              ? 'bg-yellow-500 shadow-[0_0_8px_rgba(234,179,8,0.4)]'
                                              : row.tyre === 'hard'
                                                ? 'bg-zinc-100 shadow-[0_0_8px_rgba(255,255,255,0.2)]'
                                                : 'bg-blue-500 shadow-[0_0_8px_rgba(59,130,246,0.4)]'}"
                                    ></div>
                                {:else}
                                    <div class="w-2.5 h-2.5 rounded-full bg-app-text/10 overflow-hidden"></div>
                                {/if}
                            </div>

                            <div class="w-20 text-right">
                                <span
                                    class="text-xs font-black italic {row.time !== null
                                        ? 'text-app-text'
                                        : 'text-app-text/20'}"
                                >
                                    {formatTime(row.time ?? 0)}
                                </span>
                            </div>

                            <div class="w-16 text-right">
                                <span class="text-[10px] font-bold {row.position === 1 ? 'text-app-primary/40' : 'text-app-text/40'}">
                                    {row.position === 1 ? 'Interval' : row.gap ? `+${row.gap.toFixed(3)}s` : '--'}
                                </span>
                            </div>
                        </div>
                    {/each}
                {/if}
            </div>
        </div>

        <!-- Pit Board System -->
        <div class="bg-app-surface border border-app-border rounded-2xl flex flex-col h-[180px] overflow-hidden shadow-xl">
            <div class="bg-app-surface/40 px-3 py-2 border-b border-app-border/40 flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <div class="w-1.5 h-1.5 rounded-full bg-app-primary animate-pulse"></div>
                    <span class="text-[9px] font-black uppercase tracking-widest text-app-text/60">{t('pit_board')}</span>
                </div>
                {#if lastResult?.isCrashed}
                    <div class="flex items-center gap-1 text-red-500 animate-[pulse_1s_infinite]">
                        <AlertTriangle size={12} />
                        <span class="text-[9px] font-black uppercase tracking-tighter">{t('accident_label')}</span>
                    </div>
                {:else}
                    <span class="text-[9px] font-black uppercase text-app-primary/60">Box. Box. Box.</span>
                {/if}
            </div>
            
            <div class="flex-1 bg-black/40 p-3 font-mono text-[11px] space-y-1.5 overflow-y-auto custom-scrollbar no-scrollbar">
                {#if isSimulating || pitBoardMessages.length > 0}
                    {#each pitBoardMessages as msg, i}
                        <div in:fade={{duration: 200}} class="flex gap-2 {i === 0 ? 'text-app-primary font-bold' : 'text-app-text/40'}">
                            <span class="opacity-30">[{new Date().toLocaleTimeString([], {hour12: false, minute:'2-digit', second:'2-digit'})}]</span>
                            <span>{msg}</span>
                        </div>
                    {/each}
                {:else}
                    <div class="h-full flex flex-col items-center justify-center text-app-text/20 italic">
                        <Navigation size={24} class="mb-2 opacity-20" />
                        <span>Awaiting Session Start</span>
                    </div>
                {/if}
            </div>
        </div>
    </div>
</div>

<style>
    .custom-scrollbar::-webkit-scrollbar { width: 3px; }
    .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
    .custom-scrollbar::-webkit-scrollbar-thumb { background: rgba(var(--primary-color-rgb), 0.2); border-radius: 10px; }
    .no-scrollbar::-webkit-scrollbar { display: none; }
    .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
