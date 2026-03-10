<script lang="ts">
    interface Props {
        id: string;
        gender?: "M" | "F" | "male" | "female" | string;
        seed?: string;
        size?: number;
        class?: string;
    }

    let {
        id,
        gender = "M",
        seed,
        size = 100,
        class: className = "",
    }: Props = $props();

    const isFemale = $derived(gender === "F" || gender === "female");

    // Use professional DiceBear API for high-quality, procedural vector avatars
    // Style: 'avataaars' - Clean, modern, and professional
    const avatarUrl = $derived(
        `https://api.dicebear.com/7.x/avataaars/png?seed=${seed || id}&backgroundColor=transparent`,
    );
</script>

<div
    class="relative overflow-hidden rounded-[2rem] bg-zinc-950 border border-white/5 shadow-2xl {className}"
    style="width: {size}px; height: {size}px;"
>
    <!-- Professional Avatar from DiceBear -->
    <img
        src={avatarUrl}
        alt="Driver Avatar"
        class="w-full h-full object-cover transform scale-110 translate-y-2"
        crossorigin="anonymous"
        loading="lazy"
    />

    <!-- Premium Overlay Effects -->
    <div
        class="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent pointer-events-none"
    ></div>
    <div
        class="absolute inset-0 ring-1 ring-inset ring-white/5 pointer-events-none"
    ></div>
</div>

<style>
    /* Add subtle hover effect if desired */
    img {
        transition: transform 0.5s cubic-bezier(0.4, 0, 0.2, 1);
    }
</style>
