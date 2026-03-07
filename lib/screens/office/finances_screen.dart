import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../models/core_models.dart';
import '../../services/finance_service.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../services/driver_assignment_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/common/new_dot.dart';
import '../../services/youth_academy_service.dart';

class FinancesScreen extends StatelessWidget {
  final String teamId;

  const FinancesScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final financeService = FinanceService();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .snapshots(),
      builder: (context, teamSnapshot) {
        if (!teamSnapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.secondary,
            ),
          );
        }

        final teamData = teamSnapshot.data!.data() as Map<String, dynamic>?;
        final budget = teamData?['budget'] ?? 0;
        final isNegative = budget < 0;
        final int transferBudgetPercentage =
            teamData?['transferBudgetPercentage'] ?? 20;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;

            if (isWide) {
              // — DESKTOP: Two-column layout —
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: Existing finance content
                  Expanded(
                    flex: 3,
                    child: _buildMainContent(
                      context,
                      financeService,
                      budget,
                      isNegative,
                      transferBudgetPercentage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // RIGHT: Financial Summary card
                  Expanded(
                    flex: 2,
                    child: _buildSummaryPanel(
                      context,
                      financeService,
                      teamData,
                    ),
                  ),
                ],
              );
            } else {
              // — MOBILE: Single-column, summary below the list —
              return _buildMainContent(
                context,
                financeService,
                budget,
                isNegative,
                transferBudgetPercentage,
                bottomWidget: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSummaryCard(context, financeService, teamData),
                ),
              );
            }
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────
  //  MAIN CONTENT (left column / single col)
  // ─────────────────────────────────────────
  Widget _buildMainContent(
    BuildContext context,
    FinanceService financeService,
    int budget,
    bool isNegative,
    int transferBudgetPercentage, {
    Widget? bottomWidget,
  }) {
    return Column(
      children: [
        // Balance Header
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(32),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context).currentBalanceTitle,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                financeService.formatCurrency(budget),
                style: TextStyle(
                  color: isNegative
                      ? Colors.redAccent
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Transfer Budget Slider Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _TransferBudgetCard(
            initialPercentage: transferBudgetPercentage,
            totalBudget: budget,
            teamId: teamId,
          ),
        ),

        const SizedBox(height: 12),

        // Transaction List Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context).recentMovementsTitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.secondary,
                size: 16,
              ),
            ],
          ),
        ),

        // Scrollable List
        Expanded(
          child: StreamBuilder<List<Transaction>>(
            stream: financeService.getTransactionHistory(teamId),
            builder: (context, transSnapshot) {
              if (transSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                );
              }

              final transactions = transSnapshot.data ?? [];

              if (transactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).noFinancialActivity,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: transactions.length,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return _buildTransactionTile(context, tx, financeService);
                },
              );
            },
          ),
        ),

        if (bottomWidget != null) ...[
          const SizedBox(height: 12),
          bottomWidget,
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  // ─────────────────────────────────────
  //  SUMMARY PANEL (right column wrapper)
  // ─────────────────────────────────────
  Widget _buildSummaryPanel(
    BuildContext context,
    FinanceService financeService,
    Map<String, dynamic>? teamData,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, right: 20, bottom: 20),
      child: _buildSummaryCard(context, financeService, teamData),
    );
  }

  // ─────────────────────────────────────────────
  //  FINANCIAL SUMMARY CARD (shared mobile+desk)
  // ─────────────────────────────────────────────
  Widget _buildSummaryCard(
    BuildContext context,
    FinanceService financeService,
    Map<String, dynamic>? teamData,
  ) {
    final l10n = AppLocalizations.of(context);
    final accent = Theme.of(context).colorScheme.secondary;

    return StreamBuilder<List<Transaction>>(
      stream: financeService.getTransactionHistory(teamId),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];

        // Compute per-category breakdown (Last 7 Days ONLY)
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        final recentTransactions = transactions
            .where((tx) => tx.date.isAfter(sevenDaysAgo))
            .toList();

        final Map<String, int> categoryTotals = {};
        for (final tx in recentTransactions) {
          final key = tx.type.isNotEmpty ? tx.type : 'OTHER';
          categoryTotals[key] = (categoryTotals[key] ?? 0) + tx.amount;
        }

        // Fetch drivers to calculate staff costs
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            DriverAssignmentService().getDriversByTeam(teamId),
            YouthAcademyService().streamSelectedDrivers(teamId).first,
          ]),
          builder: (context, snapshot) {
            // --- NEW PROJECTED FINANCIALS CALCULATION ---
            // 1. Calculate Staff & Academy Costs
            int staffCost = 0;
            int academyTraineesCount = 0;
            final List<Map<String, dynamic>> staffBreakdown = [];

            if (snapshot.hasData) {
              final drivers = snapshot.data![0] as List<Driver>;
              final academyDrivers = snapshot.data![1] as List;
              for (final driver in drivers) {
                // Calculate weekly value: salary / 52
                final weeklyWage = (driver.salary / 52).round();
                staffCost += weeklyWage;
                staffBreakdown.add({
                  'name': '${driver.name} Salary',
                  'cost': weeklyWage,
                });
              }
              academyTraineesCount = academyDrivers.length;
            }
            final listTrainerSalary = [0, 0, 50000, 120000, 250000, 500000];
            final weekStatus = teamData?['weekStatus'] as Map<String, dynamic>?;
            final trainerLvl = weekStatus?['fitnessTrainerLevel'] ?? 1;
            if (trainerLvl >= 1 && trainerLvl <= 5) {
              final trainerCost = listTrainerSalary[trainerLvl];
              if (trainerCost > 0) {
                staffCost += trainerCost;
                staffBreakdown.add({
                  'name': 'Fitness Trainer Lvl $trainerLvl',
                  'cost': trainerCost,
                });
              }
            }

            // 2. Calculate Facility Maintenance
            final Map<String, Facility> activeFacilitiesMap = {};
            final facilitiesData =
                teamData?['facilities'] as Map<String, dynamic>? ?? {};
            int projectedMaintenance = 0;
            facilitiesData.forEach((key, value) {
              if (value is Map<String, dynamic>) {
                final f = Facility.fromMap(value);
                if (f.level > 0 && f.maintenanceCost > 0) {
                  activeFacilitiesMap[key] = f;
                  projectedMaintenance += f.maintenanceCost;
                }
              }
            });

            // 3. Calculate Sponsor Income
            final Map<String, ActiveContract> activeSponsorsMap = {};
            final sponsorsData =
                teamData?['sponsors'] as Map<String, dynamic>? ?? {};
            int projectedIncome = 0;
            sponsorsData.forEach((key, value) {
              if (value is Map<String, dynamic>) {
                final s = ActiveContract.fromMap(value);
                activeSponsorsMap[key] = s;
                projectedIncome += s.weeklyBasePayment;
              }
            });

            // 4. Summarize Projections
            final int projectedAcademyWages = academyTraineesCount * 10000;
            final int projectedExpenses =
                staffCost + projectedMaintenance + projectedAcademyWages;
            final int projectedNet = projectedIncome - projectedExpenses;
            final int currentBalance = teamData?['budget'] as int? ?? 0;

            return NewDotWidget(
              featureId: 'finances_summary',
              badgeAlignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF15151A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: transactions.isEmpty
                    ? _buildEmptySummary(context)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Title ──
                          Row(
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                color: accent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.financialSummaryTitle,
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── CFO Dashboard (Current & Projected Run-Rate) ──
                          _SummaryRow(
                            label: 'Current Bank Balance',
                            value: financeService.formatCurrency(
                              currentBalance,
                            ),
                            valueColor: Colors.white,
                            icon: Icons.account_balance_wallet_outlined,
                            bold: true,
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'Projected Weekly Income',
                            value:
                                '+${financeService.formatCurrency(projectedIncome)}',
                            valueColor: Colors.greenAccent,
                            icon: Icons.add_circle_outline,
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'Projected Weekly Expenses',
                            value: financeService.formatCurrency(
                              -projectedExpenses,
                            ),
                            valueColor: Colors.redAccent,
                            icon: Icons.remove_circle_outline,
                          ),
                          const SizedBox(height: 10),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 24,
                          ),
                          _SummaryRow(
                            label: 'Weekly Net Run-Rate',
                            value: financeService.formatCurrency(projectedNet),
                            valueColor: projectedNet >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            icon: projectedNet >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            bold: true,
                          ),

                          const SizedBox(height: 24),

                          // ── Expected Run-Rate Breakdown ──
                          _buildWeeklyProjectionBreakdown(
                            context,
                            financeService,
                            staffCost,
                            staffBreakdown,
                            projectedAcademyWages,
                            activeFacilitiesMap,
                            activeSponsorsMap,
                          ),

                          const SizedBox(height: 16),

                          // ── Historical Category Breakdown ──
                          _buildHistoricalBreakdown(
                            context,
                            financeService,
                            categoryTotals,
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────
  //  HISTORICAL BREAKDOWN SECTION (Last 7 Days)
  // ─────────────────────────────────────────
  Widget _buildHistoricalBreakdown(
    BuildContext context,
    FinanceService financeService,
    Map<String, int> categoryTotals,
  ) {
    final l10n = AppLocalizations.of(context);
    final accent = Theme.of(context).colorScheme.secondary;

    // Define the category display order and metadata
    final categories = [
      _CategoryMeta(
        'SPONSOR',
        l10n.categorySponsor,
        Icons.handshake_outlined,
        Colors.greenAccent,
      ),
      _CategoryMeta(
        'REWARD',
        l10n.categoryReward,
        Icons.emoji_events_outlined,
        Colors.amber,
      ),
      _CategoryMeta(
        'UPGRADE',
        l10n.categoryUpgrade,
        Icons.build_circle_outlined,
        Colors.blue,
      ),
      _CategoryMeta(
        'PRACTICE',
        l10n.categoryPractice,
        Icons.directions_car_outlined,
        Colors.blueGrey,
      ),
      _CategoryMeta(
        'QUALIFYING',
        l10n.categoryQualifying,
        Icons.timer_outlined,
        Colors.purpleAccent,
      ),
      _CategoryMeta(
        'REPAIR',
        l10n.categoryRepair,
        Icons.healing_outlined,
        Colors.redAccent,
      ),
      _CategoryMeta(
        'TAX',
        l10n.categoryTax,
        Icons.account_balance_outlined,
        Colors.grey,
      ),
      _CategoryMeta(
        'ACADEMY',
        'Youth Academy',
        Icons.school_outlined,
        Colors.greenAccent,
      ),
      _CategoryMeta(
        'OTHER',
        l10n.categoryOther,
        Icons.monetization_on_outlined,
        Colors.white54,
      ),
    ];

    final activeCategories = categories.where((c) {
      return (categoryTotals[c.type] ?? 0) != 0;
    }).toList();

    if (activeCategories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, color: accent, size: 16),
                const SizedBox(width: 6),
                Text(
                  "Historical Breakdown (Last 7 Days)",
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              "No transactions in the last 7 days.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(
                "Historical Breakdown (Last 7 Days)",
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...activeCategories.map((cat) {
            final int amount = categoryTotals[cat.type] ?? 0;
            final isPositive = amount >= 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SummaryRow(
                label: cat.label,
                value:
                    '${isPositive ? '+' : ''}${financeService.formatCurrency(amount)}',
                valueColor: isPositive ? Colors.greenAccent : Colors.redAccent,
                icon: cat.icon,
                iconColor: cat.color,
                small: true,
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  WEEKLY RUN-RATE BREAKDOWN SECTION
  // ─────────────────────────────────────────
  Widget _buildWeeklyProjectionBreakdown(
    BuildContext context,
    FinanceService financeService,
    int staffCost,
    List<Map<String, dynamic>> staffBreakdown,
    int projectedAcademyWages,
    Map<String, Facility> activeFacilitiesMap,
    Map<String, ActiveContract> activeSponsorsMap,
  ) {
    final l10n = AppLocalizations.of(context);
    final accent = Theme.of(context).colorScheme.secondary;

    final int maintenanceCost = activeFacilitiesMap.values.fold<int>(
      0,
      (acc, f) => acc + f.maintenanceCost,
    );
    final int sponsorIncome = activeSponsorsMap.values.fold<int>(
      0,
      (acc, s) => acc + s.weeklyBasePayment,
    );

    if (maintenanceCost == 0 &&
        projectedAcademyWages == 0 &&
        staffCost == 0 &&
        sponsorIncome == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: accent, size: 16),
              const SizedBox(width: 6),
              Text(
                "Weekly Run-Rate Breakdown",
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Sponsor Income
          if (sponsorIncome > 0) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SummaryRow(
                label: 'Sponsor Base Income',
                value: '+${financeService.formatCurrency(sponsorIncome)}',
                valueColor: Colors.greenAccent,
                icon: Icons.handshake_outlined,
                iconColor: Colors.lightGreen,
                small: true,
              ),
            ),
            ...activeSponsorsMap.values.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 16),
                child: _SummaryRow(
                  label: s.sponsorName,
                  value:
                      '+${financeService.formatCurrency(s.weeklyBasePayment)}',
                  valueColor: Colors.lightGreen.withValues(alpha: 0.8),
                  icon: Icons.subdirectory_arrow_right_rounded,
                  iconColor: Colors.lightGreen.withValues(alpha: 0.5),
                  small: true,
                ),
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 20),
          ],

          // Maintenance
          if (maintenanceCost > 0) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SummaryRow(
                label: l10n.categoryMaintenance,
                value: financeService.formatCurrency(-maintenanceCost),
                valueColor: Colors.redAccent,
                icon: Icons.apartment_outlined,
                iconColor: Colors.orange,
                small: true,
              ),
            ),
            ...activeFacilitiesMap.values.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 16),
                child: _SummaryRow(
                  label: f.getLocalizedName(context),
                  value: financeService.formatCurrency(-f.maintenanceCost),
                  valueColor: Colors.orange.withValues(alpha: 0.8),
                  icon: Icons.subdirectory_arrow_right_rounded,
                  iconColor: Colors.orange.withValues(alpha: 0.5),
                  small: true,
                ),
              ),
            ),
          ],

          // Academy
          if (projectedAcademyWages > 0) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SummaryRow(
                label: "Academy Trainee Wages",
                value: financeService.formatCurrency(-projectedAcademyWages),
                valueColor: Colors.redAccent,
                icon: Icons.school_outlined,
                iconColor: Colors.greenAccent,
                small: true,
              ),
            ),
          ],

          // Staff
          if (staffCost > 0) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SummaryRow(
                label: "Current Staff Costs",
                value: financeService.formatCurrency(-staffCost),
                valueColor: Colors.redAccent,
                icon: Icons.person_outline,
                iconColor: Colors.deepOrangeAccent,
                small: true,
              ),
            ),
            ...staffBreakdown.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 16),
                child: _SummaryRow(
                  label: s['name'],
                  value: financeService.formatCurrency(-(s['cost'] as int)),
                  valueColor: Colors.deepOrange.withValues(alpha: 0.8),
                  icon: Icons.subdirectory_arrow_right_rounded,
                  iconColor: Colors.deepOrange.withValues(alpha: 0.5),
                  small: true,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptySummary(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context).noTransactionsForSummary,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── Transaction tile (unchanged) ──

  Widget _buildTransactionTile(
    BuildContext context,
    Transaction tx,
    FinanceService service,
  ) {
    IconData icon;
    Color iconColor;

    switch (tx.type) {
      case 'SPONSOR':
        icon = Icons.handshake_outlined;
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
      case 'SALARY':
        icon = Icons.person_outline;
        iconColor = Colors.orange;
        break;
      case 'UPGRADE':
        icon = Icons.build_circle_outlined;
        iconColor = Colors.blue;
        break;
      case 'REWARD':
        icon = Icons.emoji_events_outlined;
        iconColor = Colors.amber;
        break;
      case 'PRACTICE':
        icon = Icons.directions_car_outlined;
        iconColor = Colors.blueGrey;
        break;
      default:
        icon = Icons.monetization_on_outlined;
        iconColor = Theme.of(context).colorScheme.secondary;
    }

    final isPositive = tx.amount >= 0;
    final dateFormatted = DateFormat('E, h:mm a').format(tx.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          tx.description,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          dateFormatted,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Text(
          "${isPositive ? '+' : ''}${service.formatCurrency(tx.amount)}",
          style: TextStyle(
            color: isPositive ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────
//  SUMMARY ROW helper widget
// ─────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color? iconColor;
  final bool bold;
  final bool small;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    this.iconColor,
    this.bold = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = small ? 12.0 : 14.0;
    return Row(
      children: [
        Icon(icon, color: iconColor ?? valueColor, size: small ? 14 : 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: fontSize,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────
//  TRANSFER BUDGET CARD (unchanged)
// ─────────────────────────────────
class _TransferBudgetCard extends StatefulWidget {
  final int initialPercentage;
  final int totalBudget;
  final String teamId;

  const _TransferBudgetCard({
    required this.initialPercentage,
    required this.totalBudget,
    required this.teamId,
  });

  @override
  State<_TransferBudgetCard> createState() => _TransferBudgetCardState();
}

class _TransferBudgetCardState extends State<_TransferBudgetCard> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialPercentage.toDouble();
  }

  @override
  void didUpdateWidget(covariant _TransferBudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPercentage != widget.initialPercentage) {
      _currentValue = widget.initialPercentage.toDouble();
    }
  }

  void _onSave() {
    FirebaseFirestore.instance.collection('teams').doc(widget.teamId).update({
      'transferBudgetPercentage': _currentValue.toInt(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transfer Budget Rule Updated!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableTransfers = (widget.totalBudget * (_currentValue / 100))
        .round();

    return NewDotWidget(
      featureId: 'finances_transfer_card',
      badgeAlignment: Alignment.bottomRight,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF15151A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Transfer Market Budget",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _currentValue.toInt() == widget.initialPercentage
                      ? null
                      : _onSave,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text("Save"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Allocated: ${_currentValue.toInt()}%"),
                Text(
                  FinanceService().formatCurrency(
                    math.max(0, availableTransfers),
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
            Slider(
              value: _currentValue,
              min: 10,
              max: 90,
              divisions: 80,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) {
                setState(() {
                  _currentValue = val;
                });
              },
            ),
            const Text(
              "Set the maximum percentage of your total balance available for placing bids. (10% - 90%)",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────
//  CATEGORY METADATA HELPER
// ─────────────────────────────────
class _CategoryMeta {
  final String type;
  final String label;
  final IconData icon;
  final Color color;

  const _CategoryMeta(this.type, this.label, this.icon, this.color);
}
