<script lang="ts">
    import { teamStore } from "$lib/stores/team.svelte";
    import { transactionStore } from "$lib/stores/transactions.svelte";
    import { managerStore } from "$lib/stores/manager.svelte";
    import {
        Wallet,
        ArrowUpRight,
        ArrowDownRight,
        History,
        TrendingUp,
        TrendingDown,
        Percent,
        ChevronLeft,
        Users,
        Building2,
        GraduationCap,
    } from "lucide-svelte";
    import { fly } from "svelte/transition";
    import { staffService } from "$lib/services/staff.svelte";
    import { academyService } from "$lib/services/academy.svelte";
    import type { Driver } from "$lib/types";
    import { t } from "$lib/utils/i18n";

    let team = $derived(teamStore.value.team);
    let transactions = $derived.by(() => {
        const txs = transactionStore.transactions;
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
        return txs.filter((t) => new Date(t.date) >= sevenDaysAgo);
    });
    let isLoading = $derived(
        teamStore.value.loading || transactionStore.isLoading,
    );

    let drivers = $state<Driver[]>([]);
    let traineeCount = $state(0);
    let transferPercentage = $state(20);

    // Load drivers and trainees for calculations
    $effect(() => {
        if (team?.id) {
            staffService.getTeamDrivers(team.id).then((d) => (drivers = d));
            academyService
                .getSelectedTraineesCount(team.id)
                .then((c) => (traineeCount = c));
        }
    });

    $effect(() => {
        if (team && !updateTimeout) {
            transferPercentage = team.transferBudgetPercentage || 20;
        }
    });

    // Projections logic
    const projections = $derived.by(() => {
        if (!team)
            return {
                income: 0,
                expenses: 0,
                net: 0,
                payroll: 0,
                maintenance: 0,
                academy: 0,
                breakdown: [] as any[],
            };

        let income = 0;
        let payroll = 0;
        let maintenance = 0;
        let academy = 0;
        const breakdown: any[] = [];

        // 1. Sponsors (Income)
        Object.values(team.sponsors || {}).forEach((s) => {
            income += s.weeklyBasePayment;
            breakdown.push({
                name: s.sponsorName,
                amount: s.weeklyBasePayment,
                type: "INCOME",
                category: "Sponsors",
                icon: Wallet,
            });
        });

        // 2. Staff Salaries (Payroll)
        const teamDrivers = drivers;
        const managerRole = managerStore.profile?.role || "";
        teamDrivers.forEach((d) => {
            let weekly = Math.round(d.salary / 52);
            if (managerRole === "ex_driver") {
                weekly = Math.round(weekly * 1.2);
            }
            payroll += weekly;
            breakdown.push({
                name: `${d.name} (Salary)`,
                amount: -weekly,
                type: "EXPENSE",
                category: "Payroll",
                icon: Users,
            });
        });

        // 3. Fitness Trainer (Payroll)
        if (team.weekStatus) {
            const trainerLvl = team.weekStatus.fitnessTrainerLevel || 1;
            const trainerSalaries = [0, 0, 50000, 120000, 250000, 500000];
            if (trainerLvl >= 1 && trainerLvl < trainerSalaries.length) {
                const weekly = trainerSalaries[trainerLvl];
                if (weekly > 0) {
                    payroll += weekly;
                    breakdown.push({
                        name: `Fitness Trainer (Lvl ${trainerLvl})`,
                        amount: -weekly,
                        type: "EXPENSE",
                        category: "Payroll",
                        icon: Users,
                    });
                }
            }
        }

        // 4. Academy Trainees (Academy)
        if (traineeCount > 0) {
            const ACADEMY_WAGE = 10000;
            const weekly = traineeCount * ACADEMY_WAGE;
            academy += weekly;
            breakdown.push({
                name: `${traineeCount} Academy Trainees`,
                amount: -weekly,
                type: "EXPENSE",
                category: "Academy",
                icon: GraduationCap,
            });
        }

        // 5. Facilities Maintenance (Maintenance)
        const FACILITY_NAMES: Record<string, string> = {
            teamOffice: "Team Office",
            garage: "Garage",
            youthAcademy: "Youth Academy",
            pressRoom: "Press Room",
            scoutingOffice: "Scouting Office",
            racingSimulator: "Racing Simulator",
            gym: "Gym",
            rdOffice: "R&D Office",
            carMuseum: "Car Museum",
        };

        Object.entries(team.facilities || {}).forEach(([type, f]) => {
            if (f.level > 0) {
                const fMaintenance = f.maintenanceCost || f.level * 15000;
                maintenance += fMaintenance;
                breakdown.push({
                    name: `${FACILITY_NAMES[type] || type} Maint.`,
                    amount: -fMaintenance,
                    type: "EXPENSE",
                    category: "Facilities",
                    icon: Building2,
                });
            }
        });

        const totalExpenses = payroll + maintenance + academy;

        return {
            income,
            expenses: totalExpenses,
            payroll,
            maintenance,
            academy,
            net: income - totalExpenses,
            breakdown,
        };
    });

    // Historical breakdown (last 7 days)
    const historical = $derived.by(() => {
        const categories: Record<string, number> = {};
        const sevenDaysAgo = new Date();
        sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

        transactions.forEach((tx) => {
            const txDate = new Date(tx.date);
            if (txDate >= sevenDaysAgo) {
                const type = tx.type || "OTHER";
                categories[type] = (categories[type] || 0) + tx.amount;
            }
        });
        return categories;
    });

    // UI Helpers
    const categoryMeta: Record<string, { label: string; color: string }> = {
        SPONSOR: { label: "Sponsorships", color: "text-green-400" },
        SALARY: { label: "Salaries", color: "text-red-400" },
        UPGRADE: { label: "Upgrades", color: "text-blue-400" },
        REWARD: { label: "Race Rewards", color: "text-yellow-400" },
        PRACTICE: { label: "Sessions", color: "text-purple-400" },
        OTHER: { label: "Other", color: "text-gray-400" },
    };

    // Update percentage in Firebase when it changes (debounced-ish)
    let updateTimeout: any;
    function handlePercentageChange(e: any) {
        transferPercentage = parseInt(e.target.value);
        if (updateTimeout) clearTimeout(updateTimeout);
        updateTimeout = setTimeout(() => {
            teamStore.updateTransferBudgetPercentage(transferPercentage);
        }, 500);
    }

    function formatCurrency(amount: number) {
        return new Intl.NumberFormat("en-US", {
            style: "currency",
            currency: "USD",
            maximumFractionDigits: 0,
        }).format(amount);
    }

    function getTransactionIcon(type: string, amount: number) {
        if (amount > 0) return ArrowUpRight;
        return ArrowDownRight;
    }

    function getTransactionColor(amount: number) {
        if (amount > 0) return "text-green-400 bg-green-400/10";
        return "text-red-400 bg-red-400/10";
    }
</script>

<svelte:head>
    <title>Finances | FTG Racing Manager</title>
</svelte:head>

<div
    class="p-6 md:p-10 animate-fade-in w-full max-w-[1400px] mx-auto text-app-text min-h-screen"
>
    <!-- Breadcrumbs -->
    <nav
        class="flex items-center gap-2 mb-8 opacity-40 hover:opacity-100 transition-opacity"
    >
        <a
            href="/management"
            class="flex items-center gap-1 text-[10px] font-black uppercase tracking-widest"
        >
            <ChevronLeft size={14} /> Management
        </a>
    </nav>

    {#if isLoading}
        <div class="flex items-center justify-center h-64">
            <div
                class="w-10 h-10 border-4 border-app-primary border-t-transparent rounded-full animate-spin"
            ></div>
        </div>
    {:else if team}
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-10 items-start">
            <!-- Left Column: Main Finances -->
            <div class="lg:col-span-2 flex flex-col gap-10">
                <!-- Balance Header Card -->
                <div
                    class="relative bg-app-surface border border-app-border rounded-[40px] p-12 overflow-hidden shadow-2xl"
                >
                    <!-- Background Glow -->
                    <div
                        class="absolute -left-20 -top-20 w-64 h-64 bg-app-primary/10 blur-[100px] rounded-full"
                    ></div>

                    <div
                        class="relative flex flex-col items-center text-center gap-4"
                    >
                        <span
                            class="text-[10px] font-black tracking-[0.4em] text-app-primary uppercase font-heading"
                        >
                            {t('current_liquid_assets')}
                        </span>
                        <h2
                            class="text-6xl lg:text-7xl font-heading font-black tracking-tighter text-app-text"
                        >
                            {formatCurrency(team.budget)}
                        </h2>
                        <div
                            class="flex items-center gap-2 px-4 py-2 bg-app-text/5 rounded-full border border-app-border"
                        >
                            <Wallet size={14} class="text-app-primary" />
                            <span
                                class="text-[10px] font-bold text-app-text/40 uppercase tracking-widest"
                                >{t('global_treasury')}</span
                            >
                        </div>
                    </div>
                </div>

                <!-- Transaction History -->
                <section class="flex flex-col gap-6">
                    <div class="flex items-center justify-between px-2">
                        <h3
                            class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading"
                        >
                            {t('recent_movements')}
                        </h3>
                        <History size={14} class="text-app-text/20" />
                    </div>

                    <div class="flex flex-col gap-3">
                        {#each transactions as tx (tx.id)}
                            {@const Icon = getTransactionIcon(
                                tx.type,
                                tx.amount,
                            )}
                            <div
                                in:fly={{ x: -20, duration: 400 }}
                                class="bg-app-surface border border-app-border rounded-2xl p-5 flex items-center justify-between group hover:border-app-border transition-all shadow-sm"
                            >
                                <div class="flex items-center gap-5">
                                    <div
                                        class="p-3 rounded-xl {getTransactionColor(
                                            tx.amount,
                                        )} transition-transform group-hover:scale-110"
                                    >
                                        <Icon size={18} />
                                    </div>
                                    <div class="flex flex-col gap-0.5">
                                        <h4
                                            class="text-sm font-bold text-app-text uppercase tracking-tight"
                                        >
                                            {tx.description}
                                        </h4>
                                        <span
                                            class="text-[10px] font-black text-app-text/20 uppercase tracking-widest"
                                        >
                                            {tx.type} • {new Date(
                                                tx.date,
                                            ).toLocaleDateString(undefined, {
                                                month: "short",
                                                day: "numeric",
                                            })}
                                        </span>
                                    </div>
                                </div>
                                <div class="text-right">
                                    <span
                                        class="text-lg font-black italic {tx.amount >
                                        0
                                            ? 'text-green-400'
                                            : 'text-red-400'}"
                                    >
                                        {tx.amount > 0
                                            ? "+"
                                            : ""}{formatCurrency(tx.amount)}
                                    </span>
                                </div>
                            </div>
                        {:else}
                            <div
                                class="bg-app-surface/50 border border-app-border border-dashed rounded-3xl p-16 flex flex-col items-center justify-center opacity-30 text-center gap-4"
                            >
                                <History size={40} strokeWidth={1} />
                                <p
                                    class="text-[10px] font-black uppercase tracking-widest"
                                >
                                    {t('no_transactions_7days')}
                                </p>
                            </div>
                        {/each}
                    </div>
                </section>
            </div>

            <!-- Right Column: Summaries & Projections -->
            <div class="flex flex-col gap-10 w-full">
                <!-- Financial Run-Rate Card -->
                <section class="flex flex-col gap-6">
                    <h3
                        class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2"
                    >
                        Financial Run-Rate
                    </h3>
                    <div
                        class="bg-app-surface border border-app-border rounded-3xl p-8 flex flex-col gap-8 shadow-xl"
                    >
                        <div class="flex flex-col gap-5">
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap-3">
                                    <div
                                        class="p-2 bg-green-400/10 text-green-400 rounded-lg"
                                    >
                                        <TrendingUp size={16} />
                                    </div>
                                    <span
                                        class="text-[10px] font-bold text-app-text/60 uppercase tracking-wider"
                                        >Weekly Income</span
                                    >
                                </div>
                                <span class="text-sm font-black text-green-400"
                                    >+{formatCurrency(projections.income)}</span
                                >
                            </div>
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap-3">
                                    <div
                                        class="p-2 bg-red-400/10 text-red-400 rounded-lg"
                                    >
                                        <TrendingDown size={16} />
                                    </div>
                                    <span
                                        class="text-[10px] font-bold text-app-text/60 uppercase tracking-wider"
                                        >Weekly Expenses</span
                                    >
                                </div>
                                <span class="text-sm font-black text-red-400"
                                    >-{formatCurrency(
                                        projections.expenses,
                                    )}</span
                                >
                            </div>
                            <div class="h-px bg-app-text/5 my-2"></div>
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap-3">
                                    <span
                                        class="text-[10px] font-black text-app-text uppercase tracking-[0.2em]"
                                        >Net Run-Rate</span
                                    >
                                </div>
                                <span
                                    class="text-lg font-black {projections.net >=
                                    0
                                        ? 'text-app-primary'
                                        : 'text-red-400'} italic"
                                >
                                    {projections.net >= 0
                                        ? "+"
                                        : ""}{formatCurrency(projections.net)}
                                </span>
                            </div>
                        </div>

                        <div
                            class="bg-app-text/20 rounded-2xl p-6 border border-app-border flex flex-col gap-4"
                        >
                            <p
                                class="text-[10px] font-bold text-app-text/40 leading-relaxed uppercase tracking-widest"
                            >
                                CFO PROJECTION: Your team is currently operating
                                at a {projections.net >= 0
                                    ? "surplus"
                                    : "deficit"}.
                            </p>

                            <!-- Mini Breakdown -->
                            <div class="flex flex-col gap-4 pt-2">
                                {#each ["INCOME", "EXPENSE"] as type}
                                    {@const items =
                                        projections.breakdown.filter(
                                            (i) => i.type === type,
                                        )}
                                    {#if items.length > 0}
                                        <div class="flex flex-col gap-2">
                                            <span
                                                class="text-[8px] font-black uppercase tracking-[0.2em] text-app-text/20"
                                            >
                                                {type === "INCOME"
                                                    ? "Fixed Revenue"
                                                    : "Operational Costs"}
                                            </span>
                                            <div class="flex flex-col gap-2.5">
                                                {#each items as item}
                                                    {@const ItemIcon =
                                                        item.icon}
                                                    <div
                                                        class="flex items-center justify-between group/item"
                                                    >
                                                        <div
                                                            class="flex items-center gap-2"
                                                        >
                                                            <div
                                                                class="text-app-text/20 group-hover/item:text-app-primary transition-colors"
                                                            >
                                                                {#if ItemIcon}
                                                                    <ItemIcon
                                                                        size={12}
                                                                    />
                                                                {:else}
                                                                    <Wallet
                                                                        size={12}
                                                                    />
                                                                {/if}
                                                            </div>
                                                            <span
                                                                class="text-[10px] font-bold text-app-text/50 uppercase tracking-tight"
                                                                >{item.name}</span
                                                            >
                                                        </div>
                                                        <span
                                                            class="text-[10px] font-black {item.amount >
                                                            0
                                                                ? 'text-green-400/80'
                                                                : 'text-red-400/80'}"
                                                        >
                                                            {item.amount > 0
                                                                ? "+"
                                                                : ""}{(
                                                                item.amount /
                                                                1000
                                                            ).toFixed(1)}k
                                                        </span>
                                                    </div>
                                                {/each}
                                            </div>
                                        </div>
                                    {/if}
                                {/each}
                            </div>
                        </div>
                    </div>
                </section>

                <!-- Historical Breakdown Card -->
                <section class="flex flex-col gap-6">
                    <h3
                        class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading px-2"
                    >
                        Last 7 Days (Historical)
                    </h3>
                    <div
                        class="bg-app-surface border border-app-border rounded-3xl p-8 flex flex-col gap-4"
                    >
                        {#each Object.entries(historical) as [type, amount]}
                            <div class="flex items-center justify-between">
                                <div class="flex items-center gap-3">
                                    <div
                                        class="w-1.5 h-1.5 rounded-full {categoryMeta[
                                            type
                                        ]?.color || 'bg-gray-400'}"
                                    ></div>
                                    <span
                                        class="text-[10px] font-bold text-app-text/60 uppercase tracking-widest"
                                        >{categoryMeta[type]?.label ||
                                            type}</span
                                    >
                                </div>
                                <span
                                    class="text-xs font-black {amount >= 0
                                        ? 'text-green-400'
                                        : 'text-red-400'}"
                                >
                                    {amount > 0 ? "+" : ""}{formatCurrency(
                                        amount,
                                    )}
                                </span>
                            </div>
                        {:else}
                            <p
                                class="text-[10px] font-bold text-app-text/20 uppercase text-center py-4"
                            >
                                No recent history
                            </p>
                        {/each}
                    </div>
                </section>

                <!-- Transfer Budget Allocation -->
                <section class="flex flex-col gap-6">
                    <div class="flex items-center justify-between px-2">
                        <h3
                            class="text-[10px] font-black uppercase tracking-[0.3em] text-app-primary/40 font-heading"
                        >
                            Budget Allocation
                        </h3>
                    </div>

                    <div
                        class="bg-app-surface border border-app-border rounded-3xl p-8 flex flex-col gap-8"
                    >
                        <div class="flex flex-col gap-2">
                            <p
                                class="text-[10px] font-bold text-app-text/40 uppercase tracking-widest"
                            >
                                {transferPercentage}% FOR TRANSFERS
                            </p>
                        </div>

                        <div class="flex flex-col gap-4">
                            <input
                                type="range"
                                min="5"
                                max="100"
                                step="5"
                                value={transferPercentage}
                                oninput={handlePercentageChange}
                                class="w-full h-2 bg-app-text/5 rounded-lg appearance-none cursor-pointer accent-app-primary"
                            />
                        </div>

                        <div
                            class="grid grid-cols-2 gap-4 pt-4 border-t border-app-border"
                        >
                            <div class="flex flex-col gap-1">
                                <span
                                    class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                                    >{t('transfer_cap')}</span
                                >
                                <span
                                    class="text-xl font-black text-app-primary italic"
                                >
                                    {formatCurrency(
                                        Math.floor(
                                            team.budget *
                                                (transferPercentage / 100),
                                        ),
                                    )}
                                </span>
                            </div>
                            <div class="flex flex-col gap-1">
                                <span
                                    class="text-[9px] font-black text-app-text/20 uppercase tracking-widest"
                                    >{t('operational_reserve')}</span
                                >
                                <span
                                    class="text-xl font-black text-app-text italic"
                                >
                                    {formatCurrency(
                                        Math.floor(
                                            team.budget *
                                                (1 - transferPercentage / 100),
                                        ),
                                    )}
                                </span>
                            </div>
                        </div>
                    </div>
                </section>

                <!-- Help/Tips Card -->
                <div
                    class="bg-app-primary/5 border border-app-primary/20 rounded-3xl p-8 flex flex-col gap-4"
                >
                    <h4
                        class="text-xs font-black text-app-primary uppercase tracking-widest"
                    >
                        Strategic Tip
                    </h4>
                    <p
                        class="text-xs font-medium text-app-text/60 leading-relaxed"
                    >
                        Keeping a higher **Transfer Allocation** allows for
                        quick responses in the driver market, but might reduce
                        your operational safety margin if maintenance costs
                        spike.
                    </p>
                </div>
            </div>
        </div>
    {/if}
</div>

<style>
    /* Range Slider Styling */
    input[type="range"]::-webkit-slider-thumb {
        -webkit-appearance: none;
        height: 16px;
        width: 16px;
        border-radius: 50%;
        background: #c5a059;
        cursor: pointer;
        box-shadow: 0 0 10px rgba(var(--primary-color-rgb), 0.4);
        margin-top: -6px;
    }

    input[type="range"]::-webkit-slider-runnable-track {
        width: 100%;
        height: 4px;
        background: rgba(255, 255, 255, 0.05);
        border-radius: 2px;
    }
</style>
