<script lang="ts">
    import { authStore } from "$lib/stores/auth.svelte";
    import { functions } from "$lib/firebase/config";
    import { httpsCallable } from "firebase/functions";
    import { goto } from "$app/navigation";

    let password = $state("");
    let isAuthenticated = $state(false);
    let error = $state("");
    let processingAction = $state<string | null>(null);

    const ADMIN_PASSWORD = "ftgadmin2026";

    async function handleLogin() {
        if (password === ADMIN_PASSWORD) {
            isAuthenticated = true;
            error = "";
        } else {
            error = "Invalid Admin Password";
            password = "";
        }
    }

    async function runAction(name: string, description: string) {
        if (processingAction) return;

        const confirm = window.confirm(
            `Are you sure you want to execute: ${description}?`,
        );
        if (!confirm) return;

        processingAction = name;
        try {
            if (
                name === "nukeAndReseed" ||
                name === "fixRaceCalendars" ||
                name === "applyGreatRebalanceTax"
            ) {
                const { adminService } = await import(
                    "$lib/services/admin.svelte"
                );
                await adminService[name]();
            } else {
                const func = httpsCallable(functions, name);
                await func();
            }
            alert(`Success: ${name} executed.`);
        } catch (e: any) {
            console.error(`Error executing ${name}:`, e);
            alert(`Error: ${e.message}`);
        } finally {
            processingAction = null;
        }
    }

    async function runCommandAction(type: string, description: string) {
        if (processingAction) return;

        const confirm = window.confirm(
            `Are you sure you want to trigger: ${description}?`,
        );
        if (!confirm) return;

        processingAction = type;
        try {
            const { db } = await import("$lib/firebase/config");
            const { collection, addDoc, serverTimestamp } = await import(
                "firebase/firestore"
            );
            await addDoc(collection(db, "commands"), {
                type,
                timestamp: serverTimestamp(),
                executed: false,
            });
            alert(`Triggered: ${type} command added.`);
        } catch (e: any) {
            console.error(`Error triggering ${type}:`, e);
            alert(`Error: ${e.message}`);
        } finally {
            processingAction = null;
        }
    }

    $effect(() => {
        if (!authStore.loading && !authStore.isAdmin) {
            goto("/");
        }
    });
</script>

<svelte:head>
    <title>Admin Panel | FTG Racing Manager</title>
</svelte:head>

<div class="admin-container">
    {#if !isAuthenticated}
        <div class="auth-card glass-panel">
            <div class="header">
                <span class="icon">🔐</span>
                <h1>Admin Access</h1>
                <p>Enter the security key to continue</p>
            </div>

            <div class="input-group">
                <input
                    type="password"
                    bind:value={password}
                    placeholder="Enter security key..."
                    onkeydown={(e) => e.key === "Enter" && handleLogin()}
                />
                {#if error}
                    <span class="error-msg">{error}</span>
                {/if}
            </div>

            <button class="primary-btn" onclick={handleLogin}>
                Authenticate
            </button>
        </div>
    {:else}
        <div class="admin-panel glass-panel">
            <header class="panel-header">
                <div class="title-group">
                    <h1>System Administration</h1>
                    <span class="badge admin">Superuser</span>
                </div>
                <button
                    class="ghost-btn"
                    onclick={() => (isAuthenticated = false)}
                >
                    Lock Session
                </button>
            </header>

            <div class="admin-grid">
                <!-- Simulation Controls -->
                <section class="admin-section">
                    <h2>Simulation Engine</h2>
                    <div class="actions">
                        <button
                            class="action-btn warning"
                            disabled={!!processingAction}
                            onclick={() =>
                                runAction(
                                    "forceQualy",
                                    "Force Qualifying simulation for all active leagues",
                                )}
                        >
                            <span class="icon"
                                >{processingAction === "forceQualy"
                                    ? "⌛"
                                    : "⚡"}</span
                            >
                            <div class="label">
                                <strong>Force Qualy</strong>
                                <small
                                    >{processingAction === "forceQualy"
                                        ? "Simulation in progress..."
                                        : "Triggers qualifying simulation"}</small
                                >
                            </div>
                        </button>
                        <button
                            class="action-btn warning"
                            disabled={!!processingAction}
                            onclick={() =>
                                runAction(
                                    "forceRace",
                                    "Force Race simulation for all active leagues",
                                )}
                        >
                            <span class="icon"
                                >{processingAction === "forceRace"
                                    ? "⌛"
                                    : "🏁"}</span
                            >
                            <div class="label">
                                <strong>Force Race</strong>
                                <small
                                    >{processingAction === "forceRace"
                                        ? "Simulation in progress..."
                                        : "Triggers race simulation"}</small
                                >
                            </div>
                        </button>
                    </div>
                </section>

                <!-- Database Operations -->
                <section class="admin-section">
                    <h2>Maintenance & Seeding</h2>
                    <div class="actions">
                        <button
                            class="action-btn danger"
                            disabled={!!processingAction}
                            onclick={() =>
                                runAction(
                                    "nukeAndReseed",
                                    "DANGEROUS: Wipe ALL data and reseed database",
                                )}
                        >
                            <span class="icon"
                                >{processingAction === "nukeAndReseed"
                                    ? "⌛"
                                    : "☢️"}</span
                            >
                            <div class="label">
                                <strong>Nuke & Reseed</strong>
                                <small>Factory reset all database data</small>
                            </div>
                        </button>
                        <button
                            class="action-btn secondary"
                            disabled={!!processingAction}
                            onclick={() =>
                                runAction(
                                    "fixRaceCalendars",
                                    "Synchronize all league calendars with master config",
                                )}
                        >
                            <span class="icon"
                                >{processingAction === "fixRaceCalendars"
                                    ? "⌛"
                                    : "🛠️"}</span
                            >
                            <div class="label">
                                <strong>Fix Race Calendars</strong>
                                <small>Sync with global master config</small>
                            </div>
                        </button>
                    </div>
                </section>

                <!-- Economy & Market -->
                <section class="admin-section">
                    <h2>Economy & Market</h2>
                    <div class="actions">
                        <button
                            class="action-btn secondary"
                            disabled={!!processingAction}
                            onclick={() =>
                                runAction(
                                    "applyGreatRebalanceTax",
                                    "Apply economic rebalance across all teams",
                                )}
                        >
                            <span class="icon"
                                >{processingAction === "applyGreatRebalanceTax"
                                    ? "⌛"
                                    : "💰"}</span
                            >
                            <div class="label">
                                <strong>Apply Rebalance Tax</strong>
                                <small>Execute economic rebalance</small>
                            </div>
                        </button>
                        <button
                            class="action-btn secondary"
                            disabled={!!processingAction}
                            onclick={() =>
                                runCommandAction(
                                    "generate_market_drivers",
                                    "Force refresh of transfer market drivers",
                                )}
                        >
                            <span class="icon"
                                >{processingAction === "generate_market_drivers"
                                    ? "⌛"
                                    : "🛒"}</span
                            >
                            <div class="label">
                                <strong>Refresh Market</strong>
                                <small
                                    >{processingAction ===
                                    "generate_market_drivers"
                                        ? "Command sent..."
                                        : "Force new drivers generation"}</small
                                >
                            </div>
                        </button>
                    </div>
                </section>
            </div>
        </div>
    {/if}
</div>

<style>
    .admin-container {
        min-height: calc(100vh - 100px);
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 2rem;
        background: var(--bg-main);
    }

    .glass-panel {
        background: rgba(255, 255, 255, 0.03);
        backdrop-filter: blur(12px);
        border: 1px solid rgba(255, 255, 255, 0.08);
        border-radius: 20px;
        box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
    }

    .auth-card {
        width: 100%;
        max-width: 400px;
        padding: 3rem;
        text-align: center;
        display: flex;
        flex-direction: column;
        gap: 2rem;
    }

    .header .icon {
        font-size: 3rem;
        margin-bottom: 1rem;
        display: block;
    }

    .header h1 {
        font-size: 1.5rem;
        font-weight: 800;
        letter-spacing: -0.5px;
        margin: 0;
    }

    .header p {
        color: var(--text-muted);
        font-size: 0.9rem;
        margin-top: 0.5rem;
    }

    .input-group {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
        text-align: left;
    }

    input {
        width: 100%;
        padding: 1rem;
        background: rgba(255, 255, 255, 0.05);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 12px;
        color: white;
        font-family: inherit;
        transition: all 0.2s ease;
    }

    input:focus {
        outline: none;
        border-color: var(--accent);
        background: rgba(255, 255, 255, 0.08);
    }

    .error-msg {
        color: #ff4444;
        font-size: 0.8rem;
        padding-left: 0.5rem;
    }

    .admin-panel {
        width: 100%;
        max-width: 1000px;
        padding: 3rem;
        display: flex;
        flex-direction: column;
        gap: 3rem;
        align-self: flex-start;
    }

    .panel-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    .title-group {
        display: flex;
        align-items: center;
        gap: 1rem;
    }

    .title-group h1 {
        font-size: 2rem;
        font-weight: 900;
        margin: 0;
        background: linear-gradient(135deg, #fff 0%, #aaa 100%);
        -webkit-background-clip: text;
        background-clip: text;
        -webkit-text-fill-color: transparent;
    }

    .badge {
        padding: 0.25rem 0.75rem;
        border-radius: 20px;
        font-size: 0.7rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 1px;
    }

    .badge.admin {
        background: rgba(0, 200, 83, 0.1);
        color: #00c853;
        border: 1px solid rgba(0, 200, 83, 0.2);
    }

    .admin-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        gap: 2rem;
    }

    .admin-section {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }

    .admin-section h2 {
        font-size: 0.8rem;
        text-transform: uppercase;
        letter-spacing: 2px;
        color: var(--text-muted);
        margin: 0;
    }

    .actions {
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }

    .action-btn {
        display: flex;
        align-items: center;
        gap: 1.25rem;
        padding: 1.25rem;
        background: rgba(255, 255, 255, 0.03);
        border: 1px solid rgba(255, 255, 255, 0.05);
        border-radius: 16px;
        color: white;
        cursor: pointer;
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        text-align: left;
    }

    .action-btn:hover {
        background: rgba(255, 255, 255, 0.06);
        border-color: rgba(255, 255, 255, 0.15);
        transform: translateY(-2px);
    }

    .action-btn .icon {
        font-size: 1.5rem;
        width: 48px;
        height: 48px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: rgba(255, 255, 255, 0.05);
        border-radius: 12px;
    }

    .action-btn.warning:hover .icon {
        background: rgba(255, 160, 0, 0.1);
        color: #ffa000;
    }
    .action-btn.danger:hover .icon {
        background: rgba(255, 68, 68, 0.1);
        color: #ff4444;
    }
    .action-btn.secondary:hover .icon {
        background: rgba(0, 200, 83, 0.1);
        color: #00c853;
    }

    .label {
        display: flex;
        flex-direction: column;
    }

    .label strong {
        font-size: 1rem;
        font-weight: 600;
    }

    .label small {
        font-size: 0.8rem;
        color: var(--text-muted);
    }

    .primary-btn {
        background: var(--accent);
        color: black;
        border: none;
        padding: 1rem;
        border-radius: 12px;
        font-weight: 700;
        cursor: pointer;
        transition: transform 0.2s ease;
    }

    .primary-btn:hover {
        transform: scale(1.02);
    }

    .ghost-btn {
        background: transparent;
        border: 1px solid rgba(255, 255, 255, 0.1);
        color: var(--text-muted);
        padding: 0.6rem 1.2rem;
        border-radius: 10px;
        font-size: 0.8rem;
        cursor: pointer;
    }

    .ghost-btn:hover {
        background: rgba(255, 255, 255, 0.05);
        color: white;
    }
</style>
