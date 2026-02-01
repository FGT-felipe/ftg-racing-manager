import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../../models/core_models.dart';
import '../../services/finance_service.dart';
import 'package:intl/intl.dart';
import 'sponsorship_screen.dart';

class OfficeScreen extends StatelessWidget {
  final String teamId;

  const OfficeScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final financeService = FinanceService();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("FINANCE & OFFICE"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId)
            .snapshots(),
        builder: (context, teamSnapshot) {
          if (!teamSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
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
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (isNegative ? Colors.redAccent : Colors.greenAccent)
                        .withOpacity(0.2),
                  ),
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
                        color: isNegative ? Colors.redAccent : Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              // Sponsorships Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SponsorshipScreen(teamId: teamId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.handshake_outlined),
                  label: const Text("MANAGE SPONSORSHIPS"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Transaction List Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      "RECENT MOVEMENTS",
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.history, color: Colors.tealAccent, size: 16),
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
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.tealAccent,
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
                              color: Colors.white.withOpacity(0.1),
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
                        return _buildTransactionTile(
                          context,
                          tx,
                          financeService,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
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
        iconColor = Colors.tealAccent;
        break;
      case 'SALARY':
        icon = Icons.person_outline;
        iconColor = Colors.orangeAccent;
        break;
      case 'UPGRADE':
        icon = Icons.build_circle_outlined;
        iconColor = Colors.blueAccent;
        break;
      case 'REWARD':
        icon = Icons.emoji_events_outlined;
        iconColor = Colors.amberAccent;
        break;
      default:
        icon = Icons.monetization_on_outlined;
        iconColor = Colors.grey;
    }

    final isPositive = tx.amount >= 0;
    final dateFormatted = DateFormat('E, h:mm a').format(tx.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          tx.description,
          style: const TextStyle(
            color: Colors.white,
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
            color: isPositive ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
