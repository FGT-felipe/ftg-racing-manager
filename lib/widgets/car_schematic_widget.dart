import 'package:flutter/material.dart';

class CarSchematicWidget extends StatelessWidget {
  final Map<String, int> stats;
  final String carLabel;
  final double width;

  const CarSchematicWidget({
    super.key,
    required this.stats,
    required this.carLabel,
    this.width = 180,
  });

  @override
  Widget build(BuildContext context) {
    final aero = stats['aero'] ?? 1;
    final powertrain = stats['powertrain'] ?? 1;
    final chassis = stats['chassis'] ?? 1;
    final reliability = stats['reliability'] ?? 1;

    // Calculations based on levels (1-20)
    final corneringBoost = (aero / 20 * 100).toStringAsFixed(1);
    final powerBoost = (powertrain / 20 * 100).toStringAsFixed(1);
    final handlingBoost = (chassis / 20 * 100).toStringAsFixed(1);
    final reliabilityVal = (reliability / 20 * 100).toStringAsFixed(1);

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            carLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Stats Breakdown
          _buildStatRow("POWER", "+$powerBoost%", Colors.orangeAccent),
          const SizedBox(height: 8),
          _buildStatRow("AERO", "+$corneringBoost%", Colors.cyanAccent),
          const SizedBox(height: 8),
          _buildStatRow("HANDLING", "+$handlingBoost%", Colors.purpleAccent),
          const SizedBox(height: 8),
          _buildStatRow("RELIABILITY", "$reliabilityVal%", Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value:
                double.parse(value.replaceAll('%', '').replaceAll('+', '')) /
                100,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            color: color.withValues(alpha: 0.8),
            minHeight: 2,
          ),
        ),
      ],
    );
  }
}
