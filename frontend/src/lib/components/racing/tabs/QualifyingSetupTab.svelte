<script lang="ts">
    import { increment } from "firebase/firestore";
    import { carSetupService } from "$lib/services/car_setup_service.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import {
        type CarSetup,
        TyreCompound,
        DriverStyle,
        type Driver,
    } from "$lib/types";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { circuitService } from "$lib/services/circuit_service.svelte";
    import { raceService } from "$lib/services/race_service.svelte";
    import { practiceService, type PracticeRunResult } from "$lib/services/practice_service.svelte";
    import { timeService } from "$lib/services/time_service.svelte";
    import { uiStore } from "$lib/stores/ui.svelte";
    import { QUALY_ENTRY_FEE } from "$lib/constants/economics";
    import {
        Timer,
        Zap,
        Wind,
        Navigation,
        AlertTriangle,
        Info,
        ChevronRight,
        Flag,
        Activity,
        Bolt,
        Smile,
        MessageSquare,
    } from "lucide-svelte";
    import { universeStore } from "$lib/stores/universe.svelte";
    import { onMount, untrack } from "svelte";
    import { fade, slide } from "svelte/transition";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import Typewriter from "$lib/components/ui/Typewriter.svelte";
    import { t } from "$lib/utils/i18n";
    import { formatDriverName } from "$lib/utils/driver";

    let { driverId } = $props<{ driverId: string | null }>();

    // Derived Data
    const teamDrivers = $derived(driverStore.drivers);
    const driver = $derived(teamDrivers.find((d: Driver) => d.id === driverId));
    const team = $derived(teamStore.value.team);
    const nextEvent = $derived(seasonStore.nextEvent);
    const circuit = $derived(
        nextEvent
            ? circuitService.getCircuitProfile(nextEvent.circuitId)
            : null,
    );


    // Setup State
    let setup = $state<CarSetup>({
        frontWing: 50,
        rearWing: 50,
        suspension: 50,
        gearRatio: 50,
        tyreCompound: TyreCompound.soft,
        pitStops: [],
        initialFuel: 10,
        pitStopFuel: [],
        qualifyingStyle: DriverStyle.normal,
        raceStyle: DriverStyle.normal,
        pitStopStyles: [],
    });

    let lastResult = $state<PracticeRunResult | null>(null);

    // Qualifying State
    const MAX_ATTEMPTS = 6;
    let isSimulating = $state(false);
    let pitBoardMessages = $state<string[]>([]);
    let competitorTimes = $state<Array<{ teamName: string; driverName: string; time: number | null; tyre: string | null; totalLaps: number; driverId: string; gender: string }>>([]);
    let driverDialogue = $state<string | null>(null);

    let driverStatus = $derived.by(() => {
        if (!team || !driverId) return null;
        return team.weekStatus?.driverSetups?.[driverId];
    });

    let attempts = $derived(driverStatus?.qualifyingAttempts || 0);
    let bestTime = $derived(driverStatus?.qualifyingBestTime || 0);
    let isDnf = $derived(driverStatus?.qualifyingDnf || false);
    
    // Wet Track Detection
    const isWetSession = $derived(nextEvent?.weatherQualifying?.toLowerCase().includes('rain') || nextEvent?.weatherQualifying?.toLowerCase().includes('wet'));
    const needsWetTyres = $derived(isWetSession && setup.tyreCompound !== TyreCompound.wet);
    let isParcFerme = $derived(!isWetSession && (driverStatus?.qualifyingParcFerme || false));

    // Table Data
    const globalStandings = $derived.by(() => {
        if (competitorTimes.length === 0) return [];
        const leaderTime = competitorTimes.find(c => c.time !== null)?.time || null;
        return competitorTimes.map((s, idx) => ({
            ...s,
            position: idx + 1,
            gap: (s.time !== null && leaderTime !== null) ? s.time - leaderTime : null
        }));
    });

    async function refreshStandings() {
        if (!team || !seasonStore.value.season || !nextEvent) return;

        const league = universeStore.getLeagueByTeamId(team.id);
        const teamIds = league?.teams?.map((t: any) => t.id) || [];
        const teamNames: Record<string, string> = {};
        league?.teams?.forEach((t: any) => { teamNames[t.id] = t.name; });

        if (teamIds.length === 0) return;
        const sessionId = `${seasonStore.value.season.id}_${nextEvent.id}`;
        const times = await raceService.getCompetitorQualifyingTimes(sessionId, teamIds, teamNames);
        competitorTimes = times;
    }

    $effect(() => {
        if (team && !teamStore.value.loading && !universeStore.value.loading && !seasonStore.value.loading) {
            refreshStandings();
        }
    });

    // Watch for driver changes to load their QUALY setup and results
    $effect(() => {
        if (driverId && team) {
            untrack(() => {
                const driverData = team.weekStatus?.driverSetups?.[driverId];
                const existing = driverData?.qualifying;
                
                if (existing) {
                    setup = { ...setup, ...existing };
                } else {
                    // Fallback to practice if Qualy doesn't exist yet
                    const prac = driverData?.practice;
                    if (prac) setup = { ...setup, ...prac };
                }

                // Load last result if available, fallback to practice hints if no Qualy results yet
                if (driverData?.lastQualyResult) {
                    lastResult = driverData.lastQualyResult;
                } else if (driverData?.practice?.lastResult) {
                    // Start with basic structure from practice if we have no qualy results yet
                    lastResult = {
                        ...driverData.practice.lastResult,
                        isQualyFallback: true // Flag to distinguish it's from Practice
                    } as any;
                } else {
                    lastResult = null;
                }
            });
        }
    });

    async function runQualyAttempt() {
        if (!driver || !circuit || !team) return;
        if (attempts >= MAX_ATTEMPTS || isDnf) return;

        isSimulating = true;

        try {
            // First attempt charges the $10,000 Entry Fee
            if (attempts === 0) {
                const cost = QUALY_ENTRY_FEE;
                if (team.budget < cost) {
                    uiStore.alert(
                        t('insufficient_funds_qualy'),
                        t('insufficient_funds'),
                        "danger"
                    );
                    isSimulating = false;
                    return;
                }
                await carSetupService.chargeQualyFee(team.id, cost);
            }

            // Copy setup for sim
            const setupToRun = {
                ...setup,
                qualifyingStyle: setup.qualifyingStyle,
            };

            // Simulate Flying Lap
            driverDialogue = t('leaving_pits');
            pitBoardMessages = [driverDialogue];
            await new Promise((r) => setTimeout(r, 1000));
            
            driverDialogue = t('starting_flying_lap');
            pitBoardMessages = [driverDialogue, ...pitBoardMessages].slice(0, 50);
            await new Promise((r) => setTimeout(r, 1000));

            const result = practiceService.simulatePracticeRun(
                circuit,
                team,
                driver,
                setupToRun,
                nextEvent?.weatherQualifying || "Sunny",
                true // isQualifying
            );

            if (result.fitnessPenalty) {
                const newFitness = Math.max(0, Math.min(100, (driver.stats.fitness || 100) - result.fitnessPenalty));
                await carSetupService.applyFitnessPenalty(driver.id, newFitness);
                pitBoardMessages = [t('qualy_fitness_impact', {name: driver.name}), ...pitBoardMessages].slice(0, 50);
            }

            // Simulation Narrative
            pitBoardMessages = [t('qualy_pushing_limit'), ...pitBoardMessages].slice(0, 50);
            await new Promise((r) => setTimeout(r, 1200));

            const s1Time = (result.lapTime / 3) + (Math.random() * 0.4 - 0.2);
            pitBoardMessages = [`${t('sector_1')}: ${s1Time.toFixed(3)}s`, ...pitBoardMessages].slice(0, 50);
            await new Promise((r) => setTimeout(r, 1000));

            const s2Time = (result.lapTime / 3) + (Math.random() * 0.4 - 0.2);
            pitBoardMessages = [`${t('sector_2')}: ${s2Time.toFixed(3)}s`, ...pitBoardMessages].slice(0, 50);
            await new Promise((r) => setTimeout(r, 1000));

            const pathPrefix = `weekStatus.driverSetups.${driver.id}`;
            const newAttempts = attempts + 1;

            if (result.isCrashed) {
                const crashResult = {
                    lapTime: 999,
                    setupConfidence: result.setupConfidence,
                    isCrashed: true,
                    driverFeedback: result.driverFeedback,
                    tyreFeedback: result.tyreFeedback,
                    setupUsed: setupToRun,
                    setupHints: result.setupHints
                };
                lastResult = crashResult;

                await carSetupService.saveQualyResult(
                    team.id,
                    driver.id,
                    {
                        [`${pathPrefix}.qualifyingAttempts`]: MAX_ATTEMPTS,
                        [`${pathPrefix}.qualifyingLaps`]: increment(2),
                        [`${pathPrefix}.qualifyingDnf`]: true,
                        [`${pathPrefix}.qualifying`]: setup,
                        [`${pathPrefix}.lastQualyResult`]: crashResult,
                        [`${pathPrefix}.isSetupSent`]: true,
                    },
                    !isWetSession,
                );
                driverDialogue = t('returning_pits_bad');
                pitBoardMessages = [driverDialogue, ...pitBoardMessages].slice(0, 50);
                uiStore.alert(t('qualy_crash_report', { name: driver.name }), t('accident_label'), 'danger');
            } else {
                pitBoardMessages = [`${t('validated').toUpperCase()}: ${formatTime(result.lapTime)}`, ...pitBoardMessages].slice(0, 50);
                // Determine if new personal best
                const currentBest = bestTime;
                let newBest = currentBest;
                let bestCompound = setup.tyreCompound;

                if (currentBest === 0 || result.lapTime < currentBest) {
                    newBest = result.lapTime;
                } else {
                    bestCompound =
                        driverStatus?.qualifyingBestCompound ||
                        setup.tyreCompound;
                }

                const finalResult = {
                    lapTime: result.lapTime,
                    setupConfidence: result.setupConfidence,
                    isCrashed: false,
                    driverFeedback: result.driverFeedback,
                    tyreFeedback: result.tyreFeedback,
                    setupUsed: setupToRun,
                    setupHints: result.setupHints
                };
                lastResult = finalResult;

                await carSetupService.saveQualyResult(
                    team.id,
                    driver.id,
                    {
                        [`${pathPrefix}.qualifyingAttempts`]: newAttempts,
                        [`${pathPrefix}.qualifyingBestTime`]: newBest,
                        [`${pathPrefix}.qualifyingLaps`]: increment(3), // Out + Flying + In
                        [`${pathPrefix}.qualifyingBestCompound`]: bestCompound,
                        [`${pathPrefix}.qualifying`]: setup,
                        [`${pathPrefix}.lastQualyResult`]: finalResult,
                        [`${pathPrefix}.isSetupSent`]: true,
                    },
                    !isWetSession,
                );
                driverDialogue = (result.lapTime < (bestTime || 999)) ? t('returning_pits_good') : t('returning_pits_bad');
                pitBoardMessages = [driverDialogue, ...pitBoardMessages].slice(0, 50);
                await refreshStandings();
            }
        } catch (e) {
            console.error(e);
            uiStore.alert(t('error_qualy_lap'), t('error_renew').split(' ')[0], "danger");
        }

        isSimulating = false;
        setTimeout(() => { driverDialogue = null; }, 5000); // Clear dialogue after 5s
    }

    function formatTime(seconds: number) {
        if (seconds === 0 || seconds === null) return "--:--.---";
        if (seconds >= 999) return t('dnf');
        const mins = Math.floor(seconds / 60);
        const secs = (seconds % 60).toFixed(3);
        const parts = secs.split('.');
        return `${mins}:${parts[0].padStart(2, '0')}.${parts[1]}`;
    }

    function getConfidenceColor(conf: number) {
        if (conf > 0.9) return "text-emerald-400";
        if (conf > 0.7) return "text-emerald-500/80";
        if (conf > 0.4) return "text-yellow-400";
        return "text-red-400";
    }

    const styleConfigs = $derived.by(() => {
        const base = [
            { id: DriverStyle.defensive, icon: ChevronRight, color: "text-blue-400", label: t("defensive") },
            { id: DriverStyle.normal, icon: Zap, color: "text-emerald-400", label: t("normal") },
            { id: DriverStyle.offensive, icon: Zap, color: "text-orange-400", label: t("offensive") },
        ];

        if (managerStore.profile?.role === "ex_driver") {
            base.push({ id: DriverStyle.mostRisky, icon: Zap, color: "text-red-500", label: t("risky") });
        }

        return base;
    });
</script>

{#if timeService.currentStatus === 'qualifying'}
    <!-- Qualy in Progress Holding View -->
    <div class="flex flex-col items-center justify-center p-12 text-center min-h-[400px]">
        <Activity size={64} class="text-app-primary mb-6 animate-pulse" />
        <h2 class="text-3xl font-black italic text-app-text uppercase tracking-widest mb-4">
            {t('qualy_in_progress_header')}
        </h2>
        <p class="text-sm text-app-text/60 max-w-lg mb-8 leading-relaxed">
            {t('qualy_processing_desc')}
        </p>
        <div class="flex items-center gap-2 text-app-primary px-4 py-2 bg-app-primary/10 rounded-lg">
            <Timer size={16} />
            <span class="text-[10px] font-black uppercase tracking-widest">{t('waiting_backend_sim')}</span>
        </div>
    </div>
{:else}
<div class="grid grid-cols-1 lg:grid-cols-12 gap-5">
    <!-- Left Column: Setup Controls -->
    <div class="lg:col-span-7 space-y-5">
        {#if driver}
            <div class="space-y-3">
                <div class="bg-app-surface border border-app-border rounded-2xl p-6 shadow-2xl relative overflow-hidden group min-h-[160px] flex flex-col justify-center">
                    <div class="absolute top-0 right-0 w-32 h-32 bg-app-primary/5 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl pointer-events-none"></div>

                    <div class="flex items-start gap-6 relative">
                        <!-- BIG AVATAR -->
                        <div class="shrink-0 relative">
                            <div class="w-16 h-16 rounded-2xl bg-app-primary/10 border border-app-primary/20 flex items-center justify-center overflow-hidden shadow-inner ring-4 ring-app-primary/5">
                                <DriverAvatar id={driver.id} seed={driver.id} gender={driver.gender} size={64} />
                            </div>
                            <div class="absolute -bottom-1 -right-1 w-5 h-5 rounded-full bg-emerald-500 border-2 border-app-surface ring-1 ring-emerald-500/20 {isSimulating ? 'animate-pulse' : ''}"></div>
                        </div>

                        <!-- CONVERSATION BUBBLE -->
                        <div class="flex-1 space-y-3">
                            <div class="flex items-center justify-between">
                                <span class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary leading-none" title={driver.name}>{formatDriverName(driver.name)}</span>
                                <div class="flex items-center gap-4 text-[9px] font-black uppercase text-app-text/30">
                                    <div class="flex items-center gap-1.5"><Bolt size={10} class="text-emerald-400" /> {driver.stats?.fitness || 100}%</div>
                                    <div class="flex items-center gap-1.5"><Smile size={10} class="text-yellow-400" /> {driver.stats?.morale || 100}%</div>
                                </div>
                            </div>
                            {#if isSimulating}
                                <div in:fade class="text-[10px] font-black italic text-app-primary/60 uppercase tracking-widest animate-pulse flex items-center gap-2 mb-2">
                                    <div class="w-1.5 h-1.5 rounded-full bg-app-primary animate-ping"></div>
                                    {t('simulating_current_lap')}
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
                                {@const combinedFeedback = [...(lastResult.driverFeedback || []), ...(lastResult.tyreFeedback || [])]}
                                <div in:fade class="bg-app-text/5 rounded-2xl rounded-tl-none p-4 relative border border-white/5">
                                    <div class="absolute -left-2 top-0 w-2 h-2 bg-app-text/5 border-l border-t border-white/5" style="clip-path: polygon(100% 0, 0 0, 100% 100%);"></div>
                                    <div class="space-y-2">
                                        {#if combinedFeedback.length > 0}
                                            {#each combinedFeedback as msg}
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
                    </div>
                </div>
            </div>
        {/if}

        <div
            class="bg-app-surface border border-app-border rounded-2xl p-6 relative overflow-hidden shadow-2xl"
        >
            <div class="flex items-center justify-between mb-2">
                <h3
                    class="font-black text-xs text-app-text uppercase tracking-[0.2em]"
                >
                    {t('qualifying_setup')}
                </h3>
                {#if needsWetTyres}
                    <div class="flex items-center gap-1 text-red-500 animate-[pulse_1s_infinite]">
                        <AlertTriangle size={12} />
                        <span class="text-[9px] font-black uppercase tracking-tighter">{t('wet_track_warning')}</span>
                    </div>
                {/if}
            </div>

            <!-- Sliders -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-5">
                {#each [
                    { label: t("front_wing"), field: "frontWing" as const, icon: Wind, color: "text-cyan-400", locked: false, hintL: "Top Speed (0)", hintR: "Corner Grip (100)" }, 
                    { label: t("rear_wing"), field: "rearWing" as const, icon: Wind, color: "text-cyan-400", locked: isParcFerme, hintL: "Top Speed (0)", hintR: "Corner Grip (100)" }, 
                    { label: t("suspension"), field: "suspension" as const, icon: Navigation, color: "text-purple-400", locked: isParcFerme, hintL: "Soft/Bumps (0)", hintR: "Stiff/Aero (100)" }, 
                    { label: t("gear_ratio"), field: "gearRatio" as const, icon: Zap, color: "text-orange-400", locked: isParcFerme, hintL: "Acceleration (0)", hintR: "Top Speed (100)" }
                ] as item}
                    <div
                        class="space-y-3 group {item.locked
                            ? 'opacity-50 grayscale'
                            : ''}"
                    >
                        <div class="flex justify-between items-center px-1">
                            <div class="flex items-center gap-2 {item.color}">
                                <item.icon size={14} />
                                <span
                                    class="text-[10px] font-black uppercase tracking-widest"
                                    >{item.label}</span
                                >
                                {#if item.locked}
                                    <span class="text-[8px] text-red-400 ml-1"
                                        >({t('locked_label')})</span
                                    >
                                {/if}
                            </div>
                            <span class="text-sm font-black text-app-text"
                                >{setup[item.field]}</span
                            >
                        </div>
                        <div class="relative h-6 flex items-center">
                            {#if lastResult?.setupHints && (item.field in lastResult.setupHints) && (!isParcFerme || item.field === 'frontWing')}
                                {@const hint = (lastResult.setupHints as any)[item.field]}
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
                                disabled={item.locked}
                                class="w-full accent-current h-1.5 bg-app-text/5 rounded-full appearance-none {item.locked
                                    ? 'cursor-not-allowed'
                                    : 'cursor-pointer'} {item.color.replace(
                                    'text-',
                                    'accent-',
                                )} z-10"
                            />
                        </div>
                        <div class="flex justify-between px-1 opacity-0 group-hover:opacity-100 transition-opacity">
                            <span class="text-[8px] font-bold text-app-text/40 uppercase tracking-wider text-left max-w-[45%]">{item.hintL}</span>
                            <span class="text-[8px] font-bold text-app-text/40 uppercase tracking-wider text-right max-w-[45%]">{item.hintR}</span>
                        </div>
                    </div>
                {/each}
            </div>

            <!-- Tyres -->
            <div class="mt-8 space-y-3">
                <span
                    class="text-[9px] font-black text-app-text/40 uppercase tracking-widest"
                    >{t('tyre_compound')}</span
                >
                <div class="grid grid-cols-4 gap-3">
                    {#each [TyreCompound.soft, TyreCompound.medium, TyreCompound.hard, TyreCompound.wet] as tc}
                        <button
                            class="px-2 py-3 rounded-xl border transition-all flex flex-col items-center gap-2 {setup.tyreCompound === tc
                                ? tc === TyreCompound.soft ? 'bg-red-600 border-red-600 text-white shadow-[0_0_20px_rgba(220,38,38,0.3)]' : 
                                  tc === TyreCompound.medium ? 'bg-yellow-500 border-yellow-500 text-black shadow-[0_0_20px_rgba(234,179,8,0.3)]' : 
                                  tc === TyreCompound.hard ? 'bg-zinc-100 border-zinc-100 text-black shadow-[0_0_20px_rgba(244,244,245,0.3)]' : 
                                  'bg-blue-600 border-blue-600 text-white shadow-[0_0_20px_rgba(37,99,235,0.3)]'
                                : 'bg-app-text/5 border-app-border text-app-text/40 hover:bg-app-text/10'}"
                            onclick={() => (setup.tyreCompound = tc)}
                            disabled={isParcFerme}
                        >
                            <div
                                class="w-2.5 h-2.5 rounded-full {tc === TyreCompound.soft
                                    ? 'bg-red-500'
                                    : tc === TyreCompound.medium
                                      ? 'bg-yellow-400'
                                      : tc === TyreCompound.hard
                                        ? 'bg-white'
                                        : 'bg-blue-400'} shadow-[0_0_10px_rgba(255,255,255,0.2)]"
                            ></div>
                            <span
                                class="text-[9px] font-black uppercase tracking-tighter"
                                >{t(tc)}</span
                            >
                        </button>
                    {/each}
                </div>
            </div>

            <!-- Aggression selection -->
            <div class="mt-8 pt-6 border-t border-app-border flex flex-col md:flex-row gap-6 items-center">
                <div class="flex-1 w-full space-y-3">
                    <h4 class="text-[9px] font-black text-app-text/30 uppercase tracking-widest">{t('driving_aggression')}</h4>
                    <div class="flex gap-2">
                        {#each styleConfigs as style}
                            <button 
                                onclick={() => (setup.qualifyingStyle = style.id)} 
                                class="flex-1 py-3 rounded-xl border flex items-center justify-center transition-all {setup.qualifyingStyle === style.id ? 'bg-emerald-500/10 border-emerald-500/50 ' + style.color : 'bg-app-text/5 border-transparent text-app-text/20 hover:text-app-text/40'}" 
                                title={t(style.label)}
                            >
                                <style.icon size={16} />
                            </button>
                        {/each}
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Right Column: Status & Attempts -->
    <div class="lg:col-span-5 space-y-5 flex flex-col">
        <!-- Global Standings Table -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl flex flex-col overflow-hidden"
        >
            <div
                class="bg-app-primary/10 border-b border-app-primary/20 px-4 py-3 flex items-center justify-between"
            >
                <div class="flex items-center gap-2">
                    <Flag size={14} class="text-app-primary" />
                    <span
                        class="text-[10px] font-black uppercase tracking-widest text-app-primary"
                        >Live Classification</span
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
                    >Driver / Team</span
                >
                <span
                    class="w-12 text-[9px] font-black text-app-text/30 uppercase text-center"
                    >Tyre</span
                >
                <span
                    class="w-20 text-[9px] font-black text-app-text/30 uppercase text-right"
                    >Time</span
                >
                <span
                    class="w-16 text-[9px] font-black text-app-text/30 uppercase text-right"
                    >Gap</span
                >
            </div>

            <!-- Table Body -->
            <div class="flex-1 overflow-y-auto custom-scrollbar p-2 max-h-[300px]">
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
                                <span class="text-app-text/20">-</span>
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
            </div>
        </div>

        <!-- Action Trigger & Pit Board -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl p-6 flex flex-col gap-6 shadow-2xl"
        >
            <div class="flex justify-between items-start">
                <div>
                    <h4
                        class="text-[10px] font-black text-app-text/40 uppercase tracking-widest mb-1"
                    >
                        Qualy Attempts
                    </h4>
                    <div class="flex gap-1 mt-2">
                        {#each Array(MAX_ATTEMPTS) as _, i}
                            <div
                                class="w-6 h-2 rounded {i < attempts
                                    ? isDnf && i === attempts - 1
                                        ? 'bg-red-500'
                                        : 'bg-app-primary'
                                    : 'bg-app-text/10'}"
                            ></div>
                        {/each}
                    </div>
                </div>
                <div class="text-right">
                    <h4
                        class="text-[10px] font-black text-app-text/40 uppercase tracking-widest mb-1"
                    >
                        Best Lap Time
                    </h4>
                    <span
                        class="text-2xl font-black italic text-app-text tabular-nums"
                    >
                        {formatTime(bestTime)}
                    </span>
                </div>
            </div>

            <!-- Pit Board System -->
            <div class="flex-1 bg-black/40 rounded-xl border border-app-border/40 overflow-hidden flex flex-col min-h-[120px]">
                <div class="bg-app-surface/40 px-3 py-2 border-b border-app-border/40 flex items-center justify-between">
                    <div class="flex items-center gap-2">
                        <div class="w-1.5 h-1.5 rounded-full bg-app-primary animate-pulse"></div>
                        <span class="text-[9px] font-black uppercase tracking-widest text-app-text/60">Live Pit Board</span>
                    </div>
                    {#if needsWetTyres}
                        <div class="flex items-center gap-1 text-red-500 animate-[pulse_1s_infinite]">
                            <AlertTriangle size={12} />
                            <span class="text-[9px] font-black uppercase tracking-tighter">Wet track - Use wet tyres</span>
                        </div>
                    {:else}
                        <span class="text-[9px] font-black uppercase text-app-primary/60">Box. Box. Box.</span>
                    {/if}
                </div>
                
                <div class="flex-1 p-3 font-mono text-[11px] space-y-1.5 overflow-y-auto max-h-[140px] custom-scrollbar">
                    {#if pitBoardMessages.length === 0}
                        <div class="h-full flex flex-col items-center justify-center text-app-text/20 italic">
                            <Navigation size={24} class="mb-2 opacity-20" />
                            <span>Awaiting Session Start</span>
                        </div>
                    {:else}
                        {#each pitBoardMessages as msg, i}
                            <div 
                                in:slide={{ duration: 300 }} 
                                class="flex gap-2 {i === 0 ? 'text-app-primary font-bold' : 'text-app-text/40'}"
                            >
                                <span class="opacity-30">[{new Date().toLocaleTimeString([], { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' })}]</span>
                                <span>{msg}</span>
                            </div>
                        {/each}
                    {/if}
                </div>
            </div>

            {#if isDnf}
                <div
                    class="bg-red-500/10 border border-red-500/20 text-red-500 rounded-xl p-4 flex flex-col items-center justify-center text-center"
                >
                    <AlertTriangle size={24} class="mb-2" />
                    <span class="text-xs font-black uppercase"
                        >Driver Crashed - Session Over</span
                    >
                </div>
            {:else if attempts >= MAX_ATTEMPTS}
                <div
                    class="bg-app-text/5 border border-app-border text-app-text/50 rounded-xl p-4 flex flex-col items-center justify-center text-center"
                >
                    <Flag size={24} class="mb-2" />
                    <span class="text-xs font-black uppercase"
                        >Max Attempts Reached</span
                    >
                </div>
            {:else}
                <button
                    class="w-full py-4 bg-app-primary text-app-primary-foreground font-black uppercase tracking-widest text-sm rounded-xl hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 disabled:scale-100 flex items-center justify-center gap-2 shadow-lg shadow-app-primary/20"
                    disabled={isSimulating || !driver}
                    onclick={runQualyAttempt}
                >
                    {#if isSimulating}
                        <div
                            class="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin"
                        ></div>
                        Pushing...
                    {:else}
                        <Timer size={16} />
                        Run Flying Lap
                    {/if}
                </button>
            {/if}
        </div>
    </div>
</div>
{/if}

<style>
    .custom-scrollbar::-webkit-scrollbar {
        width: 4px;
    }
    .custom-scrollbar::-webkit-scrollbar-track {
        background: rgba(255, 255, 255, 0.05);
    }
    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: rgba(var(--primary-color-rgb), 0.2);
        border-radius: 10px;
    }
</style>
