<script lang="ts">
    import { Zap, Wind, Navigation, ShieldCheck } from "lucide-svelte";

    let { stats, carLabel } = $props<{
        stats: Record<string, number>;
        carLabel: string;
    }>();

    const aero = $derived(stats.aero || 1);
    const powertrain = $derived(stats.powertrain || 1);
    const chassis = $derived(stats.chassis || 1);
    const reliability = $derived(stats.reliability || 1);

    // Calculations based on levels (1-20)
    const powerBoost = $derived(((powertrain / 20) * 100).toFixed(1));
    const aeroBoost = $derived(((aero / 20) * 100).toFixed(1));
    const handlingBoost = $derived(((chassis / 20) * 100).toFixed(1));
    const reliabilityVal = $derived(((reliability / 20) * 100).toFixed(1));

    const statRows = $derived([
        {
            label: "Power",
            value: powerBoost,
            color: "text-orange-400",
            bg: "bg-orange-400",
            icon: Zap,
        },
        {
            label: "Aero",
            value: aeroBoost,
            color: "text-cyan-400",
            bg: "bg-cyan-400",
            icon: Wind,
        },
        {
            label: "Handling",
            value: handlingBoost,
            color: "text-purple-400",
            bg: "bg-purple-400",
            icon: Navigation,
        },
        {
            label: "Reliability",
            value: reliabilityVal,
            color: "text-emerald-400",
            bg: "bg-emerald-400",
            icon: ShieldCheck,
        },
    ]);
</script>

<div
    class="bg-app-surface/50 border border-app-border rounded-xl p-4 shadow-inner"
>
    <div
        class="flex items-center justify-between mb-4 border-b border-app-border/30 pb-2"
    >
        <span
            class="text-[10px] font-black uppercase tracking-widest text-app-primary"
        >
            {carLabel}
        </span>
        <span class="text-[9px] font-bold text-app-text/30 uppercase"
            >Performance Data</span
        >
    </div>

    <div class="space-y-4">
        {#each statRows as stat}
            <div class="space-y-1.5">
                <div class="flex justify-between items-center px-0.5">
                    <div class="flex items-center gap-1.5">
                        <stat.icon size={11} class="{stat.color} opacity-70" />
                        <span
                            class="text-[10px] font-bold text-app-text/60 uppercase racking-tighter"
                            >{stat.label}</span
                        >
                    </div>
                    <span class="text-[11px] font-black {stat.color}">
                        {stat.label === "Reliability" ? "" : "+"}{stat.value}%
                    </span>
                </div>
                <div
                    class="h-1.5 w-full bg-app-text/5 rounded-full overflow-hidden"
                >
                    <div
                        class="h-full {stat.bg} transition-all duration-500 ease-out"
                        style="width: {stat.value}%"
                    ></div>
                </div>
            </div>
        {/each}
    </div>
</div>
