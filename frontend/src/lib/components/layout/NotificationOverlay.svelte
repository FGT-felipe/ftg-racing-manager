<script lang="ts">
    import { notificationStore } from "$lib/stores/notifications.svelte";
    import { fade, slide, fly } from "svelte/transition";
    import {
        Bell,
        CheckCircle2,
        Info,
        AlertTriangle,
        XCircle,
        X,
        ExternalLink,
        Trash2,
        Check,
    } from "lucide-svelte";
    import { formatDistanceToNow } from "date-fns";

    let { isOpen = $bindable(false) } = $props<{ isOpen: boolean }>();

    let notifications = $derived(notificationStore.notifications);
    let unreadCount = $derived(notificationStore.unreadCount);

    function getIcon(type: string) {
        switch (type) {
            case "SUCCESS":
                return CheckCircle2;
            case "WARNING":
                return AlertTriangle;
            case "ERROR":
                return XCircle;
            default:
                return Info;
        }
    }

    function getColor(type: string) {
        switch (type) {
            case "SUCCESS":
                return "text-green-400";
            case "WARNING":
                return "text-yellow-400";
            case "ERROR":
                return "text-red-400";
            default:
                return "text-blue-400";
        }
    }

    // Mark as read when opening dropdown (optional UX choice)
    $effect(() => {
        if (isOpen && unreadCount > 0) {
            // We can mark all as read when opened, or let user do it individually
        }
    });
</script>

{#if isOpen}
    <!-- Backdrop for mobile -->
    <button
        onclick={() => (isOpen = false)}
        class="fixed inset-0 bg-app-text/40 z-40 md:hidden backdrop-blur-sm cursor-default"
        in:fade={{ duration: 200 }}
        aria-label="Close notifications"
    ></button>

    <div
        class="absolute top-[64px] right-2 md:right-8 w-[380px] max-h-[80vh] bg-app-surface border border-app-border rounded-2xl shadow-2xl z-50 flex flex-col overflow-hidden"
        in:fly={{ y: -10, duration: 200 }}
        out:fade={{ duration: 150 }}
    >
        <div
            class="p-4 border-b border-app-border flex items-center justify-between bg-app-text/20"
        >
            <div class="flex items-center gap-2">
                <Bell size={16} class="text-app-primary" />
                <h3 class="text-xs font-black uppercase tracking-widest text-app-text">
                    Notifications
                </h3>
                {#if unreadCount > 0}
                    <span
                        class="px-2 py-0.5 rounded-full bg-app-primary text-app-primary-foreground text-[9px] font-black"
                    >
                        {unreadCount} New
                    </span>
                {/if}
            </div>
            <button
                onclick={() => (isOpen = false)}
                class="text-app-text/40 hover:text-app-text transition-colors"
                aria-label="Close"
            >
                <X size={16} />
            </button>
        </div>

        <div class="flex-1 overflow-y-auto custom-scrollbar">
            {#if notificationStore.isLoading}
                <div class="flex flex-col items-center justify-center p-8 gap-3">
                    <div
                        class="w-6 h-6 border-2 border-app-primary border-t-transparent rounded-full animate-spin"
                    ></div>
                    <span
                        class="text-[10px] font-black uppercase tracking-widest text-app-text/40"
                        >Loading...</span
                    >
                </div>
            {:else if notifications.length === 0}
                <div class="flex flex-col items-center justify-center p-12 text-center">
                    <Bell size={32} class="text-app-text/10 mb-4" />
                    <p class="text-xs font-bold text-app-text/40 uppercase tracking-widest">
                        Inbox Empty
                    </p>
                    <p class="text-[10px] text-app-text/20 mt-1">
                        You're all caught up on news!
                    </p>
                </div>
            {:else}
                <div class="divide-y divide-white/5">
                    {#each notifications as notif (notif.id)}
                        {@const Icon = getIcon(notif.type)}
                        <div
                            class="p-4 hover:bg-app-text/5 transition-colors relative group {notif.isRead
                                ? 'opacity-70'
                                : 'bg-app-primary/5'}"
                            in:slide
                        >
                            <div class="flex gap-3 relative z-10">
                                <div class="shrink-0 mt-0.5">
                                    <Icon size={16} class={getColor(notif.type)} />
                                </div>
                                <div class="flex-1 min-w-0">
                                    <div class="flex items-start justify-between gap-2 mb-1">
                                        <h4 class="text-xs font-bold text-app-text leading-tight">
                                            {notif.title}
                                        </h4>
                                        <span class="text-[9px] text-app-text/30 whitespace-nowrap shrink-0">
                                            {notif.timestamp?.toDate()
                                                ? formatDistanceToNow(notif.timestamp.toDate(), { addSuffix: true })
                                                : "Just now"}
                                        </span>
                                    </div>
                                    <p class="text-[11px] text-app-text/60 leading-snug">
                                        {notif.message}
                                    </p>

                                    <!-- Actions -->
                                    <div class="flex items-center gap-3 mt-3">
                                        {#if notif.actionRoute}
                                            <a
                                                href={notif.actionRoute}
                                                class="text-[10px] font-black uppercase tracking-widest text-app-primary flex items-center gap-1 hover:underline"
                                                onclick={() => {
                                                    isOpen = false;
                                                    if(!notif.isRead) notificationStore.markAsRead(notif.id);
                                                }}
                                            >
                                                View Source
                                                <ExternalLink size={10} />
                                            </a>
                                        {/if}
                                        {#if !notif.isRead}
                                            <button
                                                onclick={() => notificationStore.markAsRead(notif.id)}
                                                class="text-[10px] font-bold uppercase tracking-widest text-app-text/40 flex items-center gap-1 hover:text-app-text transition-colors"
                                            >
                                                <Check size={10} />
                                                Mark Read
                                            </button>
                                        {/if}
                                    </div>
                                </div>
                                
                                <!-- Delete Button (appears on hover) -->
                                <button
                                    onclick={() => notificationStore.deleteNotification(notif.id)}
                                    class="absolute top-2 right-2 p-1.5 text-app-text/0 group-hover:text-red-400 bg-red-400/0 group-hover:bg-red-400/10 rounded-lg transition-all"
                                    title="Delete Notification"
                                >
                                    <Trash2 size={12} />
                                </button>
                            </div>
                        </div>
                    {/each}
                </div>
            {/if}
        </div>
    </div>
{/if}

<style>
    .custom-scrollbar::-webkit-scrollbar {
        width: 4px;
    }
    .custom-scrollbar::-webkit-scrollbar-track {
        background: rgba(255, 255, 255, 0.05);
    }
    .custom-scrollbar::-webkit-scrollbar-thumb {
        background: rgba(197, 160, 89, 0.2);
        border-radius: 10px;
    }
</style>
