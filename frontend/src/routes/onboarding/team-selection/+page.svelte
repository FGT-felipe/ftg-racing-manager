<script lang="ts">
    import { onMount } from "svelte";
    import { db } from "$lib/firebase/config";
    import { collection, onSnapshot, query, where } from "firebase/firestore";
    import { universeStore } from "$lib/stores/universe.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { authStore } from "$lib/stores/auth.svelte";
    import { goto } from "$app/navigation";
    import {
        Trophy,
        Users,
        CircleDollarSign,
        Lock,
        CheckCircle2,
        ChevronRight,
        Briefcase,
    } from "lucide-svelte";
    import { fly, fade } from "svelte/transition";

    let liveTeams = $state<any[]>([]);
    let liveDrivers = $state<any[]>([]);
    let isLoading = $state(true);
    let isSubmitting = $state(false);
    let error = $state<string | null>(null);

    // Get leagues from universe store
    let leagues = $derived(universeStore.value.universe?.leagues || []);

    // Map live status to league teams
    let leaguesWithLiveTeams = $derived(
        leagues.map((league) => ({
            ...league,
            teams: (league.teams || []).map((t: any) => {
                const liveTeam = liveTeams.find((lt) => lt.id === t.id);
                const teamDrivers = liveDrivers.filter(
                    (d) => d.teamId === t.id,
                );
                return {
                    ...t,
                    ...liveTeam, // Override with live Firestore data (budget, isBot, managerId)
                    isBot: liveTeam ? liveTeam.isBot : true,
                    drivers:
                        teamDrivers.length > 0 ? teamDrivers : t.drivers || [],
                };
            }),
        })),
    );

    let worldLeague = $derived(
        leaguesWithLiveTeams.find((l) => l.id === "ftg_world"),
    );
    let secondLeague = $derived(
        leaguesWithLiveTeams.find((l) => l.id === "ftg_2th"),
    );

    let isWorldFull = $derived(
        worldLeague?.teams.length > 0 &&
            worldLeague.teams.every((t: any) => !t.isBot),
    );

    onMount(() => {
        // Initialize stores
        universeStore.init();

        // Listen to teams
        const unsubscribeTeams = onSnapshot(
            collection(db, "teams"),
            (snapshot) => {
                liveTeams = snapshot.docs.map((doc) => ({
                    id: doc.id,
                    ...doc.data(),
                }));
            },
            (err) => (error = err.message),
        );

        // Listen to drivers
        const unsubscribeDrivers = onSnapshot(
            collection(db, "drivers"),
            (snapshot) => {
                liveDrivers = snapshot.docs.map((doc) => ({
                    id: doc.id,
                    ...doc.data(),
                }));
            },
            (err) => (error = err.message),
        );

        return () => {
            unsubscribeTeams();
            unsubscribeDrivers();
        };
    });

    // Also watch universeStore loading
    $effect(() => {
        // We consider it loaded when universe is not loading AND we have some teams
        if (!universeStore.value.loading && liveTeams.length > 0) {
            isLoading = false;
        }
    });

    async function handleSelectTeam(teamId: string) {
        if (isSubmitting) return;

        isSubmitting = true;
        try {
            await teamStore.claimTeam(teamId);
            goto("/");
        } catch (err: any) {
            console.error("Error claiming team:", err);
            error = err.message;
        } finally {
            isSubmitting = false;
        }
    }

    function formatBudget(budget: number) {
        return `$${(budget / 1000000).toFixed(0)}M`;
    }

    function getFlagEmoji(countryCode: string) {
        if (!countryCode) return "🏳️";
        const code = countryCode.toUpperCase();
        const flags: Record<string, string> = {
            BR: "🇧🇷",
            BRAZIL: "🇧🇷",
            AR: "🇦🇷",
            ARGENTINA: "🇦🇷",
            CO: "🇨🇴",
            COLOMBIA: "🇨🇴",
            MX: "🇲🇽",
            MEXICO: "🇲🇽",
            UY: "🇺🇾",
            URUGUAY: "🇺🇾",
            CL: "🇨🇱",
            CHILE: "🇨🇱",
            GB: "🇬🇧",
            UK: "🇬🇧",
            DE: "🇩🇪",
            GERMANY: "🇩🇪",
            IT: "🇮🇹",
            ITALY: "🇮🇹",
            ES: "🇪🇸",
            SPAIN: "🇪🇸",
            FR: "🇫🇷",
            FRANCE: "🇫🇷",
            US: "🇺🇸",
            USA: "🇺🇸",
            MC: "🇲🇨",
            MONACO: "🇲🇨",
            NL: "🇳🇱",
            NETHERLANDS: "🇳🇱",
        };
        return flags[code] || "🏳️";
    }
</script>

<div class="min-h-screen bg-[#0A0A0B] text-white p-6 md:p-12 overflow-x-hidden">
    <div class="max-w-7xl mx-auto flex flex-col gap-12">
        <!-- Header -->
        <header
            class="flex flex-col gap-4 text-center md:text-left"
            in:fly={{ y: -20, duration: 600 }}
        >
            <div
                class="flex items-center justify-center md:justify-start gap-4 text-app-primary"
            >
                <Briefcase size={32} />
                <span class="text-xs font-black uppercase tracking-[0.4em]"
                    >Team Selection Hub</span
                >
            </div>
            <h1
                class="text-5xl md:text-7xl font-heading font-black tracking-tighter uppercase italic leading-none"
            >
                Select Your <span class="text-app-primary">Command</span>
            </h1>
            <p
                class="text-white/40 font-bold uppercase tracking-widest text-xs max-w-2xl"
            >
                Choose an available team to begin your management career.
                High-tier leagues offer more prestige but demand immediate
                results.
            </p>
        </header>

        {#if isLoading}
            <div class="flex flex-col items-center justify-center py-32 gap-4">
                <div
                    class="w-12 h-12 border-4 border-app-primary border-t-transparent rounded-full animate-spin"
                ></div>
                <span
                    class="text-[10px] font-black tracking-[0.3em] text-app-primary uppercase"
                    >Analyzing Market Vacancies...</span
                >
            </div>
        {:else}
            <!-- World Championship -->
            <section class="flex flex-col gap-8">
                <div class="flex items-center gap-4">
                    <Trophy size={24} class="text-app-primary" />
                    <h2
                        class="text-2xl font-heading font-black uppercase italic tracking-tight"
                    >
                        {worldLeague?.name || "World Championship"}
                    </h2>
                    <div class="h-px flex-1 bg-white/5"></div>
                </div>

                <div
                    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
                >
                    {#each worldLeague?.teams || [] as team}
                        <div
                            class="relative group"
                            in:fly={{ y: 20, duration: 600 }}
                        >
                            <div
                                class="p-8 bg-white/5 border border-white/10 rounded-[40px] flex flex-col gap-6 transition-all duration-300 group-hover:border-app-primary/50 group-hover:bg-app-primary/5"
                            >
                                <div class="flex justify-between items-start">
                                    <h3
                                        class="font-heading font-black text-2xl uppercase italic tracking-tighter leading-none group-hover:text-app-primary transition-colors"
                                    >
                                        {team.name}
                                    </h3>
                                    {#if !team.isBot}
                                        <div
                                            class="bg-white/5 px-3 py-1 rounded-full border border-white/10 text-[10px] font-black uppercase tracking-widest text-white/30"
                                        >
                                            Occupied
                                        </div>
                                    {/if}
                                </div>

                                <!-- Drivers -->
                                <div class="flex flex-col gap-2">
                                    {#each team.drivers || [] as driver}
                                        <div class="flex items-center gap-2">
                                            <span class="text-sm"
                                                >{getFlagEmoji(
                                                    driver.countryCode,
                                                )}</span
                                            >
                                            <span
                                                class="text-[11px] font-bold text-white/60 uppercase tracking-widest"
                                                >{driver.name}</span
                                            >
                                        </div>
                                    {/each}
                                </div>

                                <div class="flex items-center gap-4">
                                    <div class="flex-1 h-px bg-white/5"></div>
                                    <CircleDollarSign
                                        size={20}
                                        class="text-white/20"
                                    />
                                    <div class="flex-1 h-px bg-white/5"></div>
                                </div>

                                <div class="grid grid-cols-2 gap-4">
                                    <div class="flex flex-col">
                                        <span
                                            class="text-[10px] font-black text-white/20 uppercase tracking-widest"
                                            >Budget</span
                                        >
                                        <span
                                            class="text-lg font-heading font-black italic"
                                            >{formatBudget(team.budget)}</span
                                        >
                                    </div>
                                    <div class="flex flex-col items-end">
                                        <span
                                            class="text-[10px] font-black text-white/20 uppercase tracking-widest"
                                            >Points</span
                                        >
                                        <span
                                            class="text-lg font-heading font-black italic"
                                            >{team.seasonPoints || 0}</span
                                        >
                                    </div>
                                </div>

                                {#if team.isBot}
                                    <button
                                        onclick={() =>
                                            handleSelectTeam(team.id)}
                                        disabled={isSubmitting}
                                        class="w-full py-4 bg-app-primary rounded-2xl flex items-center justify-center gap-3 group/btn overflow-hidden relative"
                                    >
                                        <span
                                            class="font-heading font-black text-xs text-black uppercase tracking-widest italic z-10 transition-transform group-hover/btn:scale-110"
                                            >Sign Contract</span
                                        >
                                        <ChevronRight
                                            size={16}
                                            class="text-black z-10 group-hover/btn:translate-x-1 transition-transform"
                                        />
                                    </button>
                                {:else}
                                    <div
                                        class="w-full py-4 bg-white/5 border border-white/5 rounded-2xl flex items-center justify-center gap-3 grayscale opacity-30 cursor-not-allowed"
                                    >
                                        <Lock size={16} class="text-white" />
                                        <span
                                            class="font-heading font-black text-xs text-white uppercase tracking-widest italic"
                                            >Position Taken</span
                                        >
                                    </div>
                                {/if}
                            </div>
                        </div>
                    {/each}
                </div>
            </section>

            <!-- Second Series -->
            <section
                class="flex flex-col gap-8 mt-12 {isWorldFull
                    ? ''
                    : 'opacity-60'}"
            >
                <div class="flex items-center gap-4">
                    <Users size={24} class="text-white/40" />
                    <h2
                        class="text-2xl font-heading font-black uppercase italic tracking-tight text-white/40"
                    >
                        {secondLeague?.name || "Division 2"}
                    </h2>
                    {#if !isWorldFull}
                        <div
                            class="flex items-center gap-2 px-3 py-1 bg-amber-500/10 border border-amber-500/20 rounded-full"
                        >
                            <Lock size={12} class="text-amber-500" />
                            <span
                                class="text-[9px] font-black uppercase tracking-widest text-amber-500"
                                >Locked until Tier 1 Full</span
                            >
                        </div>
                    {/if}
                    <div class="h-px flex-1 bg-white/5"></div>
                </div>

                <div
                    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
                >
                    {#each secondLeague?.teams || [] as team}
                        <div
                            class="relative group {isWorldFull
                                ? ''
                                : 'opacity-40'}"
                        >
                            <div
                                class="p-8 bg-white/5 border border-white/10 rounded-[40px] flex flex-col gap-6"
                            >
                                <div class="flex justify-between items-start">
                                    <h3
                                        class="font-heading font-black text-2xl uppercase italic tracking-tighter leading-none text-white/40"
                                    >
                                        {team.name}
                                    </h3>
                                    {#if !team.isBot}
                                        <div
                                            class="bg-white/5 px-3 py-1 rounded-full border border-white/10 text-[10px] font-black uppercase tracking-widest text-white/30"
                                        >
                                            Occupied
                                        </div>
                                    {/if}
                                </div>

                                <!-- Drivers -->
                                <div class="flex flex-col gap-2">
                                    {#each team.drivers || [] as driver}
                                        <div
                                            class="flex items-center gap-2 opacity-30"
                                        >
                                            <span class="text-sm"
                                                >{getFlagEmoji(
                                                    driver.countryCode,
                                                )}</span
                                            >
                                            <span
                                                class="text-[11px] font-bold text-white uppercase tracking-widest"
                                                >{driver.name}</span
                                            >
                                        </div>
                                    {/each}
                                </div>

                                {#if isWorldFull && team.isBot}
                                    <button
                                        onclick={() =>
                                            handleSelectTeam(team.id)}
                                        disabled={isSubmitting}
                                        class="w-full py-4 bg-app-primary rounded-2xl flex items-center justify-center gap-3 group/btn overflow-hidden relative"
                                    >
                                        <span
                                            class="font-heading font-black text-xs text-black uppercase tracking-widest italic"
                                            >Sign Contract</span
                                        >
                                    </button>
                                {:else}
                                    <div
                                        class="flex-1 py-4 flex flex-col items-center justify-center gap-2 border border-white/5 rounded-2xl"
                                    >
                                        <Lock size={16} class="text-white/20" />
                                        <span
                                            class="text-[8px] font-black text-white/20 uppercase tracking-widest"
                                            >{team.isBot
                                                ? "Division Restricted"
                                                : "Position Taken"}</span
                                        >
                                    </div>
                                {/if}
                            </div>
                        </div>
                    {/each}
                </div>
            </section>
        {/if}
    </div>
</div>

{#if isSubmitting}
    <div
        class="fixed inset-0 bg-black/80 backdrop-blur-xl z-[100] flex items-center justify-center"
        transition:fade
    >
        <div class="flex flex-col items-center gap-6" in:fly={{ y: 20 }}>
            <div class="relative">
                <div
                    class="w-24 h-24 border-4 border-app-primary/20 rounded-full"
                ></div>
                <div
                    class="absolute inset-0 w-24 h-24 border-4 border-app-primary border-t-transparent rounded-full animate-spin"
                ></div>
            </div>
            <div class="flex flex-col items-center gap-2">
                <h3
                    class="font-heading font-black text-3xl uppercase italic tracking-tighter text-app-primary"
                >
                    Negotiating Terms
                </h3>
                <p
                    class="text-white/40 font-bold uppercase tracking-widest text-[10px]"
                >
                    Please wait while we finalize your contract...
                </p>
            </div>
        </div>
    </div>
{/if}

<style>
    /* Custom refined scrollbar for the page */
    :global(body) {
        scrollbar-width: thin;
        scrollbar-color: #c5a059 #0a0a0b;
    }
</style>
