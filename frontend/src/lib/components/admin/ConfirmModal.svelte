<script lang="ts">
    import { X, AlertTriangle } from "lucide-svelte";
    import { fade, scale } from "svelte/transition";

    let { 
        show = $bindable(false), 
        title = "Confirm Dangerous Action", 
        description = "This action cannot be undone. Please confirm you want to proceed.",
        confirmText = "Execute",
        requireWord = "",
        onConfirm
    } = $props();

    let userInput = $state("");
    let isConfirmed = $derived(!requireWord || userInput.toLowerCase() === requireWord.toLowerCase());

    function handleConfirm() {
        if (!isConfirmed) return;
        onConfirm();
        show = false;
        userInput = "";
    }

    function handleClose() {
        show = false;
        userInput = "";
    }
</script>

{#if show}
    <!-- svelte-ignore a11y_click_events_have_key_events -->
    <!-- svelte-ignore a11y_no_static_element_interactions -->
    <div 
        class="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-black/80 backdrop-blur-sm"
        transition:fade={{ duration: 200 }}
        onclick={handleClose}
    >
        <div 
            class="bg-app-surface border border-app-border rounded-[2rem] w-full max-w-md overflow-hidden shadow-2xl"
            transition:scale={{ duration: 200, start: 0.95 }}
            onclick={(e) => e.stopPropagation()}
        >
            <div class="p-8 border-b border-app-border bg-red-500/5 flex items-center gap-4">
                <div class="p-3 rounded-2xl bg-red-500/10 text-red-500">
                    <AlertTriangle size={24} />
                </div>
                <div>
                    <h3 class="text-xl font-heading font-black tracking-tighter uppercase italic">{title}</h3>
                    <p class="text-[10px] text-red-500/60 font-black uppercase tracking-widest mt-1">Security Verification Required</p>
                </div>
            </div>

            <div class="p-8 flex flex-col gap-6">
                <p class="text-app-text/60 leading-relaxed text-sm">
                    {description}
                </p>

                {#if requireWord}
                    <div class="flex flex-col gap-2">
                        <label for="confirm-word" class="text-[10px] font-black uppercase tracking-widest text-app-text/40">
                            Type <span class="text-app-primary">"{requireWord}"</span> to confirm:
                        </label>
                        <input 
                            id="confirm-word"
                            type="text" 
                            bind:value={userInput}
                            placeholder="Type here..."
                            class="bg-black/40 border border-app-border rounded-xl p-4 text-sm focus:border-red-500/50 outline-none transition-all font-mono"
                        />
                    </div>
                {/if}

                <div class="grid grid-cols-2 gap-4 mt-2">
                    <button 
                        onclick={handleClose}
                        class="p-4 rounded-2xl border border-app-border text-[10px] font-black uppercase tracking-widest hover:bg-app-text/5 transition-all"
                    >
                        Cancel
                    </button>
                    <button 
                        onclick={handleConfirm}
                        disabled={!isConfirmed}
                        class="p-4 rounded-2xl bg-red-600 text-white text-[10px] font-black uppercase tracking-widest disabled:opacity-30 disabled:grayscale transition-all hover:bg-red-500 shadow-lg shadow-red-900/20"
                    >
                        {confirmText}
                    </button>
                </div>
            </div>
        </div>
    </div>
{/if}

<style>
    .font-heading {
        font-family: "Outfit", sans-serif;
    }
</style>
