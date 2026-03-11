<script lang="ts">
    import { authStore } from "$lib/stores/auth.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { 
        User, 
        Settings, 
        LogOut, 
        Shield, 
        Bell, 
        Moon, 
        Sun,
        Activity
    } from "lucide-svelte";
    import { fade } from "svelte/transition";

    let profile = $derived(managerStore.profile);
    let team = $derived(teamStore.value.team);

    let isDarkMode = $state(true); // This would ideally sync with a theme store
</script>

<div class="max-w-4xl mx-auto p-6 lg:p-10" in:fade>
    <div class="flex items-center gap-4 mb-10">
        <div class="p-3 bg-app-primary/10 rounded-2xl text-app-primary">
            <Settings size={32} />
        </div>
        <div>
            <h1 class="text-3xl font-black uppercase tracking-widest text-app-text font-heading italic">
                Account Settings
            </h1>
            <p class="text-sm text-app-text/60">Manage your manager profile and application preferences.</p>
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <!-- Sidebar context -->
        <div class="space-y-4">
            <div class="bg-app-surface/50 border border-app-border rounded-2xl p-6 flex flex-col items-center text-center gap-4">
                <div class="w-20 h-20 rounded-full bg-app-primary/10 flex items-center justify-center text-app-primary border-2 border-app-primary/20">
                    <User size={40} />
                </div>
                <div>
                    <h3 class="font-bold text-app-text">{profile?.firstName} {profile?.lastName}</h3>
                    <p class="text-xs text-app-text/40">{authStore.user?.email}</p>
                </div>
                <div class="px-3 py-1 bg-app-primary text-app-primary-foreground text-[10px] font-black rounded uppercase tracking-widest">
                    {profile?.role || "Manager"}
                </div>
            </div>
        </div>

        <!-- Main Settings Area -->
        <div class="md:col-span-2 space-y-6">
            <section class="bg-app-surface border border-app-border rounded-2xl overflow-hidden">
                <div class="px-6 py-4 border-b border-app-border bg-app-text/5 flex items-center gap-2">
                    <Activity size={16} class="text-app-primary" />
                    <span class="text-xs font-black uppercase tracking-widest text-app-text/80">Profile Information</span>
                </div>
                <div class="p-6 space-y-4">
                    <div class="flex flex-col gap-1.5">
                        <span class="text-[10px] uppercase font-bold text-app-text/40 tracking-widest">Full Name</span>
                        <div class="px-4 py-3 bg-app-bg border border-app-border rounded-xl text-app-text/60 text-sm">
                            {profile?.firstName} {profile?.lastName}
                        </div>
                    </div>
                    <div class="flex flex-col gap-1.5">
                        <span class="text-[10px] uppercase font-bold text-app-text/40 tracking-widest">Nationality</span>
                        <div class="px-4 py-3 bg-app-bg border border-app-border rounded-xl text-app-text/60 text-sm">
                            {profile?.country || "Default"}
                        </div>
                    </div>
                </div>
            </section>

            <section class="bg-app-surface border border-app-border rounded-2xl overflow-hidden">
                <div class="px-6 py-4 border-b border-app-border bg-app-text/5 flex items-center gap-2">
                    <Shield size={16} class="text-red-500" />
                    <span class="text-xs font-black uppercase tracking-widest text-app-text/80">Security</span>
                </div>
                <div class="p-6">
                    <button 
                        onclick={() => authStore.signOut()}
                        class="px-6 py-3 bg-red-500/10 hover:bg-red-500/20 border border-red-500/30 text-red-500 rounded-xl transition-all flex items-center gap-3 w-full justify-center group"
                    >
                        <LogOut size={18} class="group-hover:-translate-x-1 transition-transform" />
                        <span class="font-black uppercase tracking-widest text-xs">Sign Out from Session</span>
                    </button>
                    <p class="text-[10px] text-center text-app-text/30 mt-4 italic">
                        Session managed via Firebase Authentication
                    </p>
                </div>
            </section>
        </div>
    </div>
</div>
