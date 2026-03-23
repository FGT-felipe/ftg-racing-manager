<script lang="ts">
    import { CheckCircle2, ChevronRight, XCircle, AlertCircle, TrendingUp } from 'lucide-svelte';
    import { teamStore } from '$lib/stores/team.svelte';
    import { driverStore } from '$lib/stores/driver.svelte';
    import { t } from '$lib/utils/i18n';
    
    // Preparation steps Logic
    let team = $derived(teamStore.value.team);
    let drivers = $derived(driverStore.drivers);

    // Dynamic checklist states
    let hasMainSetups = $derived.by(() => {
        if (!team || !drivers) return false;

        const setups = team.weekStatus?.driverSetups || {};

        // Find main drivers
        const mainDrivers = drivers.filter((d: any) => d.carIndex === 0 || d.carIndex === 1);
        if (mainDrivers.length === 0) return false;

        // Check if all main drivers have race setups saved (this is the final goal)
        return mainDrivers.every((d: any) => {
            const driverSetup = setups[d.id];
            return driverSetup && driverSetup.race;
        });
    });

    let hasQualifyingSetups = $derived.by(() => {
        if (!team || !drivers) return false;

        const setups = team.weekStatus?.driverSetups || {};

        const mainDrivers = drivers.filter((d: any) => d.carIndex === 0 || d.carIndex === 1);
        if (mainDrivers.length === 0) return false;

        // Check if all main drivers have sent a qualifying setup (avoids morale/fitness penalty)
        return mainDrivers.every((d: any) => {
            const driverSetup = setups[d.id];
            return driverSetup?.isSetupSent === true;
        });
    });

    let hasSponsorsAssigned = $derived.by(() => {
        if (!team) return false;
        const sponsors = team.sponsors || {};
        // Just checking if at least one sponsor is assigned for now
        return Object.keys(sponsors).length > 0;
    });

    const checklist = $derived([
        {
            id: 'qualifying',
            title: 'Qualifying Setup',
            description: 'Send a qualifying setup to avoid fitness & morale penalties',
            isComplete: hasQualifyingSetups,
            link: '/racing',
            optional: false,
        },
        {
            id: 'setups',
            title: t('race_setups'),
            description: t('readiness_desc'),
            isComplete: hasMainSetups,
            link: '/racing',
            optional: false,
        },
        {
            id: 'sponsors',
            title: t('sponsors'),
            description: t('scouting_efforts', { country: 'Global' }), // Use existing key or create new
            isComplete: hasSponsorsAssigned,
            link: '/management/sponsors',
            optional: false,
        }
    ]);

    let progressValue = $derived.by(() => {
        const required = checklist.filter(c => !c.optional);
        const completed = required.filter(c => c.isComplete);
        return required.length > 0 ? (completed.length / required.length) * 100 : 0;
    });

</script>

<div class="bg-app-surface border border-app-border rounded-3xl p-6 lg:p-8 flex flex-col h-fit shadow-2xl relative overflow-hidden group">
    <!-- Background glowing accent -->
    <div class="absolute -top-24 -right-24 w-64 h-64 bg-app-primary/5 rounded-full blur-[60px] group-hover:bg-app-primary/10 transition-colors pointer-events-none"></div>

    <div class="flex items-center justify-between mb-8 relative z-10">
        <div>
            <h3 class="text-xl font-heading font-black italic uppercase tracking-tighter text-app-text">
                {t('race_prep_title').split(' ')[0]} <span class="text-app-primary">{t('race_prep_title').split(' ')[1] || ''}</span>
            </h3>
            <p class="text-xs font-bold text-app-text/40 uppercase tracking-widest mt-1">{t('session_label')} Checklist</p>
        </div>
        
        <!-- Progress Circular / Text Indicator -->
        <div class="flex flex-col items-end">
             <span class="text-2xl font-black italic {progressValue === 100 ? 'text-green-400' : 'text-app-text'} tabular-nums leading-none">
                 {progressValue.toFixed(0)}%
             </span>
             <span class="text-[9px] uppercase tracking-widest text-app-text/40 font-black mt-1">{t('potential_peak_label')}</span>
        </div>
    </div>

    <!-- The Checklist -->
    <div class="flex-1 space-y-4 relative z-10 flex flex-col justify-center">
        {#each checklist as item}
            <a href={item.link} class="block group/item">
                <div class="flex items-center gap-4 p-4 rounded-2xl border transition-all {item.isComplete ? 'bg-green-500/5 border-green-500/20' : 'bg-app-text/5 border-app-border hover:border-app-border hover:bg-white/[0.07]'}">
                    
                    <div class="shrink-0 transition-transform group-hover/item:scale-110">
                        {#if item.isComplete}
                            <div class="w-10 h-10 rounded-xl bg-green-500/20 text-green-500 flex items-center justify-center">
                                <CheckCircle2 size={20} />
                            </div>
                        {:else if item.optional}
                            <div class="w-10 h-10 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center">
                                <TrendingUp size={18} />
                            </div>
                        {:else}
                            <div class="w-10 h-10 rounded-xl bg-red-500/10 text-red-500 flex items-center justify-center relative overflow-hidden">
                                <AlertCircle size={20} class="relative z-10" />
                                <div class="absolute inset-0 bg-red-500/20 animate-pulse"></div>
                            </div>
                        {/if}
                    </div>

                    <div class="flex-1 min-w-0">
                        <div class="flex items-center gap-2 mb-1">
                            <h4 class="text-sm font-black uppercase tracking-widest {item.isComplete ? 'text-green-400' : 'text-app-text'} truncate">
                                {item.title}
                            </h4>
                            {#if item.optional}
                                <span class="px-1.5 py-0.5 rounded bg-app-text/10 text-[8px] font-black uppercase text-app-text/40">Opt</span>
                            {/if}
                        </div>
                        <p class="text-[11px] font-medium text-app-text/50 leading-snug line-clamp-1">
                            {item.description}
                        </p>
                    </div>

                    <div class="shrink-0 text-app-text/20 group-hover/item:text-app-primary transition-colors group-hover/item:translate-x-1">
                        <ChevronRight size={18} />
                    </div>
                </div>
            </a>
        {/each}
    </div>
</div>
