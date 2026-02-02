import 'package:flutter/material.dart';

class TeamHeader extends StatelessWidget {
  final String managerName;
  final String teamName;
  final Color teamColor;

  const TeamHeader({
    super.key,
    required this.managerName,
    required this.teamName,
    this.teamColor = Colors.tealAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: teamColor, width: 2),
            ),
            child: Icon(Icons.shield, color: teamColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back, $managerName",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  teamName.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final String status;
  final String timeUntilRace;
  final bool isRaceWeekend;

  const StatusCard({
    super.key,
    required this.status,
    required this.timeUntilRace,
    required this.isRaceWeekend,
  });

  @override
  Widget build(BuildContext context) {
    final mainColor = isRaceWeekend
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mainColor.withValues(alpha: 0.3), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mainColor.withValues(alpha: 0.1), Colors.transparent],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: mainColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontSize: 12,
                ),
              ),
              Icon(
                isRaceWeekend ? Icons.flag : Icons.factory,
                color: mainColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isRaceWeekend ? "RACE IN PROGRESS" : "TIME UNTIL NEXT RACE",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeUntilRace,
            style: TextStyle(
              color: mainColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class FinanceCard extends StatelessWidget {
  final int budget;
  final VoidCallback? onTap;

  const FinanceCard({super.key, required this.budget, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isNegative = budget < 0;
    final budgetMillions = (budget / 1000000).toStringAsFixed(1);
    final color = isNegative
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_wallet, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TEAM BUDGET",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  "\$$budgetMillions M",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isNegative ? "DEFICIT" : "SURPLUS",
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Estimated +\$1.2M",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NewsItemCard extends StatelessWidget {
  final String headline;
  final String source;

  const NewsItemCard({super.key, required this.headline, required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color, // Ensure readable
            ),
          ),
        ],
      ),
    );
  }
}
