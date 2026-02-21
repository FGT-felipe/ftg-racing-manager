import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../models/core_models.dart';
import '../../services/finance_service.dart';
import 'package:intl/intl.dart';

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
                  const Text(
                    "CURRENT BALANCE",
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

            // Transaction List Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text(
                    "RECENT MOVEMENTS",
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
                          const Text(
                            "No financial activity yet",
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
