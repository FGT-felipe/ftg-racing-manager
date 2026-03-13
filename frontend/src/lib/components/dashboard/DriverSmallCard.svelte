<script lang="ts">
    import type { Driver } from "$lib/types";
    import DriverStars from "$lib/components/DriverStars.svelte";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import { getFlagEmoji } from "$lib/utils/country";

    let { driver, carIndex } = $props<{
        driver: Driver;
        carIndex: number;
    }>();

    const DRIVING_STATS = [
        "braking",
        "cornering",
        "smoothness",
        "overtaking",
        "consistency",
        "adaptability",
    ];

    const currentStars = $derived(() => {
        if (!driver.stats) return 1;
        let sum = 0;
        let count = 0;
        for (const stat of DRIVING_STATS) {
            if (driver.stats[stat] !== undefined) {
                sum += driver.stats[stat];
                count++;
            }
        }
        if (count === 0) return 1;
        const avg = sum / count;
        let stars = Math.ceil(avg / 4.0);
        return Math.min(Math.max(stars, 1), driver.potential);
    });
</script>

<div
    class="flex items-center gap-3 p-3 bg-app-surface border border-app-border rounded-xl"
>
    <div class="relative">
        <div
            class="w-10 h-10 rounded-full bg-app-text/5 border border-app-border flex items-center justify-center overflow-hidden"
        >
            <DriverAvatar
                id={driver.id}
                gender={driver.gender}
                class="w-full h-full"
            />
        </div>
        <div
            class="absolute -bottom-1 -right-1 w-5 h-5 bg-app-primary text-app-primary-foreground rounded-full flex items-center justify-center text-[10px] font-black border-2 border-app-surface"
        >
            {carIndex === 0 ? "A" : "B"}
        </div>
    </div>

    <div class="flex-grow min-w-0">
        <div class="flex items-center justify-between gap-2">
            <h4
                class="text-xs font-black text-app-text uppercase truncate tracking-tight"
            >
                {driver.name}
            </h4>
            <span class="text-[9px] font-bold text-app-text/30 uppercase"
                >Car {carIndex === 0 ? "A" : "B"}</span
            >
        </div>
        <div class="mt-1 flex items-center justify-between">
            <DriverStars
                currentStars={currentStars()}
                maxStars={driver.potential}
                size={10}
            />
            <span class="text-[10px] font-bold text-app-primary">
                {driver.role}
            </span>
        </div>
    </div>
</div>
