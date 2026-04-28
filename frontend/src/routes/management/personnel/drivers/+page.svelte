<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { staffService } from "$lib/services/staff.svelte";
    import {
        ChevronLeft,
        Search,
        Trophy,
        Star,
        Activity,
        Smile,
        DollarSign,
        Plus,
        LayoutGrid,
        List as ListIcon,
        User,
    } from "lucide-svelte";

    import { fly, fade } from "svelte/transition";
    import { t } from "$lib/utils/i18n";
    import { formatDriverName } from "$lib/utils/driver";
    import { type Driver } from "$lib/types";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import DriverStars from "$lib/components/DriverStars.svelte";
    import DriverDetailModal from "$lib/components/DriverDetailModal.svelte";

    let team = $derived(teamStore.value.team);
    let isLoading = $derived(teamStore.value.loading);

    let drivers = $state<Driver[]>([]);
    let viewMode = $state<"grid" | "table">("table");
    let searchQuery = $state("");

    let selectedDriver = $state<Driver | null>(null);
    let isDetailModalOpen = $state(false);

    function openDriverDetail(driver: Driver) {
        selectedDriver = driver;
        isDetailModalOpen = true;
    }

    async function refreshDrivers() {
        if (team?.id) {
            drivers = await staffService.getTeamDrivers(team.id);
        }
    }

    $effect(() => {
        refreshDrivers();
    });

    let filteredDrivers = $derived(
        drivers.filter((d) =>
            d.name.toLowerCase().includes(searchQuery.toLowerCase()),
        ),
    );

    function getMoraleColor(value: number) {
        if (value >= 80) return "text-green-400";
        if (value >= 50) return "text-yellow-400";
        return "text-red-400";
    }

    function getStatusBadge(driver: Driver) {
        const role = driver.role?.toLowerCase();
        if (role === 'main')
            return { label: t('driver_role_main'),      color: "bg-green-400/10 text-green-400 border-green-400/20" };
        if (role === 'secondary')
            return { label: t('driver_role_secondary'), color: "bg-blue-400/10 text-blue-400 border-blue-400/20" };
        if (role === 'equal')
            return { label: t('driver_role_equal'),     color: "bg-green-400/10 text-green-400 border-green-400/20" };
        if (role === 'reserve' || driver.role?.toLowerCase().includes('reserve'))
            return { label: t('driver_role_reserve'),   color: "bg-yellow-400/10 text-yellow-400 border-yellow-400/20" };
        // Legacy carIndex fallback: slot 0 = Main, slot 1 = Secondary
        if (driver.carIndex === 0)
            return { label: t('driver_role_main'),      color: "bg-green-400/10 text-green-400 border-green-400/20" };
        if (driver.carIndex === 1)
            return { label: t('driver_role_secondary'), color: "bg-blue-400/10 text-blue-400 border-blue-400/20" };
        return { label: "Academy",                          color: "bg-blue-400/10 text-blue-400 border-blue-400/20" };
    }

    function formatCurrency(value: number) {
        return new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: "USD",
            maximumFractionDigits: 0,
        }).format(value);
    }

    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
</script>

<svelte:head>
    <title>Drivers Management | FTG Racing Manager</title>
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

    <header
        class="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-12"
    >
        <div class="flex flex-col gap-3">
            <h1
                class="text-4xl md:text-5xl font-heading font-black tracking-tighter uppercase italic text-app-text"
            >
                {t('driver_roster')}
            </h1>
            <p
                class="text-xs font-bold text-app-text/30 uppercase tracking-[0.3em]"
            >
                {t('drivers_page_subtitle')}
            </p>
        </div>

        <div class="flex items-center gap-4">
            <div class="relative group">
                <Search
                    size={16}
                    class="absolute left-4 top-1/2 -translate-y-1/2 text-app-text/20 group-focus-within:text-app-primary transition-colors"
                />
                <input
                    type="text"
                    placeholder={t('search_roster')}
                    bind:value={searchQuery}
                    class="bg-app-surface border border-app-border rounded-2xl py-3 pl-12 pr-6 text-sm font-bold text-app-text outline-none focus:border-app-primary/30 focus:bg-app-primary/5 transition-all w-64"
                />
            </div>

            <div
                class="flex bg-app-surface border border-app-border rounded-2xl p-1"
            >
                <button
                    onclick={() => (viewMode = "table")}
                    class="p-2 rounded-xl transition-all {viewMode === 'table'
                        ? 'bg-app-primary text-app-primary-foreground'
                        : 'text-app-text/40 hover:text-app-text'}"
                >
                    <ListIcon size={18} />
                </button>
                <button
                    onclick={() => (viewMode = "grid")}
                    class="p-2 rounded-xl transition-all {viewMode === 'grid'
                        ? 'bg-app-primary text-app-primary-foreground'
                        : 'text-app-text/40 hover:text-app-text'}"
                >
                    <LayoutGrid size={18} />
                </button>
            </div>
        </div>
    </header>

    {#if isLoading}
        <!-- Skeleton etc -->
        <div class="flex items-center justify-center h-64">
            <div
                class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"
            ></div>
        </div>
    {:else if viewMode === "table"}
        <div
            class="bg-app-surface border border-app-border rounded-[32px] overflow-hidden shadow-2xl"
        >
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr
                        class="bg-app-text/5 text-[10px] font-black uppercase tracking-[0.2em] text-app-text/40"
                    >
                        <th class="py-6 px-8">{t('pilot')}</th>
                        <th class="py-6 px-4">{t('role')}</th>
                        <th class="py-6 px-4">{t('potential')}</th>
                        <th class="py-6 px-4">Morale</th>
                        <th class="py-6 px-4">Fitness</th>
                        <th class="py-6 px-4">Stats</th>
                        <th class="py-6 px-8 text-right">{t('actions')}</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-white/5">
                    {#each filteredDrivers as driver, i (driver.id)}
                        {@const badge = getStatusBadge(driver)}
                        <tr
                            in:fly={{ y: 20, delay: i * 30 }}
                            class="group hover:bg-white/[0.02] transition-colors"
                        >
                            <td class="py-6 px-8">
                                <div class="flex items-center gap-4">
                                    <div
                                        class="w-10 h-10 rounded-full bg-app-text/5 border border-app-border overflow-hidden flex items-center justify-center p-0.5"
                                    >
                                        <DriverAvatar
                                            id={driver.id}
                                            gender={driver.gender}
                                            class="w-full h-full"
                                        />
                                    </div>
                                    <div class="flex flex-col">
                                        <div class="flex items-center gap-2">
                                            <span
                                                class="text-sm font-black text-app-text uppercase tracking-tight group-hover:text-app-primary transition-colors"
                                                title={driver.name}
                                            >
                                                {formatDriverName(driver.name)}
                                            </span>
                                            {#if driver.championships > 0}
                                                <div class="flex items-center gap-0.5 text-app-primary" aria-label="{driver.championships} title(s)">
                                                    <Trophy size={10} />
                                                    <span class="text-[9px] font-black tabular-nums">{driver.championships}</span>
                                                </div>
                                            {/if}
                                        </div>
                                        <span class="text-app-text/20 uppercase tracking-widest flex items-center gap-1.5">
                                            <CountryFlag countryCode={driver.countryCode} size="sm" />
                                            <span>{driver.age}y • CONTRACT: {driver.contractYearsRemaining}y</span>
                                        </span>
                                    </div>
                                </div>
                            </td>
                            <td class="py-6 px-4">
                                <div class="flex flex-col gap-1.5">
                                    <span
                                        class="px-2 py-0.5 rounded-md text-[8px] font-black uppercase tracking-widest border {badge.color}"
                                    >
                                        {badge.label}
                                    </span>
                                    {#if driver.isTransferListed}
                                        <span class="px-2 py-0.5 rounded-md text-[8px] font-black uppercase tracking-widest border bg-yellow-400/10 text-yellow-400 border-yellow-400/20">
                                            {t('on_market')}
                                        </span>
                                    {/if}
                                </div>
                            </td>
                            <td class="py-6 px-4">
                                <DriverStars {driver} size={14} />
                            </td>
                            <td class="py-6 px-4">
                                <div class="flex items-center gap-2">
                                    <Smile
                                        size={14}
                                        class={getMoraleColor(
                                            driver.stats?.morale || 50,
                                        )}
                                    />
                                    <span
                                        class="text-xs font-black {getMoraleColor(
                                            driver.stats?.morale || 50,
                                        )}">{driver.stats?.morale || 50}%</span
                                    >
                                </div>
                            </td>
                            <td class="py-6 px-4">
                                <div class="flex items-center gap-2">
                                    <Activity
                                        size={14}
                                        class="text-green-400"
                                    />
                                    <span class="text-xs font-black text-app-text"
                                        >{Math.round((driver.stats?.fitness || 70) * 10) / 10}%</span
                                    >
                                </div>
                            </td>
                            <td class="py-6 px-4">
                                <div class="flex flex-col gap-1">
                                    <div class="flex items-center gap-2">
                                        <span class="text-xs font-black text-app-primary italic tabular-nums">
                                            {driver.seasonPoints} PTS
                                        </span>
                                        <div class="flex items-center gap-1 opacity-60">
                                            {#each (driver.championshipForm || []).slice(-3) as form}
                                                {@const posRank = parseInt(form.pos.replace("P", "")) || 20}
                                                <div
                                                    class="w-2 h-2 rounded-full {posRank <= 3 ? 'bg-yellow-400' : posRank <= 10 ? 'bg-green-500' : 'bg-red-500/40'}"
                                                    title="P{posRank}"
                                                ></div>
                                            {/each}
                                        </div>
                                    </div>
                                    <div class="flex items-center gap-2.5 text-[8px] font-black text-app-text/30 uppercase tracking-widest">
                                        <span>{driver.seasonWins} Wins</span>
                                        <span>{driver.seasonPodiums} Podiums</span>
                                    </div>
                                </div>
                            </td>
                            <td class="py-6 px-8 text-right">
                                <button
                                    onclick={() => openDriverDetail(driver)}
                                    class="px-4 py-2 bg-app-text/5 border border-app-border rounded-xl text-[9px] font-black uppercase tracking-widest text-app-text/60 hover:bg-app-primary hover:text-app-primary-foreground hover:border-app-primary transition-all"
                                >
                                    {t('manage')}
                                </button>
                            </td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
    {:else}
        <!-- Grid View -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {#each filteredDrivers as driver, i (driver.id)}
                {@const badge = getStatusBadge(driver)}
                <div
                    in:fly={{ y: 20, delay: i * 30 }}
                    class="bg-app-surface border border-app-border rounded-[32px] p-8 flex flex-col gap-6 group hover:border-app-primary/30 transition-all shadow-xl"
                >
                    <div class="flex items-center justify-between">
                        <div class="flex items-center gap-4">
                            <div
                                class="w-14 h-14 rounded-2xl bg-app-text/5 border border-app-border overflow-hidden p-1"
                            >
                                <DriverAvatar
                                    id={driver.id}
                                    gender={driver.gender}
                                    class="w-full h-full"
                                />
                            </div>
                            <div class="flex flex-col">
                                <div class="flex items-center gap-2">
                                    <h3
                                        class="text-lg font-black text-app-text uppercase tracking-tight group-hover:text-app-primary transition-colors"
                                        title={driver.name}
                                    >
                                        {formatDriverName(driver.name)}
                                    </h3>
                                    {#if driver.championships > 0}
                                        <div class="flex items-center gap-0.5 text-app-primary" aria-label="{driver.championships} title(s)">
                                            <Trophy size={11} />
                                            <span class="text-[9px] font-black tabular-nums">{driver.championships}</span>
                                        </div>
                                    {/if}
                                </div>
                                <span
                                    class="text-[10px] font-black text-app-text/20 uppercase tracking-[0.2em] flex items-center gap-1.5"
                                    >
                                    <CountryFlag countryCode={driver.countryCode} size="sm" />
                                    <span>{driver.age}Y • {driver.salary
                                        ? formatCurrency(Math.round(driver.salary / 52))
                                        : "$0"}/WK</span></span
                                >
                            </div>
                        </div>
                        <div class="flex flex-col items-end gap-1.5">
                            <span
                                class="px-2 py-0.5 rounded-md text-[8px] font-black uppercase tracking-widest border {badge.color}"
                            >
                                {badge.label}
                            </span>
                            {#if driver.isTransferListed}
                                <span class="px-2 py-0.5 rounded-md text-[8px] font-black uppercase tracking-widest border bg-yellow-400/10 text-yellow-400 border-yellow-400/20">
                                    {t('on_market')}
                                </span>
                            {/if}
                        </div>
                    </div>

                    <div class="grid grid-cols-3 gap-4">
                        <div
                            class="flex flex-col gap-1 items-center p-3 bg-white/[0.02] rounded-2xl"
                        >
                            <span
                                class="text-[8px] font-black text-app-text/20 uppercase tracking-widest"
                                >Morale</span
                              >
                            <span
                                class="text-xs font-black {getMoraleColor(
                                    driver.stats?.morale || 50,
                                )}">{driver.stats?.morale || 50}%</span
                            >
                        </div>
                        <div
                            class="flex flex-col gap-1 items-center p-3 bg-white/[0.02] rounded-2xl"
                        >
                            <span
                                class="text-[8px] font-black text-app-text/20 uppercase tracking-widest"
                                >Fitness</span
                            >
                            <span class="text-xs font-black text-app-text"
                                >{Math.round((driver.stats?.fitness || 70) * 10) / 10}%</span
                            >
                        </div>
                        <div
                            class="flex flex-col gap-1 items-center p-3 bg-white/[0.02] rounded-2xl"
                        >
                            <span
                                class="text-[8px] font-black text-app-text/20 uppercase tracking-widest"
                                >Points</span
                            >
                            <span class="text-xs font-black text-app-primary tabular-nums"
                                >{driver.seasonPoints}</span
                            >
                        </div>
                    </div>

                    <div class="flex items-center justify-between px-2 text-[10px] font-bold text-app-text/30 uppercase tracking-tighter">
                        <span>{t('season_record')}</span>
                        <span class="text-app-text/60">
                            {driver.seasonWins}W · {driver.seasonPodiums}P · {driver.seasonPoles}L
                        </span>
                    </div>

                    <div
                        class="flex items-center justify-between pt-4 border-t border-app-border"
                    >
                        <DriverStars {driver} size={12} />
                        <button
                            onclick={() => openDriverDetail(driver)}
                            class="text-[10px] font-black text-app-primary uppercase tracking-[0.2em] flex items-center gap-2 group-hover:gap-3 transition-all"
                        >
                            {t('open_profile')} <ChevronLeft
                                size={14}
                                class="rotate-180"
                            />
                        </button>
                    </div>
                </div>
            {/each}
        </div>
    {/if}

    <!-- Bottom Action Bar (Floating maybe?) -->
    <div class="mt-12 flex justify-center">
        <a
            href="/market"
            class="px-10 py-5 bg-app-surface text-black rounded-[32px] font-black text-xs uppercase tracking-[0.3em] shadow-2xl hover:scale-105 transition-all flex items-center gap-3"
        >
            <Plus size={16} strokeWidth={3} /> {t('scout_driver_market')}
        </a>
    </div>

    {#if selectedDriver}
        <DriverDetailModal
            driver={selectedDriver}
            isOpen={isDetailModalOpen}
            onClose={() => (isDetailModalOpen = false)}
            onRefresh={refreshDrivers}
            allDrivers={drivers}
        />
    {/if}
</div>

<style>
    /* Table styles */
    th,
    td {
        vertical-align: middle;
    }
</style>
