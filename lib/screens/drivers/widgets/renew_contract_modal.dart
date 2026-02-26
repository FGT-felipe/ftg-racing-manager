import 'package:flutter/material.dart';
import '../../../models/core_models.dart';
import '../../../services/transfer_market_service.dart';

class RenewContractModal extends StatefulWidget {
  final String teamId;
  final Driver driver;

  const RenewContractModal({
    super.key,
    required this.teamId,
    required this.driver,
  });

  static void show(BuildContext context, String teamId, Driver driver) {
    showDialog(
      context: context,
      builder: (ctx) => RenewContractModal(teamId: teamId, driver: driver),
    );
  }

  @override
  State<RenewContractModal> createState() => _RenewContractModalState();
}

class _RenewContractModalState extends State<RenewContractModal> {
  int _duration = 1;
  int _salary = 500000;
  String _role = 'Equal Status';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _salary = widget.driver.salary;
    _role = widget.driver.role;
  }

  Future<void> _submitOffer() async {
    setState(() => _isProcessing = true);
    try {
      final accepted = await TransferMarketService().renewContract(
        teamId: widget.teamId,
        driverId: widget.driver.id,
        durationYears: _duration,
        salary: _salary,
        role: _role,
      );

      if (mounted) {
        Navigator.pop(context);
        if (accepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Contract offer ACCEPTED! Morale increased."),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Contract offer REJECTED. Morale decreased."),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Contract Negotiation"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Negotiating with ${widget.driver.name}"),
            const SizedBox(height: 16),

            // Duration
            const Text("Duration (Years)"),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text("1 Yr")),
                ButtonSegment(value: 3, label: Text("3 Yrs")),
                ButtonSegment(value: 5, label: Text("5 Yrs")),
              ],
              selected: {_duration},
              onSelectionChanged: (set) {
                setState(() => _duration = set.first);
              },
            ),
            const SizedBox(height: 16),

            // Role
            const Text("Driver Role"),
            DropdownButtonFormField<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: "Main", child: Text("Main Driver")),
                DropdownMenuItem(
                  value: "Equal Status",
                  child: Text("Equal Status"),
                ),
                DropdownMenuItem(
                  value: "Second",
                  child: Text("Secondary Driver"),
                ),
                DropdownMenuItem(value: "Reserve", child: Text("Reserve")),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _role = val);
              },
            ),
            const SizedBox(height: 16),

            // Salary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Salary per Race"),
                Text(
                  "\$${(_salary / 24000).toStringAsFixed(1)}k / race",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: _salary.toDouble(),
              min: 100000,
              max: 10000000,
              divisions: 99,
              onChanged: (val) => setState(() => _salary = val.toInt()),
            ),
            Text(
              "Total Salary: \$${(_salary / 1000).toStringAsFixed(0)}k",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _submitOffer,
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Offer Contract"),
        ),
      ],
    );
  }
}
