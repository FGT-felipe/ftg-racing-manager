import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/race_service.dart';
import '../../services/circuit_service.dart';
import '../../services/season_service.dart';
import '../../models/core_models.dart';

class QualifyingScreen extends StatefulWidget {
  final String seasonId;
  final String? circuitId;
  final bool isEmbed;

  const QualifyingScreen({
    super.key,
    required this.seasonId,
    this.circuitId,
    this.isEmbed = false,
  });

  @override
  State<QualifyingScreen> createState() => _QualifyingScreenState();
}

class _QualifyingScreenState extends State<QualifyingScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  bool _isCompleted = false;
  String _circuitName = "Qualifying Session";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      if (widget.circuitId != null) {
        final profile = CircuitService().getCircuitProfile(widget.circuitId!);
        setState(() {
          _circuitName = "Qualifying - ${profile.name}";
        });
      }

      // Check for existing results
      final seasonDoc = await FirebaseFirestore.instance
          .collection('seasons')
          .doc(widget.seasonId)
          .get();
      if (seasonDoc.exists) {
        final season = Season.fromMap(seasonDoc.data()!);
        final current = SeasonService().getCurrentRace(season);
        if (current != null) {
          final raceId = SeasonService().raceDocumentId(
            widget.seasonId,
            current.event,
          );
          final raceDoc = await FirebaseFirestore.instance
              .collection('races')
              .doc(raceId)
              .get();

          if (raceDoc.exists) {
            final data = raceDoc.data()!;
            if (data['qualifyingResults'] != null) {
              setState(() {
                _results = List<Map<String, dynamic>>.from(
                  data['qualifyingResults'],
                );
                _isCompleted = true;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading qualy data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runQualifying() async {
    setState(() => _isLoading = true);
    try {
      final results = await RaceService().simulateQualifying(widget.seasonId);
      setState(() {
        _results = results;
        _isCompleted = true;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (!_isCompleted)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _runQualifying,
                      icon: const Icon(Icons.timer),
                      label: const Text("START QUALIFYING SESSION"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(24),
                        textStyle: const TextStyle(fontSize: 20),
                        backgroundColor: theme.primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),

                if (_results.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final row = _results[index];
                        return Card(
                          color: index == 0
                              ? Colors.purple.withValues(alpha: 0.2)
                              : theme.cardColor,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              row['driverName'],
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              row['teamName'],
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            trailing: Text(
                              "${(row['lapTime'] as double).toStringAsFixed(3)}s",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );

    if (widget.isEmbed) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text(_circuitName)),
      body: content,
    );
  }
}
