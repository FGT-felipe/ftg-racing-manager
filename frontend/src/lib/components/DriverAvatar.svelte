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
    const suffixes = [
        "a",
        "b",
        "c",
        "d",
        "e",
        "f",
        "g",
        "h",
        "i",
        "j",
        "k",
        "l",
    ];

    // Semi-deterministic selection using a simple hash of the ID
    function getHashIndex(str: string, len: number) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash);
        }
        return Math.abs(hash) % len;
    }

    const avatarUrl = $derived.by(() => {
        const index = getHashIndex(seed || id, suffixes.length);
        const suffix = suffixes[index];
        const folder = isFemale ? "female" : "male";
        const prefix = isFemale ? "female_driver" : "male_driver";
        return `/${folder}/${prefix}_${suffix}.png`;
    });
</script>

<div
    class="relative overflow-hidden rounded-[2rem] bg-zinc-950 border border-white/5 shadow-2xl {className}"
    style="width: {size}px; height: {size}px;"
>
    <!-- Driver Portrait -->
    <img
        src={avatarUrl}
        alt="Driver Avatar"
        class="w-full h-full object-cover object-center"
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
