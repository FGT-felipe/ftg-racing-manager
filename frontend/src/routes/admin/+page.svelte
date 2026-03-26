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
        AlertOctagon, 
        RefreshCw, 
        History,
        Lock,
        ChevronRight,
        Activity
    } from "lucide-svelte";
    import { fade, fly } from "svelte/transition";
    import ConfirmModal from "$lib/components/admin/ConfirmModal.svelte";
    import { enhance } from "$app/forms";
    import { uiStore } from "$lib/stores/ui.svelte";

    let { form } = $props();

    let password = $state("");
    let isAuthenticated = $state(false);
    let error = $state("");
    let processingAction = $state<string | null>(null);
    let activeTab = $state("simulation");

    // Modal State
    let showConfirmModal = $state(false);
    let pendingActionData = $state<{ name: string, description: string, requireWord?: string, confirmText?: string }>({
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

    function triggerAction(name: string, description: string, dangerous = false) {
        if (dangerous) {
            pendingActionData = { 
                name, 
                description, 
                requireWord: name === "nukeAndReseed" ? "NUKE" : "CONFIRM",
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
                name === "nukeAndReseed" ||
                name === "fixRaceCalendars" ||
                name === "applyGreatRebalanceTax" ||
                name === "fixBrokenAcademies" ||
                name === "generate_market_drivers" ||
                name === "resetQualifyingSession"
            ) {
                const { adminService } = await import("$lib/services/admin.svelte");
                const methodName = name === "generate_market_drivers" ? "generateMarketDrivers" : name;
                const result = await adminService[methodName as keyof typeof adminService]();
                if (result && typeof result === 'object' && 'count' in result) {
                    uiStore.alert(`Success: ${name} executed. Fixed ${result.count} academies.`, 'Success', 'success');
                    return;
                }
                if (result && typeof result === 'object' && 'driversFixed' in result) {
                    uiStore.alert(`Qualifying reset complete. ${result.driversFixed} drivers across ${result.teamsFixed} teams. Entry fees refunded. Run Force Qualifying to regenerate the grid.`, 'Success', 'success');
                    return;
                }
            } else {
                const func = httpsCallable(functions, name);
                await func();
            }
            uiStore.alert(`Success: ${name} executed.`, 'Success', 'success');
        } catch (e: any) {
            console.error('Admin action failed:', e.message || 'Unknown error');
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
                            >
                                <div class="card-icon bg-emerald-500/10 text-emerald-500"><Activity size={24} /></div>
                                <div class="card-body">
                                    <h3>Force Race</h3>
                                    <p>Execute the full race simulation logic for all divisions.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100 group-hover:translate-x-1 transition-all" />
                            </button>
                        </div>
                    {:else if activeTab === 'database'}
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6" in:fly={{ y: 20 }}>
                            <button 
                                class="action-card group"
                                onclick={() => triggerAction("fixBrokenAcademies", "Identify and repair academies with no candidates.")}
                            >
                                <div class="card-icon bg-amber-500/10 text-amber-500"><Zap size={24} /></div>
                                <div class="card-body">
                                    <h3>Fix Broken Academies</h3>
                                    <p>Scan all teams and generate missing candidates for established academies.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100" />
                            </button>

                            <button
                                class="action-card group dangerous"
                                onclick={() => triggerAction("resetQualifyingSession", "Reset all qualifying data for human teams. Refunds entry fees and clears qualyGrid so Force Qualifying can re-run.", true)}
                            >
                                <div class="card-icon bg-orange-500/10 text-orange-500"><RefreshCw size={24} /></div>
                                <div class="card-body">
                                    <h3>Reset Qualifying Session</h3>
                                    <p class="text-orange-500/60 font-medium">Clears all human qualifying data and refunds entry fees. Run Force Qualifying after.</p>
                                </div>
                                <ChevronRight class="opacity-20 group-hover:opacity-100" />
                            </button>

                            <button
                                class="action-card group dangerous"
                                onclick={() => triggerAction("nukeAndReseed", "DANGEROUS: Wipes ALL collections and recreates the simulation state.", true)}
                            >
                                <div class="card-icon bg-red-500/10 text-red-500"><AlertOctagon size={24} /></div>
                                <div class="card-body">
                                    <h3>Nuke & Reseed</h3>
                                    <p class="text-red-500/60 font-medium">Critical: Irreversible database reset.</p>
                                </div>
                                <ChevronRight class="opacity-20 group-hover:opacity-100" />
                            </button>

                            <button 
                                class="action-card group"
                                onclick={() => triggerAction("fixRaceCalendars", "Sync all league schedule arrays with the master circuit config.")}
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
                                onclick={() => triggerAction("restoreDriversHistory", "Clean up career history and fix 'F1 Team' naming issues.", true)}
                            >
                                <div class="card-icon bg-purple-500/10 text-purple-500"><History size={24} /></div>
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
                                onclick={() => triggerAction("applyGreatRebalanceTax", "Execute a massive economy rebalance across all teams.", true)}
                            >
                                <div class="card-icon bg-red-500/10 text-red-500"><TrendingUp size={24} /></div>
                                <div class="card-body">
                                    <h3>Rebalance Tax</h3>
                                    <p>Apply global tax to equalize team budgets.</p>
                                </div>
                                <ChevronRight class="opacity-10 group-hover:opacity-100" />
                            </button>

                            <button 
                                class="action-card group"
                                onclick={() => triggerAction("generate_market_drivers", "Force the generation of 20+ new market drivers.")}
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

    .action-card:hover {
        background: var(--bg-color);
        border-color: var(--app-primary);
        transform: translateY(-4px);
    }

    .action-card.dangerous:hover {
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

    /* Override for lucide icons inside buttons if needed */
    :global(.lucide) {
        stroke-width: 2.5px;
    }
</style>
