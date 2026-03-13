<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import {
        sponsorService,
        NegotiationStatus,
    } from "$lib/services/sponsor.svelte";
    import {
        ChevronLeft,
        Handshake,
        CircleCheck,
        Trophy,
        Zap,
        Clock,
        Info,
        Lock,
        ArrowRight,
    } from "lucide-svelte";
    import { fly, fade } from "svelte/transition";
    import { t } from "$lib/utils/i18n";
    import {
        SponsorSlot,
        type SponsorOffer,
        type ActiveContract,
    } from "$lib/types";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";

    let team = $derived(teamStore.value.team);
    let manager = $derived(managerStore.profile);
    let isLoading = $derived(teamStore.value.loading || managerStore.isLoading);

    let selectedSlot = $state<SponsorSlot | null>(null);
    let offers = $derived(
        selectedSlot && manager
            ? sponsorService.getAvailableSponsors(
                  selectedSlot,
                  manager.role,
                  team?.weekStatus?.sponsorNegotiations || {},
                  team?.sponsors || {}
              )
            : [],
    );

    let isNegotiatingId = $state<string | null>(null);

    const slotConfigs = [
        {
            slot: SponsorSlot.rearWing,
            label: "Rear Wing",
            img: "/rearwing.png",
            color: "text-orange-400",
        },
        {
            slot: SponsorSlot.sidepods,
            label: "Sidepods",
            img: "/sidepot.png",
            color: "text-blue-400",
        },
        {
            slot: SponsorSlot.halo,
            label: "Halo",
            img: "/halo.png",
            color: "text-slate-400",
        },
        {
            slot: SponsorSlot.frontWing,
            label: "Front Wing",
            img: "/frontwing.png",
            color: "text-app-primary",
        },
        {
            slot: SponsorSlot.nose,
            label: "Nose",
            img: "/nose.png",
            color: "text-app-primary",
        },
    ];

    async function handleNegotiate(offer: SponsorOffer, tactic: string) {
        if (!team || !selectedSlot) return;
        isNegotiatingId = offer.id;
        try {
            const result = await sponsorService.negotiate({
                teamId: team.id,
                offer,
                tactic,
                slot: selectedSlot,
            });
            // Result handling (notifications are handled in service)
        } finally {
            isNegotiatingId = null;
        }
    }

    const fallbackObjectives: Record<string, string> = {
        'titans_oil': "Finish Top 3",
        'global_tech': "Both in Points",
        'zenith_sky': "Race Win",
        'fast_logistics': "Finish Top 10",
        'spark_energy': "Fastest Lap",
        'eco_pulse': "Finish Race",
        'local_drinks': "Finish Race",
        'micro_chips': "Improve Grid",
        'nitro_gear': "Overtake 3 Cars"
    };

    const fallbackBonuses: Record<string, number> = {
        'titans_oil': 250000,
        'global_tech': 200000,
        'zenith_sky': 300000,
        'fast_logistics': 100000,
        'spark_energy': 120000,
        'eco_pulse': 80000,
        'local_drinks': 30000,
        'micro_chips': 40000,
        'nitro_gear': 35000
    };

    function translateObjective(desc: string | undefined | null, sponsorId?: string) {
        if (!desc && sponsorId) desc = fallbackObjectives[sponsorId];
        if (!desc) return "";
        const mapping: Record<string, any> = {
            "Finish Top 3": "finish_top_3",
            "Both in Points": "both_in_points",
            "Race Win": "race_win",
            "Finish Top 10": "finish_top_10",
            "Fastest Lap": "fastest_lap",
            "Finish Race": "finish_race",
            "Improve Grid": "improve_grid",
            "Overtake 3 Cars": "overtake_3_cars",
            "Pole Position": "pole_position"
        };
        const key = mapping[desc] || desc;
        return t(key as any);
    }

    function formatCurrency(amount: number | undefined | null) {
        if (amount === undefined || amount === null || isNaN(amount)) return "$0";
        return new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: "USD",
            maximumFractionDigits: 0,
        }).format(amount);
    }
</script>

<svelte:head>
    <title>Sponsorships | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-6 md:p-10 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text min-h-screen"
>
    <!-- Breadcrumbs -->
    <nav
        class="flex items-center gap-2 mb-8 opacity-40 hover:opacity-100 transition-opacity"
    >
        <a
            href="/management"
            class="flex items-center gap-1 text-[10px] font-black uppercase tracking-widest"
        >
            <ChevronLeft size={14} /> Management
        </a>
    </nav>

    {#if isLoading}
        <div class="flex items-center justify-center h-64">
            <div
                class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"
            ></div>
        </div>
    {:else if team}
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 items-start">
            <!-- Left Grid: Car Blueprint Visualization (4 cols) -->
            <div class="lg:col-span-4 flex flex-col gap-8">
                <header class="flex flex-col gap-2">
                    <h1
                        class="text-3xl font-heading font-black tracking-tighter uppercase italic text-app-text"
                    >
                        Sponsorship <span class="text-app-primary">Slots</span>
                    </h1>
                    <p
                        class="text-xs font-bold text-app-text/30 uppercase tracking-[0.2em]"
                    >
                        Select a part to manage contracts
                    </p>
                </header>

                <div class="flex flex-col gap-3">
                    {#each slotConfigs as cfg}
                        {@const contract = team.sponsors[cfg.slot]}
                        <button
                            onclick={() => (selectedSlot = cfg.slot)}
                            class="relative flex items-center justify-between p-6 bg-app-surface border transition-all duration-300 rounded-2xl group overflow-hidden
                            {selectedSlot === cfg.slot
                                ? 'border-app-primary bg-app-primary/5 shadow-[0_0_20px_rgba(197,160,89,0.1)]'
                                : 'border-app-border hover:border-app-border'}"
                        >
                            <!-- Silhouette BG -->
                            <img
                                src={cfg.img}
                                alt=""
                                class="absolute left-0 top-0 h-full opacity-10 grayscale group-hover:scale-110 transition-transform pointer-events-none"
                            />

                            <div
                                class="relative flex flex-col items-start gap-1"
                            >
                                <span
                                    class="text-[9px] font-black uppercase tracking-[0.25em] {contract
                                        ? cfg.color
                                        : 'text-app-text/20'}"
                                >
                                    {cfg.label}
                                </span>
                                <h4
                                    class="text-sm font-black text-app-text uppercase tracking-tight"
                                >
                                    {contract
                                        ? contract.sponsorName
                                        : "Unsold Inventory"}
                                </h4>
                            </div>

                            {#if contract}
                                <div
                                    class="relative flex flex-col items-end gap-1"
                                >
                                    <span
                                        class="text-[10px] font-black text-green-400 italic"
                                        >{formatCurrency(
                                            contract.weeklyBasePayment,
                                        )}/WK</span
                                    >
                                    <span
                                        class="text-[8px] font-bold text-app-text/30 uppercase tracking-widest"
                                        >{contract.racesRemaining} Races Left</span
                                    >
                                </div>
                            {:else}
                                <div
                                    class="relative px-3 py-1 bg-app-text/5 rounded-full border border-app-border group-hover:bg-app-primary group-hover:border-app-primary transition-colors"
                                >
                                    <span
                                        class="text-[8px] font-black text-app-text/40 group-hover:text-black uppercase tracking-widest"
                                        >Manage</span
                                    >
                                </div>
                            {/if}
                        </button>
                    {/each}
                </div>

                <!-- Info Card -->
                <div
                    class="bg-blue-400/5 border border-blue-400/20 rounded-2xl p-6 flex flex-col gap-3"
                >
                    <div class="flex items-center gap-2 text-blue-400">
                        <Info size={16} />
                        <span
                            class="text-[10px] font-black uppercase tracking-widest"
                            >Negotiation Rules</span
                        >
                    </div>
                    <p
                        class="text-[11px] font-medium text-app-text/60 leading-relaxed"
                    >
                        Each sponsor has a unique personality. Choose the
                        negotiation tactic that best aligns with their style to
                        maximize success. You have 2 attempts before they walk
                        away.
                    </p>
                </div>
            </div>

            <!-- Right Grid: Active or Offers (8 cols) -->
            <div class="lg:col-span-8">
                {#if !selectedSlot}
                    <div
                        class="flex flex-col items-center justify-center h-full min-h-[500px] border border-app-border border-dashed rounded-[40px] opacity-20 text-center gap-6"
                    >
                        <Handshake size={64} strokeWidth={1} />
                        <p
                            class="text-[10px] font-black uppercase tracking-[0.3em]"
                        >
                            Select a car component to view offers
                        </p>
                    </div>
                {:else}
                    {@const activeContract = team.sponsors[selectedSlot]}
                    <div
                        in:fade={{ duration: 300 }}
                        class="flex flex-col gap-10"
                    >
                        {#if activeContract}
                            <!-- Active Contract Details -->
                            <section class="flex flex-col gap-6">
                                <h3
                                    class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2"
                                >
                                    Active Partnership
                                </h3>
                                <div
                                    class="bg-app-surface border border-app-primary/30 rounded-[40px] p-12 relative overflow-hidden shadow-2xl"
                                >
                                    <div
                                        class="absolute -right-20 -top-20 w-80 h-80 bg-app-primary/10 blur-[100px] rounded-full"
                                    ></div>

                                    <div
                                        class="relative flex flex-col items-center text-center gap-6"
                                    >
                                        <div
                                            class="w-20 h-20 bg-app-primary/10 rounded-3xl flex items-center justify-center text-app-primary"
                                        >
                                            <CircleCheck size={40} />
                                        </div>
                                        <div class="flex flex-col gap-2">
                                            <h2
                                                class="text-5xl font-heading font-black tracking-tighter text-app-text flex items-center justify-center gap-4"
                                            >
                                                <CountryFlag countryCode={activeContract.countryCode} size="xl" />
                                                <span class="uppercase italic">{activeContract.sponsorName}</span>
                                            </h2>
                                            <span
                                                class="text-xs font-bold text-app-primary/60 uppercase tracking-[0.3em]"
                                                >Contract Secure</span
                                            >
                                        </div>

                                        <div
                                            class="grid grid-cols-2 gap-12 mt-4"
                                        >
                                            <div class="flex flex-col gap-1">
                                                <span
                                                    class="text-[9px] font-black text-app-text/30 uppercase tracking-widest"
                                                    >Weekly Income</span
                                                >
                                                <span
                                                    class="text-3xl font-black text-app-text italic"
                                                    >{formatCurrency(
                                                        activeContract.weeklyBasePayment,
                                                    )}</span
                                                >
                                            </div>
                                            <div class="flex flex-col gap-1">
                                                <span
                                                    class="text-[9px] font-black text-app-text/30 uppercase tracking-widest"
                                                    >Term Remaining</span
                                                >
                                                <span
                                                    class="text-3xl font-black text-app-text italic"
                                                    >{activeContract.racesRemaining}
                                                    Races</span
                                                >
                                            </div>
                                        </div>

                                        <div class="mt-12 flex flex-col items-center gap-3 w-full">
                                            <span class="text-[9px] font-black text-app-text/20 uppercase tracking-[0.2em]">Performance Objective</span>
                                            <div class="flex flex-col md:flex-row items-center gap-4 px-8 py-4 bg-app-primary/5 border border-app-primary/20 rounded-3xl w-full justify-center">
                                                <div class="flex items-center gap-3">
                                                    <Trophy size={18} class="text-app-primary" />
                                                    <span class="text-lg font-black italic text-app-text uppercase tracking-tight">
                                                        {translateObjective(activeContract.objectiveDescription, activeContract.sponsorId)}
                                                    </span>
                                                </div>
                                                <div class="hidden md:block w-1 h-4 bg-app-primary/20 rounded-full"></div>
                                                <div class="flex items-center gap-2">
                                                    <div class="w-2 h-2 rounded-full bg-app-primary animate-pulse"></div>
                                                    <span class="text-sm font-black text-app-primary italic">{formatCurrency(activeContract.objectiveBonus || fallbackBonuses[activeContract.sponsorId] || 0)} BONUS</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </section>
                        {:else}
                            <!-- Available Offers -->
                            <section class="flex flex-col gap-6">
                                <h3
                                    class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2"
                                >
                                    Available Offers
                                </h3>
                                <div class="grid grid-cols-1 gap-4">
                                    {#each offers as offer (offer.id)}
                                        <div
                                            class="bg-app-surface border border-app-border rounded-3xl p-8 flex flex-col md:flex-row justify-between gap-8 group hover:border-app-border transition-all relative overflow-hidden"
                                        >
                                            {#if offer.lockedUntil && new Date(offer.lockedUntil) > new Date()}
                                                <div
                                                    class="absolute inset-0 bg-app-text/60 backdrop-blur-sm z-10 flex flex-col items-center justify-center gap-3"
                                                >
                                                    <Lock
                                                        size={24}
                                                        class="text-red-400"
                                                    />
                                                    <p
                                                        class="text-[10px] font-black uppercase tracking-widest text-red-100"
                                                    >
                                                        Sponsor reconsidering
                                                        until {new Date(
                                                            offer.lockedUntil,
                                                        ).toLocaleDateString()}
                                                    </p>
                                                </div>
                                            {/if}

                                            <div
                                                class="flex flex-col gap-6 flex-1"
                                            >
                                                <div
                                                    class="flex flex-col gap-2"
                                                >
                                                    <div
                                                        class="flex items-center gap-3"
                                                    >
                                                        <CountryFlag countryCode={offer.countryCode} size="lg" />
                                                        <h4
                                                            class="text-2xl font-black text-app-text uppercase tracking-tight italic"
                                                        >
                                                            {offer.name}
                                                        </h4>
                                                        {#if offer.isAdminBonusApplied}
                                                            <span
                                                                class="px-2 py-0.5 bg-green-400/10 border border-green-400/20 text-green-400 text-[9px] font-black rounded-full"
                                                                >+15% BONUS</span
                                                            >
                                                        {/if}
                                                    </div>
                                                    <div
                                                        class="flex items-center gap-4 text-[10px] font-bold text-app-text/30 uppercase tracking-[0.15em]"
                                                    >
                                                        <div
                                                            class="flex items-center gap-1.5"
                                                        >
                                                            <Clock size={12} />
                                                            {offer.contractDuration}
                                                            Races
                                                        </div>
                                                        <div
                                                            class="flex items-center gap-1.5"
                                                        >
                                                            <Zap size={12} />
                                                            {offer.personality} Style
                                                        </div>
                                                    </div>
                                                </div>

                                                <div
                                                    class="grid grid-cols-2 md:grid-cols-3 gap-6"
                                                >
                                                    <div
                                                        class="flex flex-col gap-1"
                                                    >
                                                        <span
                                                            class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                                                            >Signing Bonus</span
                                                        >
                                                        <span
                                                            class="text-lg font-black text-green-400 italic"
                                                            >{formatCurrency(
                                                                offer.signingBonus,
                                                            )}</span
                                                        >
                                                    </div>
                                                    <div
                                                        class="flex flex-col gap-1"
                                                    >
                                                        <span
                                                            class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                                                            >Weekly</span
                                                        >
                                                        <span
                                                            class="text-lg font-black text-app-text italic"
                                                            >{formatCurrency(
                                                                offer.weeklyBasePayment,
                                                            )}</span
                                                        >
                                                    </div>
                                                    <div
                                                        class="flex flex-col gap-1 col-span-2 md:col-span-1"
                                                    >
                                                        <span
                                                            class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                                                            >Incentive: {offer.objectiveDescription}</span
                                                        >
                                                        <span
                                                            class="text-lg font-black text-app-primary italic"
                                                            >{formatCurrency(
                                                                offer.objectiveBonus,
                                                            )}</span
                                                        >
                                                    </div>
                                                </div>
                                            </div>

                                            <div
                                                class="flex flex-col justify-center gap-4 min-w-[200px] border-t md:border-t-0 md:border-l border-app-border pt-6 md:pt-0 md:pl-8"
                                            >
                                                {#if isNegotiatingId === offer.id}
                                                    <div
                                                        class="flex items-center justify-center h-20"
                                                    >
                                                        <div
                                                            class="w-6 h-6 border-2 border-app-primary border-t-transparent rounded-full animate-spin"
                                                        ></div>
                                                    </div>
                                                {:else}
                                                    <span
                                                        class="text-[9px] font-black text-app-text/20 uppercase tracking-[0.2em] text-center"
                                                        >Select Tactic (Attempt {offer.attemptsMade +
                                                            1}/2)</span
                                                    >
                                                    <div
                                                        class="grid grid-cols-1 gap-2"
                                                    >
                                                        <button
                                                            onclick={() =>
                                                                handleNegotiate(
                                                                    offer,
                                                                    "persuasive",
                                                                )}
                                                            class="py-2 px-4 rounded-xl border border-app-border text-[9px] font-black uppercase tracking-widest hover:bg-orange-400/10 hover:border-orange-400/50 hover:text-orange-400 transition-all flex items-center justify-between"
                                                        >
                                                            Persuasive <ArrowRight
                                                                size={12}
                                                            />
                                                        </button>
                                                        <button
                                                            onclick={() =>
                                                                handleNegotiate(
                                                                    offer,
                                                                    "negotiator",
                                                                )}
                                                            class="py-2 px-4 rounded-xl border border-app-border text-[9px] font-black uppercase tracking-widest hover:bg-app-primary/10 hover:border-app-primary border-app-primary/50 hover:text-app-primary transition-all flex items-center justify-between"
                                                        >
                                                            Negotiator <ArrowRight
                                                                size={12}
                                                            />
                                                        </button>
                                                        <button
                                                            onclick={() =>
                                                                handleNegotiate(
                                                                    offer,
                                                                    "collaborative",
                                                                )}
                                                            class="py-2 px-4 rounded-xl border border-app-border text-[9px] font-black uppercase tracking-widest hover:bg-blue-400/10 hover:border-blue-400/50 hover:text-blue-400 transition-all flex items-center justify-between"
                                                        >
                                                            Collaborative <ArrowRight
                                                                size={12}
                                                            />
                                                        </button>
                                                    </div>
                                                {/if}
                                            </div>
                                        </div>
                                    {:else}
                                        <div
                                            class="bg-app-surface border border-app-border border-dashed rounded-[40px] p-20 flex flex-col items-center justify-center opacity-20 text-center gap-6"
                                        >
                                            <Handshake
                                                size={64}
                                                strokeWidth={1}
                                            />
                                            <p
                                                class="text-[10px] font-black uppercase tracking-[0.3em]"
                                            >
                                                No offers currently available
                                                for this slot
                                            </p>
                                        </div>
                                    {/each}
                                </div>
                            </section>
                        {/if}
                    </div>
                {/if}
            </div>
        </div>
    {/if}
</div>

<style>
    /* Custom styles if any */
</style>
