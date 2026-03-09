<script lang="ts">
    let {
        currentStars = 0,
        maxStars = 0,
        size = 14,
    } = $props<{
        currentStars: number;
        maxStars: number;
        size?: number;
    }>();
</script>

<div class="flex items-center">
    {#each Array(5) as _, i}
        {#if i < currentStars}
            <!-- Filled star (Current stars): Blue Accent -->
            <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                class="text-[#448AFF]"
                style="width: {size}px; height: {size}px;"
            >
                <path
                    d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"
                />
            </svg>
        {:else if i < maxStars}
            <!-- Filled star (Potential, < maxStars): Amber 50% opacity -->
            <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                class="text-[#FFC107]/50"
                style="width: {size}px; height: {size}px;"
            >
                <path
                    d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"
                />
            </svg>
        {:else}
            <!-- Outline star (Empty): White 20% opacity -->
            <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                class="text-white/20"
                style="width: {size}px; height: {size}px;"
            >
                <path
                    d="M22 9.24l-7.19-.62L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21 12 17.27 18.18 21l-1.63-7.03L22 9.24zM12 15.4l-3.76 2.27 1-4.28-3.32-2.88 4.38-.38L12 6.1l1.71 4.04 4.38.38-3.32 2.88 1 4.28L12 15.4z"
                />
            </svg>
        {/if}
    {/each}
</div>
