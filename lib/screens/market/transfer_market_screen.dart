import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../services/transfer_market_service.dart';

class TransferMarketScreen extends StatefulWidget {
  final String teamId;

  const TransferMarketScreen({super.key, required this.teamId});

  @override
  State<TransferMarketScreen> createState() => _TransferMarketScreenState();
}

class _TransferMarketScreenState extends State<TransferMarketScreen> {
  bool _isMarketOpen = true;

  @override
  void initState() {
    super.initState();
    _checkMarketWindow();
  }

  Future<void> _checkMarketWindow() async {
    // Basic logic: if remaining races is <= 1, it's closed.
    // Assuming team gives us weekStatus.racesRemaining.
    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();
      if (teamDoc.exists) {
        final data = teamDoc.data()!;
        final weekStatus = data['weekStatus'] as Map<String, dynamic>?;
        final racesRemaining = weekStatus?['racesRemaining'] as int? ?? 10;

        if (mounted) {
          setState(() {
            _isMarketOpen = racesRemaining > 1; // closes 1 race before end
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking market window: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMarketOpen) {
      return Scaffold(
        appBar: AppBar(title: const Text("Transfer Market")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_clock,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                "Transfer Market is Closed",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                "The market closes with 1 race remaining in the season.",
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Transfer Market")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .where('isTransferListed', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text("No drivers currently listed on the market."),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: _buildDriverTable(docs),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDriverTable(List<QueryDocumentSnapshot> docs) {
    final theme = Theme.of(context);
    return DataTable(
      headingRowColor: WidgetStateProperty.all(
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      columns: const [
        DataColumn(label: Text("Driver")),
        DataColumn(label: Text("Age")),
        DataColumn(label: Text("Avg Stat")),
        DataColumn(label: Text("Highest Bid")),
        DataColumn(label: Text("Time Left")),
        DataColumn(label: Text("Action")),
      ],
      rows: docs.map((doc) {
        final driver = Driver.fromMap(doc.data() as Map<String, dynamic>);

        // Calculate max stats to masquerade actual stats
        int statSum = 0;
        int count = 0;
        for (var stat in DriverStats.drivingStats) {
          statSum += driver.getStat(stat);
          count++;
        }
        final avgStat = count > 0 ? (statSum / count).round() : 50;

        // Calculate time left
        final listedAt = driver.transferListedAt ?? DateTime.now();
        final expiresAt = listedAt.add(const Duration(hours: 24));
        final diff = expiresAt.difference(DateTime.now());

        String timeLeftStr;
        if (diff.isNegative) {
          timeLeftStr = "Resolving...";
        } else {
          final hrs = diff.inHours;
          final mins = diff.inMinutes % 60;
          timeLeftStr = "${hrs}h ${mins}m";
        }

        final isMyBid = driver.highestBidderTeamId == widget.teamId;

        return DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: driver.portraitUrl != null
                        ? NetworkImage(driver.portraitUrl!)
                        : null,
                    child: driver.portraitUrl == null
                        ? Text(
                            driver.name[0],
                            style: const TextStyle(fontSize: 10),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    driver.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            DataCell(Text(driver.age.toString())),
            DataCell(Text("~$avgStat")),
            DataCell(
              Text(
                "\$${(driver.currentHighestBid / 1000).toStringAsFixed(0)}k",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isMyBid ? Colors.green : Colors.amber,
                ),
              ),
            ),
            DataCell(
              Text(
                timeLeftStr,
                style: TextStyle(
                  color: diff.isNegative ? Colors.red : Colors.white,
                ),
              ),
            ),
            DataCell(
              driver.teamId == widget.teamId
                  ? const Text(
                      "Your Driver",
                      style: TextStyle(color: Colors.grey),
                    )
                  : FilledButton.tonal(
                      onPressed: diff.isNegative
                          ? null
                          : () => _showBidModal(driver),
                      child: const Text("Bid"),
                    ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showBidModal(Driver driver) {
    int bidAmount = driver.currentHighestBid == 0
        ? driver.marketValue
        : driver.currentHighestBid + 50000;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Place Transfer Bid"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bidding for ${driver.name}"),
                  const SizedBox(height: 16),
                  Text(
                    "Current Highest Bid: \$${(driver.currentHighestBid / 1000).toStringAsFixed(0)}k",
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => setState(() => bidAmount -= 100000),
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        "\$${(bidAmount / 1000).toStringAsFixed(0)}k",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => bidAmount += 100000),
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await TransferMarketService().placeBid(
                        widget.teamId,
                        driver.id,
                        bidAmount,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Bid placed successfully."),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },
                  child: const Text("Submit Bid"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
