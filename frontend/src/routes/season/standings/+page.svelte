<script lang="ts">
    import { Trophy, ChevronLeft, Users, Medal } from "lucide-svelte";
    import { fly } from "svelte/transition";
    import { universeStore } from "$lib/stores/universe.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { browser } from "$app/environment";

    let universe = $derived(universeStore.value.universe);
    let loading = $derived(universeStore.value.loading);
    let myTeamId = $derived(teamStore.value.team?.id ?? null);
    let season = $derived(seasonStore.value.season);

    type Tab = "drivers" | "constructors";
    let activeTab = $state<Tab>("drivers");

    // ── Manager lookup map (teamId → display data) ──────────────────────────────
    let managerMap = $state<Record<string, { name: string; country: string }>>({});

    // ── League resolved from universe ────────────────────────────────────────────
    let selectedLeague = $derived.by(() => {
        if (!universe) return null;
        const all = universe.leagues ?? [];
        if (myTeamId) {
            const userLeague = all.find((l: any) => l.teams.some((t: any) => t.id === myTeamId));
            if (userLeague) return userLeague;
        }
        return all[0] ?? null;
    });

    // ── teamMap: { teamId → teamName } built from league.teams ──────────────────
    let teamMap = $derived.by(() => {
        if (!selectedLeague) return {} as Record<string, string>;
        const map: Record<string, string> = {};
        for (const t of selectedLeague.teams) {
            map[t.id] = t.name;
        }
        return map;
    });

    // ── Sorted lists ────────────────────────────────────────────────────────────
    let sortedDrivers = $derived.by(() => {
        if (!selectedLeague) return [];
        return [...selectedLeague.drivers].sort((a: any, b: any) => {
            if ((b.seasonPoints ?? 0) !== (a.seasonPoints ?? 0)) return (b.seasonPoints ?? 0) - (a.seasonPoints ?? 0);
            return (a.name ?? '').localeCompare(b.name ?? '');
        });
    });

    let sortedTeams = $derived.by(() => {
        if (!selectedLeague) return [];
        return [...selectedLeague.teams].sort((a: any, b: any) => {
            if ((b.seasonPoints ?? 0) !== (a.seasonPoints ?? 0)) return (b.seasonPoints ?? 0) - (a.seasonPoints ?? 0);
            return (a.name ?? '').localeCompare(b.name ?? '');
        });
    });

    // ── Fetch manager profiles when league changes (browser only) ───────────────
    $effect(() => {
        const league = selectedLeague;
        if (!league || !browser) return;

        const teams = league.teams
            .filter((t: any) => t.managerId)
            .map((t: any) => ({ id: t.id as string, managerId: t.managerId as string }));

        if (teams.length === 0) return;

        fetchManagers(teams);
    });

    async function fetchManagers(teams: { id: string; managerId: string }[]) {
        try {
            const { getFirestore, collection, query, where, getDocs } = await import("firebase/firestore");
            const db = getFirestore();
            const managerIds = teams.map(t => t.managerId);
            const map: Record<string, { name: string; country: string }> = {};

            for (let i = 0; i < managerIds.length; i += 30) {
                const chunk = managerIds.slice(i, i + 30);
                const snap = await getDocs(
                    query(collection(db, "managers"), where("uid", "in", chunk))
                );
                for (const docSnap of snap.docs) {
                    const d = docSnap.data();
                    const matchedTeam = teams.find(t => t.managerId === docSnap.id);
                    if (matchedTeam) {
                        map[matchedTeam.id] = {
                            name: `${d.firstName ?? ''} ${d.lastName ?? ''}`.trim(),
                            country: d.country ?? '',
                        };
                    }
                }
            }
            managerMap = map;
        } catch (e) {
            console.warn("Could not fetch managers:", e);
        }
    }

    import { getFlagEmoji, getFlagUrl } from "$lib/utils/country";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";

    function getOrdinal(n: number): string {
        const s = ["th", "st", "nd", "rd"];
        const v = n % 100;
        return n + (s[(v - 20) % 10] || s[v] || s[0]);
    }

    function isMyTeam(id: string): boolean {
        return !!myTeamId && id === myTeamId;
    }
</script>

<svelte:head>
    <title>Standings | FTG Racing Manager</title>
</svelte:head>

<div class="p-6 md:p-10 w-full max-w-[1400px] mx-auto text-app-text min-h-screen">

    <!-- Breadcrumb -->
    <nav class="flex items-center gap-2 mb-8 opacity-40 hover:opacity-100 transition-opacity">
        <a href="/season" class="flex items-center gap-1 text-[10px] font-black uppercase tracking-widest text-app-text">
            <ChevronLeft size={14} /> Season
        </a>
    </nav>

    <!-- Header -->
    <header class="flex flex-col gap-2 mb-10">
        <div class="flex items-center gap-3">
            <div class="p-2 rounded-lg bg-app-primary/10 text-app-primary">
                <Trophy size={24} />
            </div>
            <span class="text-[10px] font-black tracking-[0.3em] text-app-primary/60 uppercase font-heading">
                {#if season}Season {season.year}{:else}Championship{/if}
            </span>
        </div>
        <h1 class="text-4xl lg:text-5xl font-heading font-black tracking-tighter uppercase italic text-app-text mt-1">
            Championship <span class="text-app-primary">Standings</span>
        </h1>
    </header>

    {#if loading}
        <div class="flex items-center justify-center h-64">
            <div class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"></div>
        </div>

    {:else if !selectedLeague}
        <div class="flex flex-col items-center justify-center h-64 opacity-30 gap-4">
            <Trophy size={40} strokeWidth={1} />
            <span class="text-sm font-black uppercase tracking-widest">No league data</span>
        </div>

    {:else}
        <!-- Tab Bar -->
        <div class="flex items-center gap-1 mb-8 bg-app-surface border border-app-border rounded-2xl p-1 w-fit">
            {#each [{ id: "drivers", label: "Drivers", icon: Users }, { id: "constructors", label: "Constructors", icon: Medal }] as tab}
                <button
                    onclick={() => (activeTab = tab.id as Tab)}
                    class="flex items-center gap-2 px-5 py-2.5 rounded-xl text-[10px] font-black uppercase tracking-[0.15em] transition-all
                    {activeTab === tab.id ? 'bg-app-primary text-app-primary-foreground' : 'text-app-text/40 hover:text-app-text'}"
                >
                    <tab.icon size={14} />
                    {tab.label}
                </button>
            {/each}
        </div>

        <!-- ── Drivers Tab ───────────────────────────────────────────── -->
        {#if activeTab === "drivers"}
            <div class="bg-app-surface border border-app-border rounded-3xl overflow-hidden" in:fly={{ y: 10, duration: 200 }}>
                <!-- Header -->
                <div class="grid gap-4 px-6 py-3 border-b border-app-border text-[8px] font-black text-app-text/30 uppercase tracking-widest"
                     style="grid-template-columns: 48px 1fr 140px 40px 40px 40px 60px">
                    <span>Pos</span>
                    <span>Driver</span>
                    <span>Team</span>
                    <span class="text-center">R</span>
                    <span class="text-center">W</span>
                    <span class="text-center">Pd</span>
                    <span class="text-right">Pts</span>
                </div>

                {#each sortedDrivers as driver, i}
                    {@const pos = i + 1}
                    {@const mine = isMyTeam(driver.teamId)}
                    {@const driverTeamName = teamMap[driver.teamId] ?? '—'}
                    <div
                        in:fly={{ x: -10, duration: 200, delay: i * 20 }}
                        class="grid gap-4 px-6 py-4 border-b border-app-border last:border-0 items-center transition-colors {mine ? 'bg-app-primary/5' : 'hover:bg-app-text/[0.02]'}"
                        style="grid-template-columns: 48px 1fr 140px 40px 40px 40px 60px"
                    >
                        <span class="text-xs font-heading font-black italic {pos === 1 ? 'text-yellow-500' : pos === 2 ? 'text-slate-400' : pos === 3 ? 'text-amber-600' : 'text-app-text/30'}">
                            {getOrdinal(pos)}
                        </span>
                        <span class="text-[11px] font-black text-app-text uppercase italic truncate {mine ? 'text-app-primary' : ''}">{driver.name}</span>
                        <span class="text-[10px] font-bold text-app-text/50 truncate">{driverTeamName}</span>
                        <span class="text-[10px] font-black text-app-text/40 text-center">{driver.seasonRaces ?? 0}</span>
                        <span class="text-[10px] font-black text-app-text/40 text-center">{driver.seasonWins ?? 0}</span>
                        <span class="text-[10px] font-black text-app-text/40 text-center">{driver.seasonPodiums ?? 0}</span>
                        <span class="text-sm font-black italic text-right {mine ? 'text-app-primary' : 'text-app-text'}">{driver.seasonPoints ?? 0}</span>
                    </div>
                {:else}
                    <div class="flex flex-col items-center justify-center h-40 opacity-30 gap-3">
                        <Users size={32} strokeWidth={1} /><span class="text-xs font-black uppercase">No drivers</span>
                    </div>
                {/each}
            </div>

        <!-- ── Constructors Tab ─────────────────────────────────────── -->
        {:else}
            <div class="bg-app-surface border border-app-border rounded-3xl overflow-hidden" in:fly={{ y: 10, duration: 200 }}>
                <!-- Header -->
                <div class="grid gap-4 px-6 py-3 border-b border-app-border text-[8px] font-black text-app-text/30 uppercase tracking-widest"
                     style="grid-template-columns: 48px 1fr 40px 40px 40px 40px 60px">
                    <span>Pos</span>
                    <span>Team</span>
                    <span class="text-center">R</span>
                    <span class="text-center">W</span>
                    <span class="text-center">Pd</span>
                    <span class="text-center">Pl</span>
                    <span class="text-right">Pts</span>
                </div>

                {#each sortedTeams as team, i}
                    {@const pos = i + 1}
                    {@const mine = isMyTeam(team.id)}
                    {@const mgr = managerMap[team.id]}
                    <div
                        in:fly={{ x: -10, duration: 200, delay: i * 30 }}
                        class="grid gap-4 px-6 py-4 border-b border-app-border last:border-0 items-center transition-colors {mine ? 'bg-app-primary/5' : 'hover:bg-app-text/[0.02]'}"
                        style="grid-template-columns: 48px 1fr 40px 40px 40px 40px 60px"
                    >
                        <span class="text-xs font-heading font-black italic {pos === 1 ? 'text-yellow-500' : pos === 2 ? 'text-slate-400' : pos === 3 ? 'text-amber-600' : 'text-app-text/30'}">
                            {getOrdinal(pos)}
                        </span>

                        <!-- Team name + manager -->
                        <div class="flex flex-col gap-0.5 min-w-0">
                            <span class="text-[11px] font-black uppercase italic truncate {mine ? 'text-app-primary' : 'text-app-text'}">{team.name}</span>
                            {#if mgr}
                                <span class="text-[9px] text-app-text/40 font-medium truncate">
                                    <span class="flex items-center gap-2">
                                        <CountryFlag countryCode={mgr.country} size="sm" />
                                        <span>{mgr.name}</span>
                                    </span>
                                </span>
                            {/if}
                        </div>

                        <span class="text-[10px] font-black text-app-text/40 text-center">{team.seasonRaces ?? 0}</span>
                        <span class="text-[10px] font-black text-app-text/40 text-center">{team.seasonWins ?? 0}</span>
                        <span class="text-[10px] font-black text-app-text/40 text-center">{team.seasonPodiums ?? 0}</span>
                        <span class="text-[10px] font-black text-app-text/40 text-center">{team.seasonPoles ?? 0}</span>
                        <span class="text-sm font-black italic text-right {mine ? 'text-app-primary' : 'text-app-text'}">{team.seasonPoints ?? 0}</span>
                    </div>
                {:else}
                    <div class="flex flex-col items-center justify-center h-40 opacity-30 gap-3">
                        <Medal size={32} strokeWidth={1} /><span class="text-xs font-black uppercase">No teams</span>
                    </div>
                {/each}
            </div>
        {/if}
    {/if}
</div>
