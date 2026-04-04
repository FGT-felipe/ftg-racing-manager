<script lang="ts">
    import {
        type Driver,
        type ChampionshipForm,
        type CareerHistoryItem,
    } from "$lib/types";

    import { teamStore } from "$lib/stores/team.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { staffService } from "$lib/services/staff.svelte";
    import { raceService } from "$lib/services/race_service.svelte";
    import {
        X,
        Activity,
        Smile,
        RefreshCw,
        Info,
        Trash2,
        ShoppingBag,
        History,
        RotateCcw,
    } from "lucide-svelte";
    import { fade, fly } from "svelte/transition";
    import DriverAvatar from "./DriverAvatar.svelte";
    import DriverStars from "./DriverStars.svelte";
    import {
        calculateCurrentStars,
        calculateMaxStars,
        calculateDriverMarketValue,
        getDriverLevelInfo,
        getSpecialtyI18nKey,
        isNearingRetirement,
        isRetiringNextSeason,
    } from "$lib/utils/driver";
    import { TRANSFER_MARKET_LISTING_FEE_RATE, DISMISS_MORALE_PENALTY } from "$lib/constants/economics";
    import NegotiationModal from "./NegotiationModal.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { t } from "$lib/utils/i18n";
    import { getTitleInfo } from "$lib/constants/titles";
    import ConfirmationModal from "./ui/ConfirmationModal.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";

    interface Props {
        driver: Driver;
        isOpen: boolean;
        onClose: () => void;
        onRefresh?: () => void;
        /** Full roster — used to detect reserve availability before dismissal. */
        allDrivers?: Driver[];
    }

    let { driver, isOpen, onClose, onRefresh, allDrivers = [] }: Props = $props();

    let team = $derived(teamStore.value.team);
    let driverLevel = $derived(getDriverLevelInfo(calculateCurrentStars(driver), t));
    let isFlipped = $state(false);
    let showStatusTooltip = $state(false);
    let isProcessing = $state(false);
    let showNegotiationModal = $state(false);

    // Season stats derived from race docs — authoritative, self-healing.
    // Null while loading so the template shows "—" instead of stale driver doc values.
    let seasonStats = $state<{
        seasonRaces: number;
        seasonWins: number;
        seasonPodiums: number;
        seasonPoles: number;
    } | null>(null);

    $effect(() => {
        if (!isOpen) return;
        const season = seasonStore.value.season;
        if (!season?.id || !season.calendar) return;
        const completedRoundIds = season.calendar
            .filter((e: any) => e.isCompleted)
            .map((e: any) => e.id);
        // No completed rounds yet — show zeros immediately, no async needed
        if (completedRoundIds.length === 0) {
            seasonStats = { seasonRaces: 0, seasonWins: 0, seasonPodiums: 0, seasonPoles: 0 };
            return;
        }
        seasonStats = null; // show loading state while fetching
        raceService.syncDriverSeasonStats(
            driver.id,
            season.id,
            completedRoundIds,
            {
                seasonRaces:   driver.seasonRaces   || 0,
                seasonWins:    driver.seasonWins    || 0,
                seasonPodiums: driver.seasonPodiums || 0,
                seasonPoles:   driver.seasonPoles   || 0,
            }
        ).then(stats => { seasonStats = stats; })
         .catch(e => console.error('[DriverDetailModal] syncDriverSeasonStats failed:', e));
    });

    // Confirmation Modal State
    let confirmConfig = $state<{
        isOpen: boolean;
        title: string;
        message: string;
        confirmLabel?: string;
        cancelLabel?: string;
        type?: "danger" | "warning" | "info" | "success";
        onConfirm: () => void;
        onCancel?: () => void;
    }>({
        isOpen: false,
        title: "",
        message: "",
        onConfirm: () => {},
    });

    function showConfirm(config: Omit<typeof confirmConfig, "isOpen">) {
        confirmConfig = { ...config, isOpen: true };
    }

    function closeConfirm() {
        confirmConfig = { ...confirmConfig, isOpen: false };
    }

    function formatCurrency(value: number) {
        return new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: "USD",
            maximumFractionDigits: 0,
        }).format(value);
    }


    const DRIVING_STATS = [
        { key: "braking",      label: "Braking" },
        { key: "cornering",    label: "Cornering" },
        { key: "smoothness",   label: "Smoothness" },
        { key: "overtaking",   label: "Overtaking" },
        { key: "defending",    label: "Defending" },
        { key: "consistency",  label: "Consistency" },
        { key: "adaptability", label: "Adaptability" },
        { key: "focus",        label: "Focus" },
        { key: "feedback",     label: "Feedback" },
    ];

    const MENTAL_STATS = [
        { key: "fitness", label: "Fitness", icon: Activity },
        { key: "morale",  label: "Morale",  icon: Smile },
    ];

    function getStatColor(value: number, isPercentage = false) {
        if (isPercentage) {
            if (value >= 75) return "bg-green-400";
            if (value >= 50) return "bg-yellow-400";
            return "bg-red-400";
        }
        // 1-20 scale
        if (value >= 15) return "bg-green-400";
        if (value >= 10) return "bg-yellow-400";
        return "bg-red-400";
    }

    function getStatTextColor(value: number, isPercentage = false) {
        if (isPercentage) {
            if (value >= 75) return "text-green-400";
            if (value >= 50) return "text-yellow-400";
            return "text-red-400";
        }
        // 1-20 scale
        if (value >= 15) return "text-green-400";
        if (value >= 10) return "text-yellow-400";
        return "text-red-400";
    }

    function handleDismiss() {
        const dismissFee = driver.salary; // Full annual salary as severance
        const hasReserve = allDrivers.some(
            d => d.id !== driver.id && d.role?.toLowerCase() === 'reserve'
        );
        const isMainDriver = driver.carIndex >= 0;

        let message = t("dismiss_confirm", { name: driver.name, amount: formatCurrency(dismissFee) });
        if (isMainDriver && !hasReserve) {
            message += `\n\n${t("dismiss_no_reserve_warning")}`;
        }
        message += `\n\n${t("dismiss_driver_fate", { name: driver.name.split(' ')[0], penalty: String(DISMISS_MORALE_PENALTY) })}`;

        showConfirm({
            title: t("dismiss"),
            message,
            confirmLabel: t("dismiss"),
            type: "danger",
            onConfirm: async () => {
                if (!team) return;
                isProcessing = true;
                closeConfirm();
                try {
                    await staffService.dismissDriver(team.id, driver);
                    onRefresh?.();
                    onClose();
                } catch (e) {
                    showConfirm({
                        title: "Error",
                        message: e instanceof Error ? e.message : t("error_dismiss"),
                        type: "danger",
                        onConfirm: closeConfirm
                    });
                } finally {
                    isProcessing = false;
                }
            }
        });
    }

    function handleListOnMarket() {
        // Guard: ensure at least 1 non-listed main driver will remain after listing
        const nonListedMainDrivers = allDrivers.filter(
            d => d.id !== driver.id && (d.carIndex === 0 || d.carIndex === 1) && !d.isTransferListed
        );
        const isLastMainDriver = (driver.carIndex === 0 || driver.carIndex === 1) && nonListedMainDrivers.length === 0;

        if (isLastMainDriver) {
            const hasReserve = allDrivers.some(
                d => d.id !== driver.id && d.role?.toLowerCase().includes('reserve') && !d.isTransferListed
            );
            showConfirm({
                title: t("transfer"),
                message: hasReserve
                    ? t("list_blocked_promote_reserve", { name: driver.name.split(' ')[0] })
                    : t("list_blocked_no_reserve"),
                type: "warning",
                onConfirm: closeConfirm,
            });
            return;
        }

        const marketValue = calculateDriverMarketValue(driver);
        const listingFee = Math.round(marketValue * TRANSFER_MARKET_LISTING_FEE_RATE);

        showConfirm({
            title: t("transfer"),
            message: t("market_confirm", {
                name: driver.name,
                value: formatCurrency(marketValue),
                fee: formatCurrency(listingFee),
            }),
            confirmLabel: t("confirm"),
            type: "warning",
            onConfirm: async () => {
                if (!team) return;
                isProcessing = true;
                closeConfirm();
                try {
                    await staffService.listDriverOnMarket(team.id, driver);
                    onRefresh?.();
                    onClose();
                } catch (e) {
                    showConfirm({
                        title: "Error",
                        message: e instanceof Error ? e.message : t("error_market"),
                        type: "danger",
                        onConfirm: closeConfirm
                    });
                } finally {
                    isProcessing = false;
                }
            }
        });
    }

    function handleCancelListing() {
        if ((driver.currentHighestBid ?? 0) > 0) {
            showConfirm({
                title: "Error",
                message: t("cancel_listing_active_bid"),
                type: "danger",
                onConfirm: closeConfirm,
            });
            return;
        }

        showConfirm({
            title: t("cancel_listing"),
            message: t("cancel_listing_confirm", { name: driver.name }),
            confirmLabel: t("confirm"),
            type: "warning",
            onConfirm: async () => {
                if (!team) return;
                isProcessing = true;
                closeConfirm();
                try {
                    await staffService.cancelListing(team.id, driver);
                    onRefresh?.();
                    onClose();
                } catch (e) {
                    showConfirm({
                        title: "Error",
                        message: e instanceof Error ? e.message : t("error_cancel_listing"),
                        type: "danger",
                        onConfirm: closeConfirm
                    });
                } finally {
                    isProcessing = false;
                }
            }
        });
    }

    function handleRenew() {
        if (!team?.id || !driver) return;
        showNegotiationModal = true;
    }

    // Mock history generation matching Flutter logic
    const stableHistory = $derived.by(() => {
        if (!driver) return [];

        // Prefer real stored history
        if (driver.careerHistory && driver.careerHistory.length > 0) {
            return driver.careerHistory.map((h: CareerHistoryItem) => ({
                year: h.year,
                team: h.teamName,
                races: h.races,
                podiums: h.podiums,
                wins: h.wins,
                isChampion: h.isChampion,
            }));
        }

        const rows = [];
        const currentYear = 2026;
        const totalRaces = driver.races || 0;
        const totalPodiums = driver.podiums || 0;
        const totalWins = driver.wins || 0;

        let remainingRaces = totalRaces;
        for (let i = 0; i < 5; i++) {
            if (remainingRaces <= 0 && i > 0) break;
            const year = currentYear - (i + 1);
            const yearRaces =
                Math.floor(totalRaces / 5) + (i === 0 ? totalRaces % 5 : 0);
            const yearWins =
                Math.floor(totalWins / 5) + (i === 0 ? totalWins % 5 : 0);
            const yearPodiums =
                Math.floor(totalPodiums / 5) + (i === 0 ? totalPodiums % 5 : 0);

            rows.push({
                year,
                team:
                    i === 0
                        ? team?.name || t("current_team") || "Current Organization"
                        : "International Series", 
                races: yearRaces,
                podiums: yearPodiums,
                wins: yearWins,
                isChampion: false,
            });
            remainingRaces -= yearRaces;
        }
        return rows;
    });

    // Reset flipped state when closing or changing driver
    $effect(() => {
        if (!isOpen) isFlipped = false;
    });
</script>

{#if isOpen && driver}
    <div
        class="fixed inset-0 z-50 flex items-center justify-center p-4 md:p-8"
        transition:fade={{ duration: 200 }}
    >
        <!-- Backdrop -->
        <button
            class="absolute inset-0 bg-black/90 backdrop-blur-md cursor-default w-full h-full border-none"
            onclick={onClose}
            aria-label="Close modal"
        ></button>

        <!-- Modal Container (with perspective for flip) -->
        <div
            class="perspective-container relative w-full max-w-5xl h-[85vh] max-h-[800px]"
        >
            <!-- Flip Card Content -->
            <div
                class="card-inner w-full h-full transition-transform duration-700 {isFlipped
                    ? 'is-flipped'
                    : ''}"
            >
                <!-- FRONT SIDE -->
                <div
                    class="card-front absolute inset-0 bg-app-surface border border-app-border rounded-[32px] overflow-hidden shadow-2xl flex flex-col md:flex-row backface-hidden [transform:rotateY(0deg)]"
                >
                    <!-- Close Button -->
                    <button
                        class="absolute top-6 right-6 z-10 p-2 rounded-full bg-app-text/5 border border-app-border text-app-text/40 hover:text-app-text hover:bg-app-text/10 transition-all"
                        onclick={onClose}
                    >
                        <X size={20} />
                    </button>

                    <!-- Flip Button -->
                    <button
                        class="absolute top-6 right-20 z-10 flex items-center gap-2 px-4 py-2 rounded-full bg-app-primary/10 border border-app-primary/20 text-app-primary text-[10px] font-black uppercase tracking-widest hover:bg-app-primary hover:text-app-primary-foreground transition-all"
                        onclick={() => (isFlipped = true)}
                    >
                        <History size={14} />
                        {t("career_view")}
                    </button>

                    <!-- Column 1: Identity & Key Info -->
                    <div
                        class="flex-1 p-8 md:p-12 flex flex-col gap-8 border-r border-app-border overflow-y-auto custom-scrollbar"
                    >
                        <div class="flex items-start gap-6">
                            <div class="relative">
                                <div
                                    class="w-28 h-28 md:w-32 md:h-32 rounded-full bg-app-text/5 border-4 border-app-primary/30 p-1"
                                >
                                    <DriverAvatar
                                        id={driver.id}
                                        gender={driver.gender}
                                        class="w-full h-full rounded-full"
                                    />
                                </div>
                                <div
                                    class="absolute -bottom-2 -right-2 border {driverLevel.borderColor} bg-app-surface text-[10px] font-black px-3 py-1 rounded-lg uppercase tracking-widest shadow-lg {driverLevel.color}"
                                >
                                    {driverLevel.label}
                                </div>
                            </div>

                            <div class="flex flex-col gap-2">
                                <div class="flex items-center gap-3">
                                   <CountryFlag countryCode={driver.countryCode} size="lg" />
                                   <span
                                       class="text-xs font-black text-app-text/30 uppercase tracking-[0.2em]"
                                       >{driver.age}Y</span
                                   >
                                </div>
                                <h1
                                    class="text-4xl md:text-5xl font-heading font-black text-app-text uppercase tracking-tighter italic leading-none"
                                >
                                    {driver.name}
                                </h1>
                                <div class="flex items-center gap-3">
                                    <DriverStars {driver} size={16} />
                                    <span
                                        class="text-[10px] font-black text-app-text/40 uppercase tracking-widest"
                                        >{t("potential_peak")}</span
                                    >
                                </div>
                                {#if driver.specialty}
                                    {@const specialtyKey = getSpecialtyI18nKey(driver.specialty)}
                                    <span class="self-start px-3 py-1.5 rounded-xl bg-yellow-500/10 border border-yellow-500/30 text-[10px] font-black uppercase tracking-widest text-yellow-500">
                                        ★ {specialtyKey ? t(specialtyKey as any) : driver.specialty}
                                    </span>
                                {:else}
                                    <span class="self-start px-3 py-1.5 rounded-xl bg-app-text/5 border border-app-border text-[10px] font-black uppercase tracking-widest text-app-text/30">
                                        {t('no_specialty')}
                                    </span>
                                {/if}
                            </div>
                        </div>

                        <!-- Status Title with Tooltip Trigger -->
                        <div class="relative group">
                            {#if driver.statusTitle}
                                {@const titleInfo = getTitleInfo(
                                    driver.statusTitle,
                                    driver.gender,
                                )}
                                <button
                                    class="flex items-center gap-2 text-xs font-black text-app-text/40 uppercase tracking-widest hover:text-app-text transition-colors"
                                    onmouseenter={() =>
                                        (showStatusTooltip = true)}
                                    onmouseleave={() =>
                                        (showStatusTooltip = false)}
                                >
                                    <Info size={14} class="text-app-primary" />
                                    {titleInfo?.label || driver.statusTitle}
                                </button>

                                {#if showStatusTooltip}
                                    <div
                                        class="absolute bottom-full left-0 mb-2 z-[60] bg-app-surface border border-app-border p-4 rounded-xl shadow-2xl w-64 text-[10px] text-app-text/80 normal-case tracking-normal"
                                        transition:fade={{ duration: 150 }}
                                    >
                                        <h4
                                            class="font-black text-app-primary uppercase mb-1"
                                        >
                                            {titleInfo?.label ||
                                                driver.statusTitle}
                                        </h4>
                                        <p>
                                            {titleInfo?.description ||
                                                t("status_description")}
                                        </p>
                                    </div>
                                {/if}
                            {/if}
                        </div>

                        <!-- Contract Card -->
                        <div
                            class="bg-app-text/5 border border-app-border rounded-3xl p-6 flex flex-col gap-4"
                        >
                            <h3
                                class="text-[10px] font-black text-app-text/20 uppercase tracking-[0.2em]"
                            >
                                {t("contract_details")}
                            </h3>

                            <div class="grid grid-cols-2 gap-y-4">
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-bold text-app-text/40 uppercase"
                                        >{t("role")}</span
                                    >
                                    <span
                                        class="text-sm font-black text-app-text uppercase tracking-tight"
                                        >{driver.role}</span
                                    >
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-bold text-app-text/40 uppercase"
                                        >{t("salary")}</span
                                    >
                                    <span
                                        class="text-sm font-black text-green-400 uppercase tracking-tight"
                                        >{formatCurrency(
                                            Math.round(driver.salary / 52),
                                        )}/WK</span
                                    >
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-bold text-app-text/40 uppercase"
                                        >{t("remaining")}</span
                                    >
                                    <span
                                        class="text-sm font-black text-app-text uppercase tracking-tight"
                                        >{driver.contractYearsRemaining}
                                        {driver.contractYearsRemaining > 1
                                            ? t("seasons_plural")
                                            : t("season_singular")}</span
                                    >
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-bold text-app-text/40 uppercase"
                                        >{t("annual_salary")}</span
                                    >
                                    <span
                                        class="text-sm font-black text-app-text uppercase tracking-tight"
                                        >{formatCurrency(
                                            driver.salary,
                                        )}</span
                                    >
                                </div>
                            </div>
                        </div>

                        <!-- Personnel Actions -->
                        <div class="flex flex-col gap-3">
                            <div class="flex gap-4">
                                <button
                                    class="flex-1 flex items-center justify-center gap-3 px-6 py-4 bg-app-primary/10 border border-app-primary/20 rounded-2xl text-app-primary text-[10px] font-black uppercase tracking-widest hover:bg-app-primary hover:text-app-primary-foreground transition-all disabled:opacity-20 disabled:grayscale disabled:cursor-not-allowed"
                                    onclick={handleRenew}
                                    disabled={isProcessing || isRetiringNextSeason(driver)}
                                >
                                    <RefreshCw size={16} />
                                    {t("renew_contract")}
                                </button>
                                {#if isNearingRetirement(driver)}
                                    <div class="flex items-center gap-2 px-4 py-2 bg-amber-500/10 border border-amber-500/20 rounded-xl text-amber-500 text-[10px] font-black uppercase tracking-widest animate-pulse">
                                        <Info size={14} />
                                        {isRetiringNextSeason(driver) ? "Final Season" : "Retiring Soon"}
                                    </div>
                                {/if}
                            </div>
                            <div class="flex gap-4">
                                <button
                                    class="flex-1 flex items-center justify-center gap-3 px-6 py-4 bg-red-400/10 border border-red-400/20 rounded-2xl text-red-400 text-[10px] font-black uppercase tracking-widest hover:bg-red-400 hover:text-black transition-all disabled:opacity-50"
                                    onclick={handleDismiss}
                                    disabled={isProcessing}
                                >
                                    <Trash2 size={16} />
                                    {t("dismiss")}
                                </button>
                                <button
                                    class="flex-1 flex items-center justify-center gap-3 px-6 py-4 bg-yellow-400/10 border border-yellow-400/20 rounded-2xl text-yellow-400 text-[10px] font-black uppercase tracking-widest hover:bg-yellow-400 hover:text-black transition-all disabled:opacity-50"
                                    onclick={driver.isTransferListed ? handleCancelListing : handleListOnMarket}
                                    disabled={isProcessing}
                                >
                                    <ShoppingBag size={16} />
                                    {driver.isTransferListed
                                        ? t("cancel_listing")
                                        : t("transfer")}
                                </button>
                            </div>
                        </div>

                    </div>

                    <!-- Column 2: Performance Stats -->
                    <div
                        class="flex-1 p-8 md:p-12 bg-app-text/5 flex flex-col gap-10 overflow-y-auto custom-scrollbar"
                    >
                        <!-- Driving Skills -->
                        <div class="flex flex-col gap-6">
                            <h3
                                class="text-xs font-black text-app-text uppercase tracking-[0.3em] flex items-center gap-2"
                            >
                                {t("driving_performance")}
                            </h3>

                            <div class="grid grid-cols-3 gap-x-6 gap-y-5">
                                {#each DRIVING_STATS as stat}
                                    {@const val = driver.stats?.[stat.key] || 10}
                                    <div class="flex flex-col gap-2 group">
                                        <div class="flex items-center justify-between">
                                            <span
                                                class="text-[9px] font-black text-app-text/40 uppercase tracking-widest group-hover:text-app-text/60 transition-colors"
                                                >{stat.label}</span
                                            >
                                            <span
                                                class="text-xs font-black font-mono {getStatTextColor(val)}"
                                                >{val}</span
                                            >
                                        </div>
                                        <div class="h-1.5 w-full bg-app-text/5 rounded-full overflow-hidden">
                                            <div
                                                class="h-full transition-all duration-1000 ease-out {getStatColor(val)}"
                                                style="width: {(val / 20) * 100}%"
                                            ></div>
                                        </div>
                                    </div>
                                {/each}
                            </div>
                        </div>

                        <!-- Mental & Physical -->
                        <div class="flex flex-col gap-6">
                            <h3
                                class="text-xs font-black text-app-text uppercase tracking-[0.3em]"
                            >
                                {t("mental_physical")}
                            </h3>
                            <div class="grid grid-cols-2 gap-4">
                                {#each MENTAL_STATS as stat}
                                    {@const isPercentage = stat.key === "morale" || stat.key === "fitness"}
                                    {@const val =
                                        driver.stats?.[stat.key] || (isPercentage ? 70 : 10)}
                                    <div
                                        class="bg-app-text/5 border border-app-border rounded-2xl p-3 flex flex-col gap-2 group hover:border-app-border transition-all"
                                    >
                                        <div
                                            class="flex items-center justify-between"
                                        >
                                            <stat.icon
                                                size={14}
                                                class="text-app-text/20 group-hover:text-app-primary transition-colors"
                                            />
                                            <span
                                                class="text-xs font-heading font-black {getStatTextColor(
                                                    val,
                                                    isPercentage,
                                                )}">{isPercentage ? Math.round(val * 10) / 10 : val}{isPercentage ? "%" : ""}</span
                                            >
                                        </div>
                                        <span
                                            class="text-[9px] font-black text-app-text/40 uppercase tracking-widest"
                                            >{stat.label}</span
                                        >
                                        <div
                                            class="h-1 w-full bg-app-text/5 rounded-full overflow-hidden"
                                        >
                                            <div
                                                class="h-full transition-all duration-1000 ease-out {getStatColor(
                                                    val,
                                                    isPercentage,
                                                )}"
                                                style="width: {isPercentage ? val : (val / 20) * 100}%"
                                            ></div>
                                        </div>
                                    </div>
                                {/each}
                            </div>
                        </div>

                        <!-- Championship Form -->
                        <div class="flex flex-col gap-4">
                            <h3 class="text-[10px] font-black text-app-text/20 uppercase tracking-[0.2em]">
                                {t("championship_form")}
                            </h3>
                            <div class="grid grid-cols-2 gap-3">
                                <div class="flex flex-col gap-0.5 px-4 py-3 bg-app-text/5 border border-app-border rounded-2xl">
                                    <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-widest">{t("races")}</span>
                                    {#if seasonStats !== null}
                                        <span class="text-xl font-black text-app-text tabular-nums">{seasonStats.seasonRaces}</span>
                                    {:else}
                                        <div class="h-6 w-8 bg-app-text/5 rounded-full animate-pulse mt-1"></div>
                                    {/if}
                                </div>
                                <div class="flex flex-col gap-0.5 px-4 py-3 bg-app-text/5 border border-app-border rounded-2xl">
                                    <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-widest">{t("wins")}</span>
                                    {#if seasonStats !== null}
                                        <span class="text-xl font-black text-app-primary tabular-nums">{seasonStats.seasonWins}</span>
                                    {:else}
                                        <div class="h-6 w-8 bg-app-text/5 rounded-full animate-pulse mt-1"></div>
                                    {/if}
                                </div>
                                <div class="flex flex-col gap-0.5 px-4 py-3 bg-app-text/5 border border-app-border rounded-2xl">
                                    <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-widest">{t("podiums")}</span>
                                    {#if seasonStats !== null}
                                        <span class="text-xl font-black text-yellow-400 tabular-nums">{seasonStats.seasonPodiums}</span>
                                    {:else}
                                        <div class="h-6 w-8 bg-app-text/5 rounded-full animate-pulse mt-1"></div>
                                    {/if}
                                </div>
                                <div class="flex flex-col gap-0.5 px-4 py-3 bg-app-text/5 border border-app-border rounded-2xl">
                                    <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-widest">{t("poles")}</span>
                                    {#if seasonStats !== null}
                                        <span class="text-xl font-black text-blue-400 tabular-nums">{seasonStats.seasonPoles}</span>
                                    {:else}
                                        <div class="h-6 w-8 bg-app-text/5 rounded-full animate-pulse mt-1"></div>
                                    {/if}
                                </div>
                                <div class="col-span-2 flex flex-col gap-0.5 px-4 py-3 bg-app-primary/5 border border-app-primary/20 rounded-2xl">
                                    <span class="text-[9px] font-bold text-app-primary/50 uppercase tracking-widest">Points</span>
                                    <span class="text-xl font-black text-app-primary tabular-nums">{driver.seasonPoints || 0} PTS</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

            <!-- BACK SIDE: CAREER HISTORY -->
            <div
                class="card-back absolute inset-0 bg-app-surface border border-app-border rounded-[32px] overflow-hidden shadow-2xl flex flex-col backface-hidden [transform:rotateY(180deg)]"
            >
                <!-- Close Button -->
                <button
                    class="absolute top-6 right-6 z-10 p-2 rounded-full bg-app-text/5 border border-app-border text-app-text/40 hover:text-app-text hover:bg-app-text/10 transition-all"
                    onclick={onClose}
                >
                    <X size={20} />
                </button>

                <!-- Flip Back Button -->
                <button
                    class="absolute top-6 right-20 z-10 flex items-center gap-2 px-4 py-2 rounded-full bg-app-primary/10 border border-app-primary/20 text-app-primary text-[10px] font-black uppercase tracking-widest hover:bg-app-primary hover:text-app-primary-foreground transition-all"
                    onclick={() => (isFlipped = false)}
                >
                    <RotateCcw size={14} />
                    {t("profile_view")}
                </button>

                <div class="p-12 flex flex-col h-full gap-8">
                    <div class="flex flex-col gap-2">
                        <h2 class="text-3xl font-black text-app-text uppercase tracking-tighter italic">
                            {driver.name}
                        </h2>
                        <p class="text-xs font-black text-app-text/30 uppercase tracking-[0.3em]">
                            {t("full_career_history")}
                        </p>
                    </div>

                    <div class="flex-1 overflow-y-auto custom-scrollbar pr-4 font-mono">
                        <table class="w-full text-left">
                            <thead class="sticky top-0 bg-app-surface z-10">
                                <tr class="text-[10px] font-black text-app-text/20 uppercase tracking-[0.2em] border-b border-app-border">
                                    <th class="py-4 font-black">{t("year")}</th>
                                    <th class="py-4 font-black">{t("team_and_series")}</th>
                                    <th class="py-4 font-black text-center">{t("races")}</th>
                                    <th class="py-4 font-black text-center">{t("wins")}</th>
                                    <th class="py-4 font-black text-center">{t("podiums")}</th>
                                    <th class="py-4 font-black text-right">{t("status")}</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-app-border/10">
                                {#each stableHistory as row}
                                    <tr class="group hover:bg-app-text/5 transition-colors">
                                        <td class="py-6 text-sm font-black text-app-text/40 italic">
                                            {row.year}
                                        </td>
                                        <td class="py-6">
                                            <div class="flex flex-col">
                                                <span class="text-sm font-black text-app-text uppercase">{row.team}</span>
                                                <span class="text-[10px] font-bold text-app-text/20 uppercase">International Series</span>
                                            </div>
                                        </td>
                                        <td class="py-6 text-sm font-black text-app-text text-center">{row.races}</td>
                                        <td class="py-6 text-sm font-black text-app-primary text-center">{row.wins}</td>
                                        <td class="py-6 text-sm font-black text-yellow-400 text-center">{row.podiums}</td>
                                        <td class="py-6 text-right">
                                            {#if row.isChampion}
                                                <span class="px-3 py-1 bg-yellow-400 text-black text-[10px] font-black uppercase rounded-lg shadow-lg shadow-yellow-400/20">
                                                    Champion
                                                </span>
                                            {:else if row.wins > 0}
                                                <span class="text-[10px] font-black text-app-primary uppercase italic opacity-40 group-hover:opacity-100 transition-opacity">
                                                    Race Winner
                                                </span>
                                            {:else}
                                                <span class="text-[10px] font-black text-app-text/10 uppercase italic">
                                                    Active
                                                </span>
                                            {/if}
                                        </td>
                                    </tr>
                                {/each}
                            </tbody>
                        </table>
                    </div>

                    <div class="pt-8 border-t border-app-border grid grid-cols-4 gap-8">
                        <div class="flex flex-col gap-1">
                            <span class="text-[10px] font-bold text-app-text/30 uppercase">{t("total_races")}</span>
                            <span class="text-2xl font-black text-app-text italic">{driver.races}</span>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-[10px] font-bold text-app-text/30 uppercase">{t("total_wins")}</span>
                            <span class="text-2xl font-black text-app-primary italic">{driver.wins}</span>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-[10px] font-bold text-app-text/30 uppercase">{t("total_podiums")}</span>
                            <span class="text-2xl font-black text-yellow-400 italic">{driver.podiums}</span>
                        </div>
                        <div class="flex flex-col gap-1">
                            <span class="text-[10px] font-bold text-app-text/30 uppercase">{t("total_poles")}</span>
                            <span class="text-2xl font-black text-blue-400 italic">{driver.poles}</span>
                        </div>
                    </div>
                </div>
            </div>
            <!-- /card-back -->
        </div>
        <!-- /card-inner -->
    </div>
    <!-- /perspective-container -->
</div>
{/if}

<ConfirmationModal
    isOpen={confirmConfig.isOpen}
    title={confirmConfig.title}
    message={confirmConfig.message}
    confirmLabel={confirmConfig.confirmLabel}
    cancelLabel={confirmConfig.cancelLabel}
    type={confirmConfig.type}
    isLoading={isProcessing}
    onConfirm={confirmConfig.onConfirm}
    onCancel={confirmConfig.onCancel || closeConfirm}
/>

{#if showNegotiationModal && team}
    <NegotiationModal
        driver={driver}
        teamId={team.id}
        managerBackground={managerStore.profile?.backgroundId ?? ''}
        isOpen={showNegotiationModal}
        onClose={() => { showNegotiationModal = false; }}
        onSuccess={() => { showNegotiationModal = false; onRefresh?.(); onClose(); }}
    />
{/if}

<style>
    .font-heading {
        font-family: "Montserrat", sans-serif;
    }

    .perspective-container {
        perspective: 2000px;
    }

    .card-inner {
        position: relative;
        transform-style: preserve-3d;
    }

    .is-flipped {
        transform: rotateY(180deg);
    }

    .backface-hidden {
        backface-visibility: hidden;
        -webkit-backface-visibility: hidden;
    }

    .custom-scrollbar::-webkit-scrollbar {
        width: 4px;
    }

    .custom-scrollbar::-webkit-scrollbar-track {
        background: transparent;
    }

    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: rgba(255, 255, 255, 0.1);
        border-radius: 10px;
    }

    .custom-scrollbar::-webkit-scrollbar-thumb:hover {
        background: rgba(255, 255, 255, 0.2);
    }
</style>
