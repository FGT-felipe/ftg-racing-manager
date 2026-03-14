<script lang="ts">
    import { db } from "$lib/firebase/config";
    import { doc, updateDoc, increment, addDoc, collection, serverTimestamp } from "firebase/firestore";
    import { fade, slide } from "svelte/transition";
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
    import { circuitService } from "$lib/services/circuit_service.svelte";
    import {
        type CarSetup,
        TyreCompound,
        DriverStyle,
        type Driver,
        type Team,
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
        Activity,
    } from "lucide-svelte";
    import { t } from "$lib/utils/i18n";
    import { onMount, untrack } from "svelte";
    import { getDoc } from "firebase/firestore";

    let { driverId } = $props<{ driverId: string | null }>();

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
    let pitBoardMessages = $state<string[]>([]);
    
    const teamDrivers = $derived(driverStore.drivers);
    const driver = $derived(teamDrivers.find((d: any) => d.id === driverId));
    const nextEvent = $derived(seasonStore.nextEvent);

    // Wet Track Detection
    const isWetSession = $derived(nextEvent?.weatherPractice?.toLowerCase().includes('rain') || nextEvent?.weatherPractice?.toLowerCase().includes('wet'));
    const needsWetTyres = $derived(isWetSession && setup.tyreCompound !== TyreCompound.wet);

    let sessionLapTimes = $state<number[]>([]);
    let competitorTimes = $state<Array<{ teamName: string; driverName: string; time: number }>>([]);
    const circuit = $derived(
        nextEvent
            ? circuitService.getCircuitProfile(nextEvent.circuitId)
            : null,
    );

    const driverStatus = $derived.by(() => {
        const team = teamStore.value.team;
        if (!team || !driverId) return null;
        return team.weekStatus?.driverSetups?.[driverId];
    });

    const driverPracticeLaps = $derived(driverStatus?.practice?.laps || 0);

    const practiceBestTime = $derived.by(() => {
        if (!legacyPracticeRuns || legacyPracticeRuns.length === 0) return 0;
        const validTimes = legacyPracticeRuns.map((r: any) => r.time).filter((t: number) => t > 0);
        return validTimes.length > 0 ? Math.min(...validTimes) : 0;
    });

    const globalStandings = $derived.by(() => {
        const leaderTime = competitorTimes.length > 0 ? Math.min(...competitorTimes.map(c => c.time)) : 0;
        return competitorTimes
            .sort((a, b) => a.time - b.time)
            .map((c, i) => ({
                ...c,
                position: i + 1,
                gap: i === 0 ? 0 : c.time - leaderTime,
                driverId: "", // Optional: link to driver if needed
                tyre: (c as any).tyre || null
            }));
    });

    async function refreshStandings() {
        if (!nextEvent || !seasonStore.value.season) return;
        
        try {
            const raceDocId = `${seasonStore.value.season.id}_${nextEvent.id}`;
            const raceRef = doc(db, "races", raceDocId);
            const raceSnap = await getDoc(raceRef);

            if (raceSnap.exists()) {
                const data = raceSnap.data();
                if (data.practiceResults) {
                    competitorTimes = data.practiceResults;
                }
            }
        } catch (e) {
            console.error("Error refreshing standings:", e);
        }
    }

    const practiceHistory = $derived(
        driver ? setupStore.getHistoryByDriver(driver.id) : [],
    );

    const legacyPracticeRuns = $derived.by(() => {
        const team = teamStore.value.team;
        if (!driver || !team?.weekStatus?.driverSetups) return [];
        const driverSetup = team.weekStatus.driverSetups[driver.id] || {};
        return driverSetup.practiceRuns || [];
    });

    const combinedHistory = $derived.by(() => {
        const base = practiceHistory as PracticeHistoryItem[];
        if (!driver) return base;

        const legacy: PracticeHistoryItem[] = legacyPracticeRuns.map(
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
        if (!driver || !circuit || !teamStore.value.team) return combinedHistory;

        return (combinedHistory as PracticeHistoryItem[]).map((entry) => {
            if (entry.feedback && entry.feedback.length > 0) return entry;
            if (!entry.setupUsed) return entry;

            const sim = practiceService.simulatePracticeRun(
                circuit,
                teamStore.value.team as Team,
                driver,
                entry.setupUsed,
                nextEvent?.weatherPractice || t('sunny'),
            );

            return {
                ...entry,
                feedback: sim.driverFeedback.concat(sim.tyreFeedback),
                setupConfidence: sim.setupConfidence,
                isCrashed:
                    entry.isCrashed !== undefined
                        ? entry.isCrashed
                        : sim.isCrashed,
            };
        });
    });

    // Watch for driver changes to load their history setup
    $effect(() => {
        if (driverId) {
            untrack(() => {
                const history = setupStore.getHistoryByDriver(driverId);
                if (history.length > 0) {
                    const lastSetup = history[0].setupUsed;
                    setup = { ...setup, ...lastSetup };
                }
            });
        }
    });

    onMount(() => {
        if (teamStore.value.team?.id) {
            setupStore.init(teamStore.value.team.id);
        }

        // Fetch competitor times
        if (teamStore.value.team?.currentSeasonId) {
            raceService
                .getCompetitorPracticeTimes(
                    teamStore.value.team.currentSeasonId,
                )
                .then((times: any) => {
                    competitorTimes = times;
                });
        }
    });

    async function runPractice() {
        if (!driver || !circuit || !teamStore.value.team) return;

        isSimulating = true;
        sessionLapTimes = [];

        const team = teamStore.value.team;
        if (!team) return;

        // One-time cost check: $10,000 per driver per weekend
        const weekStatus = team.weekStatus || {};
        const practicePaid = weekStatus.practicePaid || {};
        const hasPaid = practicePaid[driver.id];

        if (!hasPaid) {
            if (team.budget < PRACTICE_SESSION_COST) {
                alert(t('insufficient_funds_practice'));
                isSimulating = false;
                return;
            }

            // Pay the fee
            try {
                const teamRef = doc(db, "teams", team.id);
                const txRef = collection(db, "teams", team.id, "transactions");

                await updateDoc(teamRef, {
                    budget: team.budget - PRACTICE_SESSION_COST,
                    [`weekStatus.practicePaid.${driver.id}`]: true
                });

                await addDoc(txRef, {
                    description: t('practice_fee_description', { name: driver.name }),
                    amount: -PRACTICE_SESSION_COST,
                    date: serverTimestamp(),
                    type: "PRACTICE"
                });
            } catch (err) {
                console.error("Error paying practice fee:", err);
                alert(t('error_payment'));
                isSimulating = false;
                return;
            }
        }

        // Check maximum laps limit
        const practiceLapsMap = weekStatus.practiceLaps || {};
        const driverSetupsMap = weekStatus.driverSetups || {};
        const driverSetupCheck = driverSetupsMap[driver.id] || {};
        const legacyLaps = practiceLapsMap[driver.id] || 0;
        const driverSetupLaps = driverSetupCheck.practice?.laps || 0;
        const currentLaps = Math.max(legacyLaps, driverSetupLaps);

        if (currentLaps + lapsToRun > MAX_PRACTICE_LAPS_PER_DRIVER) {
            alert(
                t('practice_aborted_limit', {
                    max: MAX_PRACTICE_LAPS_PER_DRIVER,
                    rem: Math.max(0, MAX_PRACTICE_LAPS_PER_DRIVER - currentLaps)
                })
            );
            isSimulating = false;
            return;
        }

        // Apply selected style to the setup for this run
        const setupToRun = { ...setup, qualifyingStyle: currentDriverStyle };

        pitBoardMessages = [
            t('heads_out', {
                name: driver.name,
                count: lapsToRun,
                unit: lapsToRun === 1 ? t('lap_singular') : t('laps_plural')
            }),
            ...pitBoardMessages,
        ].slice(0, 30);

        try {
            // Simulate laps iteratively for visual
            for (let i = 0; i < lapsToRun; i++) {
                const result = practiceService.simulatePracticeRun(
                    circuit,
                    teamStore.value.team,
                    driver,
                    setupToRun,
                    nextEvent?.weatherPractice || t('sunny'),
                );

                lastResult = result;

                // Pit board narrative
                const storedHistory = driver
                    ? setupStore.getHistoryByDriver(driver.id)
                    : [];

                const nonCrashHistoryTimes = storedHistory
                    .filter((h) => !h.isCrashed)
                    .map((h) => h.lapTime);

                const previousBest =
                    nonCrashHistoryTimes.length > 0
                        ? Math.min(...nonCrashHistoryTimes, ...sessionLapTimes)
                        : sessionLapTimes.length > 0
                            ? Math.min(...sessionLapTimes)
                            : null;

                let suffix = "";
                if (result.isCrashed) {
                    suffix = t('crash_suffix');
                } else if (
                    previousBest === null ||
                    result.lapTime < previousBest
                ) {
                    suffix = t('new_personal_best');
                }

                pitBoardMessages = [
                    `${driver.name} - Lap ${i + 1}: ${formatTime(
                        result.lapTime,
                    )}${suffix}`,
                    ...pitBoardMessages,
                ].slice(0, 30);

                sessionLapTimes = [...sessionLapTimes, result.lapTime];

                await practiceService.savePracticeRun(
                    teamStore.value.team as Team,
                    driver.id,
                    result,
                    setupToRun,
                );

                // Also maintain per-driver practiceRuns history used by competitor benchmarks
                const teamRef = doc(db, "teams", teamStore.value.team.id);
                const currentSetups =
                    teamStore.value.team.weekStatus?.driverSetups || {};
                const driverSetup = currentSetups[driver.id] || {};
                const practiceRuns = driverSetup.practiceRuns || [];

                practiceRuns.push({
                    time: result.lapTime,
                    setupUsed: setupToRun,
                    isCrashed: result.isCrashed,
                });

                await updateDoc(teamRef, {
                    [`weekStatus.driverSetups.${driver.id}.practiceRuns`]:
                        practiceRuns,
                });

                // Wait for visual feedback
                await new Promise((r) => setTimeout(r, 800));

                if (result.isCrashed) {
                    break;
                }
            }

            // Calculate team budget cost
            const teamRef = doc(db, "teams", teamStore.value.team.id);
            await updateDoc(teamRef, {
                budget: teamStore.value.team.budget - PRACTICE_SESSION_COST,
            });

            // Calculate Stamina (forma) and Morale changes for the Driver
            const staminaCost = lapsToRun * 1; // 1 pt of stamina reduction per lap
            let moralePenalty = 0;
            
            if (lastResult) {
                if (lastResult.isCrashed) {
                    moralePenalty = 5; // -5 for a crash
                } else if (lastResult.setupConfidence < 0.60) {
                    moralePenalty = 2; // -2 for a bad setup feeling
                } else if (lastResult.setupConfidence > 0.85) {
                    moralePenalty = -1; // +1 if it went exceptionally well
                }
            }

            const driverRef = doc(db, "drivers", driver.id);
            const currentStats = driver.stats || {};
            const newStamina = Math.max(
                0,
                (currentStats.stamina || 100) - staminaCost,
            );
            const newMorale = Math.max(
                0,
                Math.min(100, (currentStats.morale || 100) - moralePenalty),
            );

            await updateDoc(driverRef, {
                "stats.stamina": newStamina,
                "stats.morale": newMorale,
            });

            await refreshStandings();

        } catch (e) {
            console.error(e);
            alert(t('error_practice_session'));
        }

        isSimulating = false;
    }

    function getConfidenceColor(conf: number) {
        if (conf > 0.9) return "text-green-500";
        if (conf > 0.7) return "text-emerald-400";
        if (conf > 0.4) return "text-yellow-400";
        return "text-red-400";
    }

    function formatTime(seconds: number) {
        if (seconds >= 999) return t('dnf');
        const mins = Math.floor(seconds / 60);
        const secs = (seconds % 60).toFixed(3);
        return `${mins}:${secs.padStart(6, "0")}`;
    }

    const styleConfigs = [
        {
            id: DriverStyle.defensive,
            icon: ChevronRight,
            color: "text-blue-400",
            label: t('defensive'),
        },
        {
            id: DriverStyle.normal,
            icon: Zap,
            color: "text-green-400",
            label: t('normal'),
        },
        {
            id: DriverStyle.offensive,
            icon: Zap,
            color: "text-orange-400",
            label: t('offensive'),
        },
        {
            id: DriverStyle.mostRisky,
            icon: Zap,
            color: "text-red-500",
            label: t('risky'),
        },
    ];
</script>

<div class="grid grid-cols-1 lg:grid-cols-12 gap-5">
    <!-- Left Column: Controls -->
    <div class="lg:col-span-7 space-y-5">
        <!-- Setup Card -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl p-6 relative overflow-hidden shadow-2xl"
        >
            <h3
                class="font-black text-xs text-app-text uppercase tracking-[0.2em] mb-8"
            >
                Practice Target Setup
            </h3>

            <!-- Sliders -->
            <div class="space-y-6">
                {#each [
                    { label: t("front_wing"), field: "frontWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400", hintL: t("top_speed_0"), hintR: t("corner_grip_100") }, 
                    { label: t("rear_wing"), field: "rearWing" as keyof CarSetup, icon: Wind, color: "text-cyan-400", hintL: t("top_speed_0"), hintR: t("corner_grip_100") }, 
                    { label: t("suspension"), field: "suspension" as keyof CarSetup, icon: Navigation, color: "text-purple-400", hintL: t("soft_bumps_0"), hintR: t("stiff_aero_100") }, 
                    { label: t("gear_ratio"), field: "gearRatio" as keyof CarSetup, icon: Zap, color: "text-orange-400", hintL: t("acceleration_0"), hintR: t("top_speed_100") }
                ] as item}
                    <div class="space-y-3 group">
                        <div class="flex justify-between items-center px-1">
                            <div class="flex items-center gap-2 {item.color}">
                                <item.icon size={14} />
                                <span
                                    class="text-[10px] font-black uppercase tracking-widest"
                                    >{item.label}</span
                                >
                            </div>
                            <span class="text-sm font-black text-app-text"
                                >{setup[item.field]}</span
                            >
                        </div>
                        <input
                            type="range"
                            min="0"
                            max="100"
                            bind:value={setup[item.field]}
                            class="w-full accent-current h-1.5 bg-app-text/5 rounded-full appearance-none cursor-pointer {item.color.replace(
                                'text-',
                                'accent-',
                            )}"
                        />
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
                                ? tc === TyreCompound.soft ? 'bg-red-600 border-red-600 text-white' : 
                                  tc === TyreCompound.medium ? 'bg-yellow-500 border-yellow-500 text-black' : 
                                  tc === TyreCompound.hard ? 'bg-zinc-100 border-zinc-100 text-black' : 
                                  'bg-blue-600 border-blue-600 text-white'
                                : 'bg-app-text/5 border-app-border text-app-text/40 hover:bg-app-text/10'}"
                            onclick={() => (setup.tyreCompound = tc)}
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
        </div>

        <!-- Driver Style & Lap Selection -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl p-6 space-y-6"
        >
            <div class="flex items-center justify-between">
                <h4
                    class="text-[10px] font-black text-app-text/40 uppercase tracking-widest"
                >
                    {t('driving_aggression')}
                </h4>
                <div class="flex gap-1.5">
                    {#each styleConfigs as style}
                        <button
                            class="w-8 h-8 rounded-lg border flex items-center justify-center transition-all {currentDriverStyle ===
                            style.id
                                ? 'bg-app-text/10 border-app-border ' + style.color
                                : 'bg-app-text/5 border-transparent text-app-text/20 hover:text-app-text/40'}"
                            onclick={() => (currentDriverStyle = style.id)}
                            title={style.label}
                        >
                            <style.icon size={14} />
                        </button>
                    {/each}
                </div>
            </div>

            <div class="space-y-3">
                <h4
                    class="text-[10px] font-black text-app-text/40 uppercase tracking-widest"
                >
                    {t('stint_length')}
                </h4>
                <div class="bg-app-text/20 rounded-xl p-1.5 flex gap-1">
                    {#each [1, 3, 5] as laps}
                        <button
                            class="flex-1 py-1.5 rounded-lg text-[10px] font-black uppercase transition-all {lapsToRun ===
                            laps
                                ? 'bg-app-text/10 text-app-text'
                                : 'text-app-text/20 hover:text-app-text/40'}"
                            onclick={() => (lapsToRun = laps)}
                        >
                            {laps}
                            {laps === 1 ? t('lap_singular') : t('laps_plural')}
                        </button>
                    {/each}
                </div>
            </div>
        </div>
    </div>

    <!-- Right Column: Results & Pit Board -->
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
                        >{t('live_classification')}</span
                    >
                </div>
                <button 
                    onclick={refreshStandings}
                    class="text-[9px] font-black uppercase text-app-text/40 hover:text-app-primary transition-colors flex items-center gap-1"
                >
                    <Activity size={10} />
                    {t('sync')}
                </button>
            </div>

            <!-- Table Header -->
            <div class="flex px-4 py-2 bg-app-text/5 border-b border-app-border">
                <span class="w-8 text-[9px] font-black text-app-text/30 uppercase"
                    >{t('pos')}</span
                >
                <span
                    class="flex-1 text-[9px] font-black text-app-text/30 uppercase"
                    >{t('driver_team')}</span
                >
                <span
                    class="w-12 text-[9px] font-black text-app-text/30 uppercase text-center"
                    >{t('tyre_compound')}</span
                >
                <span
                    class="w-20 text-[9px] font-black text-app-text/30 uppercase text-right"
                    >{t('lap_time')}</span
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
                        <p class="text-[9px] font-black uppercase tracking-widest text-app-text">{t('awaiting_session_data')}</p>
                    </div>
                {:else}
                    {#each globalStandings as row}
                        <div
                            class="flex items-center px-2 py-2.5 rounded-lg {row.driverId ===
                            driverId
                                ? 'bg-app-primary/10 border border-app-primary/20'
                                : 'hover:bg-app-text/5'} transition-colors group"
                        >
                            <span class="w-8 text-xs font-black {row.time !== null ? row.position <= 3 ? 'text-app-primary' : 'text-app-text/80' : 'text-app-text/30'}">
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
                                <span class="text-xs font-black italic {row.time !== null ? 'text-app-text' : 'text-app-text/20'}">
                                    {formatTime(row.time ?? 0)}
                                </span>
                            </div>

                            <div class="w-16 text-right">
                                <span class="text-[10px] font-bold {row.position === 1 ? 'text-app-primary/40' : 'text-app-text/40'} text-mono">
                                    {row.position === 1 ? t('interval') : row.gap ? `+${row.gap.toFixed(3)}s` : '--'}
                                </span>
                            </div>
                        </div>
                    {/each}
                {/if}
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
                        PRACTICE LAPS
                    </h4>
                    <div class="flex items-center gap-2">
                         <div class="flex gap-1 mt-2">
                            {#each Array(10) as _, i}
                                <div
                                    class="w-3 h-1.5 rounded-sm {i < (driverPracticeLaps / 5)
                                        ? 'bg-app-primary'
                                        : 'bg-app-text/10'}"
                                ></div>
                            {/each}
                        </div>
                        <span class="text-[10px] font-black text-app-text/40 mt-1">{driverPracticeLaps} / 50</span>
                    </div>
                </div>
                <div class="text-right">
                    <h4
                        class="text-[10px] font-black text-app-text/40 uppercase tracking-widest mb-1"
                    >
                        Best Lap Time
                    </h4>
                    <div class="flex flex-col items-end">
                        <span class="text-2xl font-black italic text-app-text tabular-nums leading-none">
                            {formatTime(practiceBestTime)}
                        </span>
                        {#if lastResult}
                             <span class="text-[9px] font-black {getConfidenceColor(lastResult.setupConfidence)} mt-1">
                                {(lastResult.setupConfidence * 100).toFixed(0)}% CONF
                            </span>
                        {/if}
                    </div>
                </div>
            </div>

            <!-- Pit Board System -->
            <div class="flex-1 bg-black/40 rounded-xl border border-app-border/40 overflow-hidden flex flex-col min-h-[120px]">
                <div class="bg-app-surface/40 px-3 py-2 border-b border-app-border/40 flex items-center justify-between">
                    <div class="flex items-center gap-2">
                        <div class="w-1.5 h-1.5 rounded-full bg-app-primary animate-pulse"></div>
                        <span class="text-[9px] font-black uppercase tracking-widest text-app-text/60">{t('live_pit_board')}</span>
                    </div>
                    {#if needsWetTyres}
                        <div class="flex items-center gap-1 text-red-500 animate-[pulse_1s_infinite]">
                            <AlertTriangle size={12} />
                            <span class="text-[9px] font-black uppercase tracking-tighter">{t('wet_track_warning')}</span>
                        </div>
                    {:else}
                        <span class="text-[9px] font-black uppercase text-app-primary/60">{t('box_box_box')}</span>
                    {/if}
                </div>
                
                <div class="flex-1 p-3 font-mono text-[11px] space-y-1.5 overflow-y-auto max-h-[140px] custom-scrollbar">
                    {#if pitBoardMessages.length === 0}
                        <div class="h-full flex flex-col items-center justify-center text-app-text/20 italic">
                            <Navigation size={24} class="mb-2 opacity-20" />
                            <span>{t('awaiting_session_start')}</span>
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

            <div class="space-y-3">
                <button
                    class="w-full py-4 bg-app-primary text-app-primary-foreground font-black uppercase tracking-widest text-sm rounded-xl hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50 disabled:scale-100 flex items-center justify-center gap-2 shadow-lg shadow-app-primary/20"
                    disabled={isSimulating || !driver}
                    onclick={runPractice}
                >
                    {#if isSimulating}
                        <div
                            class="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin"
                        ></div>
                        Running...
                    {:else}
                        <Timer size={16} />
                        Start Practice Outing
                    {/if}
                </button>
                <div class="flex justify-center italic">
                    <span class="text-[9px] uppercase tracking-widest font-black text-red-400">-{PRACTICE_SESSION_COST.toLocaleString()} Outing Fee</span>
                </div>
            </div>
        </div>

        <!-- Feedback & History -->
        <div
            class="bg-app-surface border border-app-border rounded-2xl flex flex-col h-[350px]"
        >
            <div class="flex border-b border-app-border">
                <div
                    class="flex-1 py-3 text-center text-[10px] font-black uppercase tracking-widest border-b-2 border-app-primary text-app-text bg-app-text/5"
                >
                    Feedback
                </div>
                <div
                    class="flex-1 py-3 text-center text-[10px] font-black uppercase tracking-widest text-app-text/40 bg-app-surface border-b border-app-border"
                >
                    Lap History
                </div>
            </div>

            <div class="flex-1 overflow-y-auto p-4 space-y-4 custom-scrollbar">
                <!-- Feedback block -->
                <div class="space-y-3">
                    {#if lastResult}
                        {#each lastResult.driverFeedback as msg}
                            <div
                                class="p-3 bg-app-text/5 rounded-lg border-l-2 border-app-primary"
                            >
                                <p
                                    class="text-[11px] italic text-app-text/70 leading-relaxed font-medium"
                                >
                                    "{msg}"
                                </p>
                            </div>
                        {/each}
                        {#if lastResult.driverFeedback.length === 0}
                            <div
                                class="p-4 flex flex-col items-center justify-center text-center opacity-30 mt-4"
                            >
                                <CheckCircle2 size={32} class="mb-3" />
                                <p class="text-[10px] font-black uppercase">
                                    No Issues Reported
                                </p>
                            </div>
                        {/if}
                    {:else}
                        <div
                            class="p-4 flex flex-col items-center justify-center text-center opacity-10 mt-4"
                        >
                            <Info size={40} class="mb-3" />
                            <p
                                class="text-[10px] font-black uppercase tracking-widest"
                            >
                                Awaiting First Run
                            </p>
                        </div>
                    {/if}
                </div>

                <!-- History block -->
                <div class="pt-2 border-t border-app-border/40 space-y-2">
                    <h4
                        class="text-[9px] font-black text-app-text/40 uppercase tracking-widest"
                    >
                        Recent Laps
                    </h4>
                    {#if enrichedHistory.length === 0}
                        <p class="text-[10px] text-app-text/30 italic">
                            No recorded laps yet for this driver.
                        </p>
                    {:else}
                        {#each enrichedHistory as entry}
                            <div
                                class="flex items-center justify-between text-[11px] px-2 py-1.5 rounded-lg bg-app-text/5"
                            >
                                <div class="flex flex-col">
                                    <span class="font-mono font-black">
                                        {formatTime(entry.lapTime)}
                                    </span>
                                    <span
                                        class="text-[9px] text-app-text/40 uppercase tracking-widest"
                                    >
                                        CONF{" "}
                                        {Math.round(
                                            (entry.setupConfidence || 0) * 100,
                                        )}%
                                    </span>
                                </div>
                                {#if entry.isCrashed}
                                    <span class="text-[9px] text-red-400">
                                        CRASH
                                    </span>
                                {:else}
                                    <span class="text-[9px] text-app-text/40">
                                        {entry.feedback[0] || t('clean_lap')}
                                    </span>
                                {/if}
                            </div>
                        {/each}
                    {/if}
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    .custom-scrollbar::-webkit-scrollbar {
        width: 4px;
    }
    .custom-scrollbar::-webkit-scrollbar-track {
        background: rgba(255, 255, 255, 0.05);
    }
    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: rgba(197, 160, 89, 0.2);
        border-radius: 10px;
    }
</style>
