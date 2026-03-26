<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { staffService } from "$lib/services/staff.svelte";
    import {
        PSYCHOLOGIST_SALARY_BY_LEVEL,
        PSYCHOLOGIST_BONUS_BY_LEVEL,
        PSYCHOLOGIST_UPGRADE_COSTS,
        PSYCHOLOGIST_MAX_LEVEL,
    } from "$lib/constants/economics";
    import {
        ChevronLeft,
        Brain,
        Star,
        TrendingUp,
        Zap,
        Wallet,
        ArrowUp,
        ArrowDown,
        Info,
        Lock,
    } from "lucide-svelte";
    import { type Driver } from "$lib/types";
    import { t } from "$lib/utils/i18n";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";

    let team = $derived(teamStore.value.team);
    let isLoading = $derived(teamStore.value.loading);

    let psychologistName = $derived(
        team?.weekStatus?.psychologistName || "Dr. Sofia Marchetti",
    );
    let psychologistCountry = $derived(
        team?.weekStatus?.psychologistCountry || "IT",
    );
    let psychologistLevel = $derived(team?.weekStatus?.psychologistLevel || 1);
    let assignedPilotId = $derived(team?.weekStatus?.psychologistAssignedTo);

    let hasUpgradedThisWeek = $derived(
        team?.weekStatus?.psychologistUpgradedThisWeek || false,
    );
    let hasSessionThisWeek = $derived(
        team?.weekStatus?.psychologistSessionDoneThisWeek || false,
    );

    let drivers = $state<Driver[]>([]);
    let selectedPilotId = $state<string | undefined>(undefined);
    let isSessionRunning = $state(false);
    let isUpgrading = $state(false);

    const bonusByLevel = PSYCHOLOGIST_BONUS_BY_LEVEL;
    const salaryByLevel = PSYCHOLOGIST_SALARY_BY_LEVEL;
    const upgradeCosts = PSYCHOLOGIST_UPGRADE_COSTS;

    $effect(() => {
        if (team?.id) {
            staffService.getTeamDrivers(team.id).then((d) => {
                drivers = d.filter((driver) => !driver.statusTitle?.includes("Academy"));
            });
        }
    });

    $effect(() => {
        if (assignedPilotId && !selectedPilotId) {
            selectedPilotId = assignedPilotId;
        }
    });

    async function handleSession() {
        if (!team?.id || !selectedPilotId || hasSessionThisWeek) return;
        isSessionRunning = true;
        try {
            if (selectedPilotId !== assignedPilotId) {
                await staffService.savePsychologistAssignment(team.id, { assignedToId: selectedPilotId });
            }
            await staffService.boostMoralePsychologist(
                team.id,
                selectedPilotId,
                bonusByLevel[psychologistLevel],
            );
        } finally {
            isSessionRunning = false;
        }
    }

    async function handleChangeLevel(targetIsUpgrade: boolean) {
        if (!team?.id || hasUpgradedThisWeek) return;
        const newLevel = targetIsUpgrade ? psychologistLevel + 1 : psychologistLevel - 1;
        if (newLevel < 1 || newLevel > PSYCHOLOGIST_MAX_LEVEL) return;
        const cost = targetIsUpgrade ? upgradeCosts[newLevel] : 0;
        if (targetIsUpgrade && (team.budget ?? 0) < cost) return;
        isUpgrading = true;
        try {
            await staffService.changePsychologistLevel(team.id, newLevel, cost, targetIsUpgrade);
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
        if (level >= 3) return "SENIOR";
        return "JUNIOR";
    }

    function getLevelColor(level: number) {
        if (level >= 5) return "text-purple-400 bg-purple-400/10 border-purple-400/20";
        if (level >= 3) return "text-violet-400 bg-violet-400/10 border-violet-400/20";
        return "text-slate-400 bg-slate-400/10 border-slate-400/20";
    }
</script>

<svelte:head>
    <title>HR Manager | Personnel | FTG</title>
</svelte:head>

<div class="p-6 md:p-10 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text min-h-screen">
    <!-- Breadcrumbs -->
    <nav class="flex items-center gap-2 mb-8 opacity-40 hover:opacity-100 transition-opacity">
        <a
            href="/management/personnel"
            class="flex items-center gap-1 text-[10px] font-black uppercase tracking-widest"
        >
            <ChevronLeft size={14} /> {t('personnel_hr_breadcrumb')}
        </a>
    </nav>

    {#if isLoading}
        <div class="flex items-center justify-center h-64">
            <div class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"></div>
        </div>
    {:else if team}
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-10 items-start">
            <!-- Left Column: HR Manager Details -->
            <div class="lg:col-span-2 flex flex-col gap-10">
                <!-- HR Manager Hero Card -->
                <div class="relative bg-app-surface border border-app-border rounded-[40px] p-10 overflow-hidden shadow-2xl">
                    <div class="absolute -right-20 -top-20 w-80 h-80 bg-purple-400/10 blur-[100px] rounded-full"></div>

                    <div class="relative flex flex-col md:flex-row items-center gap-10">
                        <div class="relative">
                            <div class="w-32 h-32 rounded-full border-4 border-purple-400/20 p-1">
                                <img
                                    src="/staff/hr_manager.png"
                                    alt="HR Manager"
                                    class="w-full h-full rounded-full object-cover"
                                />
                            </div>
                            <div class="absolute -bottom-2 -right-2 bg-purple-400 text-black p-2 rounded-xl shadow-lg">
                                <Brain size={18} />
                            </div>
                        </div>

                        <div class="flex flex-col gap-4 text-center md:text-left flex-1">
                            <div class="flex flex-col gap-1">
                                <div class="flex items-center justify-center md:justify-start gap-3 mb-1">
                                    <CountryFlag countryCode={psychologistCountry} size="md" />
                                    <span class="px-3 py-1 rounded-full text-[9px] font-black tracking-widest uppercase {getLevelColor(psychologistLevel)}">
                                        {getLevelLabel(psychologistLevel)} • LEVEL {psychologistLevel}
                                    </span>
                                </div>
                                <h2 class="text-4xl font-heading font-black tracking-tighter text-app-text uppercase italic">
                                    {psychologistName}
                                </h2>
                            </div>

                            <div class="flex flex-wrap items-center justify-center md:justify-start gap-6">
                                <div class="flex items-center gap-3">
                                    <div class="p-2 bg-app-text/5 rounded-lg text-purple-400">
                                        <TrendingUp size={16} />
                                    </div>
                                    <div class="flex flex-col">
                                        <span class="text-[9px] font-black text-app-text/20 uppercase tracking-widest">{t('hr_weekly_morale_label')}</span>
                                        <span class="text-sm font-black text-app-text">+{bonusByLevel[psychologistLevel]} pts / Session</span>
                                    </div>
                                </div>
                                <div class="flex items-center gap-3">
                                    <div class="p-2 bg-app-text/5 rounded-lg text-yellow-400">
                                        <Wallet size={16} />
                                    </div>
                                    <div class="flex flex-col">
                                        <span class="text-[9px] font-black text-app-text/20 uppercase tracking-widest">{t('hr_weekly_salary_label')}</span>
                                        <span class="text-sm font-black text-app-text">
                                            {salaryByLevel[psychologistLevel] === 0
                                                ? "FREE"
                                                : formatCurrency(salaryByLevel[psychologistLevel])}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Assignment & Session Panel -->
                <section class="flex flex-col gap-6">
                    <h3 class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2">
                        {t('hr_operational_control_header')}
                    </h3>

                    <div class="bg-app-surface border border-app-border rounded-[32px] p-8 flex flex-col gap-8">
                        <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
                            <div class="flex flex-col gap-3 w-full">
                                <span class="text-[10px] font-black text-app-text/20 uppercase tracking-widest">{t('hr_target_pilot_label')}</span>
                                <div class="flex flex-col gap-2">
                                    {#each drivers as pilot}
                                        {@const morale = pilot.stats?.morale ?? 70}
                                        {@const form = pilot.form ?? 5}
                                        {@const isSelected = selectedPilotId === pilot.id}
                                        {@const isSessionDone = hasSessionThisWeek && assignedPilotId === pilot.id}
                                        <button
                                            onclick={() => { if (!hasSessionThisWeek) selectedPilotId = pilot.id; }}
                                            disabled={hasSessionThisWeek}
                                            class="w-full text-left px-4 py-3 rounded-2xl border transition-all
                                                {isSelected
                                                    ? 'bg-purple-400/10 border-purple-400/50'
                                                    : 'bg-app-text/5 border-app-border hover:border-purple-400/30'}
                                                disabled:opacity-50 disabled:cursor-not-allowed"
                                        >
                                            <div class="flex items-center justify-between gap-4">
                                                <div class="flex items-center gap-2 min-w-0">
                                                    <span class="text-xs font-black text-app-text uppercase tracking-tight truncate">
                                                        {pilot.name}
                                                    </span>
                                                    {#if isSessionDone}
                                                        <span class="shrink-0 px-1.5 py-0.5 bg-purple-400/15 border border-purple-400/30 text-purple-400 text-[8px] font-black uppercase tracking-widest rounded-full">Session</span>
                                                    {/if}
                                                </div>
                                                <div class="flex items-center gap-4 shrink-0">
                                                    <!-- Morale -->
                                                    <div class="flex flex-col items-end gap-0.5">
                                                        <span class="text-[8px] font-bold text-app-text/30 uppercase tracking-widest">Moral</span>
                                                        <div class="flex items-center gap-1.5">
                                                            <div class="w-16 h-1.5 bg-app-text/10 rounded-full overflow-hidden">
                                                                <div
                                                                    class="h-full rounded-full transition-all
                                                                        {morale >= 70 ? 'bg-purple-400' : morale >= 40 ? 'bg-yellow-400' : 'bg-red-400'}"
                                                                    style="width: {morale}%"
                                                                ></div>
                                                            </div>
                                                            <span class="text-[10px] font-black tabular-nums
                                                                {morale >= 70 ? 'text-purple-400' : morale >= 40 ? 'text-yellow-400' : 'text-red-400'}">
                                                                {morale}%
                                                            </span>
                                                        </div>
                                                    </div>
                                                    <!-- Form -->
                                                    <div class="flex flex-col items-end gap-0.5">
                                                        <span class="text-[8px] font-bold text-app-text/30 uppercase tracking-widest">Forma</span>
                                                        <span class="text-[10px] font-black tabular-nums
                                                            {form >= 7 ? 'text-green-400' : form >= 4 ? 'text-yellow-400' : 'text-red-400'}">
                                                            {form.toFixed(1)}
                                                        </span>
                                                    </div>
                                                </div>
                                            </div>
                                        </button>
                                    {/each}
                                </div>

                            </div>

                            <button
                                disabled={!selectedPilotId || hasSessionThisWeek || isSessionRunning}
                                onclick={handleSession}
                                class="flex-1 md:flex-none px-8 py-4 bg-purple-400 text-black rounded-2xl font-black text-xs uppercase tracking-widest flex items-center justify-center gap-2 hover:scale-105 transition-all disabled:opacity-20 disabled:scale-100 disabled:grayscale"
                            >
                                {#if isSessionRunning}
                                    <div class="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin"></div>
                                {:else}
                                    <Zap size={14} fill="currentColor" /> SESSION
                                {/if}
                            </button>
                        </div>

                        {#if hasSessionThisWeek}
                            <div class="p-4 bg-app-primary/5 border border-app-primary/20 rounded-2xl flex items-center gap-3">
                                <Info size={16} class="text-app-primary" />
                                <p class="text-[10px] font-bold text-app-primary/60 uppercase tracking-widest leading-relaxed">
                                    {t('hr_session_completed')}
                                </p>
                            </div>
                        {/if}

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {#if psychologistLevel < PSYCHOLOGIST_MAX_LEVEL}
                                <button
                                    disabled={hasUpgradedThisWeek || isUpgrading || (team.budget ?? 0) < upgradeCosts[psychologistLevel + 1]}
                                    onclick={() => handleChangeLevel(true)}
                                    class="p-6 bg-app-text/5 border border-app-border rounded-2xl flex flex-col items-center gap-2 hover:border-app-primary transition-all disabled:opacity-20 flex-1"
                                >
                                    <ArrowUp size={20} class="text-app-primary" />
                                    <span class="text-[9px] font-black text-app-text/40 uppercase tracking-widest">Upgrade to Level {psychologistLevel + 1}</span>
                                    <span class="text-sm font-black text-app-text italic">{formatCurrency(upgradeCosts[psychologistLevel + 1])}</span>
                                </button>
                            {/if}

                            {#if psychologistLevel > 1}
                                <button
                                    disabled={hasUpgradedThisWeek || isUpgrading}
                                    onclick={() => handleChangeLevel(false)}
                                    class="p-6 bg-app-text/5 border border-app-border rounded-2xl flex flex-col items-center gap-2 hover:border-red-400 transition-all disabled:opacity-20 flex-1"
                                >
                                    <ArrowDown size={20} class="text-red-400" />
                                    <span class="text-[9px] font-black text-app-text/40 uppercase tracking-widest">Downgrade to Level {psychologistLevel - 1}</span>
                                    <span class="text-sm font-black text-app-text italic">FREE</span>
                                </button>
                            {/if}

                            {#if psychologistLevel === PSYCHOLOGIST_MAX_LEVEL}
                                <div class="p-6 bg-app-text/20 border border-app-border rounded-2xl flex flex-col items-center justify-center gap-2 text-center">
                                    <span class="text-[9px] font-black text-app-text/20 uppercase tracking-widest">Staff Status</span>
                                    <span class="text-xs font-bold text-app-text/60">Elite Level Reached</span>
                                </div>
                            {:else if psychologistLevel === 1 && !hasUpgradedThisWeek}
                                <div class="p-6 bg-app-text/20 border border-app-border rounded-2xl flex flex-col items-center justify-center gap-2 text-center">
                                    <span class="text-[9px] font-black text-app-text/20 uppercase tracking-widest">Staff Status</span>
                                    <span class="text-xs font-bold text-app-text/60">Ready for Operations</span>
                                </div>
                            {/if}
                        </div>
                    </div>
                </section>
            </div>

            <!-- Right Column: Manual / Instructions -->
            <div class="flex flex-col gap-10">
                <section class="flex flex-col gap-6">
                    <h3 class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2">
                        {t('hr_trainer_manual_header')}
                    </h3>
                    <div class="bg-app-surface border border-app-border rounded-[32px] p-8 flex flex-col gap-6">
                        <ul class="flex flex-col gap-5">
                            <li class="flex items-start gap-4">
                                <div class="mt-1 p-1 bg-purple-400/20 text-purple-400 rounded-md">
                                    <Star size={12} fill="currentColor" />
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span class="text-[10px] font-black text-app-text uppercase tracking-widest">Morale Boost</span>
                                    <p class="text-[11px] font-medium text-app-text/40 leading-relaxed">
                                        Higher level HR Managers deliver a larger morale boost per session to the assigned driver.
                                    </p>
                                </div>
                            </li>
                            <li class="flex items-start gap-4">
                                <div class="mt-1 p-1 bg-yellow-400/20 text-yellow-400 rounded-md">
                                    <Zap size={12} fill="currentColor" />
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span class="text-[10px] font-black text-app-text uppercase tracking-widest">Session Limit</span>
                                    <p class="text-[11px] font-medium text-app-text/40 leading-relaxed">
                                        One manual session per week. Morale also changes automatically based on race results and team events.
                                    </p>
                                </div>
                            </li>
                            <li class="flex items-start gap-4">
                                <div class="mt-1 p-1 bg-red-400/20 text-red-400 rounded-md">
                                    <Lock size={12} fill="currentColor" />
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span class="text-[10px] font-black text-app-text uppercase tracking-widest">Morale Impact</span>
                                    <p class="text-[11px] font-medium text-app-text/40 leading-relaxed">
                                        Driver morale above 50% improves lap times. Below 50%, performance degrades. Range: 0–100%.
                                    </p>
                                </div>
                            </li>
                        </ul>
                    </div>
                </section>

                <!-- Tip Card -->
                <div class="bg-purple-400/5 border border-purple-400/20 rounded-[32px] p-8">
                    <h4 class="text-xs font-black text-purple-400 uppercase tracking-[0.2em] mb-4">Strategic Tip</h4>
                    <p class="text-[11px] font-medium text-app-text/60 leading-relaxed italic">
                        {t('hr_strategic_tip')}
                    </p>
                </div>
            </div>
        </div>
    {/if}
</div>
