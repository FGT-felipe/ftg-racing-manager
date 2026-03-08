<script lang="ts">
    import { ShieldAlert } from "lucide-svelte";
</script>

<svelte:head>
    <title>Management | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-6 md:p-8 animate-fade-in w-full max-w-[1200px] mx-auto text-app-text"
>
    <div class="flex items-center gap-3 mb-6">
        <ShieldAlert class="text-app-primary" size={32} />
        <h1 class="text-3xl font-heading font-black tracking-wide uppercase">
            Management
        </h1>
    </div>

    <div
        class="bg-app-surface border border-app-border rounded-xl p-8 text-app-text/60 text-center shadow-lg"
    >
        <p class="font-bold uppercase tracking-wider text-xs">
            Awaiting Implementation...
        </p>
        <p class="mt-2 text-sm">
            Targeting Personal, Finances, and Sponsors interfaces.
        </p>
    </div>
</div>
