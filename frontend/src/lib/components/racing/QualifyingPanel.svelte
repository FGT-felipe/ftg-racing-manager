<script lang="ts">
    import { onMount } from "svelte";
    import { fade, slide } from "svelte/transition";
    import { Timer, Trophy, ChevronRight, User } from "lucide-svelte";
    import CountryFlag from "$lib/components/ui/CountryFlag.svelte";
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
            
            const days = Math.floor(timeUntilNext / (1000 * 60 * 60 * 24));
            const hours = Math.floor((timeUntilNext % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            const mins = Math.floor((timeUntilNext % (1000 * 60 * 60)) / (1000 * 60));
            const secs = Math.floor((timeUntilNext % (1000 * 60)) / 1000);

            if (days > 0) {
                timeLeft = `${days}d ${hours.toString().padStart(2, "0")}:${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
            } else if (hours > 0) {
                timeLeft = `${hours.toString().padStart(2, "0")}:${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
            } else {
                timeLeft = `${mins.toString().padStart(2, "0")}:${secs.toString().padStart(2, "0")}`;
            }
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
                class="bg-app-surface/60 backdrop-blur-xl border border-app-border rounded-3xl p-12 flex flex-col items-center justify-center text-center gap-10 shadow-2xl relative overflow-hidden"
            >
                <div
                    class="absolute inset-0 bg-app-primary/5 animate-pulse pointer-events-none"
                ></div>
                
                <div class="flex flex-col items-center gap-6 relative z-10">
                    <div
                        class="w-20 h-20 rounded-2xl bg-app-primary/10 flex items-center justify-center text-app-primary border border-app-primary/20 shadow-lg"
                    >
                        <Timer size={40} />
                    </div>
    
                    <div class="max-w-md space-y-4">
                        <h3
                            class="font-black text-4xl lg:text-5xl uppercase italic text-app-text tracking-tighter leading-[0.9]"
                        >
                            {timeService.currentStatus === 'practice' ? 'Qualifying' : 'Session'} <span class="text-app-primary">{timeService.currentStatus === 'practice' ? 'Pending' : 'In Progress'}</span>
                        </h3>
                        <p
                            class="text-app-text/60 text-sm font-medium leading-relaxed"
                        >
                            {timeService.currentStatus === 'practice' 
                                ? 'Technical delegates are preparing the circuit for the official classification. Stay tuned for live telemetry.'
                                : 'The session is currently running. Technical delegates are processing initial lap data. Please wait for the official classifications.'}
                        </p>
                    </div>
                </div>

                <div
                    class="px-10 py-6 bg-app-surface border border-app-border rounded-2xl flex flex-col items-center min-w-[240px] shadow-xl relative z-10 group hover:scale-105 transition-transform duration-300"
                >
                    <span
                        class="text-[10px] font-black text-app-primary uppercase tracking-[0.3em] mb-3 font-mono opacity-80"
                        >TIME UNTIL RACE</span
                    >
                    <span
                        class="text-5xl font-black text-app-text tabular-nums font-mono italic tracking-tighter"
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
                                <div class="flex items-center gap-2">
                                    <p
                                        class="text-[13px] font-black text-app-text truncate uppercase"
                                    >
                                        {row.driverName}
                                    </p>
                                    <CountryFlag countryCode={row.countryCode} size="xs" />
                                </div>
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
