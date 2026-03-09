<script lang="ts">
    import { youthAcademyStore } from "$lib/stores/youthAcademy.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import {
        GraduationCap,
        TrendingUp,
        UserPlus,
        XCircle,
        Trophy,
        Globe,
        Star,
        AlertTriangle,
        ChevronRight,
        User,
    } from "lucide-svelte";
    import InstructionCard from "$lib/components/layout/InstructionCard.svelte";
    import DriverStars from "$lib/components/DriverStars.svelte";

    // Initialize store
    youthAcademyStore.init();

    const availableCountries = [
        { code: "CO", name: "Colombia", flagEmoji: "🇨🇴" },
        { code: "BR", name: "Brasil", flagEmoji: "🇧🇷" },
        { code: "AR", name: "Argentina", flagEmoji: "🇦🇷" },
        { code: "MX", name: "México", flagEmoji: "🇲🇽" },
        { code: "ES", name: "España", flagEmoji: "🇪🇸" },
        { code: "IT", name: "Italia", flagEmoji: "🇮🇹" },
        { code: "GB", name: "United Kingdom", flagEmoji: "🇬🇧" },
        { code: "DE", name: "Germany", flagEmoji: "🇩🇪" },
    ];

    let selectedCountry = $state(availableCountries[0]);
    let isPurchasing = $state(false);

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
        try {
            await youthAcademyStore.upgradeAcademy();
        } catch (e: any) {
            alert(e.message);
        }
    }

    async function handleSelect(id: string) {
        try {
            await youthAcademyStore.selectCandidate(id);
        } catch (e: any) {
            alert(e.message);
        }
    }

    let config = $derived(youthAcademyStore.config);
</script>

<svelte:head>
    <title>Youth Academy | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-4 md:p-8 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text"
>
    <InstructionCard
        icon={GraduationCap}
        title="Youth Academy"
        description="Scout and develop the next generation of racing world champions. Your academy identifies young talent that can be trained and eventually promoted to the main team at a lower cost."
    />

    {#if youthAcademyStore.loading}
        <div
            class="mt-20 flex flex-col items-center justify-center gap-4 text-app-text/30"
        >
            <div
                class="w-12 h-12 border-4 border-app-primary/20 border-t-app-primary rounded-full animate-spin"
            ></div>
            <span class="text-[10px] font-black uppercase tracking-widest"
                >Loading Academy...</span
            >
        </div>
    {:else if !youthAcademyStore.config}
        <!-- Purchase View -->
        <div class="mt-10 max-w-2xl mx-auto space-y-8">
            <div
                class="bg-app-surface border border-app-border rounded-3xl p-8 shadow-2xl overflow-hidden relative group"
            >
                <div
                    class="absolute top-0 right-0 w-64 h-64 bg-app-primary/5 rounded-full -mr-32 -mt-32 blur-3xl"
                ></div>

                <div class="relative">
                    <h2
                        class="text-2xl font-black text-white uppercase tracking-tight mb-2"
                    >
                        Establish Academy
                    </h2>
                    <p class="text-sm text-app-text/60 mb-8">
                        Select the primary scouting region. All academy
                        graduates will share this nationality.
                    </p>

                    <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-8">
                        {#each availableCountries as country}
                            <button
                                onclick={() => (selectedCountry = country)}
                                class="flex flex-col items-center gap-2 p-4 rounded-2xl border transition-all {selectedCountry.code ===
                                country.code
                                    ? 'bg-app-primary/10 border-app-primary shadow-lg shadow-app-primary/10'
                                    : 'bg-app-text/5 border-app-border hover:border-app-text/20'}"
                            >
                                <span class="text-3xl">{country.flagEmoji}</span
                                >
                                <span
                                    class="text-[10px] font-black uppercase tracking-widest {selectedCountry.code ===
                                    country.code
                                        ? 'text-app-primary'
                                        : 'text-app-text/40'}"
                                    >{country.name}</span
                                >
                            </button>
                        {/each}
                    </div>

                    <div
                        class="p-5 bg-black/40 border border-app-border/50 rounded-2xl space-y-3 mb-8"
                    >
                        <div class="flex items-center justify-between">
                            <span
                                class="text-[10px] font-bold text-app-text/40 uppercase"
                                >Initial Investment</span
                            >
                            <span class="text-lg font-black text-white"
                                >$100,000</span
                            >
                        </div>
                        <div
                            class="flex items-center justify-between pt-3 border-t border-app-border/30"
                        >
                            <span
                                class="text-[10px] font-bold text-app-text/40 uppercase"
                                >Available Budget</span
                            >
                            <span
                                class="text-sm font-bold {teamStore.value
                                    .team &&
                                teamStore.value.team.budget >= 100000
                                    ? 'text-emerald-400'
                                    : 'text-red-400'}"
                            >
                                {teamStore.formattedBudget}
                            </span>
                        </div>
                    </div>

                    <button
                        onclick={handlePurchase}
                        disabled={isPurchasing ||
                            (teamStore.value.team?.budget ?? 0) < 100000}
                        class="w-full py-4 bg-app-primary text-black font-black uppercase tracking-[0.2em] rounded-2xl hover:scale-[1.02] active:scale-95 transition-all shadow-xl shadow-app-primary/20 disabled:opacity-50"
                    >
                        {isPurchasing ? "Processing..." : "Build Academy"}
                    </button>
                </div>
            </div>
        </div>
    {:else if config}
        <!-- Active Academy View -->
        <div class="mt-8 grid grid-cols-1 lg:grid-cols-12 gap-8">
            <!-- Left: Info & Candidates -->
            <div class="lg:col-span-8 space-y-8">
                <!-- Status Bar -->
                <div
                    class="bg-app-surface border border-app-border rounded-2xl p-6 flex flex-wrap items-center gap-8"
                >
                    <div class="flex flex-col">
                        <span
                            class="text-[10px] font-bold text-app-text/30 uppercase tracking-widest mb-1"
                            >Level</span
                        >
                        <div class="flex gap-1">
                            {#each Array(5) as _, i}
                                <Star
                                    size={16}
                                    class={i <
                                    (youthAcademyStore.config?.academyLevel ||
                                        0)
                                        ? "text-app-primary fill-app-primary"
                                        : "text-app-text/10"}
                                />
                            {/each}
                        </div>
                    </div>

                    <div
                        class="h-8 w-px bg-app-border/50 hidden md:block"
                    ></div>

                    <div class="flex flex-col">
                        <span
                            class="text-[10px] font-bold text-app-text/30 uppercase tracking-widest mb-1"
                            >Scouting Region</span
                        >
                        <div class="flex items-center gap-2">
                            <span class="text-xl"
                                >{youthAcademyStore.config?.countryFlag}</span
                            >
                            <span
                                class="text-sm font-black text-white uppercase"
                                >{youthAcademyStore.config?.countryName}</span
                            >
                        </div>
                    </div>

                    <div
                        class="h-8 w-px bg-app-border/50 hidden md:block"
                    ></div>

                    <div class="flex flex-col">
                        <span
                            class="text-[10px] font-bold text-app-text/30 uppercase tracking-widest mb-1"
                            >Roster Load</span
                        >
                        <div class="flex items-center gap-2">
                            <span class="text-sm font-black text-white"
                                >{youthAcademyStore.selectedDrivers.length} / {youthAcademyStore
                                    .config?.maxSlots}</span
                            >
                            <div
                                class="w-16 h-1.5 bg-app-text/5 rounded-full overflow-hidden"
                            >
                                <div
                                    class="h-full bg-app-primary transition-all duration-500"
                                    style="width: {(youthAcademyStore
                                        .selectedDrivers.length /
                                        (config?.maxSlots || 1)) *
                                        100}%"
                                ></div>
                            </div>
                        </div>
                    </div>

                    <div class="ml-auto">
                        {#if config && config.academyLevel < 5}
                            <button
                                onclick={handleUpgrade}
                                class="flex items-center gap-2 px-4 py-2 bg-app-text/5 border border-app-border rounded-xl text-[10px] font-black uppercase text-app-primary hover:bg-app-primary/10 transition-all"
                            >
                                <TrendingUp size={14} />
                                Upgrade
                            </button>
                        {:else}
                            <span
                                class="text-[10px] font-black text-emerald-500 uppercase tracking-widest border border-emerald-500/20 px-3 py-1.5 rounded-lg bg-emerald-500/5"
                                >Max Level</span
                            >
                        {/if}
                    </div>
                </div>

                <!-- Candidates Section -->
                <div>
                    <div class="flex items-center justify-between mb-6 px-2">
                        <div class="flex items-center gap-2">
                            <Globe size={16} class="text-app-primary" />
                            <h3
                                class="text-xs font-black uppercase text-white tracking-[0.2em]"
                            >
                                Weekly Prospects
                            </h3>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {#if youthAcademyStore.candidates.length === 0}
                            <div
                                class="col-span-full p-12 bg-app-surface border border-app-border border-dashed rounded-3xl text-center text-app-text/20"
                            >
                                <p
                                    class="text-[10px] font-black uppercase tracking-widest"
                                >
                                    No candidates scouting this week
                                </p>
                            </div>
                        {:else}
                            {#each youthAcademyStore.candidates as candidate}
                                <div
                                    class="bg-app-surface border border-app-border rounded-3xl p-5 hover:border-app-primary/30 transition-all group overflow-hidden relative"
                                >
                                    <div
                                        class="flex items-start gap-4 mb-4 relative z-10"
                                    >
                                        {#if candidate.portraitUrl}
                                            <img
                                                src={candidate.portraitUrl}
                                                alt={candidate.name}
                                                class="w-16 h-16 rounded-2xl bg-app-text/10 object-cover"
                                            />
                                        {:else}
                                            <div
                                                class="w-16 h-16 rounded-2xl bg-app-text/10 flex items-center justify-center text-app-text/30"
                                            >
                                                <User size={32} />
                                            </div>
                                        {/if}

                                        <div class="flex-grow">
                                            <div
                                                class="flex items-center justify-between mb-1"
                                            >
                                                <h4
                                                    class="font-black text-white uppercase truncate max-w-[150px]"
                                                >
                                                    {candidate.name}
                                                </h4>
                                                <span
                                                    class="text-[10px] font-black text-app-text/40"
                                                    >{candidate.age}y</span
                                                >
                                            </div>
                                            <DriverStars
                                                currentStars={(candidate.baseSkill ??
                                                    0) / 20}
                                                maxStars={5}
                                                size={14}
                                            />
                                            <div
                                                class="mt-2 flex items-center gap-4"
                                            >
                                                <div class="flex flex-col">
                                                    <span
                                                        class="text-[8px] font-bold text-app-text/30 uppercase"
                                                        >Potential</span
                                                    >
                                                    <span
                                                        class="text-xs font-bold text-app-primary italic"
                                                        >{(
                                                            ((candidate.baseSkill ??
                                                                0) +
                                                                (candidate.growthPotential ??
                                                                    0)) /
                                                            20
                                                        ).toFixed(1)} Stars</span
                                                    >
                                                </div>
                                                <div class="flex flex-col">
                                                    <span
                                                        class="text-[8px] font-bold text-app-text/30 uppercase"
                                                        >Signing</span
                                                    >
                                                    <span
                                                        class="text-xs font-bold text-white"
                                                        >${(
                                                            (candidate.salary ??
                                                                0) / 1000
                                                        ).toFixed(0)}k</span
                                                    >
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <div
                                        class="grid grid-cols-2 gap-2 relative z-10"
                                    >
                                        <button
                                            onclick={() =>
                                                handleSelect(candidate.id)}
                                            class="flex items-center justify-center gap-2 py-2 bg-app-primary text-black text-[10px] font-black uppercase rounded-xl hover:scale-[1.05] transition-all"
                                        >
                                            <UserPlus size={14} />
                                            Sign
                                        </button>
                                        <button
                                            onclick={() =>
                                                youthAcademyStore.dismissCandidate(
                                                    candidate.id,
                                                )}
                                            class="flex items-center justify-center gap-2 py-2 bg-app-text/5 text-app-text/30 text-[10px] font-black uppercase rounded-xl hover:bg-red-500/10 hover:text-red-400 transition-all border border-transparent hover:border-red-500/20"
                                        >
                                            <XCircle size={14} />
                                            Dismiss
                                        </button>
                                    </div>
                                </div>
                            {/each}
                        {/if}
                    </div>
                </div>
            </div>

            <!-- Right: Roster -->
            <div class="lg:col-span-4 space-y-6">
                <div class="flex items-center gap-2 px-2">
                    <Trophy size={16} class="text-app-primary" />
                    <h3
                        class="text-xs font-black uppercase text-white tracking-[0.2em]"
                    >
                        Academy Roster
                    </h3>
                </div>

                <div class="space-y-4">
                    {#if youthAcademyStore.selectedDrivers.length === 0}
                        <div
                            class="p-8 bg-app-surface border border-app-border border-dashed rounded-3xl text-center text-app-text/20"
                        >
                            <p
                                class="text-[10px] font-black uppercase tracking-widest leading-relaxed"
                            >
                                Your roster is empty.<br />Sign prospects from
                                the scouting report.
                            </p>
                        </div>
                    {:else}
                        {#each youthAcademyStore.selectedDrivers as driver}
                            <div
                                class="bg-app-surface border border-app-border rounded-2xl p-4 group relative overflow-hidden"
                            >
                                <div class="flex items-center gap-4 mb-4">
                                    <div
                                        class="w-10 h-10 rounded-full bg-app-text/5 flex items-center justify-center text-app-text/40"
                                    >
                                        <User size={20} />
                                    </div>
                                    <div class="flex-grow">
                                        <h4
                                            class="text-xs font-black text-white uppercase"
                                        >
                                            {driver.name}
                                        </h4>
                                        <div
                                            class="flex items-center gap-1.5 mt-0.5"
                                        >
                                            <div class="flex gap-0.5">
                                                {#each Array(5) as _, i}
                                                    <div
                                                        class="w-1.5 h-1.5 rounded-full {i <
                                                        Math.floor(
                                                            ((driver.baseSkill ??
                                                                0) +
                                                                (driver.growthPotential ??
                                                                    0)) /
                                                                20,
                                                        )
                                                            ? 'bg-app-primary'
                                                            : 'bg-app-text/10'}"
                                                    ></div>
                                                {/each}
                                            </div>
                                            <span
                                                class="text-[9px] font-black text-app-text/40 uppercase"
                                                >Dev. Profile</span
                                            >
                                        </div>
                                    </div>
                                    <button
                                        onclick={() =>
                                            youthAcademyStore.togglePromotion(
                                                driver.id,
                                                !driver.isMarkedForPromotion,
                                            )}
                                        class="p-2 rounded-lg transition-all {driver.isMarkedForPromotion
                                            ? 'bg-emerald-500 text-black'
                                            : 'bg-app-text/5 text-app-text/30 hover:text-app-primary'}"
                                        title={driver.isMarkedForPromotion
                                            ? "Marked for Promotion"
                                            : "Mark for Promotion"}
                                    >
                                        <TrendingUp size={16} />
                                    </button>
                                </div>

                                <div
                                    class="flex items-center justify-between pt-3 border-t border-app-border/30"
                                >
                                    <span
                                        class="text-[9px] font-black text-app-text/30 uppercase tracking-widest"
                                        >Growth Potential</span
                                    >
                                    <span
                                        class="text-[10px] font-black text-app-primary"
                                        >+{driver.growthPotential ?? 0}%</span
                                    >
                                </div>

                                <button
                                    onclick={() =>
                                        youthAcademyStore.releaseDriver(
                                            driver.id,
                                        )}
                                    class="absolute top-2 right-2 opacity-0 group-hover:opacity-100 p-1.5 text-app-text/20 hover:text-red-400 transition-all"
                                >
                                    <XCircle size={14} />
                                </button>
                            </div>
                        {/each}
                    {/if}

                    <!-- Promotion Info -->
                    {#if youthAcademyStore.selectedDrivers.some((d) => d.isMarkedForPromotion)}
                        <div
                            class="p-4 bg-emerald-500/5 border border-emerald-500/20 rounded-2xl flex gap-3"
                        >
                            <AlertTriangle
                                size={16}
                                class="text-emerald-500 shrink-0 mt-0.5"
                            />
                            <p
                                class="text-[10px] font-medium text-emerald-500/80 leading-relaxed"
                            >
                                A driver is marked for promotion. They will join
                                the main team at the start of next season.
                            </p>
                        </div>
                    {/if}
                </div>
            </div>
        </div>
    {/if}
</div>

<style>
    .animate-spin {
        animation: spin 1s linear infinite;
    }
    @keyframes spin {
        from {
            transform: rotate(0deg);
        }
        to {
            transform: rotate(360deg);
        }
    }
</style>
