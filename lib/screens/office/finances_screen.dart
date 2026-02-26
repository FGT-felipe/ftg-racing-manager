import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../models/core_models.dart';
import '../../services/finance_service.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../l10n/app_localizations.dart';
import '../../widgets/common/new_badge.dart';

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
                  if (transSnapshot.connectionState ==
                      ConnectionState.waiting) {
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
          ],
        );
      },
    );
  }

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
