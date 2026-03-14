<script lang="ts">
    import { Building2, Cpu, Package, BookOpen, ChevronLeft, Globe, Languages, FileText, MoveLeft } from "lucide-svelte";
    import { fly, fade } from "svelte/transition";
    import { marked } from "marked";
    import { onMount } from "svelte";

    let { data } = $props();

    const sections = [
        { id: "arquitectura", ai_id: "architecture", title: "Arquitectura", icon: Building2, color: "text-blue-400" },
        { id: "componentes", ai_id: "components", title: "Componentes", icon: Package, color: "text-emerald-400" },
        { id: "producto", ai_id: "product", title: "Producto", icon: BookOpen, color: "text-amber-400" },
        { id: "reglas_negocio", ai_id: "business_rules", title: "Reglas de Negocio", icon: Cpu, color: "text-red-400" },
        { id: "base_datos", ai_id: "database_schema", title: "Base de Datos", icon: Database, color: "text-indigo-400" },
        { id: "servicios", ai_id: "services", title: "Servicios", icon: Globe, color: "text-purple-400" },
        { id: "recomendaciones", ai_id: "arch_recommendations", title: "Recomendaciones", icon: Cpu, color: "text-rose-400" },
        { id: "estandares", ai_id: "standards", title: "Estándares", icon: Languages, color: "text-pink-400" }
    ];

    let selectedSection = $state("arquitectura");
    let language = $state<"human" | "ai">("human");

    // Derived content
    let rawContent = $derived.by(() => {
        const cat = language;
        const sectionId = language === 'human' 
            ? selectedSection 
            : (sections.find(s => s.id === selectedSection)?.ai_id || selectedSection);
        
        return data.docsData[cat]?.[sectionId] || "# No content found\nThe requested documentation file could not be loaded.";
    });

    let htmlContent = $derived(marked.parse(rawContent));

    import { Database } from "lucide-svelte";
</script>

<svelte:head>
    <title>FTG Tech Base | Admin</title>
</svelte:head>

<div class="p-6 md:p-10 w-full max-w-[1400px] mx-auto text-app-text min-h-screen animate-fade-in flex flex-col gap-10">
    <header class="flex flex-col gap-6">
        <div class="flex items-center justify-between">
            <a href="/admin" class="flex items-center gap-3 group text-app-text/40 hover:text-app-primary transition-all">
                <div class="p-2 rounded-xl bg-app-surface border border-app-border group-hover:border-app-primary/40 group-hover:bg-app-primary/10 transition-all">
                    <MoveLeft size={16} />
                </div>
                <span class="text-[10px] font-black tracking-widest uppercase">Admin Terminal</span>
            </a>

            <div class="flex bg-app-surface border border-app-border rounded-2xl p-1 shadow-xl">
                <button 
                    onclick={() => language = "human"}
                    class="px-6 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all {language === 'human' ? 'bg-app-primary text-black shadow-lg shadow-app-primary/20' : 'text-app-text/40 hover:text-app-text'}"
                >
                    System (ES)
                </button>
                <button 
                    onclick={() => language = "ai"}
                    class="px-6 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all {language === 'ai' ? 'bg-app-primary text-black shadow-lg shadow-app-primary/20' : 'text-app-text/40 hover:text-app-text'}"
                >
                    AI Specification (EN)
                </button>
            </div>
        </div>

        <div class="flex flex-col gap-1">
            <h1 class="text-4xl lg:text-5xl font-heading font-black tracking-tighter uppercase italic text-app-text mt-1">
                Technical <span class="text-app-primary">Knowledge Base</span>
            </h1>
            <div class="flex items-center gap-2 opacity-30">
                <div class="w-1 h-1 rounded-full bg-app-primary"></div>
                <span class="text-[9px] font-black uppercase tracking-[0.3em]">Authorized Access Only</span>
            </div>
        </div>
    </header>

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        <!-- Sidebar Navigation -->
        <aside class="lg:col-span-3 flex flex-col gap-2 sticky top-10">
            {#each sections as section}
                <button
                    onclick={() => selectedSection = section.id}
                    class="flex items-center justify-between p-5 rounded-2xl border transition-all group {selectedSection === section.id ? 'bg-app-surface border-app-primary/50 shadow-lg' : 'bg-app-surface/40 border-app-border hover:border-app-text/20'}"
                >
                    <div class="flex items-center gap-4">
                        <div class="{selectedSection === section.id ? section.color : 'text-app-text/20'} transition-colors group-hover:scale-110">
                            <section.icon size={20} />
                        </div>
                        <span class="text-[10px] font-black uppercase tracking-widest {selectedSection === section.id ? 'text-app-text' : 'text-app-text/40'}">
                            {language === 'human' ? section.title : section.ai_id.replace('_', ' ')}
                        </span>
                    </div>
                    <ChevronLeft size={16} class="rotate-180 {selectedSection === section.id ? 'text-app-primary opacity-100' : 'opacity-0'} transition-all" />
                </button>
            {/each}
        </aside>

        <!-- Content Area -->
        <main class="lg:col-span-9 bg-app-surface/60 border border-app-border rounded-[2.5rem] p-8 md:p-16 backdrop-blur-md relative overflow-hidden min-h-[800px] shadow-2xl shadow-black/40">
            <div class="absolute -top-40 -right-40 w-96 h-96 bg-app-primary/5 blur-[100px] rounded-full"></div>
            
            <div class="relative z-10 prose prose-invert max-w-none prose-headings:font-heading prose-headings:font-black prose-headings:italic prose-headings:uppercase prose-headings:tracking-tighter prose-p:text-app-text/70 prose-p:leading-relaxed prose-strong:text-app-primary prose-code:text-app-primary prose-code:bg-app-primary/10 prose-code:px-2 prose-code:rounded prose-pre:bg-black/60 prose-pre:border prose-pre:border-app-border prose-pre:rounded-3xl">
                <!-- svelte-ignore svelte_transition_on_initial_render -->
                <div key={selectedSection + language} in:fade={{ duration: 200 }}>
                    {@html htmlContent}
                </div>
            </div>
        </main>
    </div>
</div>

<style>
    :global(.font-heading) {
        font-family: "Outfit", sans-serif;
    }

    /* Additional prose styling to match the premium theme */
    :global(.prose h1) {
        font-size: 3rem;
        margin-bottom: 2rem;
        border-bottom: 1px solid var(--border-color);
        padding-bottom: 1rem;
    }

    :global(.prose h2) {
        font-size: 1.5rem;
        margin-top: 3rem;
        color: var(--app-text);
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    :global(.prose h2::before) {
        content: "";
        width: 12px;
        height: 12px;
        background: var(--app-primary);
        border-radius: 3px;
        display: inline-block;
    }

    :global(.prose hr) {
        border-color: rgba(255, 255, 255, 0.05);
        margin: 4rem 0;
    }

    :global(.prose blockquote) {
        border-left: 4px solid var(--app-primary);
        background: rgba(197, 160, 89, 0.05);
        padding: 2rem;
        border-radius: 0 2rem 2rem 0;
        font-style: italic;
    }

    :global(.prose table) {
        width: 100%;
        border-collapse: collapse;
        margin: 2rem 0;
        background: rgba(0, 0, 0, 0.2);
        border-radius: 1.5rem;
        overflow: hidden;
    }

    :global(.prose th) {
        background: rgba(255, 255, 255, 0.03);
        padding: 1rem;
        text-align: left;
        font-size: 0.7rem;
        text-transform: uppercase;
        letter-spacing: 1px;
        color: var(--app-primary);
    }

    :global(.prose td) {
        padding: 1rem;
        border-top: 1px solid rgba(255, 255, 255, 0.03);
        font-size: 0.9rem;
    }
</style>
