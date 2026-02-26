import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_seeder.dart';
import '../services/driver_assignment_service.dart';
import '../services/team_assignment_service.dart';
import '../services/universe_service.dart';
import '../services/transfer_market_service.dart';
import '../models/domain/domain_models.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isProcessing = false;
  final TextEditingController _passwordController = TextEditingController();
  bool _isAuthenticated = false;

  void _handleNukeAndReseed() async {
    setState(() => _isProcessing = true);
    try {
      await DatabaseSeeder.nukeAndReseed(startDate: _selectedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Database Nuked and Reseeded successfully!"),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  final TextEditingController _newLeagueNameController =
      TextEditingController();
  int _newLeagueTier = 2;
  bool _isCreatingLeague = false;

  void _handleCreateNewLeague() async {
    if (_newLeagueNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a League Name")),
      );
      return;
    }

    setState(() => _isCreatingLeague = true);

    try {
      // Create new league document explicitly using Universe Seeder helper to set defaults
      final String generateId =
          'ftg_series_t${_newLeagueTier}_${DateTime.now().millisecondsSinceEpoch}';

      final db = FirebaseFirestore.instance;
      final seasonSnapshot = await db.collection('seasons').limit(1).get();
      String currentSeasonId = '';
      if (seasonSnapshot.docs.isNotEmpty) {
        currentSeasonId = seasonSnapshot.docs.first.id;
      } else {
        throw Exception("No active season found, cannot attach new league.");
      }

      final teams = await TeamAssignmentService().generateAndSaveTeamsForLeague(
        generateId,
        count: 11,
      );
      final drivers = await DriverAssignmentService()
          .generateAndSaveDriversForTeams(teams, _newLeagueTier);

      final newLeague = FtgLeague(
        id: generateId,
        name: _newLeagueNameController.text.trim(),
        teams: teams,
        drivers: drivers,
        currentSeasonId: currentSeasonId,
        tier: _newLeagueTier,
      );

      // Agrega la liga al universe doc y collection
      await UniverseService().addLeague(newLeague);
      await db.collection('leagues').doc(generateId).set(newLeague.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("League ${newLeague.name} created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _newLeagueNameController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error creating league: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingLeague = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person,
                  size: 64,
                  color: Colors.tealAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  "ADMIN ACCESS",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Admin Password",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.password),
                  ),
                  onSubmitted: (val) {
                    if (val == "ftgadmin2026") {
                      setState(() => _isAuthenticated = true);
                    }
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (_passwordController.text == "ftgadmin2026") {
                      setState(() => _isAuthenticated = true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid password")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text("LOGIN"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ADMIN CONTROL PANEL"),
        backgroundColor: Colors.black87,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "CURRENT SEASON STATUS",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('seasons')
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Card(
                    child: ListTile(title: Text("No active season found")),
                  );
                }
                final data =
                    snapshot.data!.docs.first.data() as Map<String, dynamic>;
                final rawStart = data['startDate'];
                DateTime? start;

                // Extremely robust date parsing for Web/Mobile mixed formats
                if (rawStart != null) {
                  final typeStr = rawStart.runtimeType.toString();
                  if (typeStr.contains('Timestamp') || rawStart is Timestamp) {
                    start = (rawStart as dynamic).toDate();
                  } else if (rawStart is String) {
                    start = DateTime.tryParse(rawStart);
                  }
                }

                return Card(
                  child: ListTile(
                    title: Text("Season ${data['year'] ?? ''}"),
                    subtitle: Text(
                      "Starts: ${start != null ? DateFormat('MMM d, yyyy').format(start) : 'N/A'}",
                    ),
                    trailing: const Icon(Icons.info_outline),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              "NEW SEASON CONFIGURATION",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text("Season 1 Start Date"),
                subtitle: Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(
                      () => _selectedDate = MathUtils.getNearestSunday(picked),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "NEW LEAGUE TIER CREATION",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Incrementally adds a new League, generates 11 default teams, and 22 default drivers.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newLeagueNameController,
              decoration: const InputDecoration(
                labelText: "League Name (e.g. FTG 2.2 Series)",
                border: OutlineInputBorder(),
              ),
              enabled: !_isCreatingLeague,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _newLeagueTier,
              decoration: const InputDecoration(
                labelText: "Tier Level",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text("Tier 1")),
                DropdownMenuItem(value: 2, child: Text("Tier 2")),
                DropdownMenuItem(value: 3, child: Text("Tier 3")),
              ],
              onChanged: _isCreatingLeague
                  ? null
                  : (val) {
                      if (val != null) setState(() => _newLeagueTier = val);
                    },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreatingLeague ? null : _handleCreateNewLeague,
                icon: _isCreatingLeague
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _isCreatingLeague
                      ? "GENERATING ENTITIES..."
                      : "CREATE LEAGUE & GENERATE ENTITIES",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "TRANSFER MARKET",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Populates the transfer market with new randomly generated drivers.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        setState(() => _isProcessing = true);
                        try {
                          await TransferMarketService()
                              .generateAdminMarketDrivers(50);
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("50 Drivers added to market!"),
                              ),
                            );
                        } catch (e) {
                          if (mounted)
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                        } finally {
                          if (mounted) setState(() => _isProcessing = false);
                        }
                      },
                icon: const Icon(Icons.people),
                label: const Text("GENERATE 50 MARKET DRIVERS"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "DATABASE ACTIONS",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Warning: Nuking the database will delete all existing data (teams, seasonal progress, etc.) and recreate the world based on the start date above.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _showConfirmNukeDialog,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.dangerous),
                label: Text(
                  _isProcessing ? "PROCESSING..." : "NUKE AND RESEED WORLD",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmNukeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ARE YOU SURE?"),
        content: const Text(
          "This action cannot be undone. All current game progress will be lost.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleNukeAndReseed();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("YES, NUKE EVERYTHING"),
          ),
        ],
      ),
    );
  }
}

class MathUtils {
  static DateTime getNearestSunday(DateTime date) {
    // 0 = Sunday in some systems, but in Dart weekday 7 is Sunday.
    int diff = DateTime.sunday - date.weekday;
    if (diff < 0) diff += 7;
    return date.add(Duration(days: diff));
  }
}
