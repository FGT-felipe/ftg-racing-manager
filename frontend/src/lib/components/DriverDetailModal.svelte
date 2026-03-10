<script lang="ts">
    import {
        type Driver,
        type ChampionshipForm,
        type CareerHistoryItem,
    } from "$lib/types";

    import { teamStore } from "$lib/stores/team.svelte";
    import { staffService } from "$lib/services/staff.svelte";
    import {
        X,
        Trophy,
        Star,
        Activity,
        Smile,
        TrendingUp,
        ShieldCheck,
        RefreshCw,
        Info,
        Trash2,
        ShoppingBag,
        History,
    } from "lucide-svelte";
    import { fade, fly } from "svelte/transition";
    import DriverAvatar from "./DriverAvatar.svelte";
    import DriverStars from "./DriverStars.svelte";
    import {
        calculateCurrentStars,
        calculateMaxStars,
        isNearingRetirement,
    } from "$lib/utils/driver";
    import { t } from "$lib/utils/i18n";
    import { getTitleInfo } from "$lib/constants/titles";

    interface Props {
        driver: Driver;
        isOpen: boolean;
        onClose: () => void;
        onRefresh?: () => void;
    }

    let { driver, isOpen, onClose, onRefresh }: Props = $props();

    let team = $derived(teamStore.value.team);
    let isFlipped = $state(false);
    let showStatusTooltip = $state(false);
    let isProcessing = $state(false);

    function formatCurrency(value: number) {
        return new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: "USD",
            maximumFractionDigits: 0,
        }).format(value);
    }

    function getFlagUrl(countryCode: string) {
        if (!countryCode) return "https://flagcdn.com/w40/un.png";
        return `https://flagcdn.com/w40/${countryCode.toLowerCase()}.png`;
    }

    const DRIVING_STATS = [
        { key: "braking", label: "Braking" },
        { key: "cornering", label: "Cornering" },
        { key: "smoothness", label: "Smoothness" },
        { key: "overtaking", label: "Overtaking" },
        { key: "consistency", label: "Consistency" },
        { key: "adaptability", label: "Adaptability" },
    ];

    const MENTAL_STATS = [
        { key: "fitness", label: "Fitness", icon: Activity },
        { key: "focus", label: "Focus", icon: ShieldCheck },
        { key: "feedback", label: "Feedback", icon: TrendingUp },
        { key: "morale", label: "Morale", icon: Smile },
    ];

    function getStatColor(value: number) {
        if (value >= 75) return "bg-green-400";
        if (value >= 50) return "bg-yellow-400";
        return "bg-red-400";
    }

    function getStatTextColor(value: number) {
        if (value >= 75) return "text-green-400";
        if (value >= 50) return "text-yellow-400";
        return "text-red-400";
    }

    async function handleDismiss() {
        if (!confirm(t("dismiss_confirm", { name: driver.name }))) return;

        if (!team) return;
        isProcessing = true;
        try {
            await staffService.dismissDriver(team.id, driver);
            onRefresh?.();
            onClose();
        } catch (e) {
            alert(e instanceof Error ? e.message : t("error_dismiss"));
        } finally {
            isProcessing = false;
        }
    }

    async function handleListOnMarket() {
        if (!confirm(t("market_confirm", { name: driver.name }))) return;

        if (!team) return;
        isProcessing = true;
        try {
            await staffService.listDriverOnMarket(team.id, driver);
            onRefresh?.();
            onClose();
        } catch (e) {
            alert(e instanceof Error ? e.message : t("error_market"));
        } finally {
            isProcessing = false;
        }
    }

    async function handleRenew() {
        if (!team?.id || !driver) return;

        // Block if nearing retirement (38+)
        if (isNearingRetirement(driver)) {
            alert(t("retirement_alert", { name: driver.name }));
            return;
        }

        const years = window.confirm(t("renew_confirm")) ? 3 : 1;

        isProcessing = true;
        try {
            await staffService.renewContract(team.id, driver.id, years);
            onRefresh?.();
            alert(t("renew_success"));
        } catch (e) {
            alert(e instanceof Error ? e.message : t("error_renew"));
        } finally {
            isProcessing = false;
        }
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
                        ? team?.name || t("current_team")
                        : t("previous_team"),
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
            class="absolute inset-0 bg-black/80 backdrop-blur-sm cursor-default w-full h-full border-none"
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
                    class="card-front absolute inset-0 bg-[#121216] border border-white/10 rounded-[32px] overflow-hidden shadow-2xl flex flex-col md:flex-row backface-hidden"
                >
                    <!-- Close Button -->
                    <button
                        class="absolute top-6 right-6 z-10 p-2 rounded-full bg-white/5 border border-white/10 text-white/40 hover:text-white hover:bg-white/10 transition-all"
                        onclick={onClose}
                    >
                        <X size={20} />
                    </button>

                    <!-- Flip Button -->
                    <button
                        class="absolute top-6 right-20 z-10 flex items-center gap-2 px-4 py-2 rounded-full bg-app-primary/10 border border-app-primary/20 text-app-primary text-[10px] font-black uppercase tracking-widest hover:bg-app-primary hover:text-black transition-all"
                        onclick={() => (isFlipped = true)}
                    >
                        <History size={14} />
                        {t("career_view")}
                    </button>

                    <!-- Column 1: Identity & Key Info -->
                    <div
                        class="flex-1 p-8 md:p-12 flex flex-col gap-8 border-r border-white/5 overflow-y-auto custom-scrollbar"
                    >
                        <div class="flex items-start gap-6">
                            <div class="relative">
                                <div
                                    class="w-28 h-28 md:w-32 md:h-32 rounded-full bg-white/5 border-4 border-app-primary/30 p-1"
                                >
                                    <DriverAvatar
                                        id={driver.id}
                                        gender={driver.gender}
                                        class="w-full h-full rounded-full"
                                    />
                                </div>
                                <div
                                    class="absolute -bottom-2 -right-2 bg-app-primary text-black text-[10px] font-black px-3 py-1 rounded-lg uppercase tracking-widest shadow-lg"
                                >
                                    {driver.potential >= 5
                                        ? t("elite")
                                        : driver.potential >= 4
                                          ? t("pro")
                                          : t("amateur")}
                                </div>
                            </div>

                            <div class="flex flex-col gap-2">
                                <div class="flex items-center gap-3">
                                    <img
                                        src={getFlagUrl(driver.countryCode)}
                                        alt={driver.countryCode}
                                        class="w-6 h-4 object-cover rounded shadow-sm"
                                    />
                                    <span
                                        class="text-xs font-black text-white/30 uppercase tracking-[0.2em]"
                                        >{driver.age}Y</span
                                    >
                                </div>
                                <h1
                                    class="text-4xl md:text-5xl font-heading font-black text-white uppercase tracking-tighter italic leading-none"
                                >
                                    {driver.name}
                                </h1>
                                <div class="flex items-center gap-3">
                                    <DriverStars {driver} size={16} />
                                    <span
                                        class="text-[10px] font-black text-white/40 uppercase tracking-widest"
                                        >{t("potential_peak")}</span
                                    >
                                </div>
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
                                    class="flex items-center gap-2 text-xs font-black text-white/40 uppercase tracking-widest hover:text-white transition-colors"
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
                                        class="absolute bottom-full left-0 mb-2 z-[60] bg-zinc-900 border border-white/10 p-4 rounded-xl shadow-2xl w-64 text-[10px] text-white/80 normal-case tracking-normal"
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
                            class="bg-white/[0.02] border border-white/5 rounded-3xl p-6 flex flex-col gap-4"
                        >
                            <h3
                                class="text-[10px] font-black text-white/20 uppercase tracking-[0.2em]"
                            >
                                {t("contract_details")}
                            </h3>

                            <div class="grid grid-cols-2 gap-y-4">
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-bold text-white/40 uppercase"
                                        >{t("role")}</span
                                    >
                                    <span
                                        class="text-sm font-black text-white uppercase tracking-tight"
                                        >{driver.role}</span
                                    >
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-bold text-white/40 uppercase"
                                        >{t("salary")}</span
                                    >
                                    <span
                                        class="text-sm font-black text-green-400 uppercase tracking-tight"
                                        >{formatCurrency(
                                            driver.salary,
                                        )}/WK</span
                                    >
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-bold text-white/40 uppercase"
                                        >{t("remaining")}</span
                                    >
                                    <span
                                        class="text-sm font-black text-white uppercase tracking-tight"
                                        >{driver.contractYearsRemaining}
                                        {driver.contractYearsRemaining > 1
                                            ? t("seasons_plural")
                                            : t("season_singular")}</span
                                    >
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span
                                        class="text-[10px] font-bold text-white/40 uppercase"
                                        >{t("market_value")}</span
                                    >
                                    <span
                                        class="text-sm font-black text-white uppercase tracking-tight"
                                        >{formatCurrency(
                                            driver.salary * 12,
                                        )}</span
                                    >
                                </div>
                            </div>
                        </div>

                        <!-- Personnel Actions -->
                        <div class="flex flex-col gap-3">
                            <div class="flex gap-4">
                                <button
                                    class="flex-1 flex items-center justify-center gap-3 px-6 py-4 bg-app-primary/10 border border-app-primary/20 rounded-2xl text-app-primary text-[10px] font-black uppercase tracking-widest hover:bg-app-primary hover:text-black transition-all disabled:opacity-50"
                                    onclick={handleRenew}
                                    disabled={isProcessing}
                                >
                                    <RefreshCw size={16} />
                                    {t("renew_contract")}
                                </button>
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
                                    onclick={handleListOnMarket}
                                    disabled={isProcessing ||
                                        driver.isTransferListed}
                                >
                                    <ShoppingBag size={16} />
                                    {driver.isTransferListed
                                        ? t("on_market")
                                        : t("transfer")}
                                </button>
                            </div>
                        </div>

                        <!-- Recent Highlights / Championship Form -->
                        <div class="flex flex-col gap-4">
                            <h3
                                class="text-[10px] font-black text-white/20 uppercase tracking-[0.2em]"
                            >
                                {t("championship_form")}
                            </h3>
                            <div class="grid grid-cols-5 gap-2">
                                {#each Array(5) as _, i}
                                    {@const item = driver.championshipForm?.[i]}
                                    <div
                                        class="bg-white/[0.03] border border-white/5 rounded-xl p-3 flex flex-col items-center gap-1"
                                    >
                                        {#if item}
                                            <span
                                                class="text-[8px] font-black text-zinc-500 uppercase truncate w-full text-center"
                                                >{item.event.substring(
                                                    0,
                                                    3,
                                                )}</span
                                            >
                                            <span
                                                class="text-sm font-black {item.pos.includes(
                                                    'P1',
                                                )
                                                    ? 'text-app-primary'
                                                    : 'text-white'}"
                                                >{item.pos}</span
                                            >
                                            <span
                                                class="text-[8px] font-bold text-zinc-600"
                                                >+{item.pts} pts</span
                                            >
                                        {:else}
                                            <span
                                                class="text-[8px] font-black text-zinc-500 uppercase"
                                                >--</span
                                            >
                                            <span
                                                class="text-sm font-black text-zinc-700"
                                                >--</span
                                            >
                                        {/if}
                                    </div>
                                {/each}
                            </div>
                        </div>
                    </div>

                    <!-- Column 2: Performance Stats -->
                    <div
                        class="flex-1 p-8 md:p-12 bg-white/[0.01] flex flex-col gap-10 overflow-y-auto custom-scrollbar"
                    >
                        <!-- Driving Skills -->
                        <div class="flex flex-col gap-6">
                            <h3
                                class="text-xs font-black text-white uppercase tracking-[0.3em] flex items-center gap-2"
                            >
                                {t("driving_performance")}
                            </h3>

                            <div class="grid grid-cols-1 gap-6">
                                {#each DRIVING_STATS as stat}
                                    {@const val =
                                        driver.stats?.[stat.key] || 50}
                                    <div class="flex flex-col gap-2 group">
                                        <div
                                            class="flex items-center justify-between"
                                        >
                                            <span
                                                class="text-[10px] font-black text-white/40 uppercase tracking-widest group-hover:text-white/60 transition-colors"
                                                >{stat.label}</span
                                            >
                                            <span
                                                class="text-sm font-black font-mono {getStatTextColor(
                                                    val,
                                                )}">{val}</span
                                            >
                                        </div>
                                        <div
                                            class="h-1.5 w-full bg-white/5 rounded-full overflow-hidden"
                                        >
                                            <div
                                                class="h-full transition-all duration-1000 ease-out {getStatColor(
                                                    val,
                                                )}"
                                                style="width: {val}%"
                                            ></div>
                                        </div>
                                    </div>
                                {/each}
                            </div>
                        </div>

                        <!-- Mental & Physical -->
                        <div class="flex flex-col gap-6">
                            <h3
                                class="text-xs font-black text-white uppercase tracking-[0.3em]"
                            >
                                {t("mental_physical")}
                            </h3>
                            <div class="grid grid-cols-2 gap-4">
                                {#each MENTAL_STATS as stat}
                                    {@const val =
                                        driver.stats?.[stat.key] || 50}
                                    <div
                                        class="bg-white/[0.03] border border-white/5 rounded-2xl p-4 flex flex-col gap-3 group hover:border-white/10 transition-all"
                                    >
                                        <div
                                            class="flex items-center justify-between"
                                        >
                                            <stat.icon
                                                size={16}
                                                class="text-white/20 group-hover:text-app-primary transition-colors"
                                            />
                                            <span
                                                class="text-xs font-heading font-black {getStatTextColor(
                                                    val,
                                                )}">{val}%</span
                                            >
                                        </div>
                                        <span
                                            class="text-[9px] font-black text-white/40 uppercase tracking-widest"
                                            >{stat.label}</span
                                        >
                                        <div
                                            class="h-1 w-full bg-white/5 rounded-full overflow-hidden"
                                        >
                                            <div
                                                class="h-full transition-all duration-1000 ease-out {getStatColor(
                                                    val,
                                                )}"
                                                style="width: {val}%"
                                            ></div>
                                        </div>
                                    </div>
                                {/each}
                            </div>
                        </div>
                    </div>
                </div>

                <!-- BACK SIDE (HISTORY) -->
                <div
                    class="card-back absolute inset-0 bg-[#0a0a0d] border border-app-primary/20 rounded-[32px] overflow-hidden shadow-2xl flex flex-col p-8 md:p-12 backface-hidden [transform:rotateY(180deg)]"
                >
                    <button
                        class="absolute top-6 right-6 p-2 rounded-full bg-white/5 border border-white/10 text-white/40 hover:text-white hover:bg-white/10 transition-all"
                        onclick={() => (isFlipped = false)}
                    >
                        <RefreshCw size={20} />
                    </button>

                    <h2
                        class="text-3xl font-heading font-black text-white uppercase tracking-tighter mb-8 italic"
                    >
                        {t("career_history")}
                    </h2>

                    <div class="flex-1 overflow-y-auto custom-scrollbar">
                        <table class="w-full text-left">
                            <thead class="sticky top-0 bg-[#0a0a0d] z-10">
                                <tr class="border-b border-white/10">
                                    <th
                                        class="py-4 text-[10px] font-black text-white/30 uppercase tracking-[0.2em]"
                                        >{t("year")}</th
                                    >
                                    <th
                                        class="py-4 text-[10px] font-black text-white/30 uppercase tracking-[0.2em]"
                                        >{t("team")}</th
                                    >
                                    <th
                                        class="py-4 text-[10px] font-black text-white/30 uppercase tracking-[0.2em]"
                                        >{t("races")}</th
                                    >
                                    <th
                                        class="py-4 text-[10px] font-black text-white/30 uppercase tracking-[0.2em]"
                                        >{t("podiums")}</th
                                    >
                                    <th
                                        class="py-4 text-[10px] font-black text-white/30 uppercase tracking-[0.2em]"
                                        >{t("wins")}</th
                                    >
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-white/5">
                                {#each stableHistory as row}
                                    <tr
                                        class="hover:bg-white/[0.02] transition-colors"
                                    >
                                        <td
                                            class="py-4 text-sm font-black text-white/60"
                                            >{row.year}</td
                                        >
                                        <td
                                            class="py-4 text-sm font-black text-white"
                                        >
                                            {row.team}
                                            {#if row.isChampion}
                                                <span
                                                    class="ml-2 px-1.5 py-0.5 bg-yellow-400 text-black text-[8px] rounded font-black uppercase tracking-tighter"
                                                    >{t("champion")}</span
                                                >
                                            {/if}
                                        </td>
                                        <td
                                            class="py-4 text-sm font-black text-white/60"
                                            >{row.races}</td
                                        >
                                        <td
                                            class="py-4 text-sm font-black text-yellow-400"
                                            >{row.podiums}</td
                                        >
                                        <td
                                            class="py-4 text-sm font-black text-app-primary"
                                            >{row.wins}</td
                                        >
                                    </tr>
                                {/each}
                            </tbody>
                        </table>
                    </div>

                    <div
                        class="mt-8 pt-8 border-t border-white/5 grid grid-cols-2 md:grid-cols-4 gap-8"
                    >
                        <div class="flex flex-col gap-1">
                            <span
                                class="text-[10px] font-bold text-white/40 uppercase"
                                >{t("total_races")}</span
                            >
                            <span class="text-2xl font-black text-white italic"
                                >{driver.races}</span
                            >
                        </div>
                        <div class="flex flex-col gap-1">
                            <span
                                class="text-[10px] font-bold text-white/40 uppercase"
                                >{t("total_wins")}</span
                            >
                            <span
                                class="text-2xl font-black text-app-primary italic"
                                >{driver.wins}</span
                            >
                        </div>
                        <div class="flex flex-col gap-1">
                            <span
                                class="text-[10px] font-bold text-white/40 uppercase"
                                >{t("championships")}</span
                            >
                            <span
                                class="text-2xl font-black text-yellow-400 italic"
                                >{driver.championships}</span
                            >
                        </div>
                        <div class="flex flex-col gap-1">
                            <span
                                class="text-[10px] font-bold text-white/40 uppercase"
                                >{t("poles")}</span
                            >
                            <span
                                class="text-2xl font-black text-blue-400 italic"
                                >{driver.poles}</span
                            >
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
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
