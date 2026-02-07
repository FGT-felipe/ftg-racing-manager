import 'package:flutter/material.dart';
import '../../services/race_service.dart';

class QualifyingScreen extends StatefulWidget {
  final String seasonId;

  const QualifyingScreen({super.key, required this.seasonId});

  @override
  State<QualifyingScreen> createState() => _QualifyingScreenState();
}

class _QualifyingScreenState extends State<QualifyingScreen> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _isCompleted = false;

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
    return Scaffold(
      appBar: AppBar(title: const Text("Qualifying Session")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_isCompleted)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runQualifying,
                  icon: const Icon(Icons.timer),
                  label: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text("START QUALIFYING SESSION"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(24),
                    textStyle: const TextStyle(fontSize: 20),
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
                      color: index == 0 ? Colors.purple.withOpacity(0.2) : null,
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
                        title: Text(row['driverName']),
                        subtitle: Text(row['teamName']),
                        trailing: Text(
                          "${(row['lapTime'] as double).toStringAsFixed(3)}s",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
