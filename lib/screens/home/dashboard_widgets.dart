import 'dart:async';
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
        borderRadius: BorderRadius.circular(8),
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
        : Theme.of(context).colorScheme.secondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(8),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source.toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
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
              color: Theme.of(context).textTheme.bodyLarge?.color,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        height: 180,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(
            colors: [Color(0xFF15151E), Color(0xFF292A33)],
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
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white70),
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.route, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  "4.309 km | 71 Laps",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Live countdown widget with seconds ticking down in real-time.
class RaceStatusHero extends StatefulWidget {
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
  State<RaceStatusHero> createState() => _RaceStatusHeroState();
}

class _RaceStatusHeroState extends State<RaceStatusHero> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final now = TimeService().nowBogota;
    setState(() {
      _timeLeft = widget.targetDate.difference(now);
      if (_timeLeft.isNegative) _timeLeft = Duration.zero;
    });
  }

  @override
  void didUpdateWidget(covariant RaceStatusHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetDate != widget.targetDate) {
      _updateTimeLeft();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    String statusText = "PADDOCK OPEN";
    Color statusColor = const Color(0xFF00C853);
    String buttonLabel = "ENTER PADDOCK";
    IconData buttonIcon = Icons.speed;

    switch (widget.currentStatus) {
      case RaceWeekStatus.practice:
        statusText = "PADDOCK OPEN";
        statusColor = const Color(0xFF00C853);
        buttonLabel = "ENTER PADDOCK";
        buttonIcon = Icons.speed;
        break;
      case RaceWeekStatus.qualifying:
        statusText = "QUALIFYING";
        statusColor = const Color(0xFFFFB800);
        buttonLabel = "VIEW QUALIFYING";
        buttonIcon = Icons.list_alt;
        break;
      case RaceWeekStatus.raceStrategy:
        statusText = "RACE STRATEGY";
        statusColor = const Color(0xFFFF6D00);
        buttonLabel = "SET RACE STRATEGY";
        buttonIcon = Icons.tune;
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
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardTheme.color!,
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
                    widget.countryCode,
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
            widget.circuitName.toUpperCase(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).textTheme.headlineMedium?.color,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          // Live countdown with individual digit boxes
          Row(
            children: [
              _buildTimeBlock(context, days.toString().padLeft(2, '0'), "DAYS"),
              _buildTimeSeparator(context),
              _buildTimeBlock(context, hours.toString().padLeft(2, '0'), "HRS"),
              _buildTimeSeparator(context),
              _buildTimeBlock(
                context,
                minutes.toString().padLeft(2, '0'),
                "MIN",
              ),
              _buildTimeSeparator(context),
              _buildTimeBlock(
                context,
                seconds.toString().padLeft(2, '0'),
                "SEC",
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onActionPressed,
              icon: Icon(buttonIcon, color: Colors.black),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: statusColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlock(BuildContext context, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      child: Text(
        ":",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
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
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PRE-RACE CHECKLIST",
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildItem(
            context,
            "Practice Program",
            "$completedLaps/$totalLaps LAPS",
            completedLaps >= totalLaps,
          ),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            height: 24,
          ),
          _buildItem(
            context,
            "Qualifying Setup",
            setupSubmitted ? "READY" : "PENDING",
            setupSubmitted,
          ),
          Divider(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            height: 24,
          ),
          _buildItem(
            context,
            "Race Strategy",
            strategySubmitted ? "READY" : "PENDING",
            strategySubmitted,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String label,
    String status,
    bool isComplete,
  ) {
    final color = isComplete
        ? const Color(0xFF00C853)
        : const Color(0xFFFFAB00);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
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

class CircuitInfoCard extends StatelessWidget {
  final String circuitName;
  final int totalLaps;
  final String weatherPractice;
  final String weatherQualifying;
  final String weatherRace;

  final Map<String, String> characteristics;

  const CircuitInfoCard({
    super.key,
    required this.circuitName,
    required this.totalLaps,
    required this.weatherPractice,
    required this.weatherQualifying,
    required this.weatherRace,
    this.characteristics = const {},
  });

  IconData _getWeatherIcon(String status) {
    status = status.toLowerCase();
    if (status.contains('rain')) return Icons.umbrella;
    if (status.contains('cloud')) return Icons.cloud;
    if (status.contains('storm')) return Icons.thunderstorm;
    return Icons.wb_sunny;
  }

  Color _getWeatherColor(String status) {
    status = status.toLowerCase();
    if (status.contains('rain')) return Colors.blue;
    if (status.contains('cloud')) return Colors.blueGrey;
    if (status.contains('storm')) return Colors.deepPurple;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                "CIRCUIT INFO",
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            circuitName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.loop, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    "$totalLaps LAPS",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildCompactWeatherDay("P", weatherPractice),
                  const SizedBox(width: 12),
                  _buildCompactWeatherDay("Q", weatherQualifying),
                  const SizedBox(width: 12),
                  _buildCompactWeatherDay("R", weatherRace),
                ],
              ),
            ],
          ),
          if (characteristics.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              "CIRCUIT INTEL",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: characteristics.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${e.key}: ",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactWeatherDay(String label, String weather) {
    final color = _getWeatherColor(weather);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Icon(_getWeatherIcon(weather), color: color, size: 16),
      ],
    );
  }
}
