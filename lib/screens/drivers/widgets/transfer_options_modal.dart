import 'package:flutter/material.dart';
import '../../../models/core_models.dart';
import '../../../services/transfer_market_service.dart';
import '../../../utils/currency_formatter.dart';

class TransferOptionsModal extends StatelessWidget {
  final String teamId;
  final Driver driver;

  const TransferOptionsModal({
    super.key,
    required this.teamId,
    required this.driver,
  });

  static void show(BuildContext context, String teamId, Driver driver) {
    showDialog(
      context: context,
      builder: (ctx) => TransferOptionsModal(teamId: teamId, driver: driver),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fee = (driver.marketValue * 0.10).round();

    return AlertDialog(
      title: const Text("Transfer Market Options"),
      content: Text(
        "What would you like to do with ${driver.name}?\n\n"
        "• List on Transfer Market (Fee: ${CurrencyFormatter.format(fee)})\n"
        "• Release Driver immediately (Fee: ${CurrencyFormatter.format(fee)})\n\n"
        "Listing a driver puts them on the market for 24 hours. Releasing removes them permanently.",
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonal(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await TransferMarketService().listDriverOnMarket(
                    teamId,
                    driver.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Driver listed on transfer market!"),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                }
              },
              child: const Text("List on Market"),
            ),
            const SizedBox(width: 8),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await TransferMarketService().releaseDriver(
                    teamId,
                    driver.id,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Driver released from the team."),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                }
              },
              child: const Text("Release"),
            ),
          ],
        ),
      ],
    );
  }
}
