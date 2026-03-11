<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { authStore } from "$lib/stores/auth.svelte";
    import { Loader2 } from "lucide-svelte";

    let teamName = $state("");
    let isCreating = $state(false);
    let errorMsg = $state<string | null>(null);

    async function handleCreateTeam() {
        if (!teamName) return;
        isCreating = true;
        errorMsg = null;
        try {
            // TODO: Implement actual team creation logic in teamStore
            // For now, this is a placeholder.
            // await teamStore.createTeam(teamName, authStore.user.uid);
            console.log("Creating team:", teamName);
        } catch (e: any) {
            errorMsg = e.message || "Failed to create team.";
        } finally {
            isCreating = false;
        }
    }
</script>

<div
    class="flex flex-col items-center justify-center min-h-screen p-6 bg-app-bg text-app-text"
>
    <div
        class="max-w-md w-full bg-app-surface border border-app-border p-8 rounded-2xl shadow-xl flex flex-col gap-6"
    >
        <h1
            class="text-2xl font-heading font-black tracking-widest text-app-primary uppercase"
        >
            Create Your Team
        </h1>
        <p class="text-xs text-app-text/50 uppercase tracking-wider">
            Enter your team name to start your journey in Formula Track Glory.
        </p>

        <div class="flex flex-col gap-4 mt-4">
            <input
                type="text"
                bind:value={teamName}
                placeholder="Team Name"
                class="w-full bg-app-text/40 border border-app-border rounded-xl py-3.5 px-4 text-sm focus:outline-none focus:border-app-primary transition-all transition-colors"
            />

            <button
                onclick={handleCreateTeam}
                disabled={isCreating || !teamName}
                class="w-full bg-app-primary text-app-primary-foreground rounded-xl py-4 flex items-center justify-center gap-3 font-black tracking-widest text-xs disabled:opacity-50 transition-all hover:brightness-110"
            >
                {#if isCreating}
                    <Loader2 size={18} class="animate-spin" />
                    <span>INITIALIZING...</span>
                {:else}
                    <span>START CAREER</span>
                {/if}
            </button>

            {#if errorMsg}
                <p
                    class="text-[10px] text-red-500 font-bold text-center uppercase tracking-widest"
                >
                    {errorMsg}
                </p>
            {/if}
        </div>
    </div>
</div>
