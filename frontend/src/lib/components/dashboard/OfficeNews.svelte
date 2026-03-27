<script lang="ts">
    import { notificationStore } from "$lib/stores/notifications.svelte";
    import {
        Bell,
        CheckCircle,
        AlertTriangle,
        AlertCircle,
        Info,
        Trash2,
    } from "lucide-svelte";
    import { t } from "$lib/utils/i18n";
    import { fly } from "svelte/transition";

    function getIcon(type: string) {
        switch (type) {
            case "SUCCESS":
                return CheckCircle;
            case "WARNING":
                return AlertTriangle;
            case "ERROR":
                return AlertCircle;
            default:
                return Info;
        }
    }

    function getColorClass(type: string) {
        switch (type) {
            case "SUCCESS":
                return "text-green-400";
            case "WARNING":
                return "text-yellow-400";
            case "ERROR":
                return "text-red-400";
            default:
                return "text-app-primary";
        }
    }

    const { notifications, isLoading } = $derived(notificationStore);
</script>

<div class="news-container flex flex-col gap-6 w-full">
    <div class="flex items-center justify-between px-2">
        <h3
            class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading"
        >
            {t('office_news')}
        </h3>
        {#if notificationStore.unreadCount > 0}
            <span
                class="bg-app-primary text-app-primary-foreground text-[9px] font-black px-2 py-0.5 rounded-full animate-pulse"
            >
                {t('notifications_new', { count: notificationStore.unreadCount })}
            </span>
        {/if}
    </div>

    {#if isLoading}
        <div class="flex items-center justify-center p-12 opacity-30">
            <div
                class="w-6 h-6 border-2 border-app-primary border-t-transparent rounded-full animate-spin"
            ></div>
        </div>
    {:else if notifications.length === 0}
        <div
            class="bg-app-surface/50 border border-app-border rounded-2xl p-12 flex flex-col items-center justify-center text-center gap-4"
        >
            <div class="relative">
                <Bell size={32} class="text-app-text/5" />
                <div
                    class="absolute inset-0 bg-app-primary/5 blur-xl rounded-full"
                ></div>
            </div>
            <p
                class="text-[10px] uppercase font-black tracking-widest text-app-text/20"
            >
                {t('no_active_notifications')}
            </p>
        </div>
    {:else}
        <div class="flex flex-col gap-3">
            {#each notifications as item (item.id)}
                {@const IconComp = getIcon(item.type)}
                <div
                    in:fly={{ x: 20, duration: 400 }}
                    class="bg-app-surface hover:bg-app-surface/80 border border-app-border rounded-xl p-4 flex gap-4 items-start group transition-all duration-300 {item.isRead
                        ? 'opacity-60'
                        : 'border-app-primary/20 shadow-[0_0_20px_rgba(197,160,89,0.05)]'}"
                >
                    <div class="mt-1 {getColorClass(item.type)} shrink-0">
                        <IconComp size={18} strokeWidth={2.5} />
                    </div>

                    <div class="flex-1 flex flex-col gap-1 min-w-0">
                        <div class="flex items-center justify-between">
                            <h4
                                class="text-[11px] font-black uppercase tracking-wider text-app-text"
                            >
                                {item.title}
                            </h4>
                            <span class="text-[9px] font-bold text-app-text/20">
                                {item.timestamp?.toDate
                                    ? new Intl.DateTimeFormat("en-US", {
                                          hour: "2-digit",
                                          minute: "2-digit",
                                      }).format(item.timestamp.toDate())
                                    : t('recently')}
                            </span>
                        </div>
                        <p
                            class="text-[12px] text-app-text/60 leading-relaxed font-medium"
                        >
                            {item.message}
                        </p>
                    </div>

                    <div
                        class="flex flex-col gap-2 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                        <button
                            onclick={() =>
                                notificationStore.markAsRead(item.id)}
                            class="p-1 px-2 hover:bg-app-text/5 rounded text-[9px] font-black uppercase tracking-widest text-app-primary"
                        >
                            {t('mark_as_read')}
                        </button>
                        <button
                            onclick={() =>
                                notificationStore.deleteNotification(item.id)}
                            class="p-1 text-app-text/20 hover:text-red-400 transition-colors"
                        >
                            <Trash2 size={12} />
                        </button>
                    </div>
                </div>
            {/each}
        </div>
    {/if}
</div>

<style>
    .news-container {
        scrollbar-width: none;
    }
    .news-container::-webkit-scrollbar {
        display: none;
    }
</style>
