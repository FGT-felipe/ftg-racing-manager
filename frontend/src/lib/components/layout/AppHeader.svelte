<script lang="ts">
    import AppLogo from "$lib/components/AppLogo.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { authStore } from "$lib/stores/auth.svelte";
    import { Shield, CircleUser, LogOut } from "lucide-svelte";

    let teamData = $derived(teamStore.value);
    let team = $derived(teamData.team);
    let loading = $derived(teamData.loading || authStore.loading);
    let isAdmin = $derived(authStore.isAdmin);

    let transferBudgetFmt = $derived.by(() => {
        if (!team) return "$0.0M";
        const percentage = team.transferBudgetPercentage || 20;
        const amount = team.budget * (percentage / 100);
        return `$${(amount / 1000000).toFixed(1)}M`;
    });

    let operationalBudgetFmt = $derived.by(() => {
        if (!team) return "$0.0M";
        const percentage = team.transferBudgetPercentage || 20;
        const amount = team.budget * (1 - percentage / 100);
        return `$${(amount / 1000000).toFixed(1)}M`;
    });
</script>

<header
    class="w-full h-[64px] bg-transparent border-b border-white/5 flex items-center justify-between px-6 lg:px-8 shrink-0 z-50 transition-colors"
>
    <!-- Left: Logo Section -->
    <div class="flex items-center gap-4">
        <AppLogo size={32} />
    </div>

    <!-- Center: Finances Section -->
    <div class="hidden md:flex items-center gap-8">
        {#if loading}
            <!-- Skeleton Loading for Finances (Gold Tinted) -->
            <div class="flex items-center gap-6">
                <div class="flex flex-col gap-1">
                    <div
                        class="h-[10px] w-24 bg-app-primary/5 rounded animate-pulse"
                    ></div>
                    <div
                        class="h-[20px] w-16 bg-app-primary/10 rounded animate-pulse"
                    ></div>
                </div>
                <div class="flex flex-col gap-1">
                    <div
                        class="h-[10px] w-24 bg-app-primary/5 rounded animate-pulse"
                    ></div>
                    <div
                        class="h-[20px] w-16 bg-app-primary/10 rounded animate-pulse"
                    ></div>
                </div>
            </div>
        {:else if team}
            <!-- Operational Balance -->
            <div class="flex flex-col items-start gap-0.5">
                <span
                    class="text-[10px] uppercase font-bold text-app-primary/50 font-heading tracking-widest"
                >
                    Operational
                </span>
                <span
                    class="text-[16px] font-bold text-app-primary font-sans tracking-wide"
                >
                    {operationalBudgetFmt}
                </span>
            </div>

            <!-- Transfer Budget -->
            <div class="flex flex-col items-start gap-0.5">
                <span
                    class="text-[10px] uppercase font-bold text-app-primary/50 font-heading tracking-widest"
                >
                    Transfer Cap
                </span>
                <span
                    class="text-[16px] font-bold text-app-primary/80 font-sans tracking-wide"
                >
                    {transferBudgetFmt}
                </span>
            </div>
        {/if}
    </div>

    <!-- Right: User Section -->
    <div class="flex items-center gap-4">
        {#if loading}
            <div
                class="w-8 h-8 rounded-full bg-app-primary/5 animate-pulse"
            ></div>
            <div
                class="w-8 h-8 rounded-full bg-app-primary/5 animate-pulse"
            ></div>
        {:else if authStore.user}
            {#if isAdmin}
                <button
                    class="p-2 text-app-primary hover:bg-app-primary/10 rounded-full transition-colors flex items-center justify-center"
                    title="Admin Tools"
                >
                    <Shield size={18} strokeWidth={2} />
                </button>
            {/if}
            <button
                class="p-2 text-app-primary/70 hover:text-app-primary hover:bg-app-primary/10 rounded-full transition-colors flex items-center justify-center"
                title="Account"
            >
                <CircleUser size={20} strokeWidth={2} />
            </button>
            <button
                onclick={() => authStore.signOut()}
                class="p-2 text-app-primary/50 hover:text-app-primary hover:bg-app-primary/10 rounded-full transition-colors flex items-center justify-center"
                title="Log Out"
            >
                <LogOut size={20} strokeWidth={2} />
            </button>
        {/if}
    </div>
</header>
