<script lang="ts">
    import { onMount, untrack } from "svelte";
    import { fade, slide, fly } from "svelte/transition";
    import {
        Flag,
        Gauge,
        History,
        Settings,
        Fuel,
        Zap,
        Trash2,
        Plus,
        ChevronRight,
        Timer,
        AlertTriangle,
        ShieldCheck,
        Save,
        Activity,
        Wind,
        Navigation,
        Lock
    } from "lucide-svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { timeService } from "$lib/services/time_service.svelte";
    import { uiStore } from "$lib/stores/ui.svelte";
    import { t } from "$lib/utils/i18n";
    import {
        type CarSetup,
        TyreCompound,
        DriverStyle,
        type Driver,
    } from "$lib/types";
    import { carSetupService } from "$lib/services/car_setup_service.svelte";

    let { driverId } = $props<{ driverId: string | null }>();

    let isSaving = $state(false);

    let strategy = $state<CarSetup>({
        frontWing: 50,
        rearWing: 50,
        suspension: 50,
        gearRatio: 50,
        tyreCompound: TyreCompound.medium,
        pitStops: [],
        initialFuel: 50,
        pitStopFuel: [],
        qualifyingStyle: DriverStyle.normal,
        raceStyle: DriverStyle.normal,
        pitStopStyles: [],
    });

    const teamDrivers = $derived(driverStore.drivers);
    const driver = $derived(teamDrivers.find((d: Driver) => d.id === driverId));
    const team = $derived(teamStore.value.team);

    let qualyCompounds = $state<Record<string, TyreCompound>>({});
    let isQualyWet = $state(false);

    // Watch for driver changes to load their RACE setup and Qualy tyre
    $effect(() => {
        if (driverId && team) {
            untrack(() => {
                const driverData = team.weekStatus?.driverSetups?.[driverId];
                if (driverData?.race) {
                    strategy = { ...strategy, ...driverData.race };
                } else {
                    // Fallback to best available if race strategy is not yet saved
                    loadBestSetup(true); // Silent load on initialization
                }

                // Also fetch the qualy grid constraints
                fetchQualyConstraints(driverId);
            });
        }
    });

    async function fetchQualyConstraints(dId: string) {
        try {
            const nextEvent = seasonStore.nextEvent;
            if (nextEvent && seasonStore.value.season) {
                const raceDocId = `${seasonStore.value.season.id}_${nextEvent.id}`;
                const grid = await carSetupService.getQualyGrid(raceDocId);
                grid.forEach((row) => {
                    qualyCompounds[row.driverId] = row.tyreCompound as TyreCompound;
                });

                // Fallback: if the grid doesn't have this driver yet (CF hasn't generated it),
                // read the compound directly from the driver's qualifying session data in the team doc.
                if (!qualyCompounds[dId]) {
                    const savedCompound = team?.weekStatus?.driverSetups?.[dId]?.qualifyingBestCompound as TyreCompound | undefined;
                    if (savedCompound) qualyCompounds[dId] = savedCompound;
                }

                // Parc fermé exception: if the driver qualified on WET tyres, free compound choice for race start
                isQualyWet = qualyCompounds[dId] === TyreCompound.wet;
                if (qualyCompounds[dId] && !isQualyWet) {
                    strategy.tyreCompound = qualyCompounds[dId];
                }
            }
        } catch (e) {
            console.error('[RaceSetupTab:fetchQualyConstraints] Error:', e);
        }
    }

    async function saveStrategy() {
        if (!driver || !team) return;
        isSaving = true;
        try {
            await carSetupService.saveRaceSetup(team.id, driver.id, strategy);
            uiStore.alert(`✓ ${t('race_strategy_saved')}`, t('race_strategy_saved'), "success");
        } catch (e) {
            console.error('[RaceSetupTab:saveStrategy] Error:', e);
            uiStore.alert(t('error_save_strategy'), t('error_renew').split(' ')[0], "danger");
        } finally {
            isSaving = false;
        }
    }

    async function loadBestSetup(silent = false) {
        if (!team || !driverId) return;
        const practiceData = team.weekStatus?.driverSetups?.[driverId]?.practice;
        const qualyData = team.weekStatus?.driverSetups?.[driverId]?.qualifying;

        if (practiceData?.bestLapSetup) {
            strategy = { ...strategy, ...practiceData.bestLapSetup };
            if (!silent) uiStore.alert(`✓ ${t('best_setup_loaded')}`, t('best_setup'), "success");
        } else if (practiceData?.lastResult?.setupUsed) {
            // Fallback 1: Last practice result
            strategy = { ...strategy, ...practiceData.lastResult.setupUsed };
            if (!silent) uiStore.alert(`✓ ${t('best_setup_loaded')}`, t('best_setup'), "success");
        } else if (practiceData?.frontWing !== undefined) {
            // Fallback 2: Direct fields in practice doc
            strategy = {
                ...strategy,
                frontWing: practiceData.frontWing,
                rearWing: practiceData.rearWing,
                suspension: practiceData.suspension,
                gearRatio: practiceData.gearRatio
            };
            if (!silent) uiStore.alert(`✓ ${t('best_setup_loaded')}`, t('best_setup'), "success");
        } else if (qualyData) {
            // Fallback 3: Qualifying setup
            strategy = { ...strategy, ...qualyData };
            if (!silent) uiStore.alert(`✓ ${t('best_setup_loaded')}`, t('best_setup'), "success");
        } else {
            if (!silent) uiStore.alert(t('no_setup_found'), t('best_setup'), "warning");
        }
    }

    function addPitStop() {
        strategy.pitStops = [...strategy.pitStops, TyreCompound.medium];
        strategy.pitStopFuel = [...strategy.pitStopFuel, 40];
        strategy.pitStopStyles = [
            ...strategy.pitStopStyles,
            DriverStyle.normal,
        ];
    }

    function removePitStop(index: number) {
        strategy.pitStops = strategy.pitStops.filter((_, i) => i !== index);
        strategy.pitStopFuel = strategy.pitStopFuel.filter(
            (_, i) => i !== index,
        );
        strategy.pitStopStyles = strategy.pitStopStyles.filter(
            (_, i) => i !== index,
        );
    }

    const styleConfigs = $derived.by(() => {
        const base = [
            { id: DriverStyle.defensive, icon: ChevronRight, color: "text-blue-400", label: t('defensive') },
            { id: DriverStyle.normal, icon: Zap, color: "text-green-400", label: t('normal') },
            { id: DriverStyle.offensive, icon: Zap, color: "text-orange-400", label: t('offensive') },
        ];

        if (managerStore.profile?.role === "ex_driver") {
            base.push({ id: DriverStyle.mostRisky, icon: Zap, color: "text-red-500", label: t('risky') });
        }

        return base;
    });
</script>

{#if timeService.currentStatus === 'qualifying'}
    <!-- Qualy in Progress Holding View -->
    <div class="flex flex-col items-center justify-center p-12 text-center min-h-[400px]">
        <Activity size={64} class="text-app-qualifying mb-6 animate-pulse" />
        <h2 class="text-3xl font-black italic text-app-text uppercase tracking-widest mb-4">
            {t('qualy_in_progress_header')}
        </h2>
        <p class="text-sm text-app-text/60 max-w-lg mb-8 leading-relaxed">
            {t('qualy_locked_desc')}
        </p>
        <div class="flex items-center gap-2 text-app-qualifying px-4 py-2 bg-app-qualifying/10 rounded-lg">
            <Timer size={16} />
            <span class="text-[10px] font-black uppercase tracking-widest">{t('awaiting_grid')}</span>
        </div>
    </div>
{:else if timeService.currentStatus === 'race'}
    <!-- Race in Progress Holding View -->
    <div class="flex flex-col items-center justify-center p-12 text-center min-h-[400px]">
        <Flag size={64} class="text-app-fastest mb-6 animate-bounce" />
        <h2 class="text-3xl font-black italic text-app-text uppercase tracking-widest mb-4">
            {t('race_in_progress_header')}
        </h2>
        <p class="text-sm text-app-text/60 max-w-lg mb-8 leading-relaxed">
            {t('race_ongoing_desc')}
        </p>
        <div class="flex items-center gap-2 text-app-fastest px-4 py-2 bg-app-fastest/10 rounded-lg">
            <Timer size={16} />
            <span class="text-[10px] font-black uppercase tracking-widest">{t('simulating_race')}</span>
        </div>
    </div>
{:else}
<div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
    <!-- Initial Setup & Fuel -->
    <div class="lg:col-span-12 space-y-6">
        <div
            class="bg-app-surface border border-app-border rounded-2xl p-6 shadow-xl"
        >
            <div class="flex items-center justify-between mb-8">
                <h3
                    class="font-black text-xs text-app-text uppercase tracking-[0.2em] italic"
                >
                    {t('race_start_config')}
                </h3>
                {#if driverId && qualyCompounds[driverId] && !isQualyWet}
                    <div class="px-3 py-1 bg-green-500/10 border border-green-500/20 rounded flex items-center gap-2">
                        <ShieldCheck size={12} class="text-green-500" />
                        <span class="text-[9px] font-black text-green-500/80 uppercase">{t('qualy_locked')}</span>
                    </div>
                {:else}
                    <div class="px-3 py-1 bg-amber-500/10 border border-amber-500/20 rounded flex items-center gap-2">
                        <ShieldCheck size={12} class="text-amber-400" />
                        <span class="text-[9px] font-black text-amber-400/80 uppercase">{t('free_choice')}</span>
                    </div>
                {/if}
            </div>

            <!-- Setup Sliders — rearWing is parc fermé locked (cannot be adjusted after qualifying) -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-5 mb-10 pb-8 border-b border-app-border">
                {#each [
                    { label: t("front_wing"),  field: "frontWing"  as const, icon: Wind,       color: "text-cyan-400",   hintL: t("top_speed_0"),    hintR: t("corner_grip_100"), locked: false },
                    { label: t("rear_wing"),   field: "rearWing"   as const, icon: Wind,       color: "text-cyan-400",   hintL: t("top_speed_0"),    hintR: t("corner_grip_100"), locked: true  },
                    { label: t("suspension"),  field: "suspension" as const, icon: Navigation, color: "text-purple-400", hintL: t("soft_bumps_0"),  hintR: t("stiff_aero_100"),  locked: false },
                    { label: t("gear_ratio"),  field: "gearRatio"  as const, icon: Zap,        color: "text-orange-400", hintL: t("acceleration_0"), hintR: t("top_speed_100"),   locked: false }
                ] as item}
                    <div class="space-y-3 group {item.locked ? 'opacity-50' : ''}">
                        <div class="flex justify-between items-center px-1">
                            <div class="flex items-center gap-2 {item.color}">
                                <item.icon size={14} />
                                <span class="text-[10px] font-black uppercase tracking-widest">{item.label}</span>
                                {#if item.locked}
                                    <Lock size={10} class="text-app-text/30" />
                                {/if}
                            </div>
                            <span class="text-sm font-black text-app-text">{strategy[item.field]}</span>
                        </div>
                        <input
                            type="range"
                            min="0"
                            max="100"
                            bind:value={strategy[item.field]}
                            disabled={item.locked}
                            class="w-full h-1.5 bg-app-text/5 rounded-full appearance-none {item.locked ? 'cursor-not-allowed' : 'cursor-pointer'} {item.color.replace('text-', 'accent-')} transition-all"
                        />
                        <div class="flex justify-between px-1 opacity-0 group-hover:opacity-100 transition-opacity">
                            <span class="text-[8px] font-bold text-app-text/40 uppercase tracking-wider text-left max-w-[45%]">{item.hintL}</span>
                            <span class="text-[8px] font-bold text-app-text/40 uppercase tracking-wider text-right max-w-[45%]">{item.hintR}</span>
                        </div>
                    </div>
                {/each}

                <div class="md:col-span-2 flex justify-end">
                    <button
                    onclick={() => loadBestSetup()}
                    class="px-4 py-2 rounded-xl bg-app-primary/10 border border-app-primary text-app-primary font-black uppercase text-[10px] hover:bg-app-primary hover:text-black transition-all flex items-center gap-2"
                >
                        <Zap size={14} class="group-hover:animate-pulse" />
                        {t('best_setup')}
                    </button>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-10">
                <!-- Fuel -->
                <div class="space-y-6">
                    <div class="flex justify-between items-center">
                        <div class="flex items-center gap-2 text-cyan-400">
                            <Fuel size={16} />
                            <span
                                class="text-[10px] font-black uppercase tracking-widest"
                                >{t('initial_fuel_load')}</span
                            >
                        </div>
                        <span class="text-xl font-black text-app-text italic"
                            >{strategy.initialFuel} L</span
                        >
                    </div>
                    <input
                        type="range"
                        min="5"
                        max="100"
                        bind:value={strategy.initialFuel}
                        class="w-full h-2 bg-app-text/5 rounded-full appearance-none cursor-pointer accent-cyan-400"
                    />
                    <div
                        class="flex justify-between text-[9px] font-bold text-app-text/20 uppercase"
                    >
                        <span>{t('light_min')}</span>
                        <span>{t('heavy_full')}</span>
                    </div>
                </div>

                <!-- Starting Tyre & Style -->
                <div class="grid grid-cols-2 gap-6">
                    <div class="space-y-4">
                        <span
                            class="text-[10px] font-black text-app-text/30 uppercase tracking-widest"
                        >
                            {t('start_tyres')} {driverId && qualyCompounds[driverId] && !isQualyWet
                                ? `(${t('qualy_locked')})`
                                : `(${t('free_choice')})`}
                        </span>
                        <div class="grid grid-cols-4 gap-1.5">
                            {#each [TyreCompound.soft, TyreCompound.medium, TyreCompound.hard, TyreCompound.wet] as tc}
                                <button
                                    class="py-2.5 rounded-lg border text-center text-[8px] font-black transition-all {strategy.tyreCompound === tc
                                        ? tc === TyreCompound.soft ? 'bg-red-600 border-red-600 text-white' : 
                                          tc === TyreCompound.medium ? 'bg-yellow-500 border-yellow-500 text-black' : 
                                          tc === TyreCompound.hard ? 'bg-zinc-100 border-zinc-100 text-black' : 
                                          'bg-blue-600 border-blue-600 text-white'
                                        : 'bg-app-text/5 border-app-border text-app-text/40'} 
                                        {driverId && qualyCompounds[driverId] && !isQualyWet && qualyCompounds[driverId] !== tc ? 'opacity-20 cursor-not-allowed' : 'hover:scale-105 active:scale-95'}"
                                    onclick={() => {
                                        if (driverId && qualyCompounds[driverId] && !isQualyWet) return;
                                        strategy.tyreCompound = tc;
                                    }}
                                    disabled={driverId && qualyCompounds[driverId] && !isQualyWet && qualyCompounds[driverId] !== tc}
                                >
                                    {t(tc).toUpperCase()}
                                </button>
                            {/each}
                        </div>
                    </div>
                    <div class="space-y-4">
                        <span
                            class="text-[10px] font-black text-app-text/30 uppercase tracking-widest"
                            >{t('initial_pace')}</span
                        >
                        <div class="grid grid-cols-2 gap-2">
                            {#each styleConfigs as style}
                                <button
                                    class="py-2 rounded-lg border text-[9px] font-black transition-all {strategy.raceStyle ===
                                    style.id
                                        ? 'bg-app-primary border-app-primary text-app-primary-foreground'
                                        : 'bg-app-text/5 border-app-border text-app-text/40'}"
                                    onclick={() =>
                                        (strategy.raceStyle = style.id)}
                                >
                                    {style.label}
                                </button>
                            {/each}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Pit Stop Builder -->
    <div class="lg:col-span-12 space-y-4">
        <div class="flex items-center justify-between px-2">
            <h3
                class="font-black text-xs text-app-text uppercase tracking-[0.2em] italic"
            >
                {t('pit_stop_strategy')}
            </h3>
            <button
                onclick={addPitStop}
                disabled={strategy.pitStops.length >= 4}
                class="flex items-center gap-2 px-4 py-2 rounded-xl bg-app-primary/10 border border-app-primary/20 text-app-primary hover:bg-app-primary hover:text-app-primary-foreground transition-all disabled:opacity-30"
            >
                <Plus size={14} />
                <span class="text-[10px] font-black uppercase"
                    >{t('add_pit_stop')}</span
                >
            </button>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {#each strategy.pitStops as compound, i}
                <div
                    in:fly={{ y: 20 }}
                    class="bg-app-surface border border-app-border rounded-2xl p-5 space-y-6 relative overflow-hidden group"
                >
                    <div
                        class="absolute top-0 left-0 w-1 h-full bg-app-primary"
                    ></div>

                    <div class="flex items-center justify-between">
                        <div class="flex items-center gap-2">
                            <div
                                class="w-6 h-6 rounded-lg bg-app-text/5 flex items-center justify-center text-[10px] font-black"
                            >
                                #{i + 1}
                            </div>
                            <span
                                class="text-[10px] font-black uppercase tracking-widest text-app-text/60"
                                >{t('stint_config')}</span
                            >
                        </div>
                        <button
                            onclick={() => removePitStop(i)}
                            class="text-app-text/20 hover:text-red-500 transition-colors"
                        >
                            <Trash2 size={14} />
                        </button>
                    </div>

                    <div class="space-y-4">
                        <!-- Tyre -->
                        <div class="flex items-center justify-between">
                            <span
                                class="text-[10px] font-black text-app-text/30 uppercase"
                                >{t('compound')}</span
                            >
                            <div class="flex gap-1.5">
                                {#each [TyreCompound.soft, TyreCompound.medium, TyreCompound.hard, TyreCompound.wet] as tc}
                                    <button
                                        class="w-7 h-7 rounded-lg border flex items-center justify-center text-[8px] font-black transition-all {strategy.pitStops[i] === tc
                                            ? tc === TyreCompound.soft ? 'bg-red-600 border-red-600 text-white' : 
                                              tc === TyreCompound.medium ? 'bg-yellow-500 border-yellow-500 text-black' : 
                                              tc === TyreCompound.hard ? 'bg-zinc-100 border-zinc-100 text-black' : 
                                              'bg-blue-600 border-blue-600 text-white'
                                            : 'bg-app-text/5 border-transparent text-app-text/20 hover:bg-app-text/10'}"
                                        onclick={() =>
                                            (strategy.pitStops[i] = tc)}
                                    >
                                        {tc[0].toUpperCase()}
                                    </button>
                                {/each}
                            </div>
                        </div>

                        <!-- Fuel -->
                        <div class="space-y-2">
                            <div
                                class="flex justify-between text-[9px] font-black uppercase text-app-text/40"
                            >
                                <span>{t('fuel_to_add')}</span>
                                <span class="text-app-text"
                                    >{strategy.pitStopFuel[i]} L</span
                                >
                            </div>
                            <input
                                type="range"
                                min="0"
                                max="80"
                                bind:value={strategy.pitStopFuel[i]}
                                class="w-full h-1 bg-app-text/5 rounded-full appearance-none cursor-pointer accent-white/20"
                            />
                        </div>

                        <!-- Style -->
                        <div class="flex items-center justify-between">
                            <span
                                class="text-[10px] font-black text-app-text/30 uppercase"
                                >{t('aggression')}</span
                            >
                            <div class="flex gap-1">
                                {#each styleConfigs as style}
                                    <button
                                        class="w-7 h-7 rounded bg-app-text/5 flex items-center justify-center transition-all {strategy
                                            .pitStopStyles[i] === style.id
                                            ? 'bg-app-text/10 text-app-text border border-app-border'
                                            : 'text-app-text/20'}"
                                        onclick={() =>
                                            (strategy.pitStopStyles[i] =
                                                style.id)}
                                    >
                                        <style.icon size={12} />
                                    </button>
                                {/each}
                            </div>
                        </div>
                    </div>
                </div>
            {/each}

            {#if strategy.pitStops.length === 0}
                <div
                    class="border border-dashed border-app-border rounded-2xl p-10 flex flex-col items-center justify-center text-center opacity-20"
                >
                    <History size={32} class="mb-3" />
                    <p class="text-[10px] font-black uppercase tracking-widest">
                        {t('no_stops_planned')}
                    </p>
                    <p class="text-[8px] font-bold mt-1">
                        {t('single_stint_strategy')}
                    </p>
                </div>
            {/if}
        </div>
    </div>

    <!-- Actions -->
    <div class="lg:col-span-12 pt-4">
        <button
            class="w-full py-5 bg-app-primary text-app-primary-foreground font-black uppercase tracking-[0.2em] text-xs rounded-2xl hover:scale-[1.01] active:scale-95 transition-all shadow-xl shadow-app-primary/10 flex items-center justify-center gap-3 disabled:opacity-50"
            disabled={isSaving || !driver}
            onclick={saveStrategy}
        >
            {#if isSaving}
                <div
                    class="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin"
                ></div>
                {t('updating_telemetry')}
            {:else}
                <Save size={18} />
                {t('submit_race_strategy')}
            {/if}
        </button>
    </div>
</div>
{/if}
