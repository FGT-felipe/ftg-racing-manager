<script lang="ts">
    import type { Component } from "svelte";
    import type { Icon } from "lucide-svelte";

    let {
        icon: IconComponent,
        title,
        description,
        extraContent,
        children,
    } = $props<{
        icon?: any;
        title: string;
        description: string;
        extraContent?: any;
        children?: any;
    }>();
</script>

<div
    class="bg-app-surface border border-app-border rounded-xl p-6 shadow-xl relative overflow-hidden group"
>
    <!-- Subtle Gradient Background -->
    <div
        class="absolute inset-0 bg-gradient-to-br from-app-primary/5 to-transparent opacity-50"
    ></div>

    <div class="relative flex flex-col md:flex-row md:items-start gap-6">
        {#if IconComponent}
            <div
                class="p-4 bg-app-primary/10 rounded-2xl text-app-primary shrink-0 self-start"
            >
                <IconComponent size={32} />
            </div>
        {/if}

        <div class="flex-grow">
            <h2
                class="text-xl font-heading font-black tracking-tight uppercase text-white mb-2"
            >
                {title}
            </h2>
            <p class="text-app-text/70 text-sm leading-relaxed max-w-2xl">
                {description}
            </p>

            {#if extraContent}
                <div class="mt-4 pt-4 border-t border-app-border/50">
                    {@render extraContent()}
                </div>
            {/if}

            {#if children}
                <div class="mt-4">
                    {@render children()}
                </div>
            {/if}
        </div>
    </div>
</div>
