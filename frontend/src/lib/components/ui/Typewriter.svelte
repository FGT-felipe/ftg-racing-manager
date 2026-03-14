<script lang="ts">
    import { onMount, untrack } from 'svelte';

    let { text = "", speed = 30 } = $props<{ text?: string, speed?: number }>();
    
    let displayedText = $state("");
    let currentIndex = 0;
    let timeoutId: any;

    function startTypewriter() {
        clearTimeout(timeoutId);
        displayedText = "";
        currentIndex = 0;
        type();
    }

    function type() {
        if (currentIndex < text.length) {
            displayedText += text[currentIndex];
            currentIndex++;
            timeoutId = setTimeout(type, speed);
        }
    }

    $effect(() => {
        // Track text, but don't track the state updates inside startTypewriter
        const t = text;
        untrack(() => {
            if (t) {
                startTypewriter();
            } else {
                displayedText = "";
            }
        });
    });

    onMount(() => {
        return () => clearTimeout(timeoutId);
    });
</script>

<span>{displayedText}</span>
