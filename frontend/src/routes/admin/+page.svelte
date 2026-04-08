<script lang="ts">
    import { authStore } from "$lib/stores/auth.svelte";
    import { APP_VERSION } from "$lib/constants/app_constants";
    import { functions } from "$lib/firebase/config";
    import { httpsCallable } from "firebase/functions";
    import { goto } from "$app/navigation";
    import {
        Shield,
        Database,
        Zap,
        TrendingUp,
        BookOpen,
        LogOut,
        RefreshCw,
        History,
        Lock,
        ChevronRight,
        Activity,
        Loader
    } from "lucide-svelte";
    import { fade, fly } from "svelte/transition";
    import ConfirmModal from "$lib/components/admin/ConfirmModal.svelte";
    import { enhance } from "$app/forms";
    import { uiStore } from "$lib/stores/ui.svelte";
    import type { AdminPreflightResult } from "$lib/services/admin.svelte";

    let { form } = $props();

    let password = $state("");
    let isAuthenticated = $state(false);
    let error = $state("");
    let processingAction = $state<string | null>(null);
    /** Action currently running its dry-run phase (spinner on card, no modal yet) */
    let runningDryRun = $state<string | null>(null);
    let activeTab = $state("simulation");

    // Modal State
    let showConfirmModal = $state(false);
    let pendingActionData = $state<{
        name: string;
        description: string;
        requireWord?: string;
        confirmText?: string;
        preflightData?: AdminPreflightResult | null;
    }>({
        name: "",
        description: ""
    });

    $effect(() => {
        if (form?.success) {
            isAuthenticated = true;
            error = "";
        } else if (form?.error) {
            error = form.error;
            password = "";
        }
    });

    /**
     * Tools that require a two-phase dry-run → confirm flow before executing writes.
     * Each entry maps the action name to a flag: true = supports dryRun parameter.
     */
    const DRY_RUN_TOOLS = new Set([
        "resetQualifyingSession",
        "applyGreatRebalanceTax",
        "fixBrokenAcademies",
        "restoreDriversHistory",
        "megaFixDebriefs",
    ]);

    async function triggerAction(name: string, description: string, dangerous = false) {
        if (runningDryRun || processingAction) return;

        if (DRY_RUN_TOOLS.has(name)) {
            // Phase 1: Run dry-run first to compute pre-flight summary
            runningDryRun = name;
            let preflightData: AdminPreflightResult | null = null;
            try {
                const { adminService } = await import("$lib/services/admin.svelte");

                if (name === "restoreDriversHistory" || name === "megaFixDebriefs") {
                    // CF tools — call with dryRun: true via httpsCallable
                    const func = httpsCallable(functions, name);
                    const result = await func({ dryRun: true });
                    const data = result.data as any;
                    if (data?.dryRun) {
                        preflightData = { affectedDocIds: data.affectedDocIds, summary: data.summary };
                    }
                } else {
                    // Frontend service tools
                    const method = adminService[name as keyof typeof adminService] as (dryRun: boolean) => Promise<any>;
                    const result = await method.call(adminService, true);
                    if (result && 'affectedDocIds' in result) {
                        preflightData = result as AdminPreflightResult;
                    }
                }
            } catch (e: any) {
                console.error(`[Admin:dryRun:${name}] Failed:`, e.message || e);
                uiStore.alert(e.message, 'Dry-Run Error', 'danger');
                runningDryRun = null;
                return;
            } finally {
                runningDryRun = null;
            }

            // Phase 2: Show modal with pre-flight data
            pendingActionData = {
                name,
                description,
                requireWord: "CONFIRM",
                confirmText: "Execute",
                preflightData
            };
            showConfirmModal = true;
            return;
        }

        if (dangerous) {
            pendingActionData = {
                name,
                description,
                requireWord: "CONFIRM",
                confirmText: "Execute Action"
            };
            showConfirmModal = true;
        } else {
            runAction(name, description);
        }
    }

    async function runAction(name: string, description: string) {
        if (processingAction) return;

        processingAction = name;
        try {
            if (
                name === "fixRaceCalendars" ||
                name === "generate_market_drivers" ||
                name === "resetQualifyingSession" ||
                name === "applyGreatRebalanceTax" ||
                name === "fixBrokenAcademies"
            ) {
                const { adminService } = await import("$lib/services/admin.svelte");
                const methodName = name === "generate_market_drivers" ? "generateMarketDrivers" : name;
                const method = adminService[methodName as keyof typeof adminService] as (dryRun: boolean) => Promise<any>;
                const result = await method.call(adminService, false);

                if (result && typeof result === 'object' && 'count' in result) {
                    uiStore.alert(`Success: ${name} executed. Fixed ${(result as any).count} academies.`, 'Success', 'success');
                    return;
                }
                if (result && typeof result === 'object' && 'driversFixed' in result) {
                    uiStore.alert(`Qualifying reset complete. ${(result as any).driversFixed} drivers across ${(result as any).teamsFixed} teams. Entry fees refunded. Run Force Qualifying to regenerate the grid.`, 'Success', 'success');
                    return;
                }
            } else {
                const func = httpsCallable(functions, name);
                await func({ dryRun: false });
            }
            uiStore.alert(`Success: ${name} executed.`, 'Success', 'success');
        } catch (e: any) {
            console.error('[Admin:runAction] Failed:', e.message || 'Unknown error');
            uiStore.alert(e.message, 'Error', 'danger');
        } finally {
            processingAction = null;
        }
    }

    const tabs = [
        { id: "simulation", label: "Simulation", icon: Activity },
        { id: "database", label: "Database", icon: Database },
        { id: "economy", label: "Economy", icon: TrendingUp },
        { id: "docs", label: "Documentation", icon: BookOpen },
    ];

    $effect(() => {
        if (!authStore.loading && !authStore.isAdmin) {
            goto("/");
        }
    });

    function navigateToDocs() {
        goto("/admin/docs");
    }
</script>

<svelte:head>
    <title>Admin Terminal | FTG</title>
</svelte:head>

<div class="admin-wrapper bg-app-bg min-h-screen text-app-text font-sans">
    {#if !isAuthenticated}
        <div class="auth-layer fixed inset-0 flex items-center justify-center p-6 bg-black/60 backdrop-blur-xl z-50">
            <div class="auth-card p-10 bg-app-surface border border-app-border rounded-[2.5rem] w-full max-w-sm shadow-2xl relative overflow-hidden" in:fly={{ y: 20, duration: 400 }}>
                <div class="absolute -top-24 -right-24 w-48 h-48 bg-app-primary/10 blur-3xl rounded-full"></div>

                <div class="flex flex-col items-center text-center gap-6 relative z-10">
                    <div class="p-4 rounded-3xl bg-app-primary/10 text-app-primary">
                        <Lock size={32} />
                    </div>
                    <div>
                        <h1 class="text-2xl font-heading font-black tracking-tighter uppercase italic">Secure Login</h1>
                        <p class="text-[10px] font-black uppercase tracking-widest text-app-text/40 mt-1">Authorized Personnel Only</p>
                    </div>

                    <form
                        method="POST"
                        action="?/login"
                        use:enhance
                        class="w-full flex flex-col gap-4"
                    >
                        <div class="flex flex-col gap-2 text-left">
                            <label for="pwd" class="text-[9px] font-black uppercase tracking-[0.2em] text-app-text/20 ml-2">Security Key</label>
                            <input
                                id="pwd"
                                name="password"
                                type="password"
                                bind:value={password}
                                placeholder="••••••••••••"
                                class="w-full bg-black/40 border border-app-border rounded-2xl p-4 text-center text-app-primary font-mono outline-none focus:border-app-primary/40 transition-all placeholder:text-app-text/10"
                            />
                            {#if error}
                                <span class="text-[9px] text-red-500 font-black uppercase text-center mt-1 animate-pulse">{error}</span>
                            {/if}
                        </div>

                        <button
                            type="submit"
                            class="w-full p-4 rounded-2xl bg-app-primary text-black font-black uppercase text-[10px] tracking-widest hover:scale-[1.02] active:scale-95 transition-all shadow-lg shadow-app-primary/10"
                        >
                            Authenticate
                        </button>
                    </form>
                </div>
            </div>
        </div>
    {:else}
        <div class="admin-layout flex flex-col lg:flex-row min-h-screen">
            <!-- Sidebar -->
            <aside class="w-full lg:w-80 border-b lg:border-b-0 lg:border-r border-app-border bg-app-surface/40 backdrop-blur-md p-8 flex flex-col gap-10">
                <div class="flex items-center gap-3">
                    <div class="p-2 rounded-xl bg-app-primary/10 text-app-primary">
                        <Shield size={20} />
                    </div>
                    <div class="flex flex-col">
                        <span class="text-sm font-heading font-black uppercase italic tracking-tighter">FTG Terminal</span>
                        <span class="text-[8px] font-black uppercase tracking-widest text-app-text/30">{APP_VERSION}</span>
                    </div>
                </div>

                <nav class="flex flex-col gap-2">
                    <span class="text-[9px] font-black uppercase tracking-[0.25em] text-app-text/20 mb-2 ml-2">Management</span>
                    {#each tabs as tab}
                        <button
                            onclick={() => activeTab = tab.id}
                            class="flex items-center gap-4 p-4 rounded-2xl transition-all group {activeTab === tab.id ? 'bg-app-primary text-black shadow-lg shadow-app-primary/10' : 'text-app-text/40 hover:bg-app-text/5 hover:text-app-text'}"
                        >
                            <tab.icon size={18} class={activeTab === tab.id ? 'opacity-100' : 'opacity-40 group-hover:opacity-100'} />
                            <span class="text-[10px] font-black uppercase tracking-widest">{tab.label}</span>
                        </button>
                    {/each}
                </nav>

                <div class="mt-auto pt-8 border-t border-app-border/40 flex flex-col gap-4">
                    <div class="p-4 rounded-2xl bg-black/40 border border-app-border flex items-center gap-3">
                        <div class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                        <span class="text-[9px] font-black uppercase tracking-widest text-app-text/60">System Online</span>
                    </div>
                    <button
                        onclick={() => (isAuthenticated = false)}
                        class="flex items-center gap-3 p-4 rounded-2xl text-[10px] font-black uppercase tracking-widest text-red-500/60 hover:text-red-500 hover:bg-red-500/5 transition-all"
                    >
                        <LogOut size={16} />
                        Logout Session
                    </button>
                </div>
            </aside>

            <!-- Main Content -->
            <main class="flex-1 p-8 md:p-12 overflow-y-auto">
                <div class="max-w-5xl mx-auto flex flex-col gap-12" in:fade={{ duration: 400 }}>
                    <header class="flex flex-col gap-2">
                        <h2 class="text-4xl font-heading font-black tracking-tighter uppercase italic text-app-text">
                            System <span class="text-app-primary">{tabs.find(t => t.id === activeTab)?.label}</span>
                        </h2>
                        <p class="text-[11px] font-black uppercase tracking-widest text-app-text/40">Administrative Command Center</p>
                    </header>

                    {#if activeTab === 'simulation'}
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6" in:fly={{ y: 20 }}>
                            <button
                                class="action-card group"
                                onclick={() => triggerAction("forceQualy", "Trigger Qualifying simulation for all active leagues", true)}
                                disabled={!!processingAction || !!runningDryRun}
                            >
                                <div class="card-icon bg-amber-500/10 text-amber-500"><Zap size={24} /></div>
                                <div class="card-body">
                                    <h3>Force Qualifying</h3>
                                    <p>Manually trigger the qualifying engine for the current event.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
                            </button>

                            <button
                                class="action-card group"
                                onclick={() => triggerAction("forceRace", "Trigger Race simulation for all active leagues", true)}
                                disabled={!!processingAction || !!runningDryRun}
                            >
                                <div class="card-icon bg-emerald-500/10 text-emerald-500"><Activity size={24} /></div>
                                <div class="card-body">
                                    <h3>Force Race</h3>
                                    <p>Execute the full race simulation logic for all divisions.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
                            </button>

                            <button
                                class="action-card group"
                                onclick={() => triggerAction("syncUniverseCallable", "Sync the universe standings document from live teams and drivers data.")}
                                disabled={!!processingAction || !!runningDryRun}
                            >
                                <div class="card-icon bg-blue-500/10 text-blue-500">
                                    {#if processingAction === 'syncUniverseCallable'}
                                        <Loader size={24} class="animate-spin" />
                                    {:else}
                                        <RefreshCw size={24} />
                                    {/if}
                                </div>
                                <div class="card-body">
                                    <h3>Sync Universe</h3>
                                    <p>Refresh standings from live data. Use when Standings page shows stale results after a race.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
                            </button>
                        </div>
                    {:else if activeTab === 'database'}
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6" in:fly={{ y: 20 }}>
                            <button
                                class="action-card group"
                                onclick={() => triggerAction("fixBrokenAcademies", "Identify and repair academies with no candidates.")}
                                disabled={!!processingAction || !!runningDryRun}
                            >
                                <div class="card-icon bg-amber-500/10 text-amber-500">
                                    {#if runningDryRun === 'fixBrokenAcademies' || processingAction === 'fixBrokenAcademies'}
                                        <Loader size={24} class="animate-spin" />
                                    {:else}
                                        <Zap size={24} />
                                    {/if}
                                </div>
                                <div class="card-body">
                                    <h3>Fix Broken Academies</h3>
                                    <p>Scan all teams and generate missing candidates for established academies.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100" />
                            </button>

                            <button
                                class="action-card group dangerous"
                                onclick={() => triggerAction("resetQualifyingSession", "Reset all qualifying data for human teams. Refunds entry fees and clears qualyGrid so Force Qualifying can re-run.")}
                                disabled={!!processingAction || !!runningDryRun}
                            >
                                <div class="card-icon bg-orange-500/10 text-orange-500">
                                    {#if runningDryRun === 'resetQualifyingSession' || processingAction === 'resetQualifyingSession'}
                                        <Loader size={24} class="animate-spin" />
                                    {:else}
                                        <RefreshCw size={24} />
                                    {/if}
                                </div>
                                <div class="card-body">
                                    <h3>Reset Qualifying Session</h3>
                                    <p class="text-orange-500/60 font-medium">Clears all human qualifying data and refunds entry fees. Run Force Qualifying after.</p>
                                </div>
                                <ChevronRight class="opacity-20 group-hover:opacity-100" />
                            </button>

                            <button
                                class="action-card group"
                                onclick={() => triggerAction("fixRaceCalendars", "Sync all league schedule arrays with the master circuit config.")}
                                disabled={!!processingAction || !!runningDryRun}
                            >
                                <div class="card-icon bg-blue-500/10 text-blue-500"><RefreshCw size={24} /></div>
                                <div class="card-body">
                                    <h3>Fix Calendars</h3>
                                    <p>Sychronize league events with global configuration.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100" />
                            </button>

                            <button
                                class="action-card group"
                                onclick={() => triggerAction("restoreDriversHistory", "Regenerate synthetic career history for all active drivers.")}
                                disabled={!!processingAction || !!runningDryRun}
                            >
                                <div class="card-icon bg-purple-500/10 text-purple-500">
                                    {#if runningDryRun === 'restoreDriversHistory' || processingAction === 'restoreDriversHistory'}
                                        <Loader size={24} class="animate-spin" />
                                    {:else}
                                        <History size={24} />
                                    {/if}
                                </div>
                                <div class="card-body">
                                    <h3>Restore Driver Stats</h3>
                                    <p>Fix legacy data issues in the drivers collection.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100" />
                            </button>
                        </div>
                    {:else if activeTab === 'economy'}
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6" in:fly={{ y: 20 }}>
                            <button
                                class="action-card group dangerous"
                                onclick={() => triggerAction("applyGreatRebalanceTax", "Execute a massive economy rebalance across all teams.")}
                                disabled={!!processingAction || !!runningDryRun}
                            >
                                <div class="card-icon bg-red-500/10 text-red-500">
                                    {#if runningDryRun === 'applyGreatRebalanceTax' || processingAction === 'applyGreatRebalanceTax'}
                                        <Loader size={24} class="animate-spin" />
                                    {:else}
                                        <TrendingUp size={24} />
                                    {/if}
                                </div>
                                <div class="card-body">
                                    <h3>Rebalance Tax</h3>
                                    <p>Apply global tax to equalize team budgets.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100" />
                            </button>

                            <button
                                class="action-card group"
                                onclick={() => triggerAction("generate_market_drivers", "Force the generation of 20+ new market drivers.")}
                                disabled={!!processingAction || !!runningDryRun}
                            >
                                <div class="card-icon bg-emerald-500/10 text-emerald-500"><RefreshCw size={24} /></div>
                                <div class="card-body">
                                    <h3>Market Refresh</h3>
                                    <p>Force inject new candidates into the transfer market.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100" />
                            </button>
                        </div>
                    {:else if activeTab === 'docs'}
                        <div class="flex flex-col items-center justify-center py-20 bg-black/20 rounded-[3rem] border border-app-border/40 gap-8">
                            <div class="p-6 rounded-full bg-app-primary/5 text-app-primary border border-app-primary/10">
                                <BookOpen size={48} />
                            </div>
                            <div class="text-center">
                                <h3 class="text-2xl font-black uppercase italic tracking-tighter">Documentation Hub</h3>
                                <p class="text-app-text/40 text-sm mt-2 max-w-sm mx-auto">Access internal architectural blueprints, business rules, and technical standards.</p>
                            </div>
                            <button
                                onclick={navigateToDocs}
                                class="px-8 py-4 rounded-2xl bg-app-primary text-black font-black uppercase text-[11px] tracking-widest hover:scale-105 transition-all shadow-xl shadow-app-primary/10 flex items-center gap-3"
                            >
                                Open Documentation Base
                                <ChevronRight size={16} />
                            </button>
                        </div>
                    {/if}
                </div>
            </main>
        </div>
    {/if}
</div>

<ConfirmModal
    bind:show={showConfirmModal}
    title={pendingActionData.name === "nukeAndReseed" ? "☢️ SYSTEM RESET" : "Confirm Action"}
    description={pendingActionData.description}
    requireWord={pendingActionData.requireWord}
    confirmText={pendingActionData.confirmText || "Execute"}
    preflightData={pendingActionData.preflightData ?? null}
    onConfirm={() => runAction(pendingActionData.name, pendingActionData.description)}
/>

<style>
    .font-heading {
        font-family: "Outfit", sans-serif;
    }

    .action-card {
        display: flex;
        align-items: center;
        gap: 1.5rem;
        padding: 2rem;
        background: var(--surface-color);
        border: 1px solid var(--border-color);
        border-radius: 2rem;
        text-align: left;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        cursor: pointer;
    }

    .action-card:disabled {
        opacity: 0.5;
        cursor: not-allowed;
        transform: none !important;
    }

    .action-card:not(:disabled):hover {
        background: var(--bg-color);
        border-color: var(--app-primary);
        transform: translateY(-4px);
    }

    .action-card.dangerous:not(:disabled):hover {
        border-color: var(--error-color);
        box-shadow: 0 10px 30px rgba(255, 68, 68, 0.05);
    }

    .card-icon {
        width: 64px;
        height: 64px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 1.25rem;
        flex-shrink: 0;
    }

    .card-body {
        flex: 1;
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
    }

    .card-body h3 {
        font-size: 1.1rem;
        font-weight: 800;
        text-transform: uppercase;
        letter-spacing: -0.5px;
    }

    .card-body p {
        font-size: 0.8rem;
        color: var(--text-muted);
        line-height: 1.4;
    }

    :global(.lucide) {
        stroke-width: 2.5px;
    }
</style>
