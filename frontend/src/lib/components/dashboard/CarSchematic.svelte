<script lang="ts">
    import { Zap, Wind, Navigation, ShieldCheck } from "lucide-svelte";

    let { stats, carLabel, condition = undefined, conditionTier = undefined } = $props<{
        stats: Record<string, number>;
        carLabel: string;
        condition?: number;
        conditionTier?: string;
    }>();

    const aero = $derived(stats.aero || 1);
    const powertrain = $derived(stats.powertrain || 1);
    const chassis = $derived(stats.chassis || 1);
    const reliability = $derived(stats.reliability || 1);

    const MAX_PART_LEVEL = 20;

    const avgLevel = $derived(((aero + powertrain + chassis + reliability) / 4).toFixed(1));

    const statRows = $derived([
        { label: "Power",       level: powertrain, color: "text-orange-400", bg: "bg-orange-400", icon: Zap        },
        { label: "Aero",        level: aero,       color: "text-cyan-400",   bg: "bg-cyan-400",   icon: Wind       },
        { label: "Handling",    level: chassis,    color: "text-purple-400", bg: "bg-purple-400", icon: Navigation },
        { label: "Reliability", level: reliability,color: "text-emerald-400",bg: "bg-emerald-400",icon: ShieldCheck},
    ]);
</script>

<div
    class="bg-app-surface/50 border border-app-border rounded-xl p-4 shadow-inner"
>
    <div
        class="flex items-center justify-between mb-4 border-b border-app-border/30 pb-2"
    >
        <span class="text-[10px] font-black uppercase tracking-widest text-app-primary">{carLabel}</span>
        <span class="text-[9px] font-bold text-app-text/30 uppercase tracking-widest">LVL {avgLevel}</span>
    </div>

    <div class="space-y-4">
        {#if condition !== undefined}
            {@const tierColor = conditionTier === 'green' ? 'text-green-400' : conditionTier === 'yellow' ? 'text-yellow-400' : conditionTier === 'orange' ? 'text-orange-400' : 'text-red-400'}
            {@const tierBg = conditionTier === 'green' ? 'bg-green-500' : conditionTier === 'yellow' ? 'bg-yellow-500' : conditionTier === 'orange' ? 'bg-orange-500' : 'bg-red-500'}
            <div class="space-y-1.5">
                <div class="flex justify-between items-center px-0.5">
                    <span class="text-[10px] font-bold text-app-text/60 uppercase tracking-tighter">Condition</span>
                    <span class="text-[11px] font-black {tierColor}">{condition}%</span>
                </div>
                <div class="h-1.5 w-full bg-app-text/5 rounded-full overflow-hidden">
                    <div class="h-full {tierBg} transition-all duration-500 ease-out" style="width: {condition}%"></div>
                </div>
            </div>
        {/if}
        {#each statRows as stat}
            <div class="space-y-1.5">
                <div class="flex justify-between items-center px-0.5">
                    <div class="flex items-center gap-1.5">
                        <stat.icon size={11} class="{stat.color} opacity-70" />
                        <span class="text-[10px] font-bold text-app-text/60 uppercase tracking-tighter">{stat.label}</span>
                    </div>
                    <span class="text-[11px] font-black {stat.color}">LVL {stat.level}</span>
                </div>
                <div class="h-1.5 w-full bg-app-text/5 rounded-full overflow-hidden">
                    <div class="h-full {stat.bg} transition-all duration-500 ease-out" style="width: {(stat.level / MAX_PART_LEVEL) * 100}%"></div>
                </div>
            </div>
        {/each}
    </div>
</div>
