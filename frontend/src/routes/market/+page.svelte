<script lang="ts">
    import { Users, Gavel, X, ChevronLeft, ChevronRight, Lock, Minus, Plus, CheckCircle } from "lucide-svelte";
    import { fly, fade } from "svelte/transition";
    import { teamStore } from "$lib/stores/team.svelte";
    import { formatDriverName } from "$lib/utils/driver";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
    import { onDestroy, onMount } from "svelte";

    // ─── Types ────────────────────────────────────────────────────────────────────
    interface MarketDriver {
        id: string;
        name: string;
        age: number;
        gender?: string;
        countryCode?: string;
        role?: string;
        currentStars: number;
        potential: number;
        salary: number;
        contractYearsRemaining: number;
        marketValue: number;
        currentHighestBid: number;
        highestBidderTeamId?: string;
        teamId?: string;
        transferListedAt?: any;
        isTransferListed?: boolean;
        stats?: Record<string, number>;
    }

    // ─── State ────────────────────────────────────────────────────────────────────
    const PAGE_SIZE = 15;
    // Firestore is loaded lazily in onMount to prevent SSR crash
    let firestoreApi: any = null;
    let db: any = null;

    let myTeamId = $derived(teamStore.value.team?.id ?? null);
    let myBudget = $derived(teamStore.value.team?.budget ?? 0);
    let isMarketOpen = $state(true);
    let loading = $state(true);
    let drivers = $state<MarketDriver[]>([]);
    let currentPage = $state(0);
    let pageHistory = $state<any[]>([null]);
    let hasNextPage = $derived(drivers.length === PAGE_SIZE);
    let cancellingBidIds = $state<Set<string>>(new Set());

    // Modal state
    let selectedDriver = $state<MarketDriver | null>(null);
    let showDetail = $state(false);
    let showBidModal = $state(false);
    let bidAmount = $state(0);
    let bidLoading = $state(false);
    let bidError = $state("");
    let bidSuccess = $state(false);

    // Countdown timers
    let countdownMap = $state<Record<string, string>>({});
    let activeDrivers = $derived(drivers.filter(d => countdownMap[d.id] !== "Expired"));
    let timerInterval: ReturnType<typeof setInterval> | null = null;

    // ─── Helpers ─────────────────────────────────────────────────────────────────
    function formatCurrency(value: number): string {
        if (!value) return "$0";
        if (value >= 1_000_000) return `$${(value / 1_000_000).toFixed(1)}M`;
        if (value >= 1_000) return `$${(value / 1_000).toFixed(0)}K`;
        return `$${value}`;
    }

    function getLevelInfo(stars: number) {
        if (stars >= 5) return { label: "Elite", color: "text-yellow-500 border-yellow-500/40" };
        if (stars >= 4) return { label: "Pro", color: "text-blue-400 border-blue-400/40" };
        if (stars >= 3) return { label: "Veteran", color: "text-green-400 border-green-400/40" };
        if (stars >= 2) return { label: "Talent", color: "text-orange-400 border-orange-400/40" };
        return { label: "Rookie", color: "text-app-text/40 border-app-border" };
    }

    function getStatColor(val: number, isPercentage = false): string {
        if (isPercentage) {
            if (val >= 75) return "bg-green-400";
            if (val >= 50) return "bg-yellow-400";
            return "bg-red-400";
        }
        if (val >= 15) return "bg-green-400";
        if (val >= 10) return "bg-yellow-400";
        return "bg-red-400";
    }

    function getStatLabel(val: number, isPercentage = false): string {
        if (isPercentage) {
            if (val >= 75) return "text-green-400";
            if (val >= 50) return "text-yellow-400";
            return "text-red-400";
        }
        if (val >= 15) return "text-green-400";
        if (val >= 10) return "text-yellow-400";
        return "text-red-400";
    }

    function updateCountdowns() {
        const map: Record<string, string> = {};
        const now = Date.now();
        for (const d of drivers) {
            if (!d.transferListedAt) { map[d.id] = "—"; continue; }
            const listed = d.transferListedAt?.toDate?.() ?? new Date(d.transferListedAt);
            const expires = listed.getTime() + 24 * 3600 * 1000;
            const diff = expires - now;
            if (diff <= 0) { map[d.id] = "Expired"; continue; }
            const totalHours = Math.floor(diff / 3600000);
            const mins = Math.floor((diff % 3600000) / 60000).toString().padStart(2, "0");
            const secs = Math.floor((diff % 60000) / 1000).toString().padStart(2, "0");
            
            if (totalHours >= 24) {
                const days = Math.floor(totalHours / 24);
                const remainingHours = (totalHours % 24).toString().padStart(2, "0");
                map[d.id] = `${days}d ${remainingHours}h ${mins}m`;
            } else {
                const hrs = totalHours.toString().padStart(2, "0");
                map[d.id] = `${hrs}h ${mins}m ${secs}s`;
            }
        }
        countdownMap = map;
    }

    function checkMarketWindow() {
        const t = teamStore.value.team as any;
        const racesRemaining = t?.weekStatus?.racesRemaining ?? 10;
        isMarketOpen = racesRemaining > 1;
    }

    async function fetchPage(pageIndex: number) {
        if (!db || !firestoreApi) return;
        loading = true;
        try {
            const { collection, query, where, orderBy, limit, startAfter, getDocs } = firestoreApi;
            const twentyFourHoursAgo = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
            const constraints: any[] = [
                where("isTransferListed", "==", true),
                where("transferListedAt", ">", twentyFourHoursAgo),
                orderBy("transferListedAt"),
                limit(PAGE_SIZE),
            ];

            const cursor = pageHistory[pageIndex];
            if (pageIndex > 0 && cursor) {
                constraints.push(startAfter(cursor));
            }

            const snap = await getDocs(query(collection(db, "drivers"), ...constraints));
            const docs = snap.docs;
            drivers = docs.map((d: any) => ({ id: d.id, ...d.data() } as MarketDriver));
            currentPage = pageIndex;

            if (pageHistory.length <= pageIndex + 1) {
                pageHistory = [...pageHistory, docs.length > 0 ? docs[docs.length - 1] : null];
            } else {
                const copy = [...pageHistory];
                copy[pageIndex + 1] = docs.length > 0 ? docs[docs.length - 1] : null;
                pageHistory = copy;
            }

            updateCountdowns();
        } catch (e) {
            console.error("Market fetch error:", e);
        } finally {
            loading = false;
        }
    }

    async function placeBid() {
        if (!selectedDriver || !myTeamId || !db || !firestoreApi) return;
        bidLoading = true;
        bidError = "";
        bidSuccess = false;
        try {
            const { doc, runTransaction } = firestoreApi;
            const driverRef = doc(db, "drivers", selectedDriver.id);
            await runTransaction(db, async (txn: any) => {
                const snap = await txn.get(driverRef);
                if (!snap.exists()) throw new Error("Driver not found");
                const data = snap.data();
                const minBid = data.currentHighestBid === 0 ? data.marketValue : data.currentHighestBid + 50_000;
                if (bidAmount < minBid) throw new Error(`Bid must be at least ${formatCurrency(minBid)}`);
                if (bidAmount > myBudget) throw new Error("Insufficient budget");
                txn.update(driverRef, {
                    currentHighestBid: bidAmount,
                    highestBidderTeamId: myTeamId,
                });
            });
            bidSuccess = true;
            setTimeout(() => { showBidModal = false; fetchPage(currentPage); }, 1200);
        } catch (e: any) {
            bidError = e.message ?? "Error placing bid";
        } finally {
            bidLoading = false;
        }
    }

    async function cancelBid(driver: MarketDriver) {
        if (!myTeamId || !db || !firestoreApi) return;
        cancellingBidIds = new Set([...cancellingBidIds, driver.id]);
        try {
            const { doc, updateDoc } = firestoreApi;
            await updateDoc(doc(db, "drivers", driver.id), { currentHighestBid: 0, highestBidderTeamId: null });
            fetchPage(currentPage);
        } catch (e) { console.error(e); } finally {
            cancellingBidIds = new Set([...cancellingBidIds].filter(x => x !== driver.id));
        }
    }

    async function cancelTransfer(driver: MarketDriver) {
        if (!db || !firestoreApi) return;
        try {
            const { doc, updateDoc } = firestoreApi;
            await updateDoc(doc(db, "drivers", driver.id), { isTransferListed: false, transferListedAt: null });
            selectedDriver = null;
            showDetail = false;
            fetchPage(currentPage);
        } catch (e) { console.error(e); }
    }

    function openBidModal(driver: MarketDriver) {
        selectedDriver = driver;
        showDetail = false;
        bidAmount = driver.currentHighestBid === 0 ? driver.marketValue : driver.currentHighestBid + 50_000;
        bidError = "";
        bidSuccess = false;
        showBidModal = true;
    }

    function isExpiringSoon(driver: MarketDriver): boolean {
        if (!driver.transferListedAt) return false;
        const listed = driver.transferListedAt?.toDate?.() ?? new Date(driver.transferListedAt);
        const diff = listed.getTime() + 24 * 3600 * 1000 - Date.now();
        return diff > 0 && diff < 5 * 60 * 1000;
    }

    // Initialize lazily in browser only — never during SSR
    onMount(async () => {
        const firestore = await import("firebase/firestore");
        firestoreApi = firestore;
        db = firestore.getFirestore();
        checkMarketWindow();
        await fetchPage(0);
        timerInterval = setInterval(updateCountdowns, 1000);
    });

    onDestroy(() => { if (timerInterval) clearInterval(timerInterval); });

    const STAT_KEYS = ["braking","cornering","smoothness","overtaking","consistency","adaptability","fitness","feedback","focus"];
</script>

<svelte:head>
    <title>Transfer Market | FTG Racing Manager</title>
</svelte:head>

<div class="p-6 md:p-10 w-full max-w-[1400px] mx-auto text-app-text min-h-screen">

    <!-- Header -->
    <header class="flex flex-col gap-2 mb-10">
        <div class="flex items-center gap-3">
            <div class="p-2 rounded-lg bg-app-primary/10 text-app-primary">
                <Users size={24} />
            </div>
            <span class="text-[10px] font-black tracking-[0.3em] text-app-primary/60 uppercase font-heading">Driver Acquisition</span>
        </div>
        <div class="flex flex-wrap items-end justify-between gap-4">
            <h1 class="text-4xl lg:text-5xl font-heading font-black tracking-tighter uppercase italic text-app-text mt-1">
                Transfer <span class="text-app-primary">Market</span>
            </h1>
            <div class="flex items-center gap-3 px-4 py-2 bg-app-surface border border-app-border rounded-2xl text-[10px] font-black uppercase tracking-widest">
                <span class="text-app-text/40">Available Budget</span>
                <span class="text-app-primary">{formatCurrency(myBudget)}</span>
            </div>
        </div>
    </header>

    <!-- Market Closed -->
    {#if !isMarketOpen}
        <div class="flex flex-col items-center justify-center h-64 gap-6 bg-app-surface border border-red-500/20 rounded-3xl text-center">
            <div class="p-6 bg-red-500/10 rounded-full text-red-400"><Lock size={40} /></div>
            <div>
                <h2 class="text-xl font-black uppercase text-red-400">Transfer Market Closed</h2>
                <p class="text-sm text-app-text/40 mt-2">The market closes with 1 race remaining in the season.</p>
            </div>
        </div>

    {:else}
        <!-- Table -->
        <div class="bg-app-surface border border-app-border rounded-3xl overflow-hidden">

            <!-- Table Header -->
            <div class="hidden md:grid px-6 py-3 border-b border-app-border text-[8px] font-black text-app-text/30 uppercase tracking-widest gap-4"
                 style="grid-template-columns: 1fr 40px 80px 100px 100px 100px 80px">
                <span>Driver</span>
                <span class="text-center">Age</span>
                <span>Potential</span>
                <span class="text-right">Market Value</span>
                <span class="text-right">Highest Bid</span>
                <span class="text-center">Time Left</span>
                <span class="text-right">Action</span>
            </div>

            <!-- Loading Skeleton -->
            {#if loading}
                {#each Array(8) as _}
                    <div class="grid px-6 py-4 border-b border-app-border gap-4 animate-pulse"
                         style="grid-template-columns: 1fr 40px 80px 100px 100px 100px 80px">
                        {#each [6, 1, 2, 2, 2, 2, 2] as flex}
                            <div class="h-4 bg-app-text/5 rounded-full" style="flex:{flex}"></div>
                        {/each}
                    </div>
                {/each}

            <!-- Empty -->
            {:else if activeDrivers.length === 0}
                <div class="flex flex-col items-center justify-center h-48 opacity-30 gap-4">
                    <Users size={36} strokeWidth={1} />
                    <span class="text-sm font-black uppercase tracking-widest">No drivers listed</span>
                </div>

            <!-- Rows -->
            {:else}
                {#each activeDrivers as driver, i (driver.id)}
                    {@const isMyBid = driver.highestBidderTeamId === myTeamId}
                    {@const isMyDriver = driver.teamId === myTeamId}
                    {@const expiring = isExpiringSoon(driver)}
                    {@const lvl = getLevelInfo(driver.currentStars)}

                    <div
                        in:fly={{ x: -8, duration: 200, delay: i * 20 }}
                        class="grid px-6 py-4 border-b border-app-border last:border-0 items-center gap-4 transition-colors hover:bg-app-text/[0.02]
                        {isMyBid ? 'bg-green-500/[0.03]' : ''}"
                        style="grid-template-columns: 1fr 40px 80px 100px 100px 100px 80px"
                    >
                        <!-- Driver Name -->
                        <button
                            onclick={() => { selectedDriver = driver; showDetail = true; showBidModal = false; }}
                            class="flex items-center gap-3 text-left hover:opacity-80 transition-opacity"
                        >
                            <div class="w-8 h-8 rounded-full bg-app-text/5 flex-shrink-0 overflow-hidden">
                                <DriverAvatar id={driver.id} gender={driver.gender ?? 'male'} class="w-full h-full" />
                            </div>
                            <div class="flex flex-col min-w-0">
                                <div class="flex items-center gap-2">
                                    <span class="text-[11px] font-black text-app-text uppercase italic truncate underline decoration-app-text/10" title={driver.name}>{formatDriverName(driver.name)}</span>
                                    <CountryFlag countryCode={driver.countryCode} size="xs" />
                                </div>
                                <span class="text-[9px] font-black border px-1.5 py-px rounded w-fit mt-0.5 {lvl.color}">{lvl.label}</span>
                            </div>
                        </button>

                        <!-- Age -->
                        <span class="text-[11px] font-bold text-app-text/50 text-center">{driver.age}</span>

                        <!-- Stars -->
                        <div class="flex gap-0.5">
                            {#each Array(5) as _, si}
                                <span class="text-xs {si < driver.currentStars ? 'text-blue-400' : si < driver.potential ? 'text-yellow-400/50' : 'text-app-text/10'}">★</span>
                            {/each}
                        </div>

                        <!-- Market Value -->
                        <span class="text-[11px] font-bold text-app-text/50 text-right">{formatCurrency(driver.marketValue)}</span>

                        <!-- Highest Bid -->
                        <span class="text-[11px] font-black text-right {isMyBid ? 'text-green-500' : 'text-yellow-500'}">
                            {driver.currentHighestBid > 0 ? formatCurrency(driver.currentHighestBid) : '—'}
                        </span>

                        <!-- Countdown -->
                        <span class="text-[10px] font-mono text-center {expiring ? 'text-red-400 animate-pulse' : 'text-app-text/40'}">
                            {countdownMap[driver.id] ?? "—"}
                        </span>

                        <!-- Action -->
                        <div class="flex justify-end">
                            {#if isMyDriver}
                                <button
                                    onclick={() => cancelTransfer(driver)}
                                    class="text-[9px] font-black uppercase tracking-widest text-red-400 border border-red-400/30 px-2 py-1 rounded-lg hover:bg-red-400/10 transition-colors"
                                >
                                    Cancel
                                </button>
                            {:else if isMyBid}
                                <button
                                    onclick={() => cancelBid(driver)}
                                    disabled={cancellingBidIds.has(driver.id)}
                                    class="text-[9px] font-black uppercase tracking-widest text-red-400 border border-red-400/30 px-2 py-1 rounded-lg hover:bg-red-400/10 transition-colors disabled:opacity-40"
                                >
                                    {cancellingBidIds.has(driver.id) ? '...' : 'Cancel Bid'}
                                </button>
                            {:else}
                                <button
                                    onclick={() => openBidModal(driver)}
                                    disabled={expiring || countdownMap[driver.id] === 'Expired'}
                                    class="flex items-center gap-1 text-[9px] font-black uppercase tracking-widest bg-green-500 text-app-text px-3 py-1.5 rounded-lg hover:bg-green-400 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
                                >
                                    <Gavel size={10} /> Bid
                                </button>
                            {/if}
                        </div>
                    </div>
                {/each}
            {/if}
        </div>

        <!-- Pagination -->
        {#if !loading && (currentPage > 0 || hasNextPage)}
            <div class="flex items-center justify-center gap-6 mt-6">
                <button
                    onclick={() => fetchPage(currentPage - 1)}
                    disabled={currentPage === 0}
                    class="flex items-center gap-1 text-[10px] font-black uppercase text-app-text/40 hover:text-app-text disabled:opacity-20 transition-colors"
                >
                    <ChevronLeft size={14} /> Prev
                </button>
                <span class="text-[10px] font-black text-app-text/30 uppercase tracking-widest">Page {currentPage + 1}</span>
                <button
                    onclick={() => fetchPage(currentPage + 1)}
                    disabled={!hasNextPage}
                    class="flex items-center gap-1 text-[10px] font-black uppercase text-app-text/40 hover:text-app-text disabled:opacity-20 transition-colors"
                >
                    Next <ChevronRight size={14} />
                </button>
            </div>
        {/if}
    {/if}
</div>

<!-- ──── Driver Detail Sheet ───────────────────────────────────────────────────── -->
{#if showDetail && selectedDriver && !showBidModal}
    {@const d = selectedDriver}
    {@const lvl = getLevelInfo(d?.currentStars || 1)}
    {@const isMyBid = d?.highestBidderTeamId === myTeamId}
    {@const isMyDriver = d?.teamId === myTeamId}
    <div
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/95 backdrop-blur-md"
        transition:fade={{ duration: 200 }}
        role="dialog"
        aria-modal="true"
        tabindex="-1"
        onclick={(e) => { if (e.target === e.currentTarget) showDetail = false; }}
        onkeydown={(e) => { if (e.key === 'Escape') showDetail = false; }}
    >
        <div
            class="bg-[#121216] border border-app-border rounded-[32px] w-full max-w-5xl overflow-hidden shadow-[0_0_50px_rgba(0,0,0,0.5)] relative"
            in:fly={{ y: 30, duration: 400 }}
        >
            <!-- Close -->
            <button
                onclick={() => showDetail = false}
                class="absolute top-6 right-6 p-2 bg-white/5 rounded-full text-app-text/40 hover:text-app-text hover:bg-white/10 transition-all z-20"
            >
                <X size={20} />
            </button>

            <div class="flex flex-col md:flex-row h-full max-h-[85vh]">
                <!-- Column 1: Identity + Contract -->
                <div class="flex-none w-full md:w-[380px] p-8 md:p-12 border-b md:border-b-0 md:border-r border-app-border overflow-y-auto custom-scrollbar">
                    <div class="flex items-start gap-6 mb-8">
                        <div class="w-24 h-24 rounded-full overflow-hidden border-4 border-app-primary/20 flex-shrink-0 p-1 bg-white/5">
                            <DriverAvatar id={d.id} gender={d.gender ?? 'male'} class="w-full h-full rounded-full" />
                        </div>
                        <div class="flex flex-col gap-2">
                            <span class="text-[9px] font-black border px-2 py-0.5 rounded-md w-fit {lvl.color} uppercase tracking-widest">{lvl.label}</span>
                            <div class="flex items-center gap-3">
                                <h2 class="text-3xl font-black text-app-text uppercase italic leading-none tracking-tighter" title={d.name}>{formatDriverName(d.name)}</h2>
                                <CountryFlag countryCode={d.countryCode} size="sm" />
                            </div>
                            <div class="flex items-center gap-2">
                                <span class="text-xs font-black text-app-text/40 uppercase tracking-widest">{d.age}Y</span>
                                <div class="flex gap-0.5">
                                    {#each Array(5) as _, si}
                                        <span class="text-xs {si < d.currentStars ? 'text-blue-400' : si < d.potential ? 'text-yellow-400/30' : 'text-app-text/5'}">★</span>
                                    {/each}
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="space-y-6">
                        <div class="bg-white/[0.02] border border-app-border rounded-3xl p-6 space-y-4">
                            <h4 class="text-[10px] font-black uppercase tracking-[0.2em] text-app-text/20">Contract Status</h4>
                            <div class="grid grid-cols-2 gap-4">
                                <div class="flex flex-col gap-1">
                                    <span class="text-[9px] font-bold text-app-text/40 uppercase">Role</span>
                                    <span class="text-xs font-black text-app-text uppercase">{d.role ?? "DRIVER"}</span>
                                </div>
                                <div class="flex flex-col gap-1 text-right">
                                    <span class="text-[9px] font-bold text-app-text/40 uppercase">Salary</span>
                                    <span class="text-xs font-black text-green-400">{formatCurrency(d.salary)}/WK</span>
                                </div>
                                <div class="flex flex-col gap-1">
                                    <span class="text-[9px] font-bold text-app-text/40 uppercase">Remaining</span>
                                    <span class="text-xs font-black text-app-text uppercase">{d.contractYearsRemaining} Season(s)</span>
                                </div>
                                <div class="flex flex-col gap-1 text-right">
                                    <span class="text-[9px] font-bold text-app-text/40 uppercase">Market Value</span>
                                    <span class="text-xs font-black text-app-text uppercase">{formatCurrency(d.marketValue)}</span>
                                </div>
                            </div>
                        </div>

                        <div class="bg-app-primary/5 border border-app-primary/10 rounded-3xl p-6">
                            <div class="flex items-center justify-between mb-4">
                                <span class="text-[10px] font-black uppercase tracking-[0.2em] text-app-primary/40">Current Bidding</span>
                                <Gavel size={14} class="text-app-primary/40" />
                            </div>
                            <div class="flex flex-col gap-1">
                                <span class="text-3xl font-black text-app-text font-mono italic">
                                    {d.currentHighestBid > 0 ? formatCurrency(d.currentHighestBid) : "No Bids"}
                                </span>
                                <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-widest">
                                    {d.currentHighestBid > 0 ? "Highest Active Bid" : "Starting Price"}
                                </span>
                            </div>
                        </div>

                        <div class="pt-2">
                            {#if isMyDriver}
                                <button onclick={() => cancelTransfer(d)} class="w-full py-4 bg-red-500/10 border border-red-500/20 text-red-400 text-[10px] font-black uppercase tracking-widest rounded-2xl hover:bg-red-500 hover:text-black transition-all">
                                    Cancel Transfer listing
                                </button>
                            {:else if isMyBid}
                                <div class="flex flex-col gap-3">
                                    <div class="flex items-center justify-center gap-2 py-4 bg-green-500/10 border border-green-500/20 rounded-2xl">
                                        <CheckCircle size={16} class="text-green-500" />
                                        <span class="text-[10px] font-black text-green-500 uppercase tracking-widest">Highest Bidder</span>
                                    </div>
                                    <button onclick={() => cancelBid(d)} disabled={cancellingBidIds.has(d.id)} class="w-full py-3 text-red-400/40 text-[9px] font-bold uppercase tracking-widest hover:text-red-400 transition-colors disabled:opacity-40">
                                        {cancellingBidIds.has(d.id) ? 'Processing...' : 'Cancel active bid'}
                                    </button>
                                </div>
                            {:else}
                                <button
                                    onclick={() => openBidModal(d)}
                                    disabled={isExpiringSoon(d)}
                                    class="w-full py-4 bg-app-primary text-app-primary-foreground text-[11px] font-black uppercase tracking-[0.2em] rounded-2xl hover:bg-app-primary/90 transition-all shadow-[0_10px_20px_rgba(197,160,89,0.2)] flex items-center justify-center gap-3 disabled:opacity-30"
                                >
                                    <Gavel size={16} /> Place Bid
                                </button>
                            {/if}
                        </div>
                    </div>
                </div>

                <!-- Column 2: Stats & Details -->
                <div class="flex-1 p-8 md:p-12 bg-white/[0.01] overflow-y-auto custom-scrollbar">
                    <div class="flex items-center justify-between mb-10">
                        <div class="flex flex-col gap-1">
                            <h3 class="text-xs font-black text-app-text uppercase tracking-[0.3em]">Performance Profile</h3>
                            <span class="text-[9px] font-bold text-app-text/20 uppercase tracking-widest">Official scouting report • Season 2026</span>
                        </div>
                        <div class="bg-app-text/5 px-4 py-2 rounded-xl border border-app-border">
                             <span class="text-[10px] font-black text-app-text/40 uppercase tracking-widest">Status: </span>
                             <span class="text-[10px] font-black text-yellow-500 uppercase tracking-widest">Active Listing</span>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-x-12 gap-y-8">
                        {#each STAT_KEYS as key}
                            {@const isPercentage = key === "fitness" || key === "morale"}
                            {@const val = (d.stats?.[key] ?? (isPercentage ? 70 : 10))}
                            <div class="flex flex-col gap-3 group">
                                <div class="flex items-center justify-between">
                                    <span class="text-[10px] font-black text-app-text/40 uppercase tracking-widest group-hover:text-app-text/60 transition-colors">{key}</span>
                                    <span class="text-sm font-black font-mono {getStatLabel(val, isPercentage)}">{val}{isPercentage ? '%' : ''}</span>
                                </div>
                                <div class="h-1.5 w-full bg-app-text/5 rounded-full overflow-hidden p-[1px]">
                                    <div
                                        class="h-full rounded-full transition-all duration-1000 ease-out {getStatColor(val, isPercentage)}"
                                        style="width: {isPercentage ? val : (val / 20) * 100}%"
                                    >
                                        <div class="w-full h-full bg-gradient-to-r from-white/20 to-transparent"></div>
                                    </div>
                                </div>
                            </div>
                        {/each}
                    </div>

                    <div class="mt-16 p-8 bg-white/[0.02] border border-app-border rounded-[32px] flex flex-col md:flex-row items-center gap-8">
                        <div class="flex-1 space-y-2">
                             <h4 class="text-sm font-black text-app-text uppercase italic">Scouting Summary</h4>
                             <p class="text-xs text-app-text/40 leading-relaxed">
                                 A {lvl.label.toLowerCase()} talent with significant potential in {STAT_KEYS[Math.floor(Math.random() * STAT_KEYS.length)]}. 
                                 Currently testing the waters of the {d.role || 'driver'} market.
                             </p>
                        </div>
                        <div class="w-px h-12 bg-app-border hidden md:block"></div>
                        <div class="flex flex-col items-center md:items-end gap-1">
                            <span class="text-[9px] font-black text-app-text/20 uppercase tracking-widest">Time Remaining</span>
                            <span class="text-2xl font-black font-mono {isExpiringSoon(d) ? 'text-red-500 animate-pulse' : 'text-app-text'}">
                                {countdownMap[d.id] ?? "—"}
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
{/if}

<!-- ──── Bid Modal ─────────────────────────────────────────────────────────────── -->
{#if showBidModal && selectedDriver}
    {@const d = selectedDriver}
    {#if d}
        {@const minBid = d.currentHighestBid === 0 ? d.marketValue : d.currentHighestBid + 50_000}
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/95 backdrop-blur-md"
            transition:fade={{ duration: 150 }}
            role="dialog"
            aria-modal="true"
            tabindex="-1"
            onclick={(e) => { if (e.target === e.currentTarget) showBidModal = false; }}
            onkeydown={(e) => { if (e.key === 'Escape') showBidModal = false; }}
        >
            <div class="bg-[#1a1a1e] border border-app-border rounded-3xl w-full max-w-md p-8 shadow-2xl relative overflow-hidden" in:fly={{ y: 20, duration: 200 }}>
                <!-- Decorative Glow -->
                <div class="absolute -top-24 -right-24 w-48 h-48 bg-app-primary/10 blur-3xl rounded-full"></div>
                <div class="flex items-center justify-between mb-6">
                    <h3 class="text-lg font-black text-app-text uppercase italic">Place Transfer Bid</h3>
                    <button onclick={() => showBidModal = false} class="text-app-text/40 hover:text-app-text transition-colors"><X size={18} /></button>
                </div>

                <p class="text-sm text-app-text/50 mb-2">Bidding for <span class="text-app-text font-black">{d.name}</span></p>
                {#if d.currentHighestBid > 0}
                    <p class="text-xs text-app-text/40 mb-6">Current highest bid: <span class="text-yellow-600 font-black">{formatCurrency(d.currentHighestBid)}</span></p>
                {:else}
                    <p class="text-xs text-app-text/40 mb-6">Starting at market value: <span class="text-app-text font-black">{formatCurrency(d.marketValue)}</span></p>
                {/if}

                <!-- Stepper -->
                <div class="flex items-center justify-between bg-app-text/[0.03] border border-app-border rounded-2xl p-4 mb-6">
                    <button
                        onclick={() => { if (bidAmount - 100_000 >= minBid) bidAmount -= 100_000; }}
                        class="p-2 rounded-xl bg-app-text/5 hover:bg-red-500/20 text-red-400 transition-colors"
                    >
                        <Minus size={18} />
                    </button>
                    <div class="text-center">
                        <p class="text-2xl font-black text-app-text font-mono">{formatCurrency(bidAmount)}</p>
                        <p class="text-[9px] text-app-text/30 uppercase tracking-widest mt-1">Your Bid</p>
                    </div>
                    <button
                        onclick={() => bidAmount += 100_000}
                        class="p-2 rounded-xl bg-app-text/5 hover:bg-green-500/20 text-green-500 transition-colors"
                    >
                        <Plus size={18} />
                    </button>
                </div>

                {#if bidAmount > myBudget}
                    <p class="text-[10px] text-red-400 font-black text-center mb-4">⚠ Exceeds available budget ({formatCurrency(myBudget)})</p>
                {/if}
                {#if bidError}
                    <p class="text-[10px] text-red-400 font-black text-center mb-4">⚠ {bidError}</p>
                {/if}
                {#if bidSuccess}
                    <div class="flex items-center gap-2 justify-center text-green-500 mb-4">
                        <CheckCircle size={16} />
                        <span class="text-[10px] font-black uppercase">Bid placed successfully!</span>
                    </div>
                {/if}

                <div class="flex gap-3">
                    <button onclick={() => showBidModal = false} class="flex-1 py-3 border border-app-border text-app-text/40 text-[10px] font-black uppercase tracking-wider rounded-2xl hover:bg-app-text/5 transition-colors">
                        Cancel
                    </button>
                    <button
                        onclick={placeBid}
                        disabled={bidLoading || bidAmount > myBudget || bidAmount < minBid}
                        class="flex-1 py-3 bg-green-500 text-app-text text-[10px] font-black uppercase tracking-wider rounded-2xl hover:bg-green-400 transition-colors disabled:opacity-30 flex items-center justify-center gap-2"
                    >
                        {#if bidLoading}
                            <div class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                        {:else}
                            <Gavel size={14} /> Submit Bid
                        {/if}
                    </button>
                </div>
            </div>
        </div>
    {/if}
{/if}
