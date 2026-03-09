<script lang="ts">
    import { youthAcademyStore } from "$lib/stores/youthAcademy.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
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
    } from "lucide-svelte";
    import InstructionCard from "$lib/components/layout/InstructionCard.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import DriverStars from "$lib/components/DriverStars.svelte";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";

    // Initialize stores
    youthAcademyStore.init();
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
                class="text-zinc-500 font-black tracking-[0.3em] text-[10px] uppercase animate-pulse"
            >
                Syncing Academy Network
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
                    class="text-5xl font-black tracking-tighter text-white mb-3 leading-none italic uppercase"
                >
                    Youth Academy
                </h1>
                <p class="text-zinc-400 font-medium tracking-wide">
                    Establish a regional scouting hub and develop next-gen
                    talent
                </p>
            </div>

            <div
                class="bg-zinc-900/60 border border-white/5 rounded-3xl p-8 backdrop-blur-md mb-8 relative overflow-hidden group"
            >
                <!-- Decorative mesh -->
                <div
                    class="absolute top-0 right-0 w-32 h-32 bg-emerald-500/5 blur-3xl rounded-full -mr-16 -mt-16 transition-transform group-hover:scale-110"
                ></div>

                <h3
                    class="text-emerald-400 font-black text-[10px] tracking-[0.2em] uppercase mb-8 flex items-center gap-2"
                >
                    <Zap class="w-3.5 h-3.5" />
                    Operational Benefits
                </h3>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-8 mb-10">
                    <div class="flex items-start gap-4">
                        <div class="mt-1 p-2 bg-emerald-500/20 rounded-xl">
                            <TrendingUp class="w-5 h-5 text-emerald-400" />
                        </div>
                        <div>
                            <h4
                                class="text-white font-black text-sm mb-1 uppercase tracking-tight italic"
                            >
                                Active Scouting
                            </h4>
                            <p
                                class="text-zinc-500 text-[11px] leading-relaxed"
                            >
                                Scout up to 2 high-potential prospects every
                                week based on regional availability.
                            </p>
                        </div>
                    </div>
                    <div class="flex items-start gap-4">
                        <div class="mt-1 p-2 bg-emerald-500/20 rounded-xl">
                            <Brain class="w-5 h-5 text-emerald-400" />
                        </div>
                        <div>
                            <h4
                                class="text-white font-black text-sm mb-1 uppercase tracking-tight italic"
                            >
                                Elite Training
                            </h4>
                            <p
                                class="text-zinc-500 text-[11px] leading-relaxed"
                            >
                                Advanced simulation rigs and mentoring programs
                                for selected trainees.
                            </p>
                        </div>
                    </div>
                </div>

                <div
                    class="pt-8 border-t border-white/5 grid grid-cols-2 gap-8"
                >
                    <div class="flex flex-col">
                        <span
                            class="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-1"
                            >Establishment Fee</span
                        >
                        <span
                            class="text-2xl font-black text-white italic tracking-tighter"
                            >$100,000</span
                        >
                    </div>
                    <div class="flex flex-col">
                        <span
                            class="text-[10px] font-black text-zinc-600 uppercase tracking-widest mb-1"
                            >Available Funds</span
                        >
                        <span
                            class="text-2xl font-black italic tracking-tighter {(teamStore
                                .value.team?.budget ?? 0) >= 100000
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
                class="bg-zinc-900/40 border border-white/5 rounded-3xl p-8 backdrop-blur-md mb-10"
            >
                <h3
                    class="text-emerald-400 font-black text-[10px] tracking-[0.2em] uppercase mb-6 flex items-center gap-2"
                >
                    <Globe class="w-3.5 h-3.5" />
                    Target Region Selection
                </h3>

                <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    {#each countries as country}
                        <button
                            class="p-4 rounded-2xl border-2 transition-all flex flex-col items-center gap-2 group
                            {selectedCountry.code === country.code
                                ? 'bg-emerald-500/10 border-emerald-500/50 text-white shadow-lg shadow-emerald-500/10'
                                : 'bg-black/20 border-white/5 text-zinc-500 hover:border-white/10'}"
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
                (teamStore.value.team?.budget ?? 0) >= 100000 &&
                !isPurchasing
                    ? 'bg-emerald-500 hover:bg-emerald-400 text-black shadow-2xl shadow-emerald-500/20 active:scale-[0.98]'
                    : 'bg-zinc-800 text-zinc-600 cursor-not-allowed'}"
                disabled={!selectedCountry ||
                    (teamStore.value.team?.budget ?? 0) < 100000 ||
                    isPurchasing}
                onclick={handlePurchase}
            >
                {#if isPurchasing}
                    <div class="flex items-center justify-center gap-3">
                        <div
                            class="w-5 h-5 border-2 border-black/30 border-t-black rounded-full animate-spin"
                        ></div>
                        <span>Acquiring Assets</span>
                    </div>
                {:else}
                    Initialize Regional Hub
                {/if}
            </button>
        </div>
    {:else}
        <!-- Active Academy View -->

        <!-- Info Header Bar -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 mb-12">
            <!-- Main Info Card -->
            <div
                class="lg:col-span-9 bg-zinc-900/60 border border-white/5 rounded-[2.5rem] p-8 backdrop-blur-md relative overflow-hidden flex flex-col md:flex-row items-center gap-10"
            >
                <!-- Highlight -->
                <div
                    class="absolute -top-20 -right-20 w-64 h-64 bg-white/5 blur-3xl rounded-full"
                ></div>

                <div
                    class="flex items-center gap-8 pr-10 md:border-r border-white/5 h-full"
                >
                    <div
                        class="w-24 h-24 bg-white/5 rounded-3xl flex items-center justify-center border border-white/10 shadow-2xl rotate-3 transition-transform hover:rotate-0 duration-500 shrink-0"
                    >
                        <School class="w-12 h-12 text-white/40" />
                    </div>
                    <div>
                        <div class="flex items-center gap-4 mb-2">
                            <h2
                                class="text-4xl font-black text-white tracking-tighter uppercase italic leading-none"
                            >
                                Academy
                            </h2>
                            <div
                                class="flex gap-1 bg-black/40 px-2 py-1 rounded-lg border border-white/5"
                            >
                                {#each Array(5) as _, i}
                                    <Star
                                        class="w-3.5 h-3.5 {i <
                                        (youthAcademyStore.config
                                            ?.academyLevel ?? 1)
                                            ? 'text-white fill-white'
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
                                class="text-[11px] font-black text-zinc-500 uppercase tracking-[0.2em]"
                                >{youthAcademyStore.config?.countryName} Regional
                                Hub</span
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
                                    class="text-[10px] font-black text-zinc-500 uppercase tracking-[0.2em]"
                                    >Roster Capacity</span
                                >
                                <span class="text-sm font-black text-white"
                                    >{youthAcademyStore.selectedDrivers
                                        .length}<span class="text-zinc-600 mx-1"
                                        >/</span
                                    >{youthAcademyStore.maxSlots}</span
                                >
                            </div>
                            <div
                                class="w-full h-2 bg-black/60 rounded-full overflow-hidden border border-white/5 p-[1px]"
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
                                    class="text-[10px] font-black text-zinc-500 uppercase tracking-[0.2em]"
                                    >Scouting Quota</span
                                >
                                <span class="text-sm font-black text-white"
                                    >{youthAcademyStore.selectedDrivers
                                        .length}<span class="text-zinc-600 mx-1"
                                        >/</span
                                    >{youthAcademyStore.scoutingQuota}</span
                                >
                            </div>
                            <div
                                class="w-full h-2 bg-black/60 rounded-full overflow-hidden border border-white/5 p-[1px]"
                            >
                                <div
                                    class="h-full bg-white/20 rounded-full transition-all duration-1000 ease-out"
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
                                ? 'bg-white/10 border-white/20 text-white hover:bg-white/20 active:scale-95'
                                : 'bg-zinc-950/40 border-white/5 text-zinc-700 opacity-50 cursor-not-allowed grayscale'}"
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
                                    >Upgrade Facility</span
                                >
                                <span
                                    class="text-sm font-black tracking-tighter leading-none italic"
                                    >${formatCurrencyCompact(
                                        1000000 *
                                            (youthAcademyStore.config
                                                ?.academyLevel ?? 1),
                                    )}</span
                                >
                            </div>
                        </button>
                    </div>
                </div>
            </div>

            <!-- Promotion Focus Card -->
            <div
                class="lg:col-span-3 bg-zinc-900/40 border border-white/5 rounded-[2.5rem] p-8 backdrop-blur-md flex flex-col justify-between group overflow-hidden relative transition-all hover:bg-zinc-900/60"
            >
                <div
                    class="absolute -bottom-10 -right-10 w-32 h-32 bg-white/5 blur-3xl rounded-full transition-transform group-hover:scale-150 duration-700"
                ></div>

                <div>
                    <h4
                        class="text-[10px] font-black text-zinc-500 uppercase tracking-[0.2em] mb-6"
                    >
                        Target Promotion
                    </h4>
                    {#if youthAcademyStore.selectedDrivers.some((d) => d.isMarkedForPromotion)}
                        {@const promoted =
                            youthAcademyStore.selectedDrivers.find(
                                (d) => d.isMarkedForPromotion,
                            )}
                        <div class="flex items-center gap-5">
                            <div
                                class="w-16 h-16 rounded-2xl bg-zinc-950 border border-emerald-500/50 overflow-hidden shadow-2xl transition-transform group-hover:-rotate-3"
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
                                    class="text-white font-black text-lg tracking-tighter leading-none mb-1.5 uppercase italic truncate w-24"
                                >
                                    {promoted?.name.split(" ")[0]}
                                </h5>
                                <div class="flex items-center gap-2">
                                    <div
                                        class="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"
                                    ></div>
                                    <span
                                        class="text-[10px] font-black text-emerald-400 uppercase tracking-tighter"
                                        >Season Finale</span
                                    >
                                </div>
                            </div>
                        </div>
                    {:else}
                        <div
                            class="flex items-center gap-5 text-zinc-700 italic"
                        >
                            <div
                                class="w-16 h-16 rounded-2xl bg-black/40 border border-white/5 flex items-center justify-center"
                            >
                                <Users class="w-8 h-8 opacity-20" />
                            </div>
                            <div>
                                <h5
                                    class="font-black text-sm tracking-tight leading-none mb-1 uppercase text-zinc-600"
                                >
                                    No Program Target
                                </h5>
                                <span
                                    class="text-[9px] font-black uppercase tracking-tighter text-zinc-700"
                                    >Mark a Graduand</span
                                >
                            </div>
                        </div>
                    {/if}
                </div>

                <div
                    class="pt-6 border-t border-white/5 mt-8 flex items-center justify-between"
                >
                    <span
                        class="text-[10px] font-black text-zinc-600 uppercase tracking-widest"
                        >Team Size</span
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
                        <span class="text-xs font-black text-white ml-1"
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
                            class="text-2xl font-black text-white tracking-tighter uppercase italic"
                        >
                            Training Roster
                        </h3>
                        <span
                            class="px-3 py-1 bg-emerald-500/10 text-emerald-400 text-[10px] font-black rounded-lg uppercase border border-emerald-500/20 ml-2 tracking-widest"
                            >Active Ops</span
                        >
                    </div>
                </div>

                {#if youthAcademyStore.selectedDrivers.length === 0}
                    <div
                        class="bg-zinc-950/40 border-2 border-dashed border-white/5 rounded-[3rem] p-24 flex flex-col items-center justify-center text-center backdrop-blur-sm group"
                    >
                        <div
                            class="w-24 h-24 bg-zinc-900 rounded-[2rem] flex items-center justify-center mb-8 border border-white/5 transition-transform group-hover:scale-110 duration-500"
                        >
                            <Users class="w-12 h-12 text-zinc-800" />
                        </div>
                        <h4
                            class="text-white font-black text-2xl mb-3 uppercase tracking-tight italic"
                        >
                            Program Dormant
                        </h4>
                        <p
                            class="text-zinc-500 text-sm max-w-sm font-medium leading-relaxed"
                        >
                            Your state-of-the-art facility is operational but
                            idle. Review the weekly scouting reports and sign
                            high-ceiling candidates to initiate their
                            development path.
                        </p>
                    </div>
                {:else}
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                        {#each youthAcademyStore.selectedDrivers as driver}
                            <div
                                class="group bg-zinc-900/60 border border-white/5 rounded-[2.5rem] p-8 backdrop-blur-md relative overflow-hidden transition-all duration-500 hover:border-emerald-500/30 hover:bg-zinc-900/80 hover:shadow-2xl hover:shadow-emerald-500/5"
                            >
                                <!-- Active Decision Banner -->
                                {#if driver.pendingAction}
                                    <div
                                        class="absolute inset-x-4 inset-y-4 bg-zinc-950/90 backdrop-blur-md z-30 flex flex-col items-center justify-center p-8 text-center animate-fade-in border-2 border-emerald-500/50 rounded-[2.25rem] shadow-2xl"
                                    >
                                        <div
                                            class="w-16 h-16 bg-emerald-500/20 rounded-2xl flex items-center justify-center mb-6 border border-emerald-500/30"
                                        >
                                            <AlertTriangle
                                                class="w-8 h-8 text-emerald-400"
                                            />
                                        </div>
                                        <h4
                                            class="text-white font-black text-xl uppercase tracking-tighter mb-2 italic"
                                        >
                                            Urgent Insight Needed
                                        </h4>
                                        <p
                                            class="text-zinc-400 font-bold text-xs mb-8 px-4 leading-relaxed tracking-wide italic"
                                        >
                                            "{driver.weeklyEventMessage ||
                                                "Critical development stage reached. Manager decision protocol activated."}"
                                        </p>

                                        <div class="flex gap-4 w-full">
                                            <button
                                                class="flex-1 py-4 bg-emerald-500 text-black font-black uppercase text-xs rounded-2xl hover:scale-105 active:scale-95 transition-all shadow-xl shadow-emerald-500/20"
                                                onclick={() =>
                                                    youthAcademyStore.solveAcademyAction(
                                                        driver.id,
                                                        "resolve",
                                                    )}>Resolve Flow</button
                                            >
                                            <button
                                                class="flex-1 py-4 bg-white/10 text-white font-black uppercase text-xs rounded-2xl border border-white/10 hover:bg-white/20 transition-all"
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
                                            class="w-24 h-24 rounded-[2rem] bg-zinc-950 border border-white/5 overflow-hidden shadow-2xl transition-transform group-hover:-rotate-3 group-hover:scale-105 duration-500"
                                        >
                                            <DriverAvatar
                                                id={driver.id}
                                                gender={driver.gender}
                                                class="w-full h-full"
                                            />
                                        </div>
                                        <div
                                            class="absolute -bottom-2 -right-2 w-10 h-10 bg-zinc-900 border {driver.isMarkedForPromotion
                                                ? 'border-fuchsia-500/50'
                                                : 'border-white/10'} rounded-2xl flex items-center justify-center shadow-2xl"
                                        >
                                            <span
                                                class="text-sm font-black text-white italic"
                                                >{driver.age}</span
                                            >
                                        </div>
                                    </div>
                                    <div class="flex-1 overflow-hidden">
                                        <div
                                            class="flex items-center justify-between mb-2"
                                        >
                                            <h4
                                                class="text-2xl font-black text-white tracking-tighter uppercase leading-none truncate w-36 italic"
                                            >
                                                {driver.name}
                                            </h4>
                                            <div
                                                class="flex items-center gap-2"
                                            >
                                                <button
                                                    class="p-2.5 rounded-2xl transition-all border {driver.isMarkedForPromotion
                                                        ? 'bg-fuchsia-500 border-fuchsia-500 text-black shadow-xl shadow-fuchsia-500/20'
                                                        : 'bg-transparent border-white/5 text-zinc-700 hover:text-fuchsia-500 hover:border-fuchsia-500/30'}"
                                                    onclick={() =>
                                                        youthAcademyStore.togglePromotion(
                                                            driver.id,
                                                            !driver.isMarkedForPromotion,
                                                        )}
                                                    title="Mark for Promotion"
                                                >
                                                    <TrendingUp
                                                        class="w-5 h-5"
                                                    />
                                                </button>
                                                <button
                                                    class="p-2.5 rounded-2xl transition-all border bg-transparent border-white/5 text-zinc-800 hover:text-red-500 hover:border-red-500/30"
                                                    onclick={() =>
                                                        youthAcademyStore.releaseDriver(
                                                            driver.id,
                                                        )}
                                                    title="Release Driver"
                                                >
                                                    <XCircle class="w-5 h-5" />
                                                </button>
                                            </div>
                                        </div>
                                        <DriverStars
                                            currentStars={driver.baseSkill / 20}
                                            maxStars={5}
                                        />
                                        <div
                                            class="flex items-center gap-4 mt-4"
                                        >
                                            <div class="flex flex-col">
                                                <span
                                                    class="text-[9px] font-black text-zinc-600 uppercase tracking-widest leading-none mb-1.5"
                                                    >Status</span
                                                >
                                                <div
                                                    class="flex items-center gap-1.5"
                                                >
                                                    <div
                                                        class="w-2 h-2 bg-emerald-500 rounded-full animate-pulse"
                                                    ></div>
                                                    <span
                                                        class="text-[11px] font-black text-emerald-400 uppercase tracking-widest italic"
                                                        >In Training</span
                                                    >
                                                </div>
                                            </div>
                                            <div
                                                class="h-8 w-px bg-white/5 mx-1"
                                            ></div>
                                            <div class="flex flex-col">
                                                <span
                                                    class="text-[9px] font-black text-zinc-600 uppercase tracking-widest leading-none mb-1.5"
                                                    >Growth</span
                                                >
                                                <span
                                                    class="text-[11px] font-black text-white uppercase tracking-tighter"
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
                                                        class="p-1.5 bg-black/40 rounded-lg border border-white/5"
                                                    >
                                                        <Icon
                                                            class="w-3.5 h-3.5 text-zinc-500"
                                                        />
                                                    </div>
                                                    <span
                                                        class="text-[10px] font-black text-zinc-400 uppercase tracking-[0.15em]"
                                                        >{key}</span
                                                    >
                                                </div>
                                                <div
                                                    class="flex items-center gap-3"
                                                >
                                                    {#if driver.weeklyStatDiffs?.[key]}
                                                        <div
                                                            class="flex items-center gap-1 px-2 py-0.5 bg-emerald-500/10 rounded-md border border-emerald-500/20"
                                                        >
                                                            <TrendingUp
                                                                class="w-2.5 h-2.5 text-emerald-400"
                                                            />
                                                            <span
                                                                class="text-[11px] font-black text-emerald-400"
                                                                >+{driver
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
                                                            class="text-xs font-black text-white tracking-tighter"
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
                                                            class="text-xs font-black text-zinc-400 tracking-tighter"
                                                            >{driver
                                                                .statRangeMax?.[
                                                                key
                                                            ] ?? 0}</span
                                                        >
                                                    </div>
                                                </div>
                                            </div>
                                            <div
                                                class="w-full h-2.5 bg-black/80 rounded-full overflow-hidden border border-white/5 relative p-[2px]"
                                            >
                                                <!-- Base Range Indicator -->
                                                <div
                                                    class="absolute h-full bg-white/10 rounded-full opacity-50"
                                                    style="left: {driver
                                                        .statRangeMin?.[key] ??
                                                        0}%; right: {100 -
                                                        (driver.statRangeMax?.[
                                                            key
                                                        ] ?? 100)}%"
                                                ></div>
                                                <!-- Current Fill Progress -->
                                                <div
                                                    class="absolute h-full {driver
                                                        .weeklyStatDiffs?.[key]
                                                        ? 'bg-emerald-500 shadow-[0_0_12px_rgba(16,185,129,0.4)]'
                                                        : 'bg-zinc-500'} rounded-full transition-all duration-1000 ease-out"
                                                    style="width: {driver
                                                        .statRangeMin?.[key] ??
                                                        0}%"
                                                ></div>

                                                {#if driver.trainingProgress}
                                                    <div
                                                        class="absolute h-full w-1.5 bg-white/30 blur-[1px] rounded-full transition-all duration-1000"
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
                                        class="p-4 bg-black/40 rounded-3xl border border-white/5 flex items-start gap-4 mt-6 group/msg transition-colors hover:border-white/10"
                                    >
                                        <div
                                            class="p-2 bg-zinc-900 rounded-xl border border-white/5"
                                        >
                                            <Eye
                                                class="w-4 h-4 text-emerald-400"
                                            />
                                        </div>
                                        <p
                                            class="text-[11px] text-zinc-400 font-medium leading-relaxed italic opacity-80 group-hover/msg:opacity-100 transition-opacity"
                                        >
                                            "{driver.weeklyEventMessage}"
                                        </p>
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
                        class="text-2xl font-black text-white tracking-tighter uppercase italic"
                    >
                        Scouting INTEL
                    </h3>
                    <div
                        class="flex items-center gap-2 text-[10px] font-black text-zinc-500 uppercase tracking-widest"
                    >
                        <Target class="w-5 h-5" />
                        <span>Live Data</span>
                    </div>
                </div>

                <div class="space-y-6">
                    {#each youthAcademyStore.candidates as candidate}
                        <div
                            class="bg-zinc-950/40 border border-white/5 rounded-[2.5rem] p-6 transition-all duration-500 hover:bg-zinc-950/80 hover:border-emerald-500/20 group relative overflow-hidden"
                        >
                            <!-- Subtle regional backdrop symbol -->
                            <span
                                class="absolute -top-6 -right-6 text-7xl opacity-[0.03] group-hover:opacity-[0.07] transition-opacity grayscale select-none pointer-events-none"
                                >{youthAcademyStore.config?.countryFlag}</span
                            >

                            <div class="flex items-center gap-6 mb-6">
                                <div
                                    class="w-20 h-20 rounded-[1.75rem] bg-zinc-900 border border-white/10 overflow-hidden shrink-0 shadow-2xl transition-transform group-hover:scale-105 group-hover:rotate-2 duration-500"
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
                                            class="text-lg font-black text-white uppercase tracking-tighter italic truncate leading-none"
                                        >
                                            {candidate.name}
                                        </h4>
                                        <span
                                            class="text-[10px] font-black text-zinc-600 uppercase"
                                            >{candidate.age}Y</span
                                        >
                                    </div>
                                    <DriverStars
                                        currentStars={candidate.baseSkill / 20}
                                        maxStars={5}
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
                                                >{(
                                                    ((candidate.baseSkill ??
                                                        0) +
                                                        (candidate.growthPotential ??
                                                            0)) /
                                                    20
                                                ).toFixed(1)} Stars Potential</span
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
                                    <span>Sign Contract</span>
                                </button>
                                <button
                                    class="flex items-center justify-center gap-2 py-4 bg-white/5 text-zinc-600 text-[11px] font-black uppercase rounded-2xl border border-white/5 hover:bg-red-500/10 hover:text-red-400 hover:border-red-500/30 transition-all active:scale-95"
                                    onclick={() =>
                                        youthAcademyStore.dismissCandidate(
                                            candidate.id,
                                        )}
                                >
                                    <XCircle class="w-4 h-4" />
                                    <span>Dismiss</span>
                                </button>
                            </div>

                            <div
                                class="mt-4 flex items-center justify-between px-2"
                            >
                                <span
                                    class="text-[9px] font-black text-zinc-700 uppercase tracking-widest leading-none"
                                    >Scouted Contract Fee</span
                                >
                                <span
                                    class="text-[11px] font-black text-white italic tracking-tighter"
                                    >{formatCurrencyCompact(
                                        candidate.salary ?? 100000,
                                    )}</span
                                >
                            </div>
                        </div>
                    {/each}

                    {#if youthAcademyStore.candidates.length === 0}
                        <div
                            class="bg-zinc-950/20 border border-white/5 rounded-[2.5rem] p-16 text-center backdrop-blur-sm"
                        >
                            <div
                                class="w-12 h-12 bg-white/5 rounded-full flex items-center justify-center mx-auto mb-4 border border-white/5"
                            >
                                <Target class="w-6 h-6 text-zinc-800" />
                            </div>
                            <p
                                class="text-zinc-600 text-[10px] font-black uppercase tracking-[0.2em] mb-1 italic"
                            >
                                Intelligence Pool Empty
                            </p>
                            <p
                                class="text-zinc-800 text-[9px] font-bold uppercase tracking-widest"
                            >
                                Next assessment in 7 days
                            </p>
                        </div>
                    {/if}

                    <!-- Regional Highlight Card -->
                    <div
                        class="bg-gradient-to-br from-zinc-500/10 via-transparent to-transparent border border-white/10 rounded-[2.5rem] p-8 mt-10 relative overflow-hidden group shadow-2xl"
                    >
                        <Globe
                            class="absolute -bottom-6 -right-6 w-32 h-32 text-white/5 rotate-12 transition-transform group-hover:scale-110 duration-1000"
                        />
                        <div class="relative z-10">
                            <h5
                                class="text-white/60 text-[11px] font-black uppercase tracking-[0.3em] mb-4 flex items-center gap-3"
                            >
                                <Target class="w-5 h-5" />
                                Regional Focus
                            </h5>
                            <p
                                class="text-zinc-400 text-xs leading-relaxed font-medium italic opacity-80 group-hover:opacity-100 transition-opacity"
                            >
                                Scouting efforts are strategically concentrated
                                in <span class="text-white font-black"
                                    >{youthAcademyStore.config?.countryName?.toUpperCase()}</span
                                >. Graduates will emerge with peak regional
                                technical expertise and optimized market entry
                                overhead.
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
