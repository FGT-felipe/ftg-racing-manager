<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { driverStore } from "$lib/stores/driver.svelte";
    import { notificationStore } from "$lib/stores/notifications.svelte";
    import { db } from "$lib/firebase/config";
    import {
        collection,
        query,
        orderBy,
        limit,
        onSnapshot,
    } from "firebase/firestore";
    import { browser } from "$app/environment";
    import {
        Building2,
        Trophy,
        MessageSquare,
        Mail,
        RefreshCw,
        Edit3,
        Check,
        X,
        ChevronRight,
        Clock,
        BarChart3,
        Info,
        TrendingUp,
        CheckCircle,
        AlertTriangle,
    } from "lucide-svelte";
    import InstructionCard from "$lib/components/layout/InstructionCard.svelte";
    import { getRoleById } from "$lib/constants/manager";

    let isEditingName = $state(false);
    let newName = $state("");
    let isSavingName = $state(false);
    let news = $state<any[]>([]);
    let isSyncing = $state(false);

    // Initialize driver store for stats aggregation
    driverStore.init();

    // Stats calculation
    const teamStats = $derived({
        titles:
            (driverStore.carADriver?.championships || 0) +
            (driverStore.carBDriver?.championships || 0),
        wins:
            (driverStore.carADriver?.wins || 0) +
            (driverStore.carBDriver?.wins || 0),
        podiums:
            (driverStore.carADriver?.podiums || 0) +
            (driverStore.carBDriver?.podiums || 0),
        poles:
            (driverStore.carADriver?.poles || 0) +
            (driverStore.carBDriver?.poles || 0),
        races:
            (driverStore.carADriver?.races || 0) +
            (driverStore.carBDriver?.races || 0),
    });

    const managerAge = $derived.by(() => {
        if (!managerStore.profile?.birthDate) return null;
        try {
            const birth = new Date(managerStore.profile.birthDate);
            const now = new Date();
            let age = now.getFullYear() - birth.getFullYear();
            const m = now.getMonth() - birth.getMonth();
            if (m < 0 || (m === 0 && now.getDate() < birth.getDate())) {
                age--;
            }
            return age;
        } catch (e) {
            return null;
        }
    });

    const managerRole = $derived.by(() => {
        const bgId = managerStore.profile?.backgroundId || "ex_driver";
        return getRoleById(bgId);
    });

    // Real-time news subscription
    $effect(() => {
        const teamId = teamStore.value.team?.id;
        if (!teamId || !browser) return;

        newName = teamStore.value.team?.name || "";

        const q = query(
            collection(db, "teams", teamId, "news"),
            orderBy("timestamp", "desc"),
            limit(10),
        );

        const unsubscribe = onSnapshot(
            q,
            (snapshot) => {
                news = snapshot.docs.map((doc) => ({
                    id: doc.id,
                    ...doc.data(),
                    timestamp:
                        (doc.data().timestamp as any)?.toDate?.() || new Date(),
                }));
            },
            (err) => {
                console.error("News sync error:", err);
            },
        );

        return unsubscribe;
    });

    async function handleRename() {
        if (!newName.trim() || newName === teamStore.value.team?.name) {
            isEditingName = false;
            return;
        }

        isSavingName = true;
        try {
            await teamStore.renameTeam(newName);
            notificationStore.addNotification({
                title: "Team Renamed",
                message: `Identity updated to ${newName}.`,
                type: "SUCCESS",
            });
            isEditingName = false;
        } catch (e: any) {
            alert(e.message);
        } finally {
            isSavingName = false;
        }
    }

    async function handleSync() {
        isSyncing = true;
        try {
            const { getFunctions, httpsCallable } = await import(
                "firebase/functions"
            );
            const functions = getFunctions();
            const megaFix = httpsCallable(functions, "megaFixDebriefs");
            await megaFix();
            notificationStore.addNotification({
                title: "Data Synchronized",
                message: "Cloud records have been reconciled with local state.",
                type: "SUCCESS",
            });
        } catch (e: any) {
            console.error("Sync error:", e);
            notificationStore.addNotification({
                title: "Sync Failed",
                message: "Cloud synchronization encountered an error: " + (e.message || "Internal 500"),
                type: "ERROR",
            });
        } finally {
            isSyncing = false;
        }
    }

    function formatDate(date: Date) {
        return (
            date.toLocaleDateString(undefined, {
                day: "numeric",
                month: "short",
            }) +
            " " +
            date.toLocaleTimeString(undefined, {
                hour: "2-digit",
                minute: "2-digit",
            })
        );
    }
</script>

<svelte:head>
    <title>Team Office | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-4 md:p-8 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text"
>
    <!-- Header -->
    <InstructionCard
        icon={Building2}
        title="Headquarters Office"
        description="The administrative nerve center of your racing organization. Manage team identity, review historical performance, and monitor official communications from the league."
    />

    <div class="mt-10 grid grid-cols-1 lg:grid-cols-12 gap-8">
        <!-- Left Column: Identity & Stats -->
        <div class="lg:col-span-4 space-y-6">
            <!-- Team Identity Card -->
            <div
                class="bg-app-surface border border-app-border rounded-2xl p-6 shadow-xl relative overflow-hidden group"
            >
                <div
                    class="absolute top-0 right-0 w-32 h-32 bg-app-primary/5 rounded-full -mr-16 -mt-16 blur-3xl group-hover:bg-app-primary/10 transition-all duration-700"
                ></div>

                <div class="flex items-center justify-between mb-6 relative">
                    <span
                        class="text-[10px] font-black uppercase tracking-widest text-app-primary"
                        >Team Identity</span
                    >
                    {#if !isEditingName}
                        <button
                            onclick={() => (isEditingName = true)}
                            class="p-2 hover:bg-app-text/5 rounded-lg text-app-text/30 hover:text-app-primary transition-all"
                        >
                            <Edit3 size={14} />
                        </button>
                    {/if}
                </div>

                {#if isEditingName}
                    <div
                        class="space-y-4 animate-in fade-in slide-in-from-top-2 duration-300"
                    >
                        <div class="space-y-1.5">
                            <label
                                for="team-name"
                                class="text-[10px] font-bold text-app-text/40 uppercase ml-1"
                                >New Name</label
                            >
                            <input
                                id="team-name"
                                type="text"
                                bind:value={newName}
                                class="w-full bg-app-text/5 border border-app-border rounded-xl px-4 py-3 font-black text-app-text focus:outline-none focus:border-app-primary/50 transition-all"
                                placeholder="Enter team name..."
                            />
                        </div>
                        <div class="flex gap-2">
                            <button
                                onclick={handleRename}
                                disabled={isSavingName}
                                class="flex-1 py-2.5 bg-app-primary text-app-primary-foreground font-black uppercase text-[10px] tracking-widest rounded-lg hover:scale-[1.02] active:scale-95 transition-all disabled:opacity-50"
                            >
                                {isSavingName ? "Saving..." : "Confirm"}
                            </button>
                            <button
                                onclick={() => {
                                    isEditingName = false;
                                    newName = teamStore.value.team?.name || "";
                                }}
                                class="px-3 bg-app-text/5 text-app-text/40 font-black uppercase text-[10px] tracking-widest rounded-lg hover:bg-app-text/10 transition-all"
                            >
                                <X size={16} />
                            </button>
                        </div>
                    </div>
                {:else}
                    <h2
                        class="text-3xl font-black text-app-text uppercase tracking-tight mb-2 truncate"
                    >
                        {teamStore.value.team?.name}
                    </h2>
                {/if}

                <div class="mt-6 pt-6 border-t border-app-border/30">
                    <div
                        class="flex items-center gap-3 p-3 bg-app-text/5 rounded-xl border border-app-border/30"
                    >
                        <div
                            class="w-8 h-8 rounded-lg bg-amber-500/10 flex items-center justify-center"
                        >
                            <Info size={14} class="text-amber-500" />
                        </div>
                        <div class="flex flex-col">
                            <span
                                class="text-[9px] font-bold text-app-text/30 uppercase"
                                >Renaming Policy</span
                            >
                            <span
                                class="text-[11px] font-bold text-app-text/60"
                            >
                                {teamStore.value.team?.nameChangeCount === 0
                                    ? "First change is FREE"
                                    : "Cost: $500,000"}
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Career Stats -->
            <div
                class="bg-app-surface border border-app-border rounded-2xl p-6"
            >
                <div class="flex items-center gap-2 mb-6">
                    <Trophy size={16} class="text-app-primary" />
                    <h3
                        class="text-xs font-black uppercase text-app-text tracking-widest"
                    >
                        Career Stats
                    </h3>
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <div
                        class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30"
                    >
                        <span
                            class="text-[9px] font-bold text-app-text/30 uppercase block mb-1"
                            >Titles</span
                        >
                        <span
                            class="text-2xl font-black text-app-primary italic"
                            >{teamStats.titles}</span
                        >
                    </div>
                    <div
                        class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30"
                    >
                        <span
                            class="text-[9px] font-bold text-app-text/30 uppercase block mb-1"
                            >Wins</span
                        >
                        <span class="text-2xl font-black text-app-text italic"
                            >{teamStats.wins}</span
                        >
                    </div>
                    <div
                        class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30"
                    >
                        <span
                            class="text-[9px] font-bold text-app-text/30 uppercase block mb-1"
                            >Podiums</span
                        >
                        <span class="text-2xl font-black text-app-text italic"
                            >{teamStats.podiums}</span
                        >
                    </div>
                    <div
                        class="p-4 bg-app-text/5 rounded-2xl border border-app-border/30"
                    >
                        <span
                            class="text-[9px] font-bold text-app-text/30 uppercase block mb-1"
                            >Races</span
                        >
                        <span
                            class="text-2xl font-black text-app-text/20 italic"
                            >{teamStats.races}</span
                        >
                    </div>
                </div>
            </div>

            <div
                class="bg-app-surface border border-app-border rounded-2xl overflow-hidden relative group shadow-lg"
            >
                <div class="p-6 border-b border-app-border bg-app-text/5 flex items-center justify-between">
                    <div class="flex items-center gap-4">
                        <div
                            class="w-16 h-16 rounded-2xl bg-app-primary text-app-primary-foreground border-4 border-app-primary/20 flex items-center justify-center font-heading font-black text-2xl italic shadow-inner shrink-0"
                        >
                            {managerStore.profile?.firstName?.[0] || "M"}
                        </div>
                        <div class="flex flex-col gap-1 min-w-0">
                            <h4 class="text-xl font-black text-app-text uppercase tracking-tighter italic truncate leading-none">
                                {managerStore.profile?.firstName} {managerStore.profile?.lastName}
                            </h4>
                            <div class="flex flex-wrap items-center gap-2">
                                <span class="text-[9px] font-black text-app-primary border border-app-primary/30 uppercase tracking-widest px-2 py-0.5 bg-app-primary/10 rounded">
                                    {managerRole?.title || managerStore.profile?.role || "Manager"}
                                </span>
                                {#if managerAge}
                                    <span class="text-[9px] font-bold text-app-text/40 uppercase bg-white/5 px-2 py-0.5 rounded border border-white/5">
                                        {managerAge} Years
                                    </span>
                                {/if}
                                {#if managerStore.profile?.nationality}
                                    <div class="flex items-center gap-1.5 px-2 py-0.5 bg-white/5 rounded border border-white/5">
                                        <img 
                                            src="https://flagcdn.com/w20/{managerStore.profile.nationality.toLowerCase()}.png" 
                                            alt={managerStore.profile.nationality}
                                            class="w-3.5 h-2.5 object-cover rounded-[1px]"
                                            onerror={(e) => (e.currentTarget as HTMLImageElement).style.display = 'none'}
                                        />
                                        <span class="text-[9px] font-bold text-app-text/60 uppercase">
                                            {managerStore.profile.nationality}
                                        </span>
                                    </div>
                                {/if}
                            </div>
                        </div>
                    </div>
                </div>

                <div class="p-6 space-y-6">
                    <!-- Background Benefits & Drawbacks -->
                    <div class="space-y-4">
                        <div class="flex items-center justify-between">
                            <h5 class="text-[10px] font-black text-app-text/30 uppercase tracking-[0.2em]">Management Edge</h5>
                            <span class="text-[10px] font-black text-app-primary/40 uppercase italic">{managerRole?.title}</span>
                        </div>
                        
                        <div class="grid grid-cols-1 gap-3">
                            {#if managerRole?.pros}
                                {#each managerRole.pros as pro}
                                    <div class="flex items-start gap-2.5 group/pro">
                                        <div class="mt-0.5 p-0.5 bg-emerald-500/20 rounded border border-emerald-500/30">
                                            <CheckCircle size={10} class="text-emerald-400" />
                                        </div>
                                        <span class="text-[11px] font-bold text-app-text/80 leading-tight group-hover/pro:text-app-text transition-colors">{pro}</span>
                                    </div>
                                {/each}
                            {/if}
                            {#if managerRole?.cons}
                                {#each managerRole.cons as con}
                                    <div class="flex items-start gap-2.5 group/con">
                                        <div class="mt-0.5 p-0.5 bg-red-500/20 rounded border border-red-500/30">
                                            <AlertTriangle size={10} class="text-red-400" />
                                        </div>
                                        <span class="text-[11px] font-bold text-app-text/40 leading-tight group-hover/con:text-app-text/60 transition-colors uppercase italic">{con}</span>
                                    </div>
                                {/each}
                            {/if}
                        </div>
                    </div>

                    <!-- Market Presence & Reputation -->
                    <div class="pt-6 border-t border-app-border/40 grid grid-cols-2 gap-4">
                        <div class="bg-white/[0.02] border border-app-border/40 rounded-2xl p-4 flex flex-col gap-1">
                            <span class="text-[8px] font-bold text-app-text/20 uppercase tracking-widest">Global Ranking</span>
                            <span class="text-sm font-black text-app-text uppercase tracking-tight italic">
                                {managerStore.profile?.reputation && managerStore.profile.reputation > 80 ? "Elite Executive" : "Regional Lead"}
                            </span>
                        </div>
                        <div class="bg-white/[0.02] border border-app-border/40 rounded-2xl p-4 flex flex-col gap-1">
                            <span class="text-[8px] font-bold text-app-text/20 uppercase tracking-widest">Reputation</span>
                            <div class="flex items-center justify-between">
                                <span class="text-xl font-black text-app-text font-mono tracking-tighter">{managerStore.profile?.reputation || 50}</span>
                                <Trophy size={14} class="text-yellow-400 opacity-50" />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right Column: Communications & Debrief -->
        <div class="lg:col-span-8 space-y-8">
            <!-- Race Debrief Card -->
            {#if teamStore.value.team?.lastRaceDebrief}
                <div
                    class="bg-gradient-to-br from-app-surface to-black border-l-4 border-app-primary border-t border-r border-b border-app-border rounded-2xl p-6 shadow-2xl"
                >
                    <div class="flex items-center gap-3 mb-6">
                        <div class="p-2 bg-app-primary text-app-primary-foreground rounded-lg">
                            <BarChart3 size={18} />
                        </div>
                        <h3
                            class="text-sm font-black uppercase text-app-text tracking-widest"
                        >
                            Last Race Debrief
                        </h3>
                        <span
                            class="ml-auto text-[10px] font-bold text-app-text/30 uppercase bg-app-text/5 px-2 py-1 rounded"
                            >Official Report</span
                        >
                    </div>

                    {#if teamStore.value.team?.lastRaceResult}
                        <div
                            class="bg-app-text/40 border border-app-border/50 rounded-xl p-4 mb-6 font-mono text-[12px] text-app-text/70 leading-relaxed"
                        >
                            {teamStore.value.team.lastRaceResult}
                        </div>
                    {/if}

                    <p
                        class="text-[14px] text-app-text/80 leading-relaxed font-medium pl-2"
                    >
                        {teamStore.value.team.lastRaceDebrief}
                    </p>
                </div>
            {/if}

            <!-- Communications Center -->
            <div class="space-y-4">
                <div class="flex items-center justify-between px-2">
                    <div class="flex items-center gap-2">
                        <Mail size={16} class="text-app-primary" />
                        <h3
                            class="text-xs font-black uppercase text-app-text tracking-[0.2em]"
                        >
                            Official Communications
                        </h3>
                    </div>
                    <button
                        onclick={handleSync}
                        disabled={isSyncing}
                        class="flex items-center gap-2 px-3 py-1.5 bg-app-primary/10 border border-app-primary/20 rounded-full text-[10px] font-black text-app-primary uppercase hover:bg-app-primary/20 transition-all disabled:opacity-50"
                    >
                        <RefreshCw
                            size={12}
                            class={isSyncing ? "animate-spin" : ""}
                        />
                        {isSyncing ? "Synchronizing..." : "Sincronizar"}
                    </button>
                </div>

                <div class="space-y-3">
                    {#if news.length === 0}
                        <div
                            class="p-12 text-center bg-app-surface border border-app-border border-dashed rounded-2xl text-app-text/20"
                        >
                            <Mail size={32} class="mx-auto mb-4 opacity-50" />
                            <p
                                class="text-[10px] font-black uppercase tracking-widest"
                            >
                                No communications received
                            </p>
                        </div>
                    {:else}
                        {#each news as item}
                            <div
                                class="bg-app-surface border border-app-border rounded-2xl p-6 hover:border-app-primary/30 transition-all group shadow-sm"
                            >
                                <div
                                    class="flex justify-between items-start mb-3"
                                >
                                    <h4
                                        class="font-black text-app-text uppercase group-hover:text-app-primary transition-colors"
                                    >
                                        {item.title}
                                    </h4>
                                    <span
                                        class="text-[10px] font-mono text-app-text/20"
                                        >{formatDate(item.timestamp)}</span
                                    >
                                </div>
                                <p
                                    class="text-[13px] text-app-text/60 leading-relaxed"
                                >
                                    {item.message}
                                </p>
                            </div>
                        {/each}
                    {/if}
                </div>
            </div>
        </div>
    </div>
</div>

<style>
    :global(.animate-spin) {
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
