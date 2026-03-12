<script lang="ts">
    import { onMount } from "svelte";
    import { fade, slide } from "svelte/transition";
    import { Timer, Trophy, ChevronRight, User } from "lucide-svelte";
    import { seasonStore } from "$lib/stores/season.svelte";
    import { timeService } from "$lib/services/time_service.svelte";
    import { db } from "$lib/firebase/config";
    import { doc, getDoc } from "firebase/firestore";

    let results = $state<any[]>([]);
    let isLoading = $state(true);
    let isCompleted = $derived(results.length > 0);
    let timeLeft = $state("");

    const nextEvent = $derived(seasonStore.nextEvent);

    onMount(() => {
        loadQualyData();

        const timer = setInterval(() => {
            const timeUntilNext = timeService.getTimeUntilNextEvent();
            const mins = Math.floor(timeUntilNext / 60000)
                .toString()
                .padStart(2, "0");
            const secs = Math.floor((timeUntilNext % 60000) / 1000)
                .toString()
                .padStart(2, "0");
            timeLeft = `${mins}:${secs}`;
        }, 1000);

        return () => clearInterval(timer);
    });

    async function loadQualyData() {
        if (!nextEvent || !seasonStore.value.season) return;

        try {
            // Find the race document (id pattern: {seasonId}_{eventIndex})
            const raceDocId = `${seasonStore.value.season.id}_${nextEvent.id}`;
            const raceRef = doc(db, "races", raceDocId);
            const raceSnap = await getDoc(raceRef);

            if (raceSnap.exists()) {
                const data = raceSnap.data();
                if (data.qualifyingResults) {
                    results = data.qualifyingResults;
                }
            }
        } catch (e) {
            console.error("Error loading qualy data:", e);
        } finally {
            isLoading = false;
        }
    }

    function formatTime(seconds: number) {
        if (seconds === 0 || !isFinite(seconds)) return "—";
        return `${seconds.toFixed(3)}s`;
    }
</script>

<div class="space-y-6">
    {#if isLoading}
        <div
            class="flex flex-col items-center justify-center py-20 gap-4 opacity-50"
        >
            <div
                class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"
            ></div>
            <span
                class="text-[10px] font-black uppercase tracking-widest text-app-primary"
                >Analyzing Telemetry...</span
            >
        </div>
    {:else}
        {#if !isCompleted}
            <div
                in:fade
                class="bg-app-surface border border-app-border rounded-2xl p-12 flex flex-col items-center justify-center text-center gap-6 shadow-xl"
            >
                <div
                    class="w-20 h-20 rounded-2xl bg-app-primary/10 flex items-center justify-center text-app-primary"
                >
                    <Timer size={40} />
                </div>

                <div class="max-w-md space-y-2">
                    <h3
                        class="font-black text-2xl uppercase italic text-app-text tracking-tight"
                    >
                        Qualifying in Progress
                    </h3>
                    <p
                        class="text-app-text/40 text-sm font-medium leading-relaxed"
                    >
                        The session is currently running. Technical delegates
                        are processing initial lap data. Please wait for the
                        official classifications.
                    </p>
                </div>

                <div
                    class="px-8 py-5 bg-app-text/30 rounded-2xl border border-app-border flex flex-col items-center min-w-[200px]"
                >
                    <span
                        class="text-[10px] font-black text-app-primary uppercase tracking-[0.2em] mb-2 font-mono"
                        >TIME UNTIL RACE</span
                    >
                    <span
                        class="text-4xl font-black text-app-text tabular-nums font-mono italic"
                        >{timeLeft}</span
                    >
                </div>
            </div>
        {/if}

        {#if results.length > 0}
            <div
                in:slide
                class="bg-app-surface border border-app-border rounded-2xl overflow-hidden shadow-2xl"
            >
                <div
                    class="p-6 border-b border-app-border bg-app-surface flex items-center justify-between"
                >
                    <div class="flex items-center gap-3">
                        <Trophy size={18} class="text-app-primary" />
                        <h3
                            class="font-black text-xs uppercase tracking-widest italic"
                        >
                            Official Classification
                        </h3>
                    </div>
                </div>

                <div class="divide-y divide-white/5">
                    {#each results as row, i}
                        <div
                            class="p-4 flex items-center gap-4 hover:bg-white/[0.02] transition-colors"
                        >
                            <div
                                class="w-8 h-8 rounded-lg bg-app-text/40 flex items-center justify-center font-black italic text-xs {i <
                                3
                                    ? 'text-app-primary'
                                    : 'text-app-text/20'}"
                            >
                                {i + 1}
                            </div>

                            <div class="flex-1 min-w-0">
                                <p
                                    class="text-[13px] font-black text-app-text truncate uppercase"
                                >
                                    {row.driverName}
                                </p>
                                <p
                                    class="text-[9px] font-bold text-app-text/30 uppercase tracking-widest"
                                >
                                    {row.teamName}
                                </p>
                            </div>

                            <div class="text-right">
                                <p
                                    class="text-sm font-black italic text-app-primary tabular-nums"
                                >
                                    {formatTime(row.lapTime)}
                                </p>
                            </div>
                        </div>
                    {/each}
                </div>
            </div>
        {/if}
    {/if}
</div>
