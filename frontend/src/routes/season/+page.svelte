<script lang="ts">
    import { Trophy, CalendarDays, ChevronRight, Flag } from "lucide-svelte";
    import { fly } from "svelte/transition";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { universeStore } from "$lib/stores/universe.svelte";

    let season = $derived(seasonStore.value.season);
    let teamStanding = $derived(
        teamStore.value.team
            ? universeStore.getTeamStanding(teamStore.value.team.id)
            : null,
    );

    const hubs = [
        {
            title: "Race Calendar",
            subtitle: "All rounds, circuits & weather",
            icon: CalendarDays,
            color: "text-app-primary",
            bg: "bg-app-primary/5",
            path: "/season/calendar",
        },
        {
            title: "Standings",
            subtitle: "Drivers & Constructors Championship",
            icon: Trophy,
            color: "text-yellow-400",
            bg: "bg-yellow-400/5",
            path: "/season/standings",
        },
    ];
</script>

<svelte:head>
    <title>Season | FTG Racing Manager</title>
</svelte:head>

<div class="p-6 md:p-10 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text min-h-screen">
    <!-- Header -->
    <header class="flex flex-col gap-2 mb-12">
        <div class="flex items-center gap-3">
            <div class="p-2 rounded-lg bg-app-primary/10 text-app-primary">
                <Flag size={24} />
            </div>
            <span class="text-[10px] font-black tracking-[0.3em] text-app-primary/40 uppercase font-heading">
                Season Overview
            </span>
        </div>
        <div class="flex flex-wrap items-end justify-between gap-6">
            <h1 class="text-4xl lg:text-5xl font-heading font-black tracking-tighter uppercase italic text-app-text mt-1">
                Season <span class="text-app-primary">{season?.year ?? "2026"}</span>
            </h1>
            {#if teamStanding}
                <div class="flex items-center gap-6 px-6 py-3 bg-app-surface/50 border border-app-border rounded-2xl backdrop-blur-md">
                    <div class="flex flex-col">
                        <span class="text-[9px] font-black text-app-text/20 uppercase tracking-widest">Constructor</span>
                        <span class="text-lg font-black text-app-primary italic">P{teamStanding.position}</span>
                    </div>
                    <div class="w-px h-8 bg-app-text/5"></div>
                    <div class="flex flex-col">
                        <span class="text-[9px] font-black text-app-text/20 uppercase tracking-widest">Points</span>
                        <span class="text-lg font-black text-app-text">{teamStanding.points}</span>
                    </div>
                </div>
            {/if}
        </div>
    </header>

    <!-- Navigation Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        {#each hubs as hub, i}
            <a
                href={hub.path}
                in:fly={{ y: 20, duration: 400, delay: i * 100 }}
                class="group relative bg-app-surface border border-app-border rounded-3xl p-8 transition-all duration-300 hover:border-app-primary/30 hover:shadow-[0_20px_40px_rgba(0,0,0,0.3)] overflow-hidden"
            >
                <div class="absolute -right-10 -bottom-10 w-48 h-48 {hub.bg} blur-3xl rounded-full transition-transform group-hover:scale-150"></div>
                <div class="relative flex flex-col gap-6 h-full">
                    <div class="flex items-center justify-between">
                        <div class="p-4 rounded-2xl {hub.bg} {hub.color} transition-transform group-hover:scale-110">
                            <hub.icon size={32} strokeWidth={2.5} />
                        </div>
                        <div class="text-app-text/10 group-hover:text-app-primary transition-colors">
                            <ChevronRight size={24} />
                        </div>
                    </div>
                    <div class="flex flex-col gap-1">
                        <h2 class="text-2xl font-black text-app-text uppercase tracking-tight group-hover:text-app-primary transition-colors">
                            {hub.title}
                        </h2>
                        <p class="text-sm font-medium text-app-text/40">{hub.subtitle}</p>
                    </div>
                    <div class="mt-4 flex items-center gap-2">
                        <div class="h-1 w-8 bg-app-primary/20 rounded-full overflow-hidden">
                            <div class="h-full bg-app-primary w-0 group-hover:w-full transition-all duration-500"></div>
                        </div>
                        <span class="text-[9px] font-black tracking-widest text-app-text/20 group-hover:text-app-text/40 uppercase">View Module</span>
                    </div>
                </div>
            </a>
        {/each}
    </div>

    <!-- Season Progress Footer -->
    {#if season}
        {@const completed = season.calendar.filter((r: any) => r.isCompleted).length}
        {@const total = season.calendar.length}
        <div class="mt-16 pt-8 border-t border-app-border flex flex-wrap gap-12 opacity-50">
            <div class="flex flex-col gap-1">
                <span class="text-[9px] font-black uppercase tracking-widest text-app-text/40">Rounds Completed</span>
                <span class="text-sm font-bold text-app-text">{completed} / {total}</span>
            </div>
            <div class="flex flex-col gap-1">
                <span class="text-[9px] font-black uppercase tracking-widest text-app-text/40">Season Year</span>
                <span class="text-sm font-bold text-app-text">{season.year}</span>
            </div>
        </div>
    {/if}
</div>
