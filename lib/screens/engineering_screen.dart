import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../models/core_models.dart';
import '../services/car_service.dart';

class EngineeringScreen extends StatelessWidget {
  final String teamId;

  const EngineeringScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final team = Team.fromMap(data);
        final budgetM = (team.budget / 1000000).toStringAsFixed(1);

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: Text(l10n.engineeringTitle),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.tealAccent.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.tealAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        l10n.budgetLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${l10n.currencySymbol}$budgetM${l10n.millionsSuffix}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                _UpgradeTile(
                  title: l10n.aero,
                  partKey: 'aero',
                  level: team.carStats['aero'] ?? 50,
                  currentBudget: team.budget,
                  teamId: team.id,
                ),
                const SizedBox(height: 16),
                _UpgradeTile(
                  title: l10n.engine,
                  partKey: 'engine',
                  level: team.carStats['engine'] ?? 50,
                  currentBudget: team.budget,
                  teamId: team.id,
                ),
                const SizedBox(height: 16),
                _UpgradeTile(
                  title: l10n.reliability,
                  partKey: 'reliability',
                  level: team.carStats['reliability'] ?? 50,
                  currentBudget: team.budget,
                  teamId: team.id,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UpgradeTile extends StatefulWidget {
  final String title;
  final String partKey;
  final int level;
  final int currentBudget;
  final String teamId;

  const _UpgradeTile({
    required this.title,
    required this.partKey,
    required this.level,
    required this.currentBudget,
    required this.teamId,
  });

  @override
  State<_UpgradeTile> createState() => _UpgradeTileState();
}

class _UpgradeTileState extends State<_UpgradeTile> {
  bool _isUpgrading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cost = widget.level * 100000;
    final canAfford = widget.currentBudget >= cost;
    final costFormatted = (cost / 1000000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "LVL ${widget.level}",
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: widget.level / 100,
            backgroundColor: Colors.white10,
            color: Colors.tealAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.costLabel(
                      l10n.currencySymbol,
                      "${costFormatted}${l10n.millionsSuffix}",
                    ),
                    style: TextStyle(
                      color: canAfford ? Colors.white70 : Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!canAfford)
                    Text(
                      l10n.insufficientFunds.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              ElevatedButton(
                onPressed: (canAfford && !_isUpgrading)
                    ? () async {
                        setState(() => _isUpgrading = true);
                        try {
                          await CarService().upgradePart(
                            teamId: widget.teamId,
                            partKey: widget.partKey,
                            currentLevel: widget.level,
                            currentBudget: widget.currentBudget,
                          );
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString()),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _isUpgrading = false);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white24,
                ),
                child: _isUpgrading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(l10n.upgradeBtn.toUpperCase()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
