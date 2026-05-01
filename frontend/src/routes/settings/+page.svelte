<script lang="ts">
    import { authStore } from "$lib/stores/auth.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import { managerService } from "$lib/services/manager.svelte";
    import { teamStore } from "$lib/stores/team.svelte";
    import { tourStore } from "$lib/stores/tour.svelte";
    import { TEAM_RENAME_COST } from "$lib/constants/economics";
    import { t } from "$lib/utils/i18n";
    import {
        User,
        Settings,
        LogOut,
        Shield,
        Activity,
        Pencil,
        X,
        Check,
        Loader2,
        Flag,
        BookOpen
    } from "lucide-svelte";
    import { fade } from "svelte/transition";

    let profile = $derived(managerStore.profile);
    let team = $derived(teamStore.value.team);

    // Team rename state
    let isEditingName = $state(false);
    let newTeamName = $state("");
    let isSavingName = $state(false);
    let renameError = $state<string | null>(null);

    let isFirstRename = $derived((team?.nameChangeCount ?? 0) === 0);
    let canAffordRename = $derived(isFirstRename || (team?.budget ?? 0) >= TEAM_RENAME_COST);

    function startEditing() {
        newTeamName = team?.name ?? "";
        renameError = null;
        isEditingName = true;
    }

    function cancelEditing() {
        isEditingName = false;
        renameError = null;
    }

    async function reactivateTour() {
        await managerService.resetTour(authStore.user!.uid);
        tourStore.start();
    }

    async function saveTeamName() {
        if (!newTeamName.trim() || newTeamName.trim() === team?.name) {
            cancelEditing();
            return;
        }
        isSavingName = true;
        renameError = null;
        try {
            await teamStore.renameTeam(newTeamName.trim());
            isEditingName = false;
        } catch (e: any) {
            renameError = e.message ?? "Failed to rename team.";
        } finally {
            isSavingName = false;
        }
    }
</script>

<div class="max-w-4xl mx-auto p-6 lg:p-10" in:fade>
    <div class="flex items-center gap-4 mb-10">
        <div class="p-3 bg-app-primary/10 rounded-2xl text-app-primary">
            <Settings size={32} />
        </div>
        <div>
            <h1 class="text-3xl font-black uppercase tracking-widest text-app-text font-heading italic">
                {t('settings_title')}
            </h1>
            <p class="text-sm text-app-text/60">{t('settings_subtitle')}</p>
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
                    <span class="text-xs font-black uppercase tracking-widest text-app-text/80">{t('profile_section_title')}</span>
                </div>
                <div class="p-6 space-y-4">
                    <div class="flex flex-col gap-1.5">
                        <span class="text-[10px] uppercase font-bold text-app-text/40 tracking-widest">{t('profile_full_name_label')}</span>
                        <div class="px-4 py-3 bg-app-bg border border-app-border rounded-xl text-app-text/60 text-sm">
                            {profile?.firstName} {profile?.lastName}
                        </div>
                    </div>
                    <div class="flex flex-col gap-1.5">
                        <span class="text-[10px] uppercase font-bold text-app-text/40 tracking-widest">{t('profile_nationality_label')}</span>
                        <div class="px-4 py-3 bg-app-bg border border-app-border rounded-xl text-app-text/60 text-sm">
                            {profile?.country || "Default"}
                        </div>
                    </div>
                </div>
            </section>

            <!-- Team Identity -->
            <section class="bg-app-surface border border-app-border rounded-2xl overflow-hidden">
                <div class="px-6 py-4 border-b border-app-border bg-app-text/5 flex items-center gap-2">
                    <Flag size={16} class="text-app-primary" />
                    <span class="text-xs font-black uppercase tracking-widest text-app-text/80">{t('team_identity_section_title')}</span>
                </div>
                <div class="p-6 space-y-4">
                    <div class="flex flex-col gap-1.5">
                        <span class="text-[10px] uppercase font-bold text-app-text/40 tracking-widest">{t('team_name_label')}</span>

                        {#if isEditingName}
                            <div class="flex gap-2">
                                <input
                                    type="text"
                                    bind:value={newTeamName}
                                    maxlength={40}
                                    disabled={isSavingName}
                                    class="flex-1 bg-app-bg border border-app-primary/50 rounded-xl px-4 py-3 text-sm text-app-text focus:outline-none focus:border-app-primary transition-colors disabled:opacity-50"
                                />
                                <button
                                    onclick={saveTeamName}
                                    disabled={isSavingName || !newTeamName.trim() || !canAffordRename}
                                    aria-label="Confirm team rename"
                                    class="p-3 bg-green-500/10 hover:bg-green-500/20 border border-green-500/30 text-green-400 rounded-xl transition-all disabled:opacity-40"
                                >
                                    {#if isSavingName}
                                        <Loader2 size={16} class="animate-spin" />
                                    {:else}
                                        <Check size={16} />
                                    {/if}
                                </button>
                                <button
                                    onclick={cancelEditing}
                                    disabled={isSavingName}
                                    aria-label="Cancel team rename"
                                    class="p-3 bg-app-text/5 hover:bg-app-text/10 border border-app-border text-app-text/50 rounded-xl transition-all"
                                >
                                    <X size={16} />
                                </button>
                            </div>

                            <!-- Cost indicator -->
                            <div class="flex items-center justify-between text-[10px] font-bold uppercase tracking-widest mt-1">
                                <span class="text-app-text/40">{t('team_rename_cost_label')}</span>
                                {#if isFirstRename}
                                    <span class="text-green-400">{t('team_rename_free')}</span>
                                {:else if canAffordRename}
                                    <span class="text-yellow-400">$500,000</span>
                                {:else}
                                    <span class="text-red-400">{t('team_rename_insufficient_budget')}</span>
                                {/if}
                            </div>

                            {#if renameError}
                                <p class="text-[10px] text-red-400 font-bold uppercase tracking-widest">{renameError}</p>
                            {/if}
                        {:else}
                            <div class="flex items-center gap-3">
                                <div class="flex-1 px-4 py-3 bg-app-bg border border-app-border rounded-xl text-app-text/80 text-sm font-medium">
                                    {team?.name ?? "—"}
                                </div>
                                <button
                                    onclick={startEditing}
                                    aria-label="Edit team name"
                                    id="btn-rename-team"
                                    class="p-3 bg-app-primary/10 hover:bg-app-primary/20 border border-app-primary/20 text-app-primary rounded-xl transition-all"
                                >
                                    <Pencil size={16} />
                                </button>
                            </div>
                            {#if (team?.nameChangeCount ?? 0) > 0}
                                <p class="text-[10px] text-app-text/30 tracking-widest uppercase">
                                    Subsequent renames cost $500,000 · {team?.nameChangeCount} change{(team?.nameChangeCount ?? 0) === 1 ? "" : "s"} made
                                </p>
                            {:else}
                                <p class="text-[10px] text-app-text/30 tracking-widest uppercase">{t('team_rename_first_free')}</p>
                            {/if}
                        {/if}
                    </div>
                </div>
            </section>

            <!-- Onboarding Tour -->
            <section class="bg-app-surface border border-app-border rounded-2xl overflow-hidden">
                <div class="px-6 py-4 border-b border-app-border bg-app-text/5 flex items-center gap-2">
                    <BookOpen size={16} class="text-app-primary" />
                    <span class="text-xs font-black uppercase tracking-widest text-app-text/80">{t('tour_section_title')}</span>
                </div>
                <div class="p-6">
                    <button
                        onclick={reactivateTour}
                        data-tour="tour-reactivate"
                        class="px-6 py-3 bg-app-primary/10 hover:bg-app-primary/20 border border-app-primary/30 text-app-primary rounded-xl transition-all flex items-center gap-3 w-full justify-center group"
                    >
                        <BookOpen size={18} class="group-hover:scale-110 transition-transform" />
                        <span class="font-black uppercase tracking-widest text-xs">{t('tour_reactivate_button')}</span>
                    </button>
                    <p class="text-[10px] text-center text-app-text/30 mt-4">{t('tour_reactivate_hint')}</p>
                </div>
            </section>

            <section class="bg-app-surface border border-app-border rounded-2xl overflow-hidden">
                <div class="px-6 py-4 border-b border-app-border bg-app-text/5 flex items-center gap-2">
                    <Shield size={16} class="text-red-500" />
                    <span class="text-xs font-black uppercase tracking-widest text-app-text/80">{t('security_section_title')}</span>
                </div>
                <div class="p-6">
                    <button 
                        onclick={() => authStore.signOut()}
                        class="px-6 py-3 bg-red-500/10 hover:bg-red-500/20 border border-red-500/30 text-red-500 rounded-xl transition-all flex items-center gap-3 w-full justify-center group"
                    >
                        <LogOut size={18} class="group-hover:-translate-x-1 transition-transform" />
                        <span class="font-black uppercase tracking-widest text-xs">{t('signout_label')}</span>
                    </button>
                    <p class="text-[10px] text-center text-app-text/30 mt-4 italic">
                        Session managed via Firebase Authentication
                    </p>
                </div>
            </section>
        </div>
    </div>
</div>
