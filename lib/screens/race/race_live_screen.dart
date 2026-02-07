import 'package:flutter/material.dart';
import '../../services/race_service.dart';

class RaceLiveScreen extends StatefulWidget {
  final String seasonId;
  const RaceLiveScreen({super.key, required this.seasonId});

  @override
  State<RaceLiveScreen> createState() => _RaceLiveScreenState();
}

class _RaceLiveScreenState extends State<RaceLiveScreen> {
  bool _isLoading = false;

  Future<void> _simulateRace() async {
    setState(() => _isLoading = true);
    // TODO: proper race simulation integration including passing grid etc.
    // For now we just call simulateNextRace which does the simplified logic
    // OR we should integrate simulateRaceSession properly.
    // Given simulateNextRace exists and does db updates, let's use it for "result view"
    try {
      final res = await RaceService().simulateNextRace(widget.seasonId);
      // simulateNextRace returns Map with podium etc, not RaceSessionResult object
      // But let's just display what we get.
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Race Completed"),
            content: Text("Winner: ${res['podium'][0].name}\nPoints updated."),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Grand Prix - LIVE")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flag, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              "Main Race Event",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _simulateRace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                ),
                child: const Text(
                  "WATCH RACE SIMULATION",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
