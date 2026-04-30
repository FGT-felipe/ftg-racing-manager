<script lang="ts">
    import { t } from "$lib/utils/i18n";
    import { CAR_PART_MAX_LEVEL } from "$lib/constants/economics";
    import type { TeamChartData } from "$lib/services/league_car_stats_service.svelte";
    import { Wind, Zap, Navigation, ShieldCheck } from "lucide-svelte";

    let {
        teams,
        playerTeamId,
        loading = false,
    }: {
        teams: TeamChartData[];
        playerTeamId: string;
        loading?: boolean;
    } = $props();

    const PALETTE = [
        { stroke: "stroke-cyan-400",    fill: "fill-cyan-400",    bg: "bg-cyan-400"    },
        { stroke: "stroke-orange-400",  fill: "fill-orange-400",  bg: "bg-orange-400"  },
        { stroke: "stroke-purple-400",  fill: "fill-purple-400",  bg: "bg-purple-400"  },
        { stroke: "stroke-emerald-400", fill: "fill-emerald-400", bg: "bg-emerald-400" },
        { stroke: "stroke-rose-400",    fill: "fill-rose-400",    bg: "bg-rose-400"    },
        { stroke: "stroke-yellow-400",  fill: "fill-yellow-400",  bg: "bg-yellow-400"  },
        { stroke: "stroke-blue-400",    fill: "fill-blue-400",    bg: "bg-blue-400"    },
        { stroke: "stroke-pink-400",    fill: "fill-pink-400",    bg: "bg-pink-400"    },
        { stroke: "stroke-teal-400",    fill: "fill-teal-400",    bg: "bg-teal-400"    },
        { stroke: "stroke-indigo-400",  fill: "fill-indigo-400",  bg: "bg-indigo-400"  },
        { stroke: "stroke-amber-400",   fill: "fill-amber-400",   bg: "bg-amber-400"   },
        { stroke: "stroke-lime-400",    fill: "fill-lime-400",    bg: "bg-lime-400"    },
    ];

    const STATS = [
        { key: "aero"        as keyof TeamChartData, labelKey: "league_car_levels_chart_aero"        as const, icon: Wind,        color: "text-cyan-400"    },
        { key: "powertrain"  as keyof TeamChartData, labelKey: "league_car_levels_chart_powertrain"  as const, icon: Zap,         color: "text-orange-400"  },
        { key: "chassis"     as keyof TeamChartData, labelKey: "league_car_levels_chart_chassis"     as const, icon: Navigation,  color: "text-purple-400"  },
        { key: "reliability" as keyof TeamChartData, labelKey: "league_car_levels_chart_reliability" as const, icon: ShieldCheck, color: "text-emerald-400" },
    ];

    // SVG layout — B reduced since X labels are now HTML
    const L = 26;   // left margin — Y axis labels
    const R = 10;   // right margin
    const T = 10;   // top
    const B = 4;    // minimal bottom padding inside SVG
    const CW = 440; // chart width
    const CH = 200; // chart height

    const SVG_W = L + CW + R;
    const SVG_H = T + CH + B;

    // Percentage-based horizontal insets so the HTML X-axis row aligns with SVG columns
    const xPadLeft  = `${((L      / SVG_W) * 100).toFixed(2)}%`;
    const xPadRight = `${((R      / SVG_W) * 100).toFixed(2)}%`;

    // Y-axis zoom
    let yZoom = $state(false);

    const dataMin = $derived(
        teams.length === 0 ? 0 :
        Math.min(...teams.flatMap(team => STATS.map(s => Number(team[s.key]) || 0)))
    );
    const dataMax = $derived(
        teams.length === 0 ? CAR_PART_MAX_LEVEL :
        Math.max(...teams.flatMap(team => STATS.map(s => Number(team[s.key]) || 0)))
    );

    const yMin = $derived(yZoom ? Math.max(0, dataMin - 1) : 0);
    const yMax = $derived(yZoom ? Math.min(CAR_PART_MAX_LEVEL, dataMax + 1) : CAR_PART_MAX_LEVEL);

    const yTicks = $derived(
        yZoom
            ? Array.from({ length: 5 }, (_, i) => Math.round(yMin + (i / 4) * (yMax - yMin)))
            : [0, 5, 10, 15, 20]
    );

    function statX(i: number): number {
        return L + (i / (STATS.length - 1)) * CW;
    }

    function levelY(level: number): number {
        const v = Math.min(Math.max(Number(level) || 0, yMin), yMax);
        const range = yMax - yMin || 1;
        return T + CH - ((v - yMin) / range) * CH;
    }

    function teamPolyPoints(team: TeamChartData): string {
        return STATS
            .map((s, i) => `${statX(i).toFixed(1)},${levelY(team[s.key] as number).toFixed(1)}`)
            .join(" ");
    }

    function color(i: number) { return PALETTE[i % PALETTE.length]; }

    const playerIdx = $derived(teams.findIndex(t => t.teamId === playerTeamId));

    // Team visibility
    let hiddenTeams = $state(new Set<string>());

    function toggleTeam(teamId: string) {
        if (teamId === playerTeamId) return;
        const next = new Set(hiddenTeams);
        if (next.has(teamId)) next.delete(teamId); else next.add(teamId);
        hiddenTeams = next;
    }

    function isVisible(teamId: string): boolean {
        return teamId === playerTeamId || !hiddenTeams.has(teamId);
    }
</script>

<div class="bg-app-surface border border-app-border rounded-2xl p-5 flex flex-col gap-3">

    <!-- Header -->
    <div class="flex items-center justify-between">
        <span class="text-[10px] font-bold text-app-text/40 uppercase tracking-[0.2em]">
            {t("league_car_levels_title")}
        </span>
        {#if teams.length >= 2}
            <button
                onclick={() => { yZoom = !yZoom; }}
                class="flex items-center gap-1 px-2 py-0.5 rounded-md border text-[8.5px] font-bold uppercase tracking-widest transition-all
                       {yZoom
                           ? 'border-app-primary text-app-primary bg-app-primary/10'
                           : 'border-app-border text-app-text/40 hover:border-app-text/30'}"
                aria-label={t("league_car_levels_chart_zoom")}
            >
                {yZoom ? `${yMin}–${yMax} ✕` : t("league_car_levels_chart_zoom")}
            </button>
        {/if}
    </div>

    {#if loading}
        <div class="rounded-xl bg-app-border/20 animate-pulse" style="height:{SVG_H + 60}px"></div>
    {:else if teams.length < 2}
        <div class="flex items-center justify-center border border-app-border border-dashed rounded-xl min-h-[160px]">
            <span class="text-[10px] font-black text-app-text/20 uppercase tracking-[0.3em]">
                {t("league_car_levels_chart_no_data")}
            </span>
        </div>
    {:else}
        <!-- SVG chart -->
        <svg
            viewBox="0 0 {SVG_W} {SVG_H}"
            width="100%"
            preserveAspectRatio="xMidYMid meet"
            aria-label={t("league_car_levels_title")}
            class="overflow-visible"
        >
            <!-- Horizontal grid lines + left Y labels -->
            {#each yTicks as tick}
                {@const y = levelY(tick)}
                <line x1={L} y1={y} x2={L + CW} y2={y} class="stroke-app-border/30 stroke-[0.5]" />
                <text x={L - 4} y={y} dy="0.35em" text-anchor="end" font-size="7" class="fill-app-text/35">{tick}</text>
            {/each}

            <!-- Vertical stat column guides (no text labels — handled in HTML below) -->
            {#each STATS as _stat, i}
                {@const x = statX(i)}
                <line x1={x} y1={T} x2={x} y2={T + CH} class="stroke-app-border/20 stroke-[0.5]" />
            {/each}

            <!-- Non-player team lines -->
            {#each teams as team, i}
                {#if team.teamId !== playerTeamId && isVisible(team.teamId)}
                    <polyline
                        points={teamPolyPoints(team)}
                        class="fill-none {color(i).stroke} stroke-[1] opacity-60"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                    />
                    {#each STATS as stat, si}
                        <circle cx={statX(si)} cy={levelY(team[stat.key] as number)} r="2.5" class="{color(i).fill} stroke-none opacity-70" />
                    {/each}
                {/if}
            {/each}

            <!-- Player team line on top -->
            {#if playerIdx >= 0}
                {@const team = teams[playerIdx]}
                <polyline
                    points={teamPolyPoints(team)}
                    class="fill-none stroke-app-primary stroke-[2.5]"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                />
                {#each STATS as stat, si}
                    <circle cx={statX(si)} cy={levelY(team[stat.key] as number)} r="5"   class="fill-none stroke-app-primary stroke-[1.5]" />
                    <circle cx={statX(si)} cy={levelY(team[stat.key] as number)} r="3.5" class="{color(playerIdx).fill} stroke-none" />
                {/each}
            {/if}
        </svg>

        <!-- X-axis labels — HTML row aligned with SVG stat columns -->
        <div
            class="flex justify-between -mt-1"
            style="padding-left:{xPadLeft}; padding-right:{xPadRight};"
        >
            {#each STATS as stat}
                <div class="flex flex-col items-center gap-0.5">
                    <svelte:component this={stat.icon} size={10} class={stat.color} />
                    <span class="text-[8px] font-bold uppercase tracking-widest {stat.color}">
                        {t(stat.labelKey)}
                    </span>
                </div>
            {/each}
        </div>

        <!-- Legend — clickable per team -->
        <div class="flex flex-wrap gap-x-2 gap-y-1.5 pt-1 border-t border-app-border/30">
            {#each teams as team, i}
                {@const isPlayer = team.teamId === playerTeamId}
                {@const visible = isVisible(team.teamId)}
                <button
                    onclick={() => toggleTeam(team.teamId)}
                    disabled={isPlayer}
                    class="flex items-center gap-1.5 px-1.5 py-0.5 rounded-md border transition-all
                           {isPlayer
                               ? 'border-app-primary/30 cursor-default order-first'
                               : visible
                                   ? 'border-app-border hover:border-app-text/30 cursor-pointer'
                                   : 'border-transparent opacity-30 cursor-pointer'}"
                    aria-label={team.name}
                    aria-pressed={visible}
                >
                    <span class="w-5 h-0.5 rounded-full inline-block {isPlayer ? 'bg-app-primary' : color(i).bg}"></span>
                    <span class="text-[8.5px] {isPlayer ? 'font-bold text-app-primary' : 'font-normal text-app-text/40'} whitespace-nowrap">
                        {team.name}
                    </span>
                </button>
            {/each}
        </div>
    {/if}
</div>
