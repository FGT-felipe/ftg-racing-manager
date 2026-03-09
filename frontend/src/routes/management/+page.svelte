<script lang="ts">
    import {
        ShieldAlert,
        Wallet,
        Handshake,
        Users,
        ChevronRight,
    } from "lucide-svelte";
    import { fly } from "svelte/transition";

    const managementItems = [
        {
            id: "finances",
            title: "Finances",
            subtitle: "Balance, and Transactions",
            icon: Wallet,
            color: "text-green-400",
            bg: "bg-green-400/5",
            path: "/management/finances",
        },
        {
            id: "sponsors",
            title: "Sponsors",
            subtitle: "Contracts & Negotiations",
            icon: Handshake,
            color: "text-app-primary",
            bg: "bg-app-primary/5",
            path: "/management/sponsors",
        },
        {
            id: "personnel",
            title: "Personnel",
            subtitle: "Team & Staff Management",
            icon: Users,
            color: "text-blue-400",
            bg: "bg-blue-400/5",
            path: "/management/personnel",
        },
    ];
</script>

<svelte:head>
    <title>Management | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-6 md:p-10 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text min-h-screen"
>
    <!-- Header Section -->
    <header class="flex flex-col gap-2 mb-12">
        <div class="flex items-center gap-3">
            <div class="p-2 rounded-lg bg-app-primary/10 text-app-primary">
                <ShieldAlert size={24} />
            </div>
            <span
                class="text-[10px] font-black tracking-[0.3em] text-app-primary/40 uppercase font-heading"
            >
                Operational Control
            </span>
        </div>
        <h1
            class="text-4xl lg:text-5xl font-heading font-black tracking-tighter uppercase italic text-white mt-1"
        >
            Management <span class="text-app-primary">Center</span>
        </h1>
    </header>

    <!-- Navigation Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {#each managementItems as item, i}
            <a
                href={item.path}
                in:fly={{ y: 20, duration: 400, delay: i * 100 }}
                class="group relative bg-app-surface border border-white/5 rounded-3xl p-8 transition-all duration-300 hover:border-app-primary/30 hover:shadow-[0_20px_40px_rgba(0,0,0,0.3)] overflow-hidden"
            >
                <!-- Background Gradient Decoration -->
                <div
                    class="absolute -right-10 -bottom-10 w-40 h-40 {item.bg} blur-3xl rounded-full transition-transform group-hover:scale-150"
                ></div>

                <div class="relative flex flex-col gap-6 h-full">
                    <div class="flex items-center justify-between">
                        <div
                            class="p-4 rounded-2xl {item.bg} {item.color} transition-transform group-hover:scale-110"
                        >
                            <item.icon size={32} strokeWidth={2.5} />
                        </div>
                        <div
                            class="text-white/10 group-hover:text-app-primary transition-colors"
                        >
                            <ChevronRight size={20} />
                        </div>
                    </div>

                    <div class="flex flex-col gap-1">
                        <h2
                            class="text-2xl font-black text-white uppercase tracking-tight group-hover:text-app-primary transition-colors"
                        >
                            {item.title}
                        </h2>
                        <p class="text-sm font-medium text-app-text/40">
                            {item.subtitle}
                        </p>
                    </div>

                    <div class="mt-4 flex items-center gap-2">
                        <div
                            class="h-1 w-8 bg-app-primary/20 rounded-full overflow-hidden"
                        >
                            <div
                                class="h-full bg-app-primary w-0 group-hover:w-full transition-all duration-500"
                            ></div>
                        </div>
                        <span
                            class="text-[9px] font-black tracking-widest text-white/20 group-hover:text-white/40 uppercase"
                        >
                            Access Module
                        </span>
                    </div>
                </div>
            </a>
        {/each}
    </div>

    <!-- Quick Status Footer -->
    <div
        class="mt-12 pt-8 border-t border-white/5 flex flex-wrap gap-12 opacity-50"
    >
        <div class="flex flex-col gap-1">
            <span
                class="text-[9px] font-black uppercase tracking-widest text-app-text/40"
                >Efficiency</span
            >
            <span class="text-sm font-bold text-white">94.2%</span>
        </div>
        <div class="flex flex-col gap-1">
            <span
                class="text-[9px] font-black uppercase tracking-widest text-app-text/40"
                >Morale</span
            >
            <span class="text-sm font-bold text-white">Very High</span>
        </div>
        <div class="flex flex-col gap-1">
            <span
                class="text-[9px] font-black uppercase tracking-widest text-app-text/40"
                >System Load</span
            >
            <span class="text-sm font-bold text-white">Optimal</span>
        </div>
    </div>
</div>

<style>
    /* Add any custom styles if needed */
</style>
