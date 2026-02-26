import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../services/transfer_market_service.dart';
import '../../widgets/common/onyx_table.dart';
import '../../widgets/common/driver_stars.dart';
import '../drivers/widgets/driver_card.dart';

class TransferMarketScreen extends StatefulWidget {
  final String teamId;

  const TransferMarketScreen({super.key, required this.teamId});

  @override
  State<TransferMarketScreen> createState() => _TransferMarketScreenState();
}

class _TransferMarketScreenState extends State<TransferMarketScreen> {
  bool _isMarketOpen = true;
  int _limit = 5;

  @override
  void initState() {
    super.initState();
    _checkMarketWindow();
  }

  Future<void> _checkMarketWindow() async {
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
            _isMarketOpen = racesRemaining > 1;
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
            .orderBy('transferListedAt')
            .limit(_limit)
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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: _buildDriverTable(docs),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDriverTable(List<QueryDocumentSnapshot> docs) {
    return OnyxTable(
      flexValues: const [4, 1, 3, 2, 2, 2, 2],
      columns: const [
        "Driver",
        "Age",
        "Potential",
        "Market Value",
        "Highest Bid",
        "Time Left",
        "Action",
      ],
      itemCount: docs.length,
      itemBuilder: (context, index) {
        return _buildRow(docs[index]);
      },
      onReachEnd: _loadMore,
      highlightIndices: const [],
    );
  }

  Widget _buildRow(QueryDocumentSnapshot doc) {
    final driver = Driver.fromMap(doc.data() as Map<String, dynamic>);

    final listedAt = driver.transferListedAt ?? DateTime.now();
    final expiresAt = listedAt.add(const Duration(hours: 24));
    final diff = expiresAt.difference(DateTime.now());

    final isMyBid = driver.highestBidderTeamId == widget.teamId;

    final rowItems = <Widget>[
      GestureDetector(
        onTap: () => _showDriverDetail(driver),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: driver.portraitUrl != null
                    ? (driver.portraitUrl!.startsWith('http')
                          ? NetworkImage(driver.portraitUrl!)
                          : AssetImage(driver.portraitUrl!) as ImageProvider)
                    : null,
                child: driver.portraitUrl == null
                    ? Text(driver.name[0], style: const TextStyle(fontSize: 10))
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  driver.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white24,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      Text(driver.age.toString(), style: const TextStyle(fontSize: 13)),
      DriverStars(
        currentStars: driver.currentStars,
        maxStars: driver.potential,
      ),
      Text(
        "\$${(driver.marketValue / 1000).toStringAsFixed(0)}k",
        style: const TextStyle(fontSize: 13, color: Colors.white70),
      ),
      Text(
        "\$${(driver.currentHighestBid / 1000).toStringAsFixed(0)}k",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: isMyBid ? Colors.green : Colors.amber,
        ),
      ),
      _MarketCountdown(expiresAt: expiresAt),
      driver.teamId == widget.teamId
          ? const Text(
              "Your Driver",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            )
          : FilledButton(
              onPressed: (diff.isNegative || diff.inMinutes < 5)
                  ? null
                  : () => _showBidModal(driver),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.yellow,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(60, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gavel, size: 14),
                  SizedBox(width: 4),
                  Text("Bid", style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
    ];

    return Row(
      children: List.generate(rowItems.length, (i) {
        return Expanded(
          flex: const [4, 1, 3, 2, 2, 2, 2][i],
          child: rowItems[i],
        );
      }),
    );
  }

  bool _isLoadingMore = false;
  void _loadMore() async {
    if (_isLoadingMore || !mounted) return;
    _isLoadingMore = true;
    setState(() {
      _limit += 5;
    });
    // Small delay to allow the stream to react and avoid double triggers from scroll momentum
    await Future.delayed(const Duration(milliseconds: 300));
    _isLoadingMore = false;
  }

  void _showDriverDetail(Driver driver) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Center(
                child: SizedBox(
                  width: screenWidth * 0.7,
                  child: DriverCard(driver: driver),
                ),
              ),
            ],
          ),
        ),
      ),
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
                        onPressed: () {
                          final minBid = driver.currentHighestBid == 0
                              ? driver.marketValue
                              : driver.currentHighestBid + 50000;
                          if (bidAmount > minBid) {
                            setState(() => bidAmount -= 100000);
                          }
                        },
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

class _MarketCountdown extends StatefulWidget {
  final DateTime expiresAt;

  const _MarketCountdown({required this.expiresAt});

  @override
  State<_MarketCountdown> createState() => _MarketCountdownState();
}

class _MarketCountdownState extends State<_MarketCountdown> {
  Timer? _timer;
  late Duration _diff;

  @override
  void initState() {
    super.initState();
    _diff = widget.expiresAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _diff = widget.expiresAt.difference(DateTime.now());
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String timeLeftStr;
    if (_diff.isNegative) {
      timeLeftStr = "Resolving...";
    } else {
      final hrs = _diff.inHours.toString().padLeft(2, '0');
      final mins = (_diff.inMinutes % 60).toString().padLeft(2, '0');
      final secs = (_diff.inSeconds % 60).toString().padLeft(2, '0');
      timeLeftStr = "${hrs}h ${mins}m ${secs}s";
    }

    return Text(
      timeLeftStr,
      style: TextStyle(
        color: _diff.isNegative ? Colors.redAccent : Colors.white70,
        fontSize: 13,
      ),
    );
  }
}
