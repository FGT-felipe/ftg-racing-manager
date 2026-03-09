<script lang="ts">
    import { seasonStore } from "$lib/stores/season.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { Flag, Trophy, Timer } from "lucide-svelte";
    import { onDestroy } from "svelte";

    let nextEvent = $derived(seasonStore.nextEvent);
    let weekStatus = $derived(
        teamStore.value.team?.weekStatus?.globalStatus || "practice",
    );

    // Time state
    let days = $state(0);
    let hours = $state(0);
    let minutes = $state(0);

    let timer: ReturnType<typeof setInterval>;

    // Function to calculate time remaining
    function updateCountdown() {
        if (!nextEvent || !nextEvent.date) return;

        const now = new Date().getTime();
        const eventTime = nextEvent.date.getTime();
        const distance = eventTime - now;

        if (distance < 0) {
            days = 0;
            hours = 0;
            minutes = 0;
            return;
        }

        days = Math.floor(distance / (1000 * 60 * 60 * 24));
        hours = Math.floor(
            (distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60),
        );
        minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
    }

    // Reactive effect to start timer when nextEvent changes
    $effect(() => {
        if (nextEvent) {
            updateCountdown();
            if (timer) clearInterval(timer);
            timer = setInterval(updateCountdown, 60000); // UI updates every minute
        }
    });

    onDestroy(() => {
        if (timer) clearInterval(timer);
    });

    // Derived UI configuration - Luxury Refactor (Onyx & Gold)
    let uiConfig = $derived.by(() => {
        if (weekStatus === "qualifying") {
            return {
                colorPrefix: "text-app-primary",
                borderColor: "border-app-primary/30",
                bgGlow: "shadow-[0_0_25px_rgba(197,160,89,0.05)]",
                btnLabel: "VIEW QUALIFYING",
                btnColor:
                    "bg-transparent border border-app-primary text-app-primary hover:bg-app-primary/10",
                route: "/racing",
                icon: Trophy,
            };
        } else if (weekStatus === "raceStrategy" || weekStatus === "race") {
            return {
                colorPrefix: "text-app-primary",
                borderColor: "border-app-primary/30",
                bgGlow: "shadow-[0_0_25px_rgba(197,160,89,0.05)]",
                btnLabel:
                    weekStatus === "race" ? "GO TO RACE" : "SET RACE STRATEGY",
                btnColor:
                    "bg-transparent border border-app-primary text-app-primary hover:bg-app-primary/10",
                route: "/racing",
                icon: Flag,
            };
        } else {
            // Default Practice / Weekend Setup
            return {
                colorPrefix: "text-app-primary",
                borderColor: "border-app-primary/30",
                bgGlow: "shadow-[0_0_25px_rgba(197,160,89,0.05)]",
                btnLabel: "WEEKEND SETUP",
                btnColor:
                    "bg-transparent border border-app-primary text-app-primary hover:bg-app-primary/10",
                route: "/racing",
                icon: Timer,
            };
        }
    });
</script>

<div
    class="relative w-full overflow-hidden rounded-2xl border {uiConfig.borderColor} {uiConfig.bgGlow} bg-app-surface p-8 lg:p-10 transition-all duration-300"
>
    <div
        class="flex flex-col md:flex-row justify-between items-start md:items-center gap-6"
    >
        <!-- Event Information -->
        <div class="flex flex-col gap-2">
            <div class="flex items-center gap-3">
                <span
                    class="text-xs font-bold tracking-[2.0px] text-app-text/60 uppercase"
                >
                    Next Grand Prix
                </span>
                {#if weekStatus === "race"}
                    <div class="flex items-center gap-2">
                        <div
                            class="w-2 h-2 rounded-full bg-red-500 animate-pulse"
                        ></div>
                        <span
                            class="text-[10px] font-black tracking-widest text-red-500 uppercase"
                            >ON LIVE</span
                        >
                    </div>
                {/if}
            </div>

            {#if seasonStore.value.loading}
                <div
                    class="h-8 w-48 bg-white/5 rounded animate-pulse my-2"
                ></div>
                <div class="h-4 w-32 bg-white/5 rounded animate-pulse"></div>
            {:else if nextEvent}
                <div class="flex items-center gap-3">
                    <span class="text-3xl">{nextEvent.flagEmoji}</span>
                    <h2
                        class="text-3xl lg:text-4xl font-heading font-black tracking-wide text-white uppercase"
                    >
                        {nextEvent.trackName}
                    </h2>
                </div>
                <span class="text-sm font-bold text-app-text/50">
                    {nextEvent.countryCode} — {nextEvent.totalLaps} Laps
                </span>
            {:else}
                <h2
                    class="text-2xl font-heading font-black text-white/50 uppercase"
                >
                    No Event Scheduled
                </h2>
            {/if}
        </div>

        <!-- Action & Countdown -->
        <div class="flex flex-col items-end gap-4 w-full md:w-auto">
            {#if nextEvent}
                <!-- Countdown Display -->
                <div
                    class="flex items-center gap-4 bg-black/40 px-4 py-3 rounded-xl border border-white/5"
                >
                    <div class="flex flex-col items-center min-w-[30px]">
                        <span
                            class="font-mono text-xl font-bold {uiConfig.colorPrefix}"
                            >{days}</span
                        >
                        <span
                            class="text-[9px] font-black tracking-wider text-app-text/40"
                            >DAYS</span
                        >
                    </div>
                    <span class="text-white/20 pb-4">:</span>
                    <div class="flex flex-col items-center min-w-[30px]">
                        <span
                            class="font-mono text-xl font-bold {uiConfig.colorPrefix}"
                            >{hours.toString().padStart(2, "0")}</span
                        >
                        <span
                            class="text-[9px] font-black tracking-wider text-app-text/40"
                            >HRS</span
                        >
                    </div>
                    <span class="text-white/20 pb-4">:</span>
                    <div class="flex flex-col items-center min-w-[30px]">
                        <span
                            class="font-mono text-xl font-bold {uiConfig.colorPrefix}"
                            >{minutes.toString().padStart(2, "0")}</span
                        >
                        <span
                            class="text-[9px] font-black tracking-wider text-app-text/40"
                            >MIN</span
                        >
                    </div>
                </div>
            {/if}

            <!-- Contextual Action Button -->
            <a
                href={uiConfig.route}
                class="w-full md:w-auto px-6 py-3 rounded-lg font-bold tracking-[1.5px] text-xs transition-all flex items-center justify-center gap-2 {uiConfig.btnColor}"
            >
                <uiConfig.icon size={16} strokeWidth={2.5} />
                {uiConfig.btnLabel}
            </a>
        </div>
    </div>
</div>
