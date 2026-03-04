import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../models/core_models.dart';
import '../../services/finance_service.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../l10n/app_localizations.dart';
import '../../widgets/common/new_badge.dart';
import '../../services/time_service.dart';

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
                    child: _buildSummaryPanel(context, financeService),
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
                  child: _buildSummaryCard(context, financeService),
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
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, right: 20, bottom: 20),
      child: _buildSummaryCard(context, financeService),
    );
  }

  // ─────────────────────────────────────────────
  //  FINANCIAL SUMMARY CARD (shared mobile+desk)
  // ─────────────────────────────────────────────
  Widget _buildSummaryCard(
    BuildContext context,
    FinanceService financeService,
  ) {
    final l10n = AppLocalizations.of(context);
    final accent = Theme.of(context).colorScheme.secondary;

    return StreamBuilder<List<Transaction>>(
      stream: financeService.getTransactionHistory(teamId),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];

        // Compute totals
        int totalIncome = 0;
        int totalExpenses = 0;
        for (final tx in transactions) {
          if (tx.amount >= 0) {
            totalIncome += tx.amount;
          } else {
            totalExpenses += tx.amount; // negative
          }
        }
        final netResult = totalIncome + totalExpenses;

        // Compute per-category breakdown
        final Map<String, int> categoryTotals = {};
        for (final tx in transactions) {
          final key = tx.type.isNotEmpty ? tx.type : 'OTHER';
          categoryTotals[key] = (categoryTotals[key] ?? 0) + tx.amount;
        }

        // Weekly calculation: average income/expenses per week
        int weeklyIncome = 0;
        int weeklyExpenses = 0;
        if (transactions.isNotEmpty) {
          // Find the date span
          final now = DateTime.now();
          final oldest = transactions
              .map((t) => t.date)
              .reduce((a, b) => a.isBefore(b) ? a : b);
          final daySpan = now.difference(oldest).inDays;
          final weeks = daySpan < 7 ? 1.0 : daySpan / 7.0;
          weeklyIncome = (totalIncome / weeks).round();
          weeklyExpenses = (totalExpenses / weeks).round();
        }
        final weeklyNet = weeklyIncome + weeklyExpenses;

        return Container(
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
                        Icon(Icons.analytics_outlined, color: accent, size: 18),
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

                    // ── All-time totals ──
                    _SummaryRow(
                      label: l10n.totalIncomeLabel,
                      value: financeService.formatCurrency(totalIncome),
                      valueColor: Colors.greenAccent,
                      icon: Icons.arrow_upward_rounded,
                    ),
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: l10n.totalExpensesLabel,
                      value: financeService.formatCurrency(totalExpenses),
                      valueColor: Colors.redAccent,
                      icon: Icons.arrow_downward_rounded,
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      color: Colors.white.withValues(alpha: 0.06),
                      height: 24,
                    ),
                    _SummaryRow(
                      label: l10n.netResultLabel,
                      value: financeService.formatCurrency(netResult),
                      valueColor: netResult >= 0
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      icon: netResult >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      bold: true,
                    ),

                    const SizedBox(height: 24),

                    // ── Category Breakdown ──
                    _buildCategoryBreakdown(
                      context,
                      financeService,
                      categoryTotals,
                    ),

                    const SizedBox(height: 16),

                    // ── Weekly projection ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.date_range_rounded,
                                    color: accent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.weeklyProjectionTitle,
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              Builder(
                                builder: (context) {
                                  // Calcula el próximo domingo a las 16:00 COT
                                  final now = TimeService().nowBogota;
                                  int daysUntilSunday = (7 - now.weekday) % 7;
                                  var nextUpdate = DateTime(
                                    now.year,
                                    now.month,
                                    now.day,
                                    16,
                                    0,
                                  ).add(Duration(days: daysUntilSunday));
                                  // Si ya pasó la hora este domingo, pasa al siguiente
                                  if (daysUntilSunday == 0 && now.hour >= 16) {
                                    nextUpdate = nextUpdate.add(
                                      const Duration(days: 7),
                                    );
                                  }
                                  final dateStr = DateFormat(
                                    'E, h:mm a',
                                  ).format(nextUpdate);

                                  return Text(
                                    '${l10n.nextFinanceUpdate}: $dateStr COT',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SummaryRow(
                            label: l10n.weeklyIncomeLabel,
                            value:
                                '+${financeService.formatCurrency(weeklyIncome)}',
                            valueColor: Colors.greenAccent,
                            icon: Icons.add_circle_outline,
                            small: true,
                          ),
                          const SizedBox(height: 8),
                          _SummaryRow(
                            label: l10n.weeklyExpensesLabel,
                            value: financeService.formatCurrency(
                              weeklyExpenses,
                            ),
                            valueColor: Colors.redAccent,
                            icon: Icons.remove_circle_outline,
                            small: true,
                          ),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.06),
                            height: 20,
                          ),
                          _SummaryRow(
                            label: l10n.weeklyNetLabel,
                            value: financeService.formatCurrency(weeklyNet),
                            valueColor: weeklyNet >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            icon: weeklyNet >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            bold: true,
                            small: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  //  CATEGORY BREAKDOWN SECTION
  // ─────────────────────────────────────────
  Widget _buildCategoryBreakdown(
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
        'MAINTENANCE',
        l10n.categoryMaintenance,
        Icons.apartment_outlined,
        Colors.orange,
      ),
      _CategoryMeta(
        'UPGRADE',
        l10n.categoryUpgrade,
        Icons.build_circle_outlined,
        Colors.blue,
      ),
      _CategoryMeta(
        'SALARY',
        l10n.categorySalary,
        Icons.person_outline,
        Colors.deepOrangeAccent,
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
        'OTHER',
        l10n.categoryOther,
        Icons.monetization_on_outlined,
        Colors.white54,
      ),
    ];

    // Filter to only categories that have transactions
    final activeCategories = categories
        .where((c) => (categoryTotals[c.type] ?? 0) != 0)
        .toList();

    if (activeCategories.isEmpty) return const SizedBox.shrink();

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
                l10n.breakdownTitle,
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
            final amount = categoryTotals[cat.type] ?? 0;
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

    return NewBadgeWidget(
      createdAt: DateTime.now(),
      forceShow: true,
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
