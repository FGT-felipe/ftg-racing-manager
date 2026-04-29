<script lang="ts">
    import { onMount, onDestroy } from 'svelte';
    import type { SeasonFormEntry } from '$lib/types';

    let { data, totalTeams }: { data: SeasonFormEntry[]; totalTeams: number } = $props();

    let canvas: HTMLCanvasElement;
    let chart: import('chart.js').Chart | null = null;

    const GOLD = 'rgba(212, 175, 55, 1)';
    const GOLD_FAINT = 'rgba(212, 175, 55, 0.15)';
    const GRID = 'rgba(255, 255, 255, 0.06)';
    const LABEL = 'rgba(255, 255, 255, 0.35)';

    function buildChart() {
        if (!canvas) return;

        const sorted = [...data].sort((a, b) => a.round - b.round);
        const labels = sorted.map(e => `R${e.round}`);
        const positions = sorted.map(e => e.position);
        const maxY = Math.max(totalTeams, ...positions, 2);

        const yLabels: Record<number, string> = {};
        for (let i = 1; i <= maxY; i++) yLabels[i] = `P${i}`;

        import('chart.js').then(({ Chart, LineController, LineElement, PointElement, LinearScale, CategoryScale, Tooltip }) => {
            Chart.register(LineController, LineElement, PointElement, LinearScale, CategoryScale, Tooltip);

            chart?.destroy();
            chart = new Chart(canvas, {
                type: 'line',
                data: {
                    labels,
                    datasets: [{
                        data: positions,
                        borderColor: GOLD,
                        backgroundColor: GOLD_FAINT,
                        pointBackgroundColor: positions.map((_, i) => i === positions.length - 1 ? GOLD : 'rgba(212,175,55,0.6)'),
                        pointRadius: positions.map((_, i) => i === positions.length - 1 ? 6 : 4),
                        pointHoverRadius: 7,
                        borderWidth: 2,
                        tension: 0.3,
                        fill: false,
                    }],
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    animation: false,
                    plugins: {
                        legend: { display: false },
                        tooltip: {
                            callbacks: {
                                label: (ctx) => ` P${ctx.parsed.y}`,
                            },
                            backgroundColor: 'rgba(0,0,0,0.85)',
                            titleColor: GOLD,
                            bodyColor: '#fff',
                            borderColor: 'rgba(212,175,55,0.3)',
                            borderWidth: 1,
                        },
                    },
                    scales: {
                        x: {
                            grid: { color: GRID },
                            ticks: { color: LABEL, font: { size: 11, weight: 'bold' } },
                            border: { color: GRID },
                        },
                        y: {
                            reverse: true,
                            min: 1,
                            max: maxY,
                            ticks: {
                                stepSize: 1,
                                color: LABEL,
                                font: { size: 11, weight: 'bold' },
                                callback: (v) => `P${v}`,
                            },
                            grid: { color: GRID },
                            border: { color: GRID },
                        },
                    },
                },
            });
        });
    }

    onMount(() => buildChart());
    onDestroy(() => chart?.destroy());

    $effect(() => {
        // re-build when data changes
        data; totalTeams;
        buildChart();
    });
</script>

<canvas bind:this={canvas}></canvas>
