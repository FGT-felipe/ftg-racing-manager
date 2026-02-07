import 'package:flutter/material.dart';
import '../../services/time_service.dart';

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
            isRaceWeekend ? "SESSION IN PROGRESS" : "TIME UNTIL NEXT SESSION",
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

class UpcomingCircuitCard extends StatelessWidget {
  final String circuitName;
  final String countryCode;
  final String date;

  const UpcomingCircuitCard({
    super.key,
    required this.circuitName,
    required this.countryCode,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 180,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.black54],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "NEXT GRAND PRIX",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.orangeAccent,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    countryCode.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              circuitName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  Icons.route,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "4.309 km | 71 Laps",
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ), // Mock details
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RaceStatusHero extends StatelessWidget {
  final RaceWeekStatus currentStatus;
  final String circuitName;
  final String countryCode;
  final DateTime targetDate;
  final VoidCallback? onActionPressed;

  const RaceStatusHero({
    super.key,
    required this.currentStatus,
    required this.circuitName,
    required this.countryCode,
    required this.targetDate,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Current Time (Mocked from TimeService usually, but we can use DateTime.now() if checking difference)
    // Actually, to be consistent visually with the countdown, we should use TimeService().nowBogota if available,
    // but visual countdown usually uses real time relative to target.
    // However, since targetDate is likely mocked, we should use TimeService().nowBogota for diff.

    final now = TimeService().nowBogota;
    final timeLeft = targetDate.difference(now);
    final days = timeLeft.inDays;
    final hours = timeLeft.inHours % 24;
    final minutes = timeLeft.inMinutes % 60;

    String statusText = "PADDOCK OPEN";
    Color statusColor = const Color(0xFF00FF88);
    String buttonLabel = "ENTER PRACTICE SESSION";
    IconData buttonIcon = Icons.speed;

    switch (currentStatus) {
      case RaceWeekStatus.practice:
        statusText = "PADDOCK OPEN";
        statusColor = const Color(0xFF00FF88);
        buttonLabel = "ENTER PRACTICE SESSION";
        buttonIcon = Icons.speed;
        break;
      case RaceWeekStatus.qualifying:
      case RaceWeekStatus.raceStrategy:
        statusText = "QUALIFYING / STRATEGY";
        statusColor = const Color(0xFFFFB800);
        buttonLabel = "VIEW QUALIFYING RESULTS";
        buttonIcon = Icons.list_alt;
        break;
      case RaceWeekStatus.race:
        statusText = "RACE WEEKEND";
        statusColor = const Color(0xFFFF5252);
        buttonLabel = "GO TO RACE";
        buttonIcon = Icons.flag;
        break;
      case RaceWeekStatus.postRace:
        statusText = "RACE FINISHED";
        statusColor = const Color(0xFF9E9E9E);
        buttonLabel = "VIEW RESULTS";
        buttonIcon = Icons.emoji_events;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    countryCode,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            circuitName.toUpperCase(),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).textTheme.headlineMedium?.color,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "EVENT STARTS IN: ${days}D ${hours}H ${minutes}M",
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onActionPressed,
              icon: Icon(buttonIcon, color: Colors.black),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PreparationChecklist extends StatelessWidget {
  final bool setupSubmitted;
  final bool strategySubmitted;
  final int completedLaps;
  final int totalLaps;

  const PreparationChecklist({
    super.key,
    required this.setupSubmitted,
    required this.strategySubmitted,
    required this.completedLaps,
    required this.totalLaps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PRE-RACE CHECKLIST",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildItem(
            "Qualifying Setup",
            setupSubmitted ? "READY" : "PENDING",
            setupSubmitted,
          ),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            height: 24,
          ),
          _buildItem(
            "Race Strategy",
            strategySubmitted ? "READY" : "PENDING",
            strategySubmitted,
          ),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            height: 24,
          ),
          _buildItem(
            "Practice Program",
            "$completedLaps/$totalLaps LAPS",
            completedLaps >= totalLaps,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String status, bool isComplete) {
    final color = isComplete
        ? const Color(0xFF00E676)
        : const Color(0xFFFFEA00);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(
                isComplete ? Icons.check : Icons.priority_high,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
