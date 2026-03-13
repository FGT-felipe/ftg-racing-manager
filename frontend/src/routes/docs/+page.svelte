<script lang="ts">
    import { Building2, Cpu, Package, BookOpen, ChevronRight, Globe, Languages } from "lucide-svelte";
    import { fly } from "svelte/transition";

    const sections = [
        { id: "architecture", title: "Arquitectura / Architecture", icon: Building2, color: "text-blue-400" },
        { id: "components", title: "Componentes / Components", icon: Package, color: "text-emerald-400" },
        { id: "product", title: "Producto / Product", icon: BookOpen, color: "text-amber-400" },
        { id: "business_rules", title: "Reglas de Negocio / Business Rules", icon: Cpu, color: "text-red-400" },
        { id: "services", title: "Servicios / Services", icon: Globe, color: "text-purple-400" },
        { id: "database", title: "Base de Datos / Database", icon: Building2, color: "text-indigo-400" },
        { id: "recommendations", title: "Recomendaciones / Recommendations", icon: Cpu, color: "text-rose-400" },
        { id: "standards", title: "Estándares / Standards", icon: Languages, color: "text-pink-400" }
    ];

    let selectedSection = $state("architecture");
    let language = $state<"human" | "ai">("human");

    // Dynamic import of markdown files could be done here if using a plugin like mdsvex
    // For now, we will simulate the content display
</script>

<svelte:head>
    <title>Technical Documentation | Internal</title>
</svelte:head>

<div class="p-6 md:p-10 w-full max-w-[1400px] mx-auto text-app-text min-h-screen animate-fade-in">
    <header class="flex flex-col gap-2 mb-12">
        <div class="flex items-center gap-3">
            <div class="p-2 rounded-lg bg-app-primary/10 text-app-primary">
                <BookOpen size={24} />
            </div>
            <span class="text-[10px] font-black tracking-[0.3em] text-app-primary/40 uppercase font-heading">Internal Technical Base</span>
        </div>
        <div class="flex flex-wrap items-end justify-between gap-6">
            <h1 class="text-4xl lg:text-5xl font-heading font-black tracking-tighter uppercase italic text-app-text mt-1">
                Tech <span class="text-app-primary">Documentation</span>
            </h1>

            <div class="flex bg-app-surface border border-app-border rounded-2xl p-1 p-1">
                <button 
                    onclick={() => language = "human"}
                    class="px-6 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all {language === 'human' ? 'bg-app-primary text-black' : 'text-app-text/40 hover:text-app-text'}"
                >
                    Human (ES)
                </button>
                <button 
                    onclick={() => language = "ai"}
                    class="px-6 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all {language === 'ai' ? 'bg-app-primary text-black' : 'text-app-text/40 hover:text-app-text'}"
                >
                    AI (EN)
                </button>
            </div>
        </div>
    </header>

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
        <!-- Sidebar Navigation -->
        <aside class="lg:col-span-3 flex flex-col gap-2">
            {#each sections as section}
                <button
                    onclick={() => selectedSection = section.id}
                    class="flex items-center justify-between p-5 rounded-2xl border transition-all group {selectedSection === section.id ? 'bg-app-surface border-app-primary/50 shadow-lg' : 'bg-app-surface/40 border-app-border hover:border-app-text/20'}"
                >
                    <div class="flex items-center gap-4">
                        <div class="{selectedSection === section.id ? section.color : 'text-app-text/20'} transition-colors group-hover:scale-110">
                            <section.icon size={20} />
                        </div>
                        <span class="text-[11px] font-black uppercase tracking-widest {selectedSection === section.id ? 'text-app-text' : 'text-app-text/40'}">
                            {language === 'human' ? section.title.split(' / ')[0] : section.title.split(' / ')[1]}
                        </span>
                    </div>
                    <ChevronRight size={16} class="{selectedSection === section.id ? 'text-app-primary opacity-100' : 'opacity-0'} transition-all" />
                </button>
            {/each}
        </aside>

        <!-- Content Area -->
        <main class="lg:col-span-9 bg-app-surface/60 border border-app-border rounded-[2.5rem] p-8 md:p-12 backdrop-blur-md relative overflow-hidden min-h-[600px]">
            <div class="absolute -top-20 -right-20 w-64 h-64 bg-app-text/5 blur-3xl rounded-full"></div>
            
            <div class="relative z-10 prose prose-invert max-w-none">
                <div class="flex items-center gap-4 mb-8 opacity-30">
                    <BookOpen size={16} />
                    <span class="text-[10px] font-black uppercase tracking-widest">Documentation / {selectedSection} / {language}</span>
                </div>

                {#if language === 'human'}
                    <p class="text-app-text/60 italic">Documentation content is being loaded from markdown files at `/src/routes/docs/human/`</p>
                    <h2 class="text-3xl font-black uppercase italic tracking-tighter text-app-text mb-6">
                        {sections.find(s => s.id === selectedSection)?.title.split(' / ')[0]}
                    </h2>
                    <p class="text-app-text/40 leading-relaxed max-w-2xl">
                        Esta sección contiene el conocimiento técnico detallado para el equipo de desarrollo.
                    </p>
                {:else}
                    <p class="text-app-text/60 italic">Documentation content is being loaded from markdown files at `/src/routes/docs/ai/`</p>
                    <h2 class="text-3xl font-black uppercase italic tracking-tighter text-app-text mb-6">
                        {sections.find(s => s.id === selectedSection)?.title.split(' / ')[1]}
                    </h2>
                    <p class="text-app-text/40 leading-relaxed max-w-2xl">
                        This section contains condensed, structured engineering data optimized for AI context parsing.
                    </p>
                {/if}
            </div>
        </main>
    </div>
</div>

<style>
    :global(.font-heading) {
        font-family: "Outfit", sans-serif;
    }
</style>
