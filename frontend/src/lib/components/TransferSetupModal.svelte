<script lang="ts">
    import { fade, fly } from "svelte/transition";
    import { X, ArrowRight, Users } from "lucide-svelte";
    import { t } from "$lib/utils/i18n";
    import { staffService } from "$lib/services/staff.svelte";
    import { formatDriverName, calculateCurrentStars } from "$lib/utils/driver";
    import DriverAvatar from "$lib/components/DriverAvatar.svelte";
    import type { Driver } from "$lib/types";

    type DriverRole = 'main' | 'secondary' | 'equal';

    interface Props {
        /** The incoming driver that won the auction — in pendingNegotiation state. */
        driver: Driver;
        teamId: string;
        isOpen: boolean;
        onConfirm: (replacedDriverId: string, role: DriverRole) => void;
        onClose: () => void;
    }

    let { driver, teamId, isOpen, onConfirm, onClose }: Props = $props();

    // ── State ──────────────────────────────────────────────────────────────────
    let teamDrivers = $state<Driver[]>([]);
    let selectedReplacedId = $state<string | null>(null);
    let selectedRole = $state<DriverRole | null>(null);
    let loading = $state(true);

    const ROLES: { value: DriverRole; labelKey: 'driver_role_main' | 'driver_role_secondary' | 'driver_role_equal' }[] = [
        { value: 'main',      labelKey: 'driver_role_main' },
        { value: 'secondary', labelKey: 'driver_role_secondary' },
        { value: 'equal',     labelKey: 'driver_role_equal' },
    ];

    // Active team drivers (those occupying a car slot — carIndex 0 or 1)
    const activeDrivers = $derived(
        teamDrivers.filter(d => d.carIndex === 0 || d.carIndex === 1)
    );

    const canConfirm = $derived(selectedReplacedId !== null && selectedRole !== null);

    $effect(() => {
        if (isOpen && teamId) {
            loading = true;
            staffService.getTeamDrivers(teamId)
                .then(d => { teamDrivers = d; })
                .catch(e => console.error('[TransferSetupModal] Failed to load roster:', e))
                .finally(() => { loading = false; });
        }
    });

    function handleConfirm() {
        if (!selectedReplacedId || !selectedRole) return;
        onConfirm(selectedReplacedId, selectedRole);
    }
</script>

{#if isOpen}
    <div
        class="fixed inset-0 z-[90] flex items-center justify-center p-4"
        transition:fade={{ duration: 180 }}
    >
        <!-- Backdrop -->
        <button
            class="absolute inset-0 bg-black/80 backdrop-blur-md cursor-default border-none w-full h-full"
            onclick={onClose}
            aria-label="Close"
        ></button>

        <!-- Modal -->
        <div
            class="relative w-full max-w-md bg-app-surface border border-app-border rounded-[28px] overflow-hidden shadow-2xl"
            transition:fly={{ y: 24, duration: 280 }}
        >
            <!-- Header -->
            <div class="px-6 pt-6 pb-4 border-b border-app-border flex items-center justify-between gap-4">
                <div>
                    <p class="text-[10px] font-black uppercase tracking-widest text-app-primary">
                        {t('transfer_setup_title')}
                    </p>
                    <h2 class="text-lg font-heading font-black uppercase italic tracking-tighter text-app-text truncate pr-2">
                        {formatDriverName(driver.name)}
                    </h2>
                </div>
                <button
                    onclick={onClose}
                    class="p-2 bg-white/5 rounded-full text-app-text/40 hover:text-app-text hover:bg-white/10 transition-all"
                    aria-label="Close"
                >
                    <X size={16} />
                </button>
            </div>

            <!-- Body -->
            <div class="p-6 space-y-6">

                <!-- Incoming driver summary -->
                <div class="flex items-center gap-4 p-4 bg-app-primary/5 border border-app-primary/10 rounded-2xl">
                    <DriverAvatar id={driver.id} gender={driver.gender} class="w-12 h-12 rounded-xl overflow-hidden shrink-0" />
                    <div class="flex-1 overflow-hidden">
                        <p class="font-black uppercase tracking-tight text-app-text truncate">{formatDriverName(driver.name)}</p>
                        <p class="text-[10px] text-app-text/40">
                            {driver.age}y · {Array(5).fill('★').map((s, i) => i < calculateCurrentStars(driver) ? s : '☆').join('')}
                        </p>
                    </div>
                    <ArrowRight size={16} class="text-app-primary/40 shrink-0" />
                </div>

                <!-- Role selector -->
                <div class="space-y-2">
                    <label class="text-[10px] font-black uppercase tracking-widest text-app-text/40">
                        {t('transfer_incoming_role')}
                    </label>
                    <div class="flex gap-2">
                        {#each ROLES as r}
                            <button
                                onclick={() => selectedRole = r.value}
                                class="flex-1 py-3 rounded-2xl border text-[11px] font-black uppercase tracking-wider transition-all
                                    {selectedRole === r.value
                                        ? 'bg-app-primary text-app-primary-foreground border-app-primary'
                                        : 'border-app-border text-app-text/60 hover:border-app-primary/40 hover:text-app-text'}"
                            >
                                {t(r.labelKey)}
                            </button>
                        {/each}
                    </div>
                </div>

                <!-- Replacement driver selector -->
                <div class="space-y-2">
                    <label class="text-[10px] font-black uppercase tracking-widest text-app-text/40">
                        {t('transfer_select_replacement')}
                    </label>

                    {#if loading}
                        <div class="flex flex-col gap-2">
                            {#each Array(2) as _}
                                <div class="h-14 bg-app-text/5 rounded-2xl animate-pulse"></div>
                            {/each}
                        </div>
                    {:else if activeDrivers.length === 0}
                        <div class="flex items-center gap-3 p-4 bg-app-text/5 border border-app-border rounded-2xl opacity-50">
                            <Users size={16} class="text-app-text/30" />
                            <span class="text-[11px] text-app-text/40">{t('transfer_no_active_drivers')}</span>
                        </div>
                    {:else}
                        <div class="flex flex-col gap-2">
                            {#each activeDrivers as candidate}
                                <button
                                    onclick={() => selectedReplacedId = candidate.id}
                                    class="flex items-center gap-3 p-3 rounded-2xl border text-left transition-all
                                        {selectedReplacedId === candidate.id
                                            ? 'border-red-500/50 bg-red-500/5'
                                            : 'border-app-border hover:border-app-border/80 hover:bg-app-text/[0.02]'}"
                                >
                                    <DriverAvatar id={candidate.id} gender={candidate.gender} class="w-9 h-9 rounded-xl overflow-hidden shrink-0" />
                                    <div class="flex-1 overflow-hidden">
                                        <p class="text-[11px] font-black uppercase tracking-tight text-app-text truncate">{formatDriverName(candidate.name)}</p>
                                        <p class="text-[9px] text-app-text/40 uppercase tracking-wider">{t('transfer_auto_list_note')}</p>
                                    </div>
                                    {#if selectedReplacedId === candidate.id}
                                        <span class="text-[9px] font-black text-red-400 uppercase shrink-0">{t('transfer_released')}</span>
                                    {/if}
                                </button>
                            {/each}
                        </div>
                    {/if}
                </div>

                <!-- Auto-list notice -->
                <p class="text-[10px] text-app-text/30 leading-relaxed text-center">
                    {t('transfer_auto_list_disclaimer')}
                </p>

                <!-- Action -->
                <button
                    onclick={handleConfirm}
                    disabled={!canConfirm}
                    class="w-full py-4 bg-app-primary rounded-2xl text-[10px] font-black uppercase tracking-widest text-app-primary-foreground hover:opacity-90 transition-all shadow-lg disabled:opacity-30 disabled:cursor-not-allowed"
                >
                    {t('transfer_confirm_setup')}
                </button>

            </div>
        </div>
    </div>
{/if}
