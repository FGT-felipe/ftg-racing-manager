import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/core_models.dart';
import '../../services/transfer_market_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/common/onyx_table.dart';
import '../../widgets/common/driver_stars.dart';
import '../../widgets/common/onyx_skeleton.dart';
import 'widgets/transfer_market_driver_card.dart';

class TransferMarketScreen extends StatefulWidget {
  final String teamId;

  const TransferMarketScreen({super.key, required this.teamId});

  @override
  State<TransferMarketScreen> createState() => _TransferMarketScreenState();
}

class _TransferMarketScreenState extends State<TransferMarketScreen> {
  bool _isMarketOpen = true;
  bool _isFetching = true;
  List<Driver> _drivers = [];
  DocumentSnapshot? _lastDocument;
  final List<DocumentSnapshot?> _pageHistory = [null];
  int _currentPage = 0;
  static const int _pageSize = 15;
  final Set<String> _cancellingBidDriverIds = {};

  @override
  void initState() {
    super.initState();
    _checkMarketWindow();
    _fetchPage(0);
  }

  Future<void> _fetchPage(int pageIndex) async {
    setState(() => _isFetching = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('drivers')
          .where('isTransferListed', isEqualTo: true)
          .orderBy('transferListedAt');

      // Use cursor for pagination
      if (pageIndex > 0 && _pageHistory[pageIndex] != null) {
        query = query.startAfterDocument(_pageHistory[pageIndex]!);
      }

      final snapshot = await query.limit(_pageSize).get();
      final docs = snapshot.docs;

      if (mounted) {
        setState(() {
          _drivers = docs
              .map((d) => Driver.fromMap(d.data() as Map<String, dynamic>))
              .toList();
          _isFetching = false;
          _currentPage = pageIndex;
          _lastDocument = docs.isNotEmpty ? docs.last : null;

          // Update page history for next page's "startAfter"
          if (_pageHistory.length <= pageIndex + 1) {
            _pageHistory.add(_lastDocument);
          } else {
            _pageHistory[pageIndex + 1] = _lastDocument;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching market page: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }

  void _nextPage() {
    if (_drivers.length == _pageSize) {
      _fetchPage(_currentPage + 1);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _fetchPage(_currentPage - 1);
    }
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
      body: Column(
        children: [
          Expanded(
            child: _isFetching
                ? _buildSkeletonTable()
                : _drivers.isEmpty
                ? const Center(
                    child: Text("No drivers currently listed on the market."),
                  )
                : _buildDriverTable(_drivers),
          ),
          if (!_isFetching &&
              (_currentPage > 0 || _drivers.length == _pageSize))
            _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildDriverTable(List<Driver> drivers) {
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
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        return _buildRow(drivers[index]);
      },
      highlightIndices: const [],
    );
  }

  Widget _buildRow(Driver driver) {
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
        CurrencyFormatter.format(driver.marketValue),
        style: const TextStyle(fontSize: 13, color: Colors.white70),
      ),
      Text(
        CurrencyFormatter.format(driver.currentHighestBid),
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
                foregroundColor: Colors.white,
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

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0 ? _prevPage : null,
            icon: const Icon(Icons.chevron_left),
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Text(
            "Page ${_currentPage + 1}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _drivers.length == _pageSize ? _nextPage : null,
            icon: const Icon(Icons.chevron_right),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonTable() {
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
      itemCount: 8,
      itemBuilder: (context, index) {
        return Row(
          children: [
            const Expanded(flex: 4, child: OnyxSkeleton(height: 20)),
            const SizedBox(width: 12),
            const Expanded(flex: 1, child: OnyxSkeleton(height: 20)),
            const SizedBox(width: 12),
            const Expanded(flex: 3, child: OnyxSkeleton(height: 20)),
            const SizedBox(width: 12),
            const Expanded(flex: 2, child: OnyxSkeleton(height: 20)),
            const SizedBox(width: 12),
            const Expanded(flex: 2, child: OnyxSkeleton(height: 20)),
            const SizedBox(width: 12),
            const Expanded(flex: 2, child: OnyxSkeleton(height: 20)),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: OnyxSkeleton(height: 32, borderRadius: 100, width: 60),
            ),
          ],
        );
      },
    );
  }

  void _handleCancelTransfer(Driver driver) async {
    try {
      await TransferMarketService().cancelTransfer(widget.teamId, driver.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transfer cancelled successfully.")),
        );
        _fetchPage(_currentPage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _handleCancelBid(Driver driver) async {
    if (_cancellingBidDriverIds.contains(driver.id)) return;

    setState(() => _cancellingBidDriverIds.add(driver.id));
    try {
      await TransferMarketService().cancelBid(widget.teamId, driver.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Bid cancelled successfully. Funds were not returned.",
            ),
          ),
        );
        _fetchPage(_currentPage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _cancellingBidDriverIds.remove(driver.id));
      }
    }
  }

  void _showDriverDetail(Driver driver) {
    final screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SizedBox(
          width: math.min(screenWidth * 0.85, 1200),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('drivers')
                .doc(driver.id)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData ||
                  snapshot.data == null ||
                  snapshot.data!.data() == null) {
                return TransferMarketDriverCard(
                  driver: driver,
                  currentTeamId: widget.teamId,
                  isCancellingBid: _cancellingBidDriverIds.contains(driver.id),
                  onClose: () => Navigator.pop(ctx),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final updatedDriver = Driver.fromMap(data);

              return TransferMarketDriverCard(
                driver: updatedDriver,
                currentTeamId: widget.teamId,
                onBid: () => _showBidModal(updatedDriver),
                onCancelTransfer: () => _handleCancelTransfer(updatedDriver),
                onCancelBid: () => _handleCancelBid(updatedDriver),
                isCancellingBid: _cancellingBidDriverIds.contains(
                  updatedDriver.id,
                ),
                onClose: () => Navigator.pop(ctx),
              );
            },
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
                    "Current Highest Bid: ${CurrencyFormatter.format(driver.currentHighestBid)}",
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
                        CurrencyFormatter.format(bidAmount),
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
                _BidButton(
                  teamId: widget.teamId,
                  driver: driver,
                  bidAmount: bidAmount,
                  onSuccess: () => Navigator.pop(ctx),
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

class _BidButton extends StatefulWidget {
  final String teamId;
  final Driver driver;
  final int bidAmount;
  final VoidCallback onSuccess;

  const _BidButton({
    required this.teamId,
    required this.driver,
    required this.bidAmount,
    required this.onSuccess,
  });

  @override
  State<_BidButton> createState() => _BidButtonState();
}

class _BidButtonState extends State<_BidButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _isLoading
          ? null
          : () async {
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _isLoading = true);
              try {
                await TransferMarketService().placeBid(
                  widget.teamId,
                  widget.driver.id,
                  widget.bidAmount,
                );
                if (mounted) {
                  widget.onSuccess();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Bid placed successfully."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoading = false);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text("Submit Bid"),
    );
  }
}
