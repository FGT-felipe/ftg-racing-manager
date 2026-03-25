<script lang="ts">
    import { CheckCircle2, XCircle, ChevronUp, ChevronDown, AlertTriangle } from "lucide-svelte";
    import { fade, fly } from "svelte/transition";
    import type { Driver } from "$lib/types";
    import { t } from "$lib/utils/i18n";
    import {
        calculateCurrentStars,
        calculateDriverCounterProposal,
        getDriverLevelInfo,
        isRetiringNextSeason,
        rejectsLongContracts,
    } from "$lib/utils/driver";
    import { DRIVER_RENEWAL_FEE_RATE, NEGOTIATION_MAX_ATTEMPTS, NEGOTIATION_MORALE_PENALTY_PER_FAIL, NEGOTIATION_MORALE_PENALTY_TOTAL_FAIL } from "$lib/constants/economics";
    import { staffService } from "$lib/services/staff.svelte";
    import DriverStars from "./DriverStars.svelte";

    interface Props {
        driver: Driver;
        teamId: string;
        managerBackground: string;
        isOpen: boolean;
        onClose: () => void;
        onSuccess: () => void;
        /** Optional override: called instead of staffService.negotiateRenewal on agreement. */
        onFinalize?: (salary: number, years: number, moraleChange: number) => Promise<void>;
        /** Optional override: called instead of staffService.applyNegotiationFailPenalty on breakdown. */
        onFailed?: (moraleChange: number) => Promise<void>;
        /** Mode label shown in the fee row. Defaults to 'Signing Fee'. */
        feeLabel?: string;
    }

    let { driver, teamId, managerBackground, isOpen, onClose, onSuccess, onFinalize, onFailed, feeLabel }: Props = $props();

    // ── State ──────────────────────────────────────────────────────────────────
    type Step = 'offer' | 'counter' | 'success' | 'failed' | 'retired';

    let step = $state<Step>('offer');
    let offeredSalary = $state(Math.max(driver.salary, SALARY_MIN));
    let years = $state(1);
    let attemptsLeft = $state(NEGOTIATION_MAX_ATTEMPTS);
    let counterProposal = $state(0);
    let cumulativeMoraleChange = $state(0);
    let isProcessing = $state(false);
    let errorMsg = $state('');

    // ── Derived ───────────────────────────────────────────────────────────────
    const currentStars = $derived(calculateCurrentStars(driver));
    const levelInfo = $derived(getDriverLevelInfo(currentStars, t));

    const backgroundMultiplier = $derived(
        managerBackground === 'ex_driver' ? 1.20 :
        managerBackground === 'business'  ? 0.90 :
        1.00
    );

    /** Driver's minimum annual salary they'll accept, adjusted for manager background. */
    const driverFloor = $derived(
        Math.round(calculateDriverCounterProposal(driver, driver.salary) * backgroundMultiplier)
    );

    // Signing fee = 10% of total annual contract value
    const renewalFee = $derived(
        Math.round(offeredSalary * years * DRIVER_RENEWAL_FEE_RATE)
    );

    const SALARY_STEP = 10_000;
    const SALARY_MIN = 50_000;
    const SALARY_MAX = 2_000_000;

    // ── Helpers ───────────────────────────────────────────────────────────────
    function formatCurrency(v: number) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(v);
    }

    function adjustSalary(delta: number) {
        offeredSalary = Math.max(SALARY_MIN, Math.min(SALARY_MAX, offeredSalary + delta));
    }

    function reset() {
        step = 'offer';
        offeredSalary = Math.max(driver.salary, SALARY_MIN);
        years = 1;
        attemptsLeft = NEGOTIATION_MAX_ATTEMPTS;
        cumulativeMoraleChange = 0;
        counterProposal = 0;
        errorMsg = '';
    }

    // ── Negotiation logic ─────────────────────────────────────────────────────
    function handlePropose() {
        if (isRetiringNextSeason(driver)) {
            step = 'retired';
            return;
        }

        attemptsLeft -= 1;

        if (offeredSalary >= driverFloor) {
            // Driver accepts — commit
            commitRenewal();
        } else {
            // Driver counter-proposes at their floor
            cumulativeMoraleChange -= NEGOTIATION_MORALE_PENALTY_PER_FAIL;
            counterProposal = driverFloor;

            if (attemptsLeft <= 0) {
                // All attempts exhausted
                cumulativeMoraleChange -= NEGOTIATION_MORALE_PENALTY_TOTAL_FAIL;
                applyFailPenalty();
                step = 'failed';
            } else {
                step = 'counter';
            }
        }
    }

    function handleAcceptCounter() {
        offeredSalary = counterProposal;
        commitRenewal();
    }

    function handleAbandon() {
        applyFailPenalty();
        onClose();
    }

    async function commitRenewal() {
        isProcessing = true;
        errorMsg = '';
        try {
            if (onFinalize) {
                await onFinalize(offeredSalary, years, cumulativeMoraleChange);
            } else {
                await staffService.negotiateRenewal(teamId, driver, {
                    years,
                    salary: offeredSalary,
                    moraleChange: cumulativeMoraleChange,
                });
            }
            step = 'success';
        } catch (e) {
            errorMsg = e instanceof Error ? e.message : t('error_renew');
        } finally {
            isProcessing = false;
        }
    }

    async function applyFailPenalty() {
        try {
            if (onFailed) {
                await onFailed(cumulativeMoraleChange);
            } else if (cumulativeMoraleChange !== 0) {
                await staffService.applyNegotiationFailPenalty(driver, cumulativeMoraleChange);
            }
        } catch {
            // Non-critical — penalty is best-effort
        }
    }

    function handleClose() {
        if (step === 'success') {
            onSuccess();
        }
        reset();
        onClose();
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
            onclick={handleClose}
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
                        {t('negotiation_title')}
                    </p>
                    <h2 class="text-lg font-heading font-black uppercase italic tracking-tighter text-app-text truncate pr-2">
                        {driver.name}
                    </h2>
                </div>
                <div class="flex flex-col items-end gap-1 shrink-0">
                    <DriverStars currentStars={currentStars} maxStars={driver.potential} size={12} />
                    <span class="text-[10px] font-bold {levelInfo.color}">{levelInfo.label}</span>
                </div>
            </div>

            <!-- Body -->
            <div class="p-6 space-y-6">

                {#if step === 'retired'}
                    <!-- Retiring -->
                    <div class="flex flex-col items-center text-center gap-4 py-4">
                        <div class="p-4 rounded-3xl bg-yellow-500/10 border border-yellow-500/20">
                            <AlertTriangle size={32} class="text-yellow-500" />
                        </div>
                        <div class="space-y-1">
                            <p class="font-heading font-black uppercase italic tracking-tight text-app-text">
                                {t('negotiation_retired_title')}
                            </p>
                            <p class="text-sm text-app-text/60">{t('retirement_alert', { name: driver.name })}</p>
                        </div>
                        <button
                            onclick={handleClose}
                            class="w-full py-4 bg-app-text/5 border border-app-border rounded-2xl text-[10px] font-black uppercase tracking-widest text-app-text/40 hover:bg-app-text/10 transition-all"
                        >
                            {t('cancel')}
                        </button>
                    </div>

                {:else if step === 'success'}
                    <!-- Success -->
                    <div class="flex flex-col items-center text-center gap-4 py-4">
                        <div class="p-4 rounded-3xl bg-emerald-500/10 border border-emerald-500/20">
                            <CheckCircle2 size={32} class="text-emerald-500" />
                        </div>
                        <div class="space-y-1">
                            <p class="font-heading font-black uppercase italic tracking-tight text-app-text">
                                {t('negotiation_success_title')}
                            </p>
                            <p class="text-sm text-app-text/60">
                                {t('negotiation_success_msg', {
                                    years: String(years),
                                    salary: formatCurrency(offeredSalary),
                                    fee: formatCurrency(renewalFee),
                                })}
                            </p>
                        </div>
                        <button
                            onclick={handleClose}
                            class="w-full py-4 bg-emerald-500 rounded-2xl text-[10px] font-black uppercase tracking-widest text-white hover:bg-emerald-600 transition-all"
                        >
                            {t('confirm')}
                        </button>
                    </div>

                {:else if step === 'failed'}
                    <!-- Failed -->
                    <div class="flex flex-col items-center text-center gap-4 py-4">
                        <div class="p-4 rounded-3xl bg-red-500/10 border border-red-500/20">
                            <XCircle size={32} class="text-red-500" />
                        </div>
                        <div class="space-y-1">
                            <p class="font-heading font-black uppercase italic tracking-tight text-app-text">
                                {t('negotiation_failed_title')}
                            </p>
                            <p class="text-sm text-app-text/60">
                                {t('negotiation_failed_msg', {
                                    name: driver.name,
                                    penalty: String(Math.abs(cumulativeMoraleChange)),
                                })}
                            </p>
                        </div>
                        <button
                            onclick={handleClose}
                            class="w-full py-4 bg-app-text/5 border border-app-border rounded-2xl text-[10px] font-black uppercase tracking-widest text-app-text/40 hover:bg-app-text/10 transition-all"
                        >
                            {t('cancel')}
                        </button>
                    </div>

                {:else}
                    <!-- Offer / Counter steps -->

                    {#if step === 'counter'}
                        <!-- Driver's counter-proposal banner -->
                        <div class="bg-yellow-500/10 border border-yellow-500/20 rounded-2xl p-4 text-center space-y-1">
                            <p class="text-[10px] font-black uppercase tracking-widest text-yellow-500">
                                {t('attempts_remaining', { n: String(attemptsLeft) })}
                            </p>
                            <p class="text-sm font-medium text-app-text/80">
                                {t('driver_counter_msg', { name: driver.name.split(' ')[0], amount: formatCurrency(counterProposal) })}
                            </p>
                        </div>
                    {/if}

                    {#if managerBackground === 'ex_driver'}
                        <p class="text-[10px] text-yellow-500/70 italic text-center -mt-2">
                            {t('background_ex_driver_note')}
                        </p>
                    {:else if managerBackground === 'business'}
                        <p class="text-[10px] text-emerald-500/70 italic text-center -mt-2">
                            {t('background_business_note')}
                        </p>
                    {/if}

                    <!-- Salary stepper -->
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-app-text/40">
                            {t('annual_salary')}
                        </label>
                        <div class="flex items-center gap-3">
                            <button
                                onclick={() => adjustSalary(-SALARY_STEP)}
                                class="w-10 h-10 rounded-xl bg-app-text/5 border border-app-border flex items-center justify-center hover:bg-app-text/10 transition-all shrink-0"
                                aria-label="Decrease salary"
                            >
                                <ChevronDown size={18} class="text-app-text/60" />
                            </button>
                            <div class="flex-1 text-center">
                                <span class="text-xl font-heading font-black text-app-text">
                                    {formatCurrency(offeredSalary)}
                                </span>
                                <span class="text-[10px] text-app-text/40 block">≈ {formatCurrency(Math.round(offeredSalary / 52))}/wk</span>
                            </div>
                            <button
                                onclick={() => adjustSalary(SALARY_STEP)}
                                class="w-10 h-10 rounded-xl bg-app-text/5 border border-app-border flex items-center justify-center hover:bg-app-text/10 transition-all shrink-0"
                                aria-label="Increase salary"
                            >
                                <ChevronUp size={18} class="text-app-text/60" />
                            </button>
                        </div>
                        <p class="text-[10px] text-app-text/30 text-center">
                            Current: {formatCurrency(driver.salary)}/yr
                        </p>
                    </div>

                    <!-- Years selector -->
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-app-text/40">
                            {t('contract_years')}
                        </label>
                        <div class="flex gap-2">
                            {#each [1, 2, 3] as yr}
                                {@const disabled = yr > 1 && rejectsLongContracts(driver)}
                                <button
                                    onclick={() => { if (!disabled) years = yr; }}
                                    class="flex-1 py-3 rounded-2xl border text-[11px] font-black uppercase tracking-wider transition-all
                                        {years === yr
                                            ? 'bg-app-primary text-app-primary-foreground border-app-primary'
                                            : disabled
                                                ? 'border-app-border text-app-text/20 cursor-not-allowed'
                                                : 'border-app-border text-app-text/60 hover:border-app-primary/40 hover:text-app-text'}"
                                    title={disabled ? 'Driver rejects multi-year contracts at this age' : ''}
                                >
                                    {yr} {yr === 1 ? 'Season' : 'Seasons'}
                                </button>
                            {/each}
                        </div>
                    </div>

                    <!-- Renewal fee -->
                    <div class="bg-app-text/5 border border-app-border rounded-2xl p-4 space-y-1">
                        <div class="flex justify-between items-center">
                            <span class="text-[10px] font-black uppercase tracking-widest text-app-text/40">{feeLabel ?? t('renewal_fee')}</span>
                            <span class="text-sm font-bold text-app-primary">{formatCurrency(renewalFee)}</span>
                        </div>
                        <p class="text-[10px] text-app-text/30">{t('renewal_fee_note')}</p>
                    </div>

                    {#if errorMsg}
                        <p class="text-xs text-red-400 text-center">{errorMsg}</p>
                    {/if}

                    <!-- Action buttons -->
                    <div class="flex flex-col gap-2">
                        {#if step === 'counter'}
                            <button
                                onclick={handleAcceptCounter}
                                disabled={isProcessing}
                                class="w-full py-4 bg-emerald-500 rounded-2xl text-[10px] font-black uppercase tracking-widest text-white hover:bg-emerald-600 transition-all disabled:opacity-50"
                            >
                                {t('accept_counter')} — {formatCurrency(counterProposal)}/yr
                            </button>
                        {/if}

                        <button
                            onclick={handlePropose}
                            disabled={isProcessing}
                            class="w-full py-4 bg-app-primary rounded-2xl text-[10px] font-black uppercase tracking-widest text-app-primary-foreground hover:opacity-90 transition-all shadow-lg disabled:opacity-50 flex items-center justify-center gap-2"
                        >
                            {#if isProcessing}
                                <div class="w-3 h-3 border-2 border-current border-t-transparent rounded-full animate-spin"></div>
                            {/if}
                            {step === 'counter' ? t('counter_offer') : t('make_offer')}
                        </button>

                        <button
                            onclick={handleAbandon}
                            disabled={isProcessing}
                            class="w-full py-3 text-[10px] font-black uppercase tracking-widest text-app-text/30 hover:text-app-text/50 transition-all disabled:opacity-50"
                        >
                            {t('abandon_negotiation')}
                        </button>
                    </div>
                {/if}

            </div>
        </div>
    </div>
{/if}
