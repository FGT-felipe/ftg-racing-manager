<script lang="ts">
    import { youthAcademyStore } from "$lib/stores/youthAcademy.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { browser } from "$app/environment";
    import {
        School,
        TrendingUp,
        UserPlus,
        XCircle,
        Star,
        AlertTriangle,
        ArrowUpCircle,
        Users,
        Target,
        Globe,
        User as UserIcon,
        Brain,
        Shield,
        Zap,
        Eye,
        Activity,
        Repeat,
    } from "lucide-svelte";
    import InstructionCard from "$lib/components/layout/InstructionCard.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import DriverStars from "$lib/components/DriverStars.svelte";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import {
        calculateAcademyCurrentStars,
        calculateAcademyMaxStars,
    } from "$lib/utils/driver";
    import {
        t,
        translateAcademyNarrative,
        type TranslationKey,
    } from "$lib/utils/i18n";

    function getSpecialtyKey(
        specialty: string | null | undefined,
    ): TranslationKey | null {
        if (!specialty) return null;
        const s = specialty.toLowerCase().replace(/\s+/g, "_");
        if (s === "rainmaster") return "rain_master";
        if (s === "tyre_whisperer") return "tyre_whisperer";
        if (s === "late_braker") return "late_braker";
        if (s === "defensive_minister") return "defensive_minister";
        return null;
    }

    // Initialize stores
    $effect(() => {
        if (browser && teamStore.value.team?.id) {
            youthAcademyStore.init(teamStore.value.team.id);
        }
    });

    driverStore.init();

    const countries = [
        { code: "CO", name: "Colombia", flagEmoji: "🇨🇴" },
        { code: "BR", name: "Brazil", flagEmoji: "🇧🇷" },
        { code: "AR", name: "Argentina", flagEmoji: "🇦🇷" },
        { code: "MX", name: "Mexico", flagEmoji: "🇲🇽" },
        { code: "ES", name: "Spain", flagEmoji: "🇪🇸" },
        { code: "IT", name: "Italy", flagEmoji: "🇮🇹" },
        { code: "GB", name: "United Kingdom", flagEmoji: "🇬🇧" },
        { code: "DE", name: "Germany", flagEmoji: "🇩🇪" },
    ];

    let selectedCountry = $state(countries[0]);
    let isPurchasing = $state(false);
    let isUpgrading = $state(false);

    function formatCurrencyCompact(val: number) {
        if (val >= 1000000) return `$${(val / 1000000).toFixed(1)}M`;
        if (val >= 1000) return `$${(val / 1000).toFixed(0)}k`;
        return `$${val}`;
    }

    async function handlePurchase() {
        isPurchasing = true;
        try {
            await youthAcademyStore.purchaseAcademy(selectedCountry);
        } catch (e: any) {
            alert(e.message);
        } finally {
            isPurchasing = false;
        }
    }

    async function handleUpgrade() {
        isUpgrading = true;
        try {
            await youthAcademyStore.upgradeAcademy();
        } catch (e: any) {
            alert(e.message);
        } finally {
            isUpgrading = false;
        }
    }

    async function handleSelect(id: string) {
        try {
            await youthAcademyStore.selectCandidate(id);
        } catch (e: any) {
            alert(e.message);
        }
    }

    const StatIcons = {
        braking: Shield,
        cornering: TrendingUp,
        smoothness: Target,
        overtaking: Zap,
        consistency: Repeat,
        adaptability: Globe,
        focus: Brain,
        fitness: Activity,
    };
</script>

<svelte:head>
    <title>Youth Academy | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-4 md:p-8 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text min-h-screen"
>
    {#if youthAcademyStore.loading}
        <div class="flex flex-col items-center justify-center py-40 gap-6">
            <div class="relative">
                <div
                    class="w-16 h-16 border-4 border-emerald-500/10 border-t-emerald-500 rounded-full animate-spin"
                ></div>
                <School
                    class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-6 h-6 text-emerald-400 opacity-50"
                />
            </div>
            <p
                class="text-app-text/40 font-black tracking-[0.3em] text-[10px] uppercase animate-pulse"
            >
                {t("academy_sync")}
            </p>
        </div>
    {:else if !youthAcademyStore.config}
        <!-- Purchase View -->
        <div class="max-w-2xl mx-auto py-12 px-4 shadow-2xl">
            <div class="text-center mb-12">
                <div
                    class="w-24 h-24 bg-emerald-500/10 rounded-3xl flex items-center justify-center mx-auto mb-8 border border-emerald-500/20 shadow-2xl shadow-emerald-500/10 rotate-3 transition-transform hover:rotate-0 duration-500"
                >
                    <School class="w-12 h-12 text-emerald-400" />
                </div>
                <h1
                    class="text-5xl font-black tracking-tighter text-app-text mb-3 leading-none italic uppercase"
                >
                    {t("academy_title")}
                </h1>
                {t("academy_subtitle")}
            </div>

            <div
                class="bg-app-surface/60 border border-app-border rounded-3xl p-8 backdrop-blur-md mb-8 relative overflow-hidden group"
            >
                <!-- Decorative mesh -->
                <div
                    class="absolute top-0 right-0 w-32 h-32 bg-emerald-500/5 blur-3xl rounded-full -mr-16 -mt-16 transition-transform group-hover:scale-110"
                ></div>

                <h3
                    class="text-emerald-400 font-black text-[10px] tracking-[0.2em] uppercase mb-8 flex items-center gap-2"
                >
                    <Zap class="w-3.5 h-3.5" />
                    {t("operational_benefits")}
                </h3>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-8 mb-10">
                    <div class="flex items-start gap-4">
                        <div class="mt-1 p-2 bg-emerald-500/20 rounded-xl">
                            <TrendingUp class="w-5 h-5 text-emerald-400" />
                        </div>
                        <div>
                            <h4
                                class="text-app-text font-black text-sm mb-1 uppercase tracking-tight italic"
                            >
                                {t("active_scouting")}
                            </h4>
                            <p
                                class="text-app-text/40 text-[11px] leading-relaxed"
                            >
                                {t("scouting_desc")}
                            </p>
                        </div>
                    </div>
                    <div class="flex items-start gap-4">
                        <div class="mt-1 p-2 bg-emerald-500/20 rounded-xl">
                            <Brain class="w-5 h-5 text-emerald-400" />
                        </div>
                        <div>
                            <h4
                                class="text-app-text font-black text-sm mb-1 uppercase tracking-tight italic"
                            >
                                {t("elite_training")}
                            </h4>
                            <p
                                class="text-app-text/40 text-[11px] leading-relaxed"
                            >
                                {t("training_desc")}
                            </p>
                        </div>
                    </div>
                </div>

                <div
                    class="pt-8 border-t border-app-border grid grid-cols-2 gap-8"
                >
                    <div class="flex flex-col">
                        <span
                            class="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-1"
                            >{t("establishment_fee")}</span
                        >
                        <span
                            class="text-2xl font-black text-app-text italic tracking-tighter"
                            >{formatCurrencyCompact(10000)}</span
                        >
                    </div>
                    <div class="flex flex-col">
                        <span
                            class="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-1"
                            >{t("available_funds")}</span
                        >
                        <span
                            class="text-2xl font-black italic tracking-tighter {(teamStore
                                .value.team?.budget ?? 0) >= 10000
                                ? 'text-emerald-400'
                                : 'text-red-400'}"
                        >
                            {formatCurrencyCompact(
                                teamStore.value.team?.budget ?? 0,
                            )}
                        </span>
                    </div>
                </div>
            </div>

            <div
                class="bg-app-surface/40 border border-app-border rounded-3xl p-8 backdrop-blur-md mb-10"
            >
                <h3
                    class="text-emerald-400 font-black text-[10px] tracking-[0.2em] uppercase mb-6 flex items-center gap-2"
                >
                    <Globe class="w-3.5 h-3.5" />
                    {t("target_region_selection")}
                </h3>

                <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    {#each countries as country}
                        <button
                            class="p-4 rounded-2xl border-2 transition-all flex flex-col items-center gap-2 group
                            {selectedCountry.code === country.code
                                ? 'bg-emerald-500/10 border-emerald-500/50 text-app-text shadow-lg shadow-emerald-500/10'
                                : 'bg-app-text/20 border-app-border text-app-text/40 hover:border-app-border'}"
                            onclick={() => (selectedCountry = country)}
                        >
                            <span
                                class="text-3xl group-hover:scale-110 transition-transform"
                                >{country.flagEmoji}</span
                            >
                            <span
                                class="text-[10px] font-black uppercase tracking-tighter truncate w-full text-center"
                                >{country.name}</span
                            >
                        </button>
                    {/each}
                </div>
            </div>

            <button
                class="w-full py-5 rounded-2xl font-black tracking-[0.3em] uppercase transition-all relative overflow-hidden group
                {selectedCountry &&
                (teamStore.value.team?.budget ?? 0) >= 10000 &&
                !isPurchasing
                    ? 'bg-emerald-500 hover:bg-emerald-400 text-black shadow-2xl shadow-emerald-500/20 active:scale-[0.98]'
                    : 'bg-zinc-800 text-zinc-600 cursor-not-allowed'}"
                disabled={!selectedCountry ||
                    (teamStore.value.team?.budget ?? 0) < 10000 ||
                    isPurchasing}
                onclick={handlePurchase}
            >
                {#if isPurchasing}
                    <div class="flex items-center justify-center gap-3">
                        <div
                            class="w-5 h-5 border-2 border-black/30 border-t-black rounded-full animate-spin"
                        ></div>
                        <span>{t("acquiring_assets")}</span>
                    </div>
                {:else}
                    {t("initialize_hub")}
                {/if}
            </button>
        </div>
    {:else}
        <!-- Active Academy View -->

        <!-- Info Header Bar -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 mb-12">
            <!-- Main Info Card -->
            <div
                class="lg:col-span-9 bg-app-surface/60 border border-app-border rounded-[2.5rem] p-8 backdrop-blur-md relative overflow-hidden flex flex-col md:flex-row items-center gap-10"
            >
                <!-- Highlight -->
                <div
                    class="absolute -top-20 -right-20 w-64 h-64 bg-app-text/5 blur-3xl rounded-full"
                ></div>

                <div
                    class="flex items-center gap-8 pr-10 md:border-r border-app-border h-full"
                >
                    <div
                        class="w-24 h-24 bg-app-text/5 rounded-3xl flex items-center justify-center border border-app-border shadow-2xl rotate-3 transition-transform hover:rotate-0 duration-500 shrink-0"
                    >
                        <School class="w-12 h-12 text-app-text/40" />
                    </div>
                    <div>
                        <div class="flex items-center gap-4 mb-2">
                            <h2
                                class="text-4xl font-black text-app-text tracking-tighter uppercase italic leading-none"
                            >
                                {t("academy_header")}
                            </h2>
                            <div
                                class="flex gap-1 bg-app-text/40 px-2 py-1 rounded-lg border border-app-border"
                            >
                                {#each Array(5) as _, i}
                                    <Star
                                        class="w-3.5 h-3.5 {i <
                                        (youthAcademyStore.config
                                            ?.academyLevel ?? 1)
                                            ? 'text-app-text fill-white'
                                            : 'text-zinc-800'}"
                                    />
                                {/each}
                            </div>
                        </div>
                        <div class="flex items-center gap-2">
                            <span class="text-2xl"
                                >{youthAcademyStore.config?.countryFlag}</span
                            >
                            <span
                                class="text-[11px] font-black text-app-text/40 uppercase tracking-[0.2em]"
                                >{youthAcademyStore.config?.countryName}
                                {t("regional_hub")}</span
                            >
                        </div>
                    </div>
                </div>

                <div class="flex-1 flex flex-col gap-8 w-full">
                    <div
                        class="grid grid-cols-1 md:grid-cols-2 gap-10 w-full items-center"
                    >
                        <div class="flex flex-col">
                            <div class="flex justify-between items-end mb-2.5">
                                <span
                                    class="text-[10px] font-black text-app-text/40 uppercase tracking-[0.2em]"
                                    >{t("roster_capacity")}</span
                                >
                                <span class="text-sm font-black text-app-text"
                                    >{youthAcademyStore.selectedDrivers
                                        .length}<span class="text-zinc-600 mx-1"
                                        >/</span
                                    >{youthAcademyStore.maxSlots}</span
                                >
                            </div>
                            <div
                                class="w-full h-2 bg-app-text/60 rounded-full overflow-hidden border border-app-border p-[1px]"
                            >
                                <div
                                    class="h-full bg-zinc-200 rounded-full transition-all duration-1000 ease-out shadow-[0_0_10px_rgba(255,255,255,0.2)]"
                                    style="width: {(youthAcademyStore
                                        .selectedDrivers.length /
                                        youthAcademyStore.maxSlots) *
                                        100}%"
                                ></div>
                            </div>
                        </div>
                        <div class="flex flex-col">
                            <div class="flex justify-between items-end mb-2.5">
                                <span
                                    class="text-[10px] font-black text-app-text/40 uppercase tracking-[0.2em]"
                                    >{t("scouting_quota")}</span
                                >
                                <span class="text-sm font-black text-app-text"
                                    >{youthAcademyStore.selectedDrivers
                                        .length}<span class="text-zinc-600 mx-1"
                                        >/</span
                                    >{youthAcademyStore.scoutingQuota}</span
                                >
                            </div>
                            <div
                                class="w-full h-2 bg-app-text/60 rounded-full overflow-hidden border border-app-border p-[1px]"
                            >
                                <div
                                    class="h-full bg-app-text/20 rounded-full transition-all duration-1000 ease-out"
                                    style="width: {(youthAcademyStore
                                        .selectedDrivers.length /
                                        youthAcademyStore.scoutingQuota) *
                                        100}%"
                                ></div>
                            </div>
                        </div>
                    </div>

                    <div class="flex items-center justify-end">
                        <button
                            class="flex items-center gap-4 px-6 py-4 rounded-2xl transition-all border group relative overflow-hidden
                            {youthAcademyStore.canUpgrade && !isUpgrading
                                ? 'bg-app-text/10 border-app-border text-app-text hover:bg-app-text/20 active:scale-95'
                                : 'bg-app-bg/40 border-app-border text-zinc-700 opacity-50 cursor-not-allowed grayscale'}"
                            disabled={!youthAcademyStore.canUpgrade ||
                                isUpgrading}
                            onclick={handleUpgrade}
                        >
                            <ArrowUpCircle
                                class="w-6 h-6 transition-transform group-hover:scale-110"
                            />
                            <div class="flex flex-col items-start">
                                <span
                                    class="text-[9px] font-black uppercase tracking-[0.1em] leading-none mb-1"
                                >
                                    {#if youthAcademyStore.config?.academyLevel >= 5}
                                        {t("max_level")}
                                    {:else if !youthAcademyStore.canUpgrade && !isUpgrading}
                                        LIMIT REACHED
                                    {:else}
                                        {t("upgrade_facility")}
                                    {/if}
                                </span>
                                <span
                                    class="text-sm font-black tracking-tighter leading-none italic"
                                >
                                    {#if !youthAcademyStore.canUpgrade && !isUpgrading && youthAcademyStore.config?.academyLevel < 5}
                                        Next Season
                                    {:else}
                                        ${formatCurrencyCompact(
                                            1000000 *
                                                (youthAcademyStore.config
                                                    ?.academyLevel ?? 1),
                                        )}
                                    {/if}
                                </span>
                            </div>
                        </button>
                    </div>
                </div>
            </div>

            <!-- Promotion Focus Card -->
            <div
                class="lg:col-span-3 bg-app-surface/40 border border-app-border rounded-[2.5rem] p-8 backdrop-blur-md flex flex-col justify-between group overflow-hidden relative transition-all hover:bg-app-surface/60"
            >
                <div
                    class="absolute -bottom-10 -right-10 w-32 h-32 bg-app-text/5 blur-3xl rounded-full transition-transform group-hover:scale-150 duration-700"
                ></div>

                <div>
                    <h4
                        class="text-[10px] font-black text-app-text/40 uppercase tracking-[0.2em] mb-6"
                    >
                        {t("target_promotion")}
                    </h4>
                    {#if youthAcademyStore.selectedDrivers.some((d) => d.isMarkedForPromotion)}
                        {@const promoted =
                            youthAcademyStore.selectedDrivers.find(
                                (d) => d.isMarkedForPromotion,
                            )}
                        <div class="flex items-center gap-5">
                            <div
                                class="w-16 h-16 rounded-2xl bg-app-bg border border-emerald-500/50 overflow-hidden shadow-2xl transition-transform group-hover:-rotate-3"
                            >
                                {#if promoted}
                                    <DriverAvatar
                                        id={promoted.id}
                                        gender={promoted.gender}
                                        class="w-full h-full"
                                    />
                                {/if}
                            </div>
                            <div>
                                <h5
                                    class="text-app-text font-black text-lg tracking-tighter leading-none mb-1.5 uppercase italic truncate w-24"
                                >
                                    {promoted?.name.split(" ")[0]}
                                </h5>
                                <div class="flex items-center gap-2">
                                    <div
                                        class="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"
                                    ></div>
                                    <span
                                        class="text-[10px] font-black text-emerald-400 uppercase tracking-tighter"
                                        >{t("season_finale")}</span
                                    >
                                </div>
                            </div>
                        </div>
                    {:else}
                        <div
                            class="flex items-center gap-5 text-zinc-700 italic"
                        >
                            <div
                                class="w-16 h-16 rounded-2xl bg-app-text/40 border border-app-border flex items-center justify-center"
                            >
                                <Users class="w-8 h-8 opacity-20" />
                            </div>
                            <div>
                                <h5
                                    class="font-black text-sm tracking-tight leading-none mb-1 uppercase text-zinc-600"
                                >
                                    {t("no_target")}
                                </h5>
                                <span
                                    class="text-[9px] font-black uppercase tracking-tighter text-zinc-700"
                                    >{t("mark_graduand")}</span
                                >
                            </div>
                        </div>
                    {/if}
                </div>

                <div
                    class="pt-6 border-t border-app-border mt-8 flex items-center justify-between"
                >
                    <span
                        class="text-[10px] font-black text-zinc-600 uppercase tracking-widest"
                        >{t("team_size")}</span
                    >
                    <div class="flex items-center gap-2">
                        <div class="flex gap-1.5">
                            {#each Array(5) as _, i}
                                <div
                                    class="w-2 h-2 rounded-full {i <
                                    driverStore.drivers.length
                                        ? 'bg-emerald-500/50'
                                        : 'bg-zinc-800'} transition-all"
                                ></div>
                            {/each}
                        </div>
                        <span class="text-xs font-black text-app-text ml-1"
                            >{driverStore.drivers.length}<span
                                class="text-zinc-700 mx-0.5">/</span
                            >5</span
                        >
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Workspace: Roster (8) | Prospects (4) -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 items-start">
            <!-- Center Column: Roster (Main) -->
            <div class="lg:col-span-8 order-2 lg:order-1">
                <div class="flex items-center justify-between mb-10">
                    <div class="flex items-center gap-4">
                        <div
                            class="w-2 h-8 bg-emerald-500 rounded-full shadow-[0_0_15px_rgba(16,185,129,0.4)]"
                        ></div>
                        <h3
                            class="text-2xl font-black text-app-text tracking-tighter uppercase italic"
                        >
                            {t("training_roster")}
                        </h3>
                        <span
                            class="px-3 py-1 bg-emerald-500/10 text-emerald-400 text-[10px] font-black rounded-lg uppercase border border-emerald-500/20 ml-2 tracking-widest"
                            >{t("active_ops")}</span
                        >
                    </div>
                </div>

                {#if youthAcademyStore.selectedDrivers.length === 0}
                    <div
                        class="bg-app-bg/40 border-2 border-dashed border-app-border rounded-[3rem] p-24 flex flex-col items-center justify-center text-center backdrop-blur-sm group"
                    >
                        <div
                            class="w-24 h-24 bg-app-surface rounded-[2rem] flex items-center justify-center mb-8 border border-app-border transition-transform group-hover:scale-110 duration-500"
                        >
                            <Users class="w-12 h-12 text-zinc-800" />
                        </div>
                        <h4
                            class="text-app-text font-black text-2xl mb-3 uppercase tracking-tight italic"
                        >
                            {t("program_dormant")}
                        </h4>
                        <p
                            class="text-app-text/40 text-sm max-w-sm font-medium leading-relaxed"
                        >
                            {t("program_idle_desc")}
                        </p>
                    </div>
                {:else}
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                        {#each youthAcademyStore.selectedDrivers as driver}
                            <div
                                class="group bg-app-surface/60 border border-app-border rounded-[2.5rem] p-8 backdrop-blur-md relative overflow-hidden transition-all duration-500 hover:border-emerald-500/30 hover:bg-app-surface/80 hover:shadow-2xl hover:shadow-emerald-500/5"
                            >
                                <!-- Active Decision Banner -->
                                {#if driver.pendingAction}
                                    <div
                                        class="absolute inset-x-4 inset-y-4 bg-app-bg/90 backdrop-blur-md z-30 flex flex-col items-center justify-center p-8 text-center animate-fade-in border-2 border-emerald-500/50 rounded-[2.25rem] shadow-2xl"
                                    >
                                        <div
                                            class="w-16 h-16 bg-emerald-500/20 rounded-2xl flex items-center justify-center mb-6 border border-emerald-500/30"
                                        >
                                            <AlertTriangle
                                                class="w-8 h-8 text-emerald-400"
                                            />
                                        </div>
                                        <h4
                                            class="text-app-text font-black text-xl uppercase tracking-tighter mb-2 italic"
                                        >
                                            {t("urgent_insight")}
                                        </h4>
                                        <p
                                            class="text-app-text/60 font-bold text-xs mb-8 px-4 leading-relaxed tracking-wide italic"
                                        >
                                            "{translateAcademyNarrative(
                                                driver.weeklyEventMessage,
                                            ) ||
                                                t(
                                                    "critical_development_fallback",
                                                )}"
                                        </p>

                                        <div class="flex gap-4 w-full">
                                            <button
                                                class="flex-1 py-4 bg-emerald-500 text-black font-black uppercase text-xs rounded-2xl hover:scale-105 active:scale-95 transition-all shadow-xl shadow-emerald-500/20"
                                                onclick={() =>
                                                    youthAcademyStore.solveAcademyAction(
                                                        driver.id,
                                                        "resolve",
                                                    )}
                                                >{t("resolve_flow")}</button
                                            >
                                            <button
                                                class="flex-1 py-4 bg-app-text/10 text-app-text font-black uppercase text-xs rounded-2xl border border-app-border hover:bg-app-text/20 transition-all"
                                                onclick={() =>
                                                    youthAcademyStore.solveAcademyAction(
                                                        driver.id,
                                                        "dismiss",
                                                    )}>Dismiss</button
                                            >
                                        </div>
                                    </div>
                                {/if}

                                <div
                                    class="flex items-start gap-6 mb-10 relative z-10"
                                >
                                    <div class="relative group-pro">
                                        <div
                                            class="w-24 h-24 rounded-[2rem] bg-app-bg border border-app-border overflow-hidden shadow-2xl transition-transform group-hover:-rotate-3 group-hover:scale-105 duration-500"
                                        >
                                            <DriverAvatar
                                                id={driver.id}
                                                gender={driver.gender}
                                                class="w-full h-full"
                                            />
                                        </div>
                                        <div
                                            class="absolute -bottom-2 -right-2 w-10 h-10 bg-app-surface border {driver.isMarkedForPromotion
                                                ? 'border-fuchsia-500/50'
                                                : 'border-app-border'} rounded-2xl flex items-center justify-center shadow-2xl"
                                        >
                                            <span
                                                class="text-sm font-black text-app-text italic"
                                                >{driver.age}</span
                                            >
                                        </div>
                                    </div>
                                    <div class="flex-1 overflow-hidden">
                                        <div
                                            class="flex items-center justify-between mb-2"
                                        >
                                            <h4
                                                class="text-2xl font-black text-app-text tracking-tighter uppercase leading-none truncate w-36 italic"
                                            >
                                                {driver.name}
                                            </h4>
                                            {#if getSpecialtyKey(driver.specialty)}
                                                <div class="mt-1 flex gap-2">
                                                    <span
                                                        class="px-2 py-0.5 bg-fuchsia-500/10 text-fuchsia-400 text-[9px] font-black rounded border border-fuchsia-500/20 tracking-wider uppercase"
                                                    >
                                                        {t(
                                                            getSpecialtyKey(
                                                                driver.specialty,
                                                            )!,
                                                        )}
                                                    </span>
                                                </div>
                                            {/if}
                                            <div
                                                class="flex items-center gap-2"
                                            >
                                                <button
                                                    class="p-2.5 rounded-2xl transition-all border {driver.isMarkedForPromotion
                                                        ? 'bg-fuchsia-500 border-fuchsia-500 text-black shadow-xl shadow-fuchsia-500/20'
                                                        : 'bg-transparent border-app-border text-zinc-700 hover:text-fuchsia-500 hover:border-fuchsia-500/30'}"
                                                    onclick={() =>
                                                        youthAcademyStore.togglePromotion(
                                                            driver.id,
                                                            !driver.isMarkedForPromotion,
                                                        )}
                                                    title={t(
                                                        "mark_for_promotion",
                                                    )}
                                                >
                                                    <TrendingUp
                                                        class="w-5 h-5"
                                                    />
                                                </button>
                                                <button
                                                    class="p-2.5 rounded-2xl transition-all border bg-transparent border-app-border text-zinc-800 hover:text-red-500 hover:border-red-500/30"
                                                    onclick={() =>
                                                        youthAcademyStore.releaseDriver(
                                                            driver.id,
                                                        )}
                                                    title={t(
                                                        "release_driver_tooltip",
                                                    )}
                                                >
                                                    <XCircle class="w-5 h-5" />
                                                </button>
                                            </div>
                                        </div>
                                        <DriverStars
                                            currentStars={calculateAcademyCurrentStars(
                                                driver,
                                            )}
                                            maxStars={calculateAcademyMaxStars(
                                                driver,
                                            )}
                                        />
                                        <div
                                            class="flex items-center gap-4 mt-4"
                                        >
                                            <div class="flex flex-col">
                                                <span
                                                    class="text-[9px] font-black text-zinc-600 uppercase tracking-widest leading-none mb-1.5"
                                                    >{t("role")}</span
                                                >
                                                <div
                                                    class="flex items-center gap-1.5"
                                                >
                                                    <div
                                                        class="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"
                                                    ></div>
                                                    <span
                                                        class="text-[11px] font-black text-emerald-400 uppercase tracking-widest italic"
                                                        >{t(
                                                            "in_training",
                                                        )}</span
                                                    >
                                                </div>
                                            </div>
                                            <div
                                                class="h-8 w-px bg-app-text/5 mx-1"
                                            ></div>
                                            <div class="flex flex-col">
                                                <span
                                                    class="text-[9px] font-black text-zinc-600 uppercase tracking-widest leading-none mb-1.5"
                                                    >{t("potential_peak")}</span
                                                >
                                                <span
                                                    class="text-[11px] font-black text-app-text uppercase tracking-tighter"
                                                    >+{driver.growthPotential ??
                                                        0}%</span
                                                >
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <!-- Stat Range Bars (Onyx Parity) -->
                                <div class="space-y-5 mb-8 relative z-10">
                                    {#each Object.entries(StatIcons) as [key, Icon]}
                                        <div class="space-y-2">
                                            <div
                                                class="flex justify-between items-center px-1"
                                            >
                                                <div
                                                    class="flex items-center gap-2.5"
                                                >
                                                    <div
                                                        class="p-1.5 bg-app-text/40 rounded-lg border border-app-border"
                                                    >
                                                        <Icon
                                                            class="w-3.5 h-3.5 text-app-text/40"
                                                        />
                                                    </div>
                                                    <span
                                                        class="text-[10px] font-black text-app-text/60 uppercase tracking-[0.15em]"
                                                        >{key}</span
                                                    >
                                                </div>
                                                <div
                                                    class="flex items-center gap-3"
                                                >
                                                    {#if driver.weeklyStatDiffs?.[key]}
                                                        <div
                                                            class="flex items-center gap-1 px-2 py-0.5 {driver.weeklyStatDiffs[key] > 0 ? 'bg-emerald-500/10 border-emerald-500/20' : 'bg-red-500/10 border-red-500/20'} rounded-md border"
                                                        >
                                                            {#if driver.weeklyStatDiffs[key] > 0}
                                                                <TrendingUp
                                                                    class="w-2.5 h-2.5 text-emerald-400"
                                                                />
                                                            {:else}
                                                                <AlertTriangle
                                                                    class="w-2.5 h-2.5 text-red-400"
                                                                />
                                                            {/if}
                                                            <span
                                                                class="text-[11px] font-black {driver.weeklyStatDiffs[key] > 0 ? 'text-emerald-400' : 'text-red-400'}"
                                                                >{driver.weeklyStatDiffs[key] > 0 ? '+' : ''}{driver
                                                                    .weeklyStatDiffs[
                                                                    key
                                                                ]}</span
                                                            >
                                                        </div>
                                                    {/if}
                                                    <div
                                                        class="flex items-center gap-1.5"
                                                    >
                                                        <span
                                                            class="text-xs font-black text-app-text tracking-tighter"
                                                            >{driver
                                                                .statRangeMin?.[
                                                                key
                                                            ] ?? 0}</span
                                                        >
                                                        <span
                                                            class="text-[10px] font-black text-zinc-700 italic"
                                                            >...</span
                                                        >
                                                        <span
                                                            class="text-xs font-black text-app-text/60 tracking-tighter"
                                                            >{driver
                                                                .statRangeMax?.[
                                                                key
                                                            ] ?? 0}</span
                                                        >
                                                    </div>
                                                </div>
                                            </div>
                                            <div
                                                class="w-full h-2.5 bg-app-text/80 rounded-full overflow-hidden border border-app-border relative p-[2px]"
                                            >
                                                <!-- Base Range Indicator -->
                                                <div
                                                    class="absolute h-full bg-app-text/10 rounded-full opacity-50"
                                                    style="left: {driver
                                                        .statRangeMin?.[key] ??
                                                        0}%; right: {100 -
                                                        (driver.statRangeMax?.[
                                                            key
                                                        ] ?? 100)}%"
                                                ></div>
                                                <!-- Current Fill Progress -->
                                                <div
                                                    class="absolute h-full {driver.weeklyStatDiffs?.[key] 
                                                        ? (driver.weeklyStatDiffs[key] > 0 
                                                            ? 'bg-emerald-400 shadow-[0_0_12px_rgba(52,211,153,0.5)]' 
                                                            : 'bg-red-400 shadow-[0_0_12px_rgba(248,113,113,0.5)]')
                                                        : 'bg-app-text/40'} rounded-full transition-all duration-1000 ease-out"
                                                    style="width: {driver
                                                        .statRangeMin?.[key] ??
                                                        0}%"
                                                ></div>

                                                {#if driver.trainingProgress}
                                                    <div
                                                        class="absolute h-full w-1.5 bg-app-text/30 blur-[1px] rounded-full transition-all duration-1000"
                                                        style="left: {Math.min(
                                                            98,
                                                            (driver
                                                                .statRangeMin?.[
                                                                key
                                                            ] ?? 0) +
                                                                driver
                                                                    .trainingProgress[
                                                                    key
                                                                ] /
                                                                    2,
                                                        )}%"
                                                    ></div>
                                                {/if}
                                            </div>
                                        </div>
                                    {/each}
                                </div>

                                {#if driver.weeklyEventMessage}
                                    <div
                                        class="p-4 bg-app-text/40 rounded-3xl border border-app-border flex items-start gap-4 mt-6 group/msg transition-colors hover:border-app-border"
                                    >
                                        <div
                                            class="p-2 bg-app-surface rounded-xl border border-app-border shrink-0 mt-1"
                                        >
                                            <Eye
                                                class="w-4 h-4 text-emerald-400"
                                            />
                                        </div>
                                        <div class="flex flex-col gap-2">
                                            <p
                                                class="text-xs text-app-text/60 font-medium leading-relaxed italic opacity-80 group-hover/msg:opacity-100 transition-opacity"
                                            >
                                                "{translateAcademyNarrative(
                                                    driver.weeklyEventMessage,
                                                )}"
                                            </p>
                                            {#if driver.weeklyStatDiffs && Object.keys(driver.weeklyStatDiffs).length > 0}
                                                <div class="flex flex-wrap gap-2 mt-1">
                                                    {#each Object.entries(driver.weeklyStatDiffs) as [stat, diffValue]}
                                                        {@const diff = diffValue as number}
                                                        <span class="text-[9px] px-2 py-0.5 rounded-lg font-black {diff > 0 ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' : 'bg-red-500/20 text-red-400 border border-red-500/30'} uppercase tracking-widest italic">
                                                            {diff > 0 ? '+' : ''}{diff} {t(stat as any) || stat}
                                                        </span>
                                                    {/each}
                                                </div>
                                            {/if}
                                        </div>
                                    </div>
                                {/if}
                            </div>
                        {/each}
                    </div>
                {/if}
            </div>

            <!-- Right Panel: Scouting Report (Side) -->
            <div class="lg:col-span-4 order-1 lg:order-2">
                <div class="flex items-center justify-between mb-10">
                    <h3
                        class="text-2xl font-black text-app-text tracking-tighter uppercase italic"
                    >
                        {t("scouting_intel")}
                    </h3>
                    <div
                        class="flex items-center gap-2 text-[10px] font-black text-app-text/40 uppercase tracking-widest"
                    >
                        <Target class="w-5 h-5" />
                        <span>{t("live_data")}</span>
                    </div>
                </div>

                <div class="space-y-6">
                    {#each youthAcademyStore.candidates as candidate}
                        <div
                            class="bg-app-bg/40 border border-app-border rounded-[2.5rem] p-6 transition-all duration-500 hover:bg-app-bg/80 hover:border-emerald-500/20 group relative overflow-hidden"
                        >
                            <!-- Subtle regional backdrop symbol -->
                            <span
                                class="absolute -top-6 -right-6 text-7xl opacity-[0.03] group-hover:opacity-[0.07] transition-opacity grayscale select-none pointer-events-none"
                                >{youthAcademyStore.config?.countryFlag}</span
                            >

                            <div class="flex items-center gap-6 mb-6">
                                <div
                                    class="w-20 h-20 rounded-[1.75rem] bg-app-surface border border-app-border overflow-hidden shrink-0 shadow-2xl transition-transform group-hover:scale-105 group-hover:rotate-2 duration-500"
                                >
                                    <DriverAvatar
                                        id={candidate.id}
                                        gender={candidate.gender}
                                        class="w-full h-full"
                                    />
                                </div>
                                <div class="flex-1 overflow-hidden">
                                    <div
                                        class="flex items-center justify-between mb-2"
                                    >
                                        <h4
                                            class="text-lg font-black text-app-text uppercase tracking-tighter italic truncate leading-none"
                                        >
                                            {candidate.name}
                                        </h4>
                                        {#if getSpecialtyKey(candidate.specialty)}
                                            <div
                                                class="px-2 py-0.5 bg-fuchsia-500/10 text-fuchsia-400 text-[8px] font-black rounded border border-fuchsia-500/20 tracking-wider uppercase w-max"
                                            >
                                                {t(
                                                    getSpecialtyKey(
                                                        candidate.specialty,
                                                    )!,
                                                )}
                                            </div>
                                        {/if}
                                        <span
                                            class="text-[10px] font-black text-zinc-600 uppercase"
                                            >{candidate.age}Y</span
                                        >
                                    </div>
                                    <DriverStars
                                        currentStars={calculateAcademyCurrentStars(
                                            candidate,
                                        )}
                                        maxStars={calculateAcademyMaxStars(
                                            candidate,
                                        )}
                                    />
                                    <div
                                        class="flex flex-wrap items-center gap-3 mt-3"
                                    >
                                        <div
                                            class="flex items-center gap-1.5 px-2 py-1 bg-emerald-500/10 rounded-lg border border-emerald-500/20"
                                        >
                                            <TrendingUp
                                                class="w-3 h-3 text-emerald-400"
                                            />
                                            <span
                                                class="text-[10px] font-black text-emerald-400 uppercase tracking-tighter italic"
                                                >{t("stars_potential", {
                                                    stars: (
                                                        candidate.potentialStars ||
                                                        0
                                                    ).toFixed(1),
                                                })}</span
                                            >
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="grid grid-cols-2 gap-4">
                                <button
                                    class="flex items-center justify-center gap-3 py-4 bg-emerald-500 text-black text-[11px] font-black uppercase rounded-2xl hover:scale-105 active:scale-95 transition-all shadow-xl shadow-emerald-500/20 disabled:grayscale disabled:opacity-20 disabled:cursor-not-allowed group/btn overflow-hidden"
                                    disabled={youthAcademyStore.selectedDrivers
                                        .length >= youthAcademyStore.maxSlots}
                                    onclick={() => handleSelect(candidate.id)}
                                >
                                    <UserPlus
                                        class="w-4 h-4 transition-transform group-hover/btn:rotate-12"
                                    />
                                    <span>{t("sign_contract")}</span>
                                </button>
                                <button
                                    class="flex items-center justify-center gap-2 py-4 bg-app-text/5 text-zinc-600 text-[11px] font-black uppercase rounded-2xl border border-app-border hover:bg-red-500/10 hover:text-red-400 hover:border-red-500/30 transition-all active:scale-95"
                                    onclick={() =>
                                        youthAcademyStore.dismissCandidate(
                                            candidate.id,
                                        )}
                                >
                                    <XCircle class="w-4 h-4" />
                                    <span>{t("dismiss")}</span>
                                </button>
                            </div>

                            <div
                                class="mt-4 flex items-center justify-between px-2"
                            >
                                <span
                                    class="text-[9px] font-black text-zinc-600 uppercase tracking-widest leading-none"
                                    >{t("scouted_fee")}</span
                                >
                                <span
                                    class="text-[11px] font-black text-app-text italic tracking-tighter"
                                    >{formatCurrencyCompact(10000)}</span
                                >
                            </div>
                        </div>
                    {/each}

                    {#if youthAcademyStore.candidates.length === 0}
                        <div
                            class="bg-app-bg/20 border border-app-border rounded-[2.5rem] p-16 text-center backdrop-blur-sm"
                        >
                            <div
                                class="w-12 h-12 bg-app-text/5 rounded-full flex items-center justify-center mx-auto mb-4 border border-app-border"
                            >
                                <Target class="w-6 h-6 text-zinc-800" />
                            </div>
                            <p
                                class="text-zinc-600 text-[10px] font-black uppercase tracking-[0.2em] mb-1 italic"
                            >
                                {t("program_dormant")}
                            </p>
                            <p
                                class="text-zinc-800 text-[9px] font-bold uppercase tracking-widest"
                            >
                                {t("seasons_plural")}
                            </p>
                        </div>
                    {/if}

                    <!-- Regional Highlight Card -->
                    <div
                        class="bg-gradient-to-br from-zinc-500/10 via-transparent to-transparent border border-app-border rounded-[2.5rem] p-8 mt-10 relative overflow-hidden group shadow-2xl"
                    >
                        <Globe
                            class="absolute -bottom-6 -right-6 w-32 h-32 text-app-text/5 rotate-12 transition-transform group-hover:scale-110 duration-1000"
                        />
                        <div class="relative z-10">
                            <h5
                                class="text-app-text/60 text-[11px] font-black uppercase tracking-[0.3em] mb-4 flex items-center gap-3"
                            >
                                <Target class="w-5 h-5" />
                                {t("regional_focus")}
                            </h5>
                            <p
                                class="text-app-text/60 text-xs leading-relaxed font-medium italic opacity-80 group-hover:opacity-100 transition-opacity"
                            >
                                {t("scouting_efforts", {
                                    country:
                                        youthAcademyStore.config?.countryName?.toUpperCase() ||
                                        "",
                                })}
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    {/if}
</div>

<style>
    :global(.animate-fade-in) {
        animation: fadeIn 1s cubic-bezier(0.16, 1, 0.3, 1) forwards;
    }

    @keyframes fadeIn {
        from {
            opacity: 0;
            transform: translateY(20px);
            filter: blur(10px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
            filter: blur(0);
        }
    }

    .animate-spin {
        animation: spin 8s linear infinite;
    }

    @keyframes spin {
        from {
            transform: rotate(0deg);
        }
        to {
            transform: rotate(360deg);
        }
    }

    /* Custom scrollbar for premium feel */
    :global(body::-webkit-scrollbar) {
        width: 8px;
    }
    :global(body::-webkit-scrollbar-track) {
        background: #09090b;
    }
    :global(body::-webkit-scrollbar-thumb) {
        background: #27272a;
        border-radius: 10px;
    }
    :global(body::-webkit-scrollbar-thumb:hover) {
        background: #3f3f46;
    }
</style>
