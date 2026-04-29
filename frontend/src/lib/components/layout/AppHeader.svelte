<script lang="ts">
    import { goto } from "$app/navigation";
    import AppLogo from "$lib/components/AppLogo.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { authStore } from "$lib/stores/auth.svelte";
    import { notificationStore } from "$lib/stores/notifications.svelte";
    import NotificationOverlay from "./NotificationOverlay.svelte";
    import ChangelogOverlay from "./ChangelogOverlay.svelte";
    import {
        Shield,
        CircleUser,
        LogOut,
        Bell,
        Settings,
        Activity,
        Sparkles,
    } from "lucide-svelte";
    import { fade, slide } from "svelte/transition";
    import { t } from "$lib/utils/i18n";
    import { APP_VERSION } from "$lib/constants/app_constants";
    import { LATEST_VERSION } from "$lib/constants/changelog";
    import { formatMoney } from "$lib/utils/format";
    import { browser } from "$app/environment";

    let team = $derived(teamStore.value.team);
    let loading = $derived(teamStore.value.loading || authStore.loading);
    let isAdmin = $derived(authStore.isAdmin);
    let unreadCount = $derived(notificationStore.unreadCount);

    let isNotificationsOpen = $state(false);
    let isAccountOpen = $state(false);
    let isChangelogOpen = $state(false);

    const CHANGELOG_STORAGE_KEY = 'lastSeenChangelog';

    let hasUnreadChangelog = $state(
        browser ? localStorage.getItem(CHANGELOG_STORAGE_KEY) !== LATEST_VERSION : false
    );

    function markChangelogSeen() {
        if (browser) {
            localStorage.setItem(CHANGELOG_STORAGE_KEY, LATEST_VERSION);
            hasUnreadChangelog = false;
        }
    }

    let transferBudgetFmt = $derived.by(() => {
        const t = teamStore.value.team;
        if (!t) return "$0.0M";
        const percentage = t.transferBudgetPercentage || 20;
        const amount = t.budget * (percentage / 100);
        return formatMoney(amount);
    });

    let operationalBudgetFmt = $derived.by(() => {
        const t = teamStore.value.team;
        if (!t) return "$0";
        const percentage = t.transferBudgetPercentage || 20;
        const amount = t.budget * (1 - percentage / 100);
        return formatMoney(amount);
    });
</script>

<header
    class="w-full h-[64px] bg-app-surface/80 backdrop-blur-md border-b border-app-border flex items-center justify-between px-6 lg:px-8 shrink-0 z-50 transition-colors"
>
    <!-- Left: Logo Section -->
    <div class="flex items-center gap-4">
        <AppLogo size={32} />
        <div
            class="px-2 py-0.5 bg-app-primary/10 border border-app-primary/20 rounded text-[9px] font-black text-app-primary uppercase tracking-tighter"
        >
            {APP_VERSION}
        </div>
    </div>

    <!-- Race Day Center Button (User Requested) -->
    <a
        href="/racing/live"
        class="hidden lg:flex items-center gap-2 px-4 py-2 border border-red-500/20 bg-red-500/5 hover:bg-red-500/10 rounded-xl transition-all group"
    >
        <div class="text-red-500 group-hover:scale-110 transition-transform">
            <Activity size={16} strokeWidth={3} />
        </div>
        <span
            class="text-[10px] font-black uppercase tracking-widest text-red-500/80 group-hover:text-red-500 transition-colors"
            >{t('race_day')}</span
        >
    </a>

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
                    {t('operational')}
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
                    {t('transfer_cap')}
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
                    onclick={() => goto("/admin")}
                    class="p-2 text-app-primary hover:bg-app-primary/10 rounded-full transition-colors flex items-center justify-center cursor-pointer"
                    title="Admin Tools"
                >
                    <Shield size={18} strokeWidth={2} />
                </button>
            {/if}

            <!-- Changelog Toggle -->
            <div class="relative">
                <button
                    onclick={() => {
                        isChangelogOpen = !isChangelogOpen;
                        isNotificationsOpen = false;
                        isAccountOpen = false;
                    }}
                    class="p-2 relative text-app-primary/70 hover:text-app-primary hover:bg-app-primary/10 rounded-full transition-colors flex items-center justify-center"
                    title={t('whats_new')}
                >
                    <Sparkles size={20} strokeWidth={2} />
                    {#if hasUnreadChangelog}
                        <div
                            class="absolute top-1.5 right-1.5 w-2 h-2 bg-app-primary rounded-full"
                        ></div>
                    {/if}
                </button>
                <ChangelogOverlay bind:isOpen={isChangelogOpen} onSeen={markChangelogSeen} />
            </div>

            <!-- Notifications Toggle -->
            <div class="relative">
                <button
                    onclick={() => {
                        isNotificationsOpen = !isNotificationsOpen;
                        isChangelogOpen = false;
                        isAccountOpen = false;
                    }}
                    class="p-2 relative text-app-primary/70 hover:text-app-primary hover:bg-app-primary/10 rounded-full transition-colors flex items-center justify-center"
                    title="Notifications"
                >
                    <Bell size={20} strokeWidth={2} />
                    {#if unreadCount > 0}
                        <div
                            class="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full animate-bounce"
                        ></div>
                    {/if}
                </button>
                <NotificationOverlay bind:isOpen={isNotificationsOpen} />
            </div>

            <!-- Account Dropdown Toggle -->
            <div class="relative">
                <button
                    onclick={() => {
                        isAccountOpen = !isAccountOpen;
                        isNotificationsOpen = false;
                        isChangelogOpen = false;
                    }}
                    class="p-2 text-app-primary/70 hover:text-app-primary hover:bg-app-primary/10 rounded-full transition-colors flex items-center justify-center"
                    title="Account"
                >
                    <CircleUser size={20} strokeWidth={2} />
                </button>

                {#if isAccountOpen}
                    <div
                        in:fade={{ duration: 150 }}
                        out:fade={{ duration: 100 }}
                        class="absolute top-12 right-0 w-48 bg-app-surface border border-app-border rounded-2xl shadow-2xl z-50 overflow-hidden flex flex-col py-2"
                    >
                        <div
                            class="px-4 py-3 border-b border-app-border flex flex-col"
                        >
                            <span
                                class="text-xs font-bold text-app-text truncate"
                                >{authStore.user.displayName || "Manager"}</span
                            >
                            <span class="text-[10px] text-app-text/40 truncate"
                                >{authStore.user.email}</span
                            >
                        </div>
                        <button
                            onclick={() => {
                                isAccountOpen = false;
                                goto("/settings");
                            }}
                            class="px-4 py-3 flex items-center gap-3 hover:bg-app-text/5 transition-colors text-app-text/70 hover:text-app-text w-full text-left cursor-pointer"
                        >
                            <Settings size={14} />
                            <span
                                class="text-[11px] font-black uppercase tracking-widest"
                                >{t('settings')}</span
                            >
                        </button>
                        <button
                            onclick={() => {
                                isAccountOpen = false;
                                authStore.signOut();
                            }}
                            class="px-4 py-3 flex items-center gap-3 hover:bg-red-500/10 transition-colors text-red-500/70 hover:text-red-500 w-full text-left"
                        >
                            <LogOut size={14} />
                            <span
                                class="text-[11px] font-black uppercase tracking-widest"
                                >{t('log_out')}</span
                            >
                        </button>
                    </div>

                    <!-- Backdrop for clicking outside (invisible) -->
                    <button
                        onclick={() => (isAccountOpen = false)}
                        class="fixed inset-0 z-40 bg-transparent cursor-default"
                        aria-label="Close menu"
                    ></button>
                {/if}
            </div>
        {/if}
    </div>
</header>
