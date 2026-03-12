<script lang="ts">
    import {
        Users,
        Dumbbell,
        HardHat,
        Badge,
        Megaphone,
        ChevronLeft,
        ChevronRight,
        Lock,
    } from "lucide-svelte";
    import { fly } from "svelte/transition";

    const personnelItems = [
        {
            id: "drivers",
            title: "Drivers",
            description: "Manage contracts, morale, and performance",
            icon: Users,
            href: "/management/personnel/drivers",
            enabled: true,
            color: "text-app-primary",
        },
        {
            id: "fitness",
            title: "Fitness Trainer",
            description: "Optimize pilot recovery and energy levels",
            icon: Dumbbell,
            href: "/management/personnel/fitness",
            enabled: true,
            color: "text-green-400",
        },
        {
            id: "engineer",
            title: "Chief Engineer",
            description: "Technical lead for car development",
            icon: HardHat,
            href: "#",
            enabled: false,
            color: "text-blue-400",
        },
        {
            id: "hr",
            title: "HR Manager",
            description: "Staff morale and recruitment efficiency",
            icon: Badge,
            href: "#",
            enabled: false,
            color: "text-purple-400",
        },
        {
            id: "marketing",
            title: "Marketing Head",
            description: "Boost sponsor interest and fan engagement",
            icon: Megaphone,
            href: "#",
            enabled: false,
            color: "text-orange-400",
        },
    ];
</script>

<svelte:head>
    <title>Personnel Hub | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-6 md:p-10 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text min-h-screen"
>
    <!-- Breadcrumbs -->
    <nav
        class="flex items-center gap-2 mb-8 opacity-40 hover:opacity-100 transition-opacity"
    >
        <a
            href="/management"
            class="flex items-center gap-1 text-[10px] font-black uppercase tracking-widest"
        >
            <ChevronLeft size={14} /> Management
        </a>
    </nav>

    <header class="flex flex-col gap-3 mb-12">
        <h1
            class="text-4xl md:text-5xl font-heading font-black tracking-tighter uppercase italic text-app-text flex items-center gap-4"
        >
            Personnel <span class="text-app-primary">Hub</span>
        </h1>
        <p class="text-xs font-bold text-app-text/30 uppercase tracking-[0.3em]">
            Assemble and manage your world-class racing staff
        </p>
    </header>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {#each personnelItems as item, i (item.id)}
            <div in:fly={{ y: 20, delay: i * 50 }} class="relative group">
                <a
                    href={item.enabled ? item.href : undefined}
                    class="block relative bg-app-surface border border-app-border rounded-[32px] p-8 transition-all duration-500 overflow-hidden
                    {item.enabled
                        ? 'hover:border-app-primary/40 hover:bg-app-primary/5 hover:-translate-y-2 cursor-pointer'
                        : 'opacity-40 grayscale cursor-not-allowed'}"
                >
                    <!-- Background Glow -->
                    <div
                        class="absolute -right-10 -bottom-10 w-32 h-32 {item.color} opacity-0 group-hover:opacity-10 blur-[60px] transition-opacity rounded-full"
                    ></div>

                    <div class="relative flex flex-col gap-6">
                        <div class="flex items-center justify-between">
                            <div
                                class="p-4 bg-app-text/5 rounded-2xl border border-app-border group-hover:border-app-primary/20 transition-all"
                            >
                                <item.icon
                                    size={28}
                                    class={item.enabled
                                        ? item.color
                                        : "text-app-text/20"}
                                />
                            </div>
                            {#if !item.enabled}
                                <div
                                    class="px-3 py-1 bg-red-500/10 border border-red-500/20 text-red-500 text-[8px] font-black uppercase tracking-tighter rounded-full flex items-center gap-1"
                                >
                                    <Lock size={10} /> Locked
                                </div>
                            {/if}
                        </div>

                        <div class="flex flex-col gap-2">
                            <h3
                                class="text-xl font-black text-app-text uppercase tracking-tight group-hover:text-app-primary transition-colors"
                            >
                                {item.title}
                            </h3>
                            <p
                                class="text-xs font-medium text-app-text/40 leading-relaxed"
                            >
                                {item.description}
                            </p>
                        </div>

                        {#if item.enabled}
                            <div
                                class="flex items-center gap-2 text-[10px] font-black text-app-primary uppercase tracking-widest mt-2 group-hover:gap-4 transition-all"
                            >
                                Manage Unit <ChevronRight size={14} />
                            </div>
                        {/if}
                    </div>
                </a>
            </div>
        {/each}
    </div>
</div>
