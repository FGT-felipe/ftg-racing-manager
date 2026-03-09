<script lang="ts">
    interface Props {
        id: string;
        gender?: "M" | "F" | "male" | "female";
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

    // Simple hashing function to get deterministic numbers from string
    function hashString(str: string): number {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = (hash << 5) - hash + str.charCodeAt(i);
            hash |= 0;
        }
        return Math.abs(hash);
    }

    // Feature Selection Logic (Derived for reactivity)
    const h = $derived(hashString(seed || id || "default"));

    const skinTones = [
        "#FFDDBB", // Fair
        "#F1C27D", // Tanned
        "#E0AC69", // Medium
        "#8D5524", // Dark
        "#C68642", // Deep
        "#F3E5AB", // Warm Pale
    ];

    const hairColors = [
        "#2C1B18", // Black
        "#4B3621", // Dark Brown
        "#964B00", // Brown
        "#D4A017", // Blonde
        "#A52A2A", // Auburn
        "#704214", // Chestnut
        "#C0C0C0", // Silver/Grey
    ];

    const skinTone = $derived(skinTones[h % skinTones.length]);
    const hairColor = $derived(hairColors[(h >> 2) % hairColors.length]);
    const eyeColor = $derived(
        ["#3E2723", "#2E7D32", "#1565C0", "#4E342E"][(h >> 4) % 4],
    );

    const faceShapeIndex = $derived((h >> 1) % 3); // 0: Oval, 1: Round, 2: Squared
    const hairStyleIndex = $derived((h >> 3) % 10);
</script>

<div
    class="relative overflow-hidden rounded-[2rem] bg-zinc-950 border border-white/5 shadow-2xl {className}"
    style="width: {size}px; height: {size}px;"
>
    <!-- Background Glow -->
    <div
        class="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-40"
    ></div>

    <svg
        viewBox="0 0 100 100"
        class="w-full h-full drop-shadow-[0_10px_10px_rgba(0,0,0,0.5)]"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
    >
        <!-- Neck -->
        <path
            d="M40 85C40 85 40 95 50 95C60 95 60 85 60 85"
            stroke={skinTone}
            stroke-width="8"
            stroke-linecap="round"
            opacity="0.8"
        />

        <!-- Face Base -->
        {#if faceShapeIndex === 0}
            <!-- Oval -->
            <path
                d="M25 45C25 25 75 25 75 45C75 75 50 85 50 85C50 85 25 75 25 45Z"
                fill={skinTone}
            />
        {:else if faceShapeIndex === 1}
            <!-- Round -->
            <path
                d="M25 45C25 25 75 25 75 45C75 75 65 82 50 82C35 82 25 75 25 45Z"
                fill={skinTone}
            />
        {:else}
            <!-- Squared -->
            <path
                d="M25 40C25 25 75 25 75 40C75 65 70 78 50 82C30 78 25 65 25 40Z"
                fill={skinTone}
            />
        {/if}

        <!-- Eyes -->
        <g class="eyes">
            <!-- Left Eye -->
            <circle cx="38" cy="45" r="3.5" fill="white" />
            <circle cx="38" cy="45" r="2" fill={eyeColor} />
            <circle cx="39" cy="44" r="0.8" fill="white" opacity="0.6" />

            <!-- Right Eye -->
            <circle cx="62" cy="45" r="3.5" fill="white" />
            <circle cx="62" cy="45" r="2" fill={eyeColor} />
            <circle cx="63" cy="44" r="0.8" fill="white" opacity="0.6" />
        </g>

        <!-- Eyebrows -->
        <path
            d="M32 38C34 37 38 37 42 38.5"
            stroke={hairColor}
            stroke-width="1.5"
            stroke-linecap="round"
            opacity="0.8"
        />
        <path
            d="M58 38.5C62 37 66 37 68 38"
            stroke={hairColor}
            stroke-width="1.5"
            stroke-linecap="round"
            opacity="0.8"
        />

        <!-- Nose -->
        <path
            d="M48 55C48 55 50 57 52 55"
            stroke="black"
            stroke-width="0.5"
            opacity="0.2"
        />

        <!-- Mouth -->
        <path
            d="M42 68C45 70 55 70 58 68"
            stroke="black"
            stroke-width="1"
            stroke-linecap="round"
            opacity="0.3"
        />

        <!-- Hair (Simplified procedural styles) -->
        <g class="hair">
            {#if !isFemale}
                {#if hairStyleIndex % 3 === 0}
                    <!-- Short / Spiky -->
                    <path
                        d="M25 35C20 30 30 15 50 15C70 15 80 30 75 35L75 45C75 45 78 45 22 45L25 35Z"
                        fill={hairColor}
                    />
                {:else if hairStyleIndex % 3 === 1}
                    <!-- Side Part -->
                    <path
                        d="M23 45C20 35 30 20 45 18C65 15 80 25 77 45C72 45 28 45 23 45Z"
                        fill={hairColor}
                    />
                {:else}
                    <!-- Buzz cut look -->
                    <path
                        d="M25 45C25 30 35 25 50 25C65 25 75 30 75 45H25Z"
                        fill={hairColor}
                        opacity="0.6"
                    />
                {/if}
            {:else}
                <!-- Female Styles -->
                {#if hairStyleIndex % 3 === 0}
                    <!-- Long Straight -->
                    <path
                        d="M22 45C22 30 35 15 50 15C65 15 78 30 78 45V85H70V45C70 45 65 40 50 40C35 40 30 45 30 45V85H22V45Z"
                        fill={hairColor}
                    />
                {:else if hairStyleIndex % 3 === 1}
                    <!-- Bob / Mid -->
                    <path
                        d="M22 45C22 30 35 18 50 18C65 18 78 30 78 45V65C78 65 75 60 50 60C25 60 22 65 22 65V45Z"
                        fill={hairColor}
                    />
                {:else}
                    <!-- Ponytail/up -->
                    <circle cx="75" cy="30" r="10" fill={hairColor} />
                    <path
                        d="M25 45C25 30 35 20 50 20C65 20 75 30 75 45H25Z"
                        fill={hairColor}
                    />
                {/if}
            {/if}
        </g>
    </svg>
</div>

<style>
    .eyes {
        transform-origin: center 45%;
        animation: blink 4s infinite;
    }

    @keyframes blink {
        0%,
        90%,
        100% {
            transform: scaleY(1);
        }
        95% {
            transform: scaleY(0.1);
        }
    }
</style>
