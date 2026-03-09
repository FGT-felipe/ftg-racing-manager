<script lang="ts">
    let { size = 40, withText = true } = $props<{
        size?: number;
        withText?: boolean;
    }>();

    // "FTG" size calculation
    let topTextSize = $derived(size * 0.6);

    // "RACING MANAGER" size calculation
    let bottomTextSize = $derived(size * 0.18);
</script>

<!-- Inline style for Montserrat import to ensure the specific weights are available if not globally loaded -->
<svelte:head>
    <link
        href="https://fonts.googleapis.com/css2?family=Montserrat:wght@600;900&display=swap"
        rel="stylesheet"
    />
</svelte:head>

{#if withText}
    <div class="flex flex-col items-center justify-center text-center">
        <!-- FTG Top Label -->
        <span
            class="text-app-primary mix-blend-normal m-0 p-0 tracking-[-1.0px] leading-none"
            style="font-family: 'Montserrat', sans-serif; font-weight: 900; font-size: {topTextSize}px; line-height: 1.0;"
        >
            FTG
        </span>

        <!-- FORMULA TRACK GLORY Bottom Label -->
        <span
            class="text-app-primary mix-blend-normal m-0 p-0 tracking-[2px]"
            style="font-family: 'Montserrat', sans-serif; font-weight: 600; font-size: {bottomTextSize}px; margin-top: 2px;"
        >
            FORMULA TRACK GLORY
        </span>
    </div>
{/if}
