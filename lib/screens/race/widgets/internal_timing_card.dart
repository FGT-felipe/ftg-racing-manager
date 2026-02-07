import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InternalTimingCard extends StatelessWidget {
  final String teamId;
  final List<Map<String, dynamic>> drivers; // [{id, name}]

  const InternalTimingCard({
    super.key,
    required this.teamId,
    required this.drivers,
  });

  String _formatLapTime(double seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toStringAsFixed(3).padLeft(6, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(0, 8, 16, 16),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, color: Color(0xFF00FF88), size: 20),
                const SizedBox(width: 8),
                Text(
                  "INTERNAL TIMING",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .doc(teamId)
                  .collection('practice_results')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // Get best lap for each driver
                Map<String, double> bestLaps = {};
                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final driverId = data['driverId'] as String;
                  final lapTime = (data['lapTime'] as num).toDouble();

                  if (!bestLaps.containsKey(driverId) ||
                      lapTime < bestLaps[driverId]!) {
                    bestLaps[driverId] = lapTime;
                  }
                }

                if (bestLaps.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "No lap times recorded yet",
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }

                // Sort drivers by best lap time
                final sortedDrivers =
                    drivers
                        .map((d) {
                          return {
                            'id': d['id'],
                            'name': d['name'],
                            'bestLap': bestLaps[d['id']],
                          };
                        })
                        .where((d) => d['bestLap'] != null)
                        .toList()
                      ..sort(
                        (a, b) => (a['bestLap'] as double).compareTo(
                          b['bestLap'] as double,
                        ),
                      );

                final fastestTime = sortedDrivers.isNotEmpty
                    ? sortedDrivers.first['bestLap'] as double
                    : 0.0;

                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 40,
                            child: Text(
                              "POS",
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "DRIVER",
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "BEST LAP",
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1A1A1A),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            flex: 1,
                            child: Text(
                              "GAP",
                              style: TextStyle(
                                fontFamily: 'RobotoMono',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF1A1A1A),
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Timing rows
                    ...sortedDrivers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final driver = entry.value;
                      final lapTime = driver['bestLap'] as double;
                      final gap = lapTime - fastestTime;
                      final isFastest = index == 0;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isFastest
                              ? const Color(0xFF00FF88).withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isFastest
                                      ? const Color(0xFF00FF88)
                                      : const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                driver['name'] as String,
                                style: TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 14,
                                  fontWeight: isFastest
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatLapTime(lapTime),
                                style: TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 14,
                                  fontWeight: isFastest
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isFastest
                                      ? const Color(0xFF00FF88)
                                      : const Color(0xFF1A1A1A),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: Text(
                                isFastest ? "—" : "+${gap.toStringAsFixed(3)}",
                                style: const TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
