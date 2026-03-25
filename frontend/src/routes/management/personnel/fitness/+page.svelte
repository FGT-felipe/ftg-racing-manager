<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { staffService } from "$lib/services/staff.svelte";
    import {
        FITNESS_TRAINER_SALARY_BY_LEVEL,
        FITNESS_TRAINER_BONUS_BY_LEVEL,
        FITNESS_TRAINER_UPGRADE_COSTS,
        FITNESS_TRAINER_MAX_LEVEL,
    } from "$lib/constants/economics";
    import {
        ChevronLeft,
        Dumbbell,
        Star,
        TrendingUp,
        Zap,
        Wallet,
        ArrowUp,
        ArrowDown,
        Info,
        User,
        Lock,
    } from "lucide-svelte";
    import { fly, fade } from "svelte/transition";
    import { type Driver } from "$lib/types";

    let team = $derived(teamStore.value.team);
    let isLoading = $derived(teamStore.value.loading);

    // Derived staff data from weekStatus
    let trainerName = $derived(
        team?.weekStatus?.fitnessTrainerName || "Aleksei Ivanov",
    );
    let trainerCountry = $derived(
        team?.weekStatus?.fitnessTrainerCountry || "RU",
    );
    let trainerLevel = $derived(team?.weekStatus?.fitnessTrainerLevel || 1);
    let assignedPilotId = $derived(team?.weekStatus?.fitnessTrainerAssignedTo);

    let hasUpgradedThisWeek = $derived(
        team?.weekStatus?.fitnessTrainerUpgradedThisWeek || false,
    );
    let hasTrainedThisWeek = $derived(
        team?.weekStatus?.fitnessTrainerTrainedThisWeek || false,
    );

    let drivers = $state<Driver[]>([]);
    let selectedPilotId = $state<string | undefined>(undefined);
    let isTraining = $state(false);
    let isUpgrading = $state(false);
    let isSaving = $state(false);

    const salaryByLevel = FITNESS_TRAINER_SALARY_BY_LEVEL;
    const bonusByLevel = FITNESS_TRAINER_BONUS_BY_LEVEL;
    const upgradeCosts = FITNESS_TRAINER_UPGRADE_COSTS;

    $effect(() => {
        if (team?.id) {
            staffService.getTeamDrivers(team.id).then((d) => {
                // Filter out academy drivers if necessary, replicating Flutter logic
                drivers = d.filter(
                    (driver) => !driver.statusTitle?.includes("Academy"),
                );
            });
        }
    });

    $effect(() => {
        if (assignedPilotId && !selectedPilotId) {
            selectedPilotId = assignedPilotId;
        }
    });

    async function handleTrain() {
        if (!team?.id || !assignedPilotId || hasTrainedThisWeek) return;
        isTraining = true;
        try {
            await staffService.trainPilot(
                team.id,
                assignedPilotId,
                bonusByLevel[trainerLevel],
            );
        } finally {
            isTraining = false;
        }
    }

    async function handleSaveAssignment() {
        if (!team?.id || !selectedPilotId || isSaving) return;
        isSaving = true;
        try {
            await staffService.saveFitnessAssignment(team.id, {
                assignedToId: selectedPilotId,
            });
        } finally {
            isSaving = false;
        }
    }

    async function handleChangeLevel(targetIsUpgrade: boolean) {
        if (!team?.id || hasUpgradedThisWeek) return;

        const newLevel = targetIsUpgrade ? trainerLevel + 1 : trainerLevel - 1;
        if (newLevel < 1 || newLevel > 5) return;

        const cost = targetIsUpgrade ? upgradeCosts[newLevel] : 0;
        if (targetIsUpgrade && team.budget < cost) return;

        isUpgrading = true;
        try {
            await staffService.changeTrainerLevel(
                team.id,
                newLevel,
                cost,
                targetIsUpgrade,
            );
        } finally {
            isUpgrading = false;
        }
    }

    function formatCurrency(amount: number) {
        return new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: "USD",
            maximumFractionDigits: 0,
        }).format(amount);
    }

    function getLevelLabel(level: number) {
        if (level >= 5) return "ELITE";
        if (level >= 3) return "PRO";
        return "AMATEUR";
    }

    function getLevelColor(level: number) {
        if (level >= 5)
            return "text-green-400 bg-green-400/10 border-green-400/20";
        if (level >= 3)
            return "text-yellow-400 bg-yellow-400/10 border-yellow-400/20";
        return "text-slate-400 bg-slate-400/10 border-slate-400/20";
    }
</script>

<svelte:head>
    <title>Fitness Trainer | Personnel | FTG</title>
</svelte:head>

<div
    class="p-6 md:p-10 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text min-h-screen"
>
    <!-- Breadcrumbs -->
    <nav
        class="flex items-center gap-2 mb-8 opacity-40 hover:opacity-100 transition-opacity"
    >
        <a
            href="/management/personnel"
            class="flex items-center gap-1 text-[10px] font-black uppercase tracking-widest"
        >
            <ChevronLeft size={14} /> Personnel Hub
        </a>
    </nav>

    {#if isLoading}
        <div class="flex items-center justify-center h-64">
            <div
                class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"
            ></div>
        </div>
    {:else if team}
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-10 items-start">
            <!-- Left Column: Trainer Details -->
            <div class="lg:col-span-2 flex flex-col gap-10">
                <!-- Trainer Hero Card -->
                <div
                    class="relative bg-app-surface border border-app-border rounded-[40px] p-10 overflow-hidden shadow-2xl"
                >
                    <div
                        class="absolute -right-20 -top-20 w-80 h-80 bg-green-400/10 blur-[100px] rounded-full"
                    ></div>

                    <div
                        class="relative flex flex-col md:flex-row items-center gap-10"
                    >
                        <div class="relative">
                            <div
                                class="w-32 h-32 rounded-full border-4 border-green-400/20 p-1"
                            >
                                <img
                                    src="/staff/fitness_trainer.png"
                                    alt="Trainer"
                                    class="w-full h-full rounded-full object-cover"
                                />
                            </div>
                            <div
                                class="absolute -bottom-2 -right-2 bg-green-400 text-black p-2 rounded-xl shadow-lg"
                            >
                                <Dumbbell size={18} />
                            </div>
                        </div>

                        <div
                            class="flex flex-col gap-4 text-center md:text-left flex-1"
                        >
                            <div class="flex flex-col gap-1">
                                <div
                                    class="flex items-center justify-center md:justify-start gap-3 mb-1"
                                >
                                    <span class="text-xl">🇷🇺</span>
                                    <span
                                        class="px-3 py-1 rounded-full text-[9px] font-black tracking-widest uppercase {getLevelColor(
                                            trainerLevel,
                                        )}"
                                    >
                                        {getLevelLabel(trainerLevel)} • LEVEL {trainerLevel}
                                    </span>
                                </div>
                                <h2
                                    class="text-4xl font-heading font-black tracking-tighter text-app-text uppercase italic"
                                >
                                    {trainerName}
                                </h2>
                            </div>

                            <div
                                class="flex flex-wrap items-center justify-center md:justify-start gap-6"
                            >
                                <div class="flex items-center gap-3">
                                    <div
                                        class="p-2 bg-app-text/5 rounded-lg text-green-400"
                                    >
                                        <TrendingUp size={16} />
                                    </div>
                                    <div class="flex flex-col">
                                        <span
                                            class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                                            >Recovery Bonus</span
                                        >
                                        <span
                                            class="text-sm font-black text-app-text"
                                            >+{bonusByLevel[trainerLevel]}% /
                                            Week</span
                                        >
                                    </div>
                                </div>
                                <div class="flex items-center gap-3">
                                    <div
                                        class="p-2 bg-app-text/5 rounded-lg text-yellow-400"
                                    >
                                        <Wallet size={16} />
                                    </div>
                                    <div class="flex flex-col">
                                        <span
                                            class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                                            >Weekly Salary</span
                                        >
                                        <span
                                            class="text-sm font-black text-app-text"
                                            >{salaryByLevel[trainerLevel] === 0
                                                ? "FREE"
                                                : formatCurrency(
                                                      salaryByLevel[
                                                          trainerLevel
                                                      ],
                                                  )}</span
                                        >
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Assignment & Training Panel -->
                <section class="flex flex-col gap-6">
                    <h3
                        class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2"
                    >
                        Operational Control
                    </h3>

                    <div
                        class="bg-app-surface border border-app-border rounded-[32px] p-8 flex flex-col gap-8"
                    >
                        <div
                            class="flex flex-col md:flex-row md:items-center justify-between gap-6"
                        >
                            <div class="flex flex-col gap-1">
                                <span
                                    class="text-[10px] font-black text-app-text/20 uppercase tracking-widest"
                                    >Target Pilot</span
                                >
                                <div class="flex items-center gap-3">
                                    <select
                                        bind:value={selectedPilotId}
                                        disabled={hasTrainedThisWeek ||
                                            isSaving}
                                        class="bg-app-surface border border-app-border rounded-xl px-4 py-2 text-sm font-bold text-app-text outline-none focus:border-app-primary/30 transition-all cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
                                    >
                                        <option value={undefined} disabled
                                            >Select a pilot</option
                                        >
                                        {#each drivers as pilot}
                                            <option value={pilot.id}
                                                >{pilot.name}</option
                                            >
                                        {/each}
                                    </select>

                                    {#if selectedPilotId && selectedPilotId !== assignedPilotId}
                                        <button
                                            onclick={handleSaveAssignment}
                                            disabled={isSaving}
                                            class="px-4 py-2 bg-green-400 text-black rounded-xl font-black text-[10px] uppercase tracking-widest hover:scale-105 transition-all disabled:opacity-50"
                                        >
                                            {#if isSaving}
                                                Saving...
                                            {:else}
                                                Save Assignment
                                            {/if}
                                        </button>
                                    {/if}
                                </div>
                            </div>

                            <div class="flex items-center gap-4">
                                <button
                                    disabled={!assignedPilotId ||
                                        hasTrainedThisWeek ||
                                        isTraining}
                                    onclick={handleTrain}
                                    class="flex-1 md:flex-none px-8 py-4 bg-yellow-400 text-black rounded-2xl font-black text-xs uppercase tracking-widest flex items-center justify-center gap-2 hover:scale-105 transition-all disabled:opacity-20 disabled:scale-100 disabled:grayscale"
                                >
                                    {#if isTraining}
                                        <div
                                            class="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin"
                                        ></div>
                                    {:else}
                                        <Zap size={14} fill="currentColor" /> TRAIN
                                        PILOT
                                    {/if}
                                </button>
                            </div>
                        </div>

                        {#if hasTrainedThisWeek}
                            <div
                                class="p-4 bg-app-primary/5 border border-app-primary/20 rounded-2xl flex items-center gap-3"
                            >
                                <Info size={16} class="text-app-primary" />
                                <p
                                    class="text-[10px] font-bold text-app-primary/60 uppercase tracking-widest leading-relaxed"
                                >
                                    Training session completed for this week.
                                    Wait for the next season update to perform
                                    manual recovery.
                                </p>
                            </div>
                        {/if}

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {#if trainerLevel < 5}
                                <button
                                    disabled={hasUpgradedThisWeek ||
                                        isUpgrading ||
                                        team.budget <
                                            upgradeCosts[trainerLevel + 1]}
                                    onclick={() => handleChangeLevel(true)}
                                    class="p-6 bg-app-text/5 border border-app-border rounded-2xl flex flex-col items-center gap-2 hover:border-app-primary transition-all disabled:opacity-20 flex-1"
                                >
                                    <ArrowUp
                                        size={20}
                                        class="text-app-primary"
                                    />
                                    <span
                                        class="text-[9px] font-black text-app-text/40 uppercase tracking-widest"
                                        >Upgrade to Level {trainerLevel +
                                            1}</span
                                    >
                                    <span
                                        class="text-sm font-black text-app-text italic"
                                        >{formatCurrency(
                                            upgradeCosts[trainerLevel + 1],
                                        )}</span
                                    >
                                </button>
                            {/if}

                            {#if trainerLevel > 1}
                                <button
                                    disabled={hasUpgradedThisWeek ||
                                        isUpgrading}
                                    onclick={() => handleChangeLevel(false)}
                                    class="p-6 bg-app-text/5 border border-app-border rounded-2xl flex flex-col items-center gap-2 hover:border-red-400 transition-all disabled:opacity-20 flex-1"
                                >
                                    <ArrowDown size={20} class="text-red-400" />
                                    <span
                                        class="text-[9px] font-black text-app-text/40 uppercase tracking-widest"
                                        >Downgrade to Level {trainerLevel -
                                            1}</span
                                    >
                                    <span
                                        class="text-sm font-black text-app-text italic"
                                        >FREE</span
                                    >
                                </button>
                            {/if}

                            {#if trainerLevel === 5}
                                <div
                                    class="p-6 bg-app-text/20 border border-app-border rounded-2xl flex flex-col items-center justify-center gap-2 text-center"
                                >
                                    <span
                                        class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                                        >Staff Status</span
                                    >
                                    <span
                                        class="text-xs font-bold text-app-text/60"
                                        >Elite Level Reached</span
                                    >
                                </div>
                            {:else if trainerLevel === 1 && !hasUpgradedThisWeek}
                                <div
                                    class="p-6 bg-app-text/20 border border-app-border rounded-2xl flex flex-col items-center justify-center gap-2 text-center"
                                >
                                    <span
                                        class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                                        >Staff Status</span
                                    >
                                    <span
                                        class="text-xs font-bold text-app-text/60"
                                        >Ready for Operations</span
                                    >
                                </div>
                            {/if}
                        </div>
                    </div>
                </section>
            </div>

            <!-- Right Column: Manual/Instructions -->
            <div class="flex flex-col gap-10">
                <section class="flex flex-col gap-6">
                    <h3
                        class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2"
                    >
                        Trainer Manual
                    </h3>
                    <div
                        class="bg-app-surface border border-app-border rounded-[32px] p-8 flex flex-col gap-6"
                    >
                        <ul class="flex flex-col gap-5">
                            <li class="flex items-start gap-4">
                                <div
                                    class="mt-1 p-1 bg-green-400/20 text-green-400 rounded-md"
                                >
                                    <Star size={12} fill="currentColor" />
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-black text-app-text uppercase tracking-widest"
                                        >Weekly Recovery</span
                                    >
                                    <p
                                        class="text-[11px] font-medium text-app-text/40 leading-relaxed"
                                    >
                                        Higher level trainers provide larger
                                        automatic fitness recovery each week.
                                    </p>
                                </div>
                            </li>
                            <li class="flex items-start gap-4">
                                <div
                                    class="mt-1 p-1 bg-yellow-400/20 text-yellow-400 rounded-md"
                                >
                                    <Zap size={12} fill="currentColor" />
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-black text-app-text uppercase tracking-widest"
                                        >Manual Boost</span
                                    >
                                    <p
                                        class="text-[11px] font-medium text-app-text/40 leading-relaxed"
                                    >
                                        Perform extra training once per week to
                                        boost the assigned pilot's energy.
                                    </p>
                                </div>
                            </li>
                            <li class="flex items-start gap-4">
                                <div
                                    class="mt-1 p-1 bg-red-400/20 text-red-400 rounded-md"
                                >
                                    <Lock size={12} fill="currentColor" />
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-black text-app-text uppercase tracking-widest"
                                        >Weekly Limit</span
                                    >
                                    <p
                                        class="text-[11px] font-medium text-app-text/40 leading-relaxed"
                                    >
                                        You can only upgrade or perform extra
                                        training once per week cycle.
                                    </p>
                                </div>
                            </li>
                        </ul>
                    </div>
                </section>

                <!-- Tip Card -->
                <div
                    class="bg-blue-400/5 border border-blue-400/20 rounded-[32px] p-8"
                >
                    <h4
                        class="text-xs font-black text-blue-400 uppercase tracking-[0.2em] mb-4"
                    >
                        Strategic Tip
                    </h4>
                    <p
                        class="text-[11px] font-medium text-app-text/60 leading-relaxed italic"
                    >
                        "Keeping your star driver at 100% fitness significantly
                        reduces the risk of errors during the final stages of a
                        race. Don't neglect recovery."
                    </p>
                </div>
            </div>
        </div>
    {/if}
</div>
