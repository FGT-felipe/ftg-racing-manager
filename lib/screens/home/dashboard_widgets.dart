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
        borderRadius: BorderRadius.circular(12),
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
        ? const Color(0xFFEF5350) // Red Error
        : const Color(0xFF00C853); // Green Success

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
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
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.account_balance_wallet, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TEAM BUDGET",
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "\$$budgetMillions M",
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD700), // Gold
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
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "EST. +\$1.2M",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
          borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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
  final String flagEmoji;
  final DateTime targetDate;
  final VoidCallback? onActionPressed;

  final int totalLaps;
  final String weatherPractice;
  final String weatherQualifying;
  final String weatherRace;
  final Map<String, String> characteristics;
  final double aeroWeight;
  final double chassisWeight;
  final double powertrainWeight;

  const RaceStatusHero({
    super.key,
    required this.currentStatus,
    required this.circuitName,
    required this.countryCode,
    required this.flagEmoji,
    required this.targetDate,
    this.onActionPressed,
    this.totalLaps = 50,
    this.weatherPractice = 'Sunny',
    this.weatherQualifying = 'Cloudy',
    this.weatherRace = 'Sunny',
    this.characteristics = const {},
    this.aeroWeight = 0.33,
    this.chassisWeight = 0.33,
    this.powertrainWeight = 0.34,
  });

  @override
  State<RaceStatusHero> createState() => _RaceStatusHeroState();
}

class _RaceStatusHeroState extends State<RaceStatusHero>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;
  late AnimationController _blinkingController;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeLeft();
    });

    _blinkingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
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
    _blinkingController.dispose();
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
        buttonLabel = "WEEKEND SETUP";
        buttonIcon = Icons.settings;
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
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background Climate Icon
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  _getWeatherIcon(widget.weatherRace),
                  size: 200,
                  color: _getWeatherColor(widget.weatherRace),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
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
                          borderRadius: BorderRadius.circular(12),
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
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${widget.flagEmoji} ${widget.countryCode}",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 500;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Section: Circuit & Countdown
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.circuitName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    _buildTimeBlock(
                                      context,
                                      days.toString().padLeft(2, '0'),
                                      "DAYS",
                                    ),
                                    _buildTimeSeparator(context),
                                    _buildTimeBlock(
                                      context,
                                      hours.toString().padLeft(2, '0'),
                                      "HRS",
                                    ),
                                    _buildTimeSeparator(context),
                                    _buildTimeBlock(
                                      context,
                                      minutes.toString().padLeft(2, '0'),
                                      "MIN",
                                    ),
                                    if (isWide) ...[
                                      _buildTimeSeparator(context),
                                      _buildTimeBlock(
                                        context,
                                        seconds.toString().padLeft(2, '0'),
                                        "SEC",
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 24),

                          // Right Section: Circuit Intel
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildIntelHeader("CIRCUIT INTEL"),
                                const SizedBox(height: 8),
                                _buildIntelRow(
                                  "LAPS",
                                  "${widget.totalLaps}",
                                  Colors.white,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildCompactWeatherDay(
                                      "P",
                                      widget.weatherPractice,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildCompactWeatherDay(
                                      "Q",
                                      widget.weatherQualifying,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildCompactWeatherDay(
                                      "R",
                                      widget.weatherRace,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  alignment: WrapAlignment.end,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    if (widget.aeroWeight >= 0.4)
                                      _buildCompactChip("AERO", "HIGH"),
                                    if (widget.powertrainWeight >= 0.4)
                                      _buildCompactChip("POWER", "HIGH"),
                                    if (widget.characteristics.containsKey(
                                      'Top Speed',
                                    ))
                                      _buildCompactChip(
                                        "SPEED",
                                        widget.characteristics['Top Speed']!,
                                      ),
                                    if (widget.characteristics.containsKey(
                                      'Tyre Wear',
                                    ))
                                      _buildCompactChip(
                                        "TYRE",
                                        widget.characteristics['Tyre Wear']!,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLiveIndicator(),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2A2A2A), Color(0xFF000000)],
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFF00C853,
                            ).withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: widget.onActionPressed,
                          icon: Icon(
                            buttonIcon,
                            color: const Color(0xFF00C853),
                            size: 18,
                          ),
                          label: Text(buttonLabel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF00C853),
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntelHeader(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildIntelRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "$label: ",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        Text(
          value.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFFD700), // Gold
          ),
        ),
      ],
    );
  }

  Widget _buildCompactChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        "$label: ${value.toUpperCase()}",
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
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
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 2),
        Icon(_getWeatherIcon(weather), color: color, size: 14),
      ],
    );
  }

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

  Widget _buildLiveIndicator() {
    final bool isLive = widget.currentStatus == RaceWeekStatus.race;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive
              ? const Color(0xFFFF5252).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive)
            FadeTransition(
              opacity: _blinkingController,
              child: const Icon(
                Icons.fiber_manual_record,
                color: Color(0xFFFF5252),
                size: 12,
              ),
            )
          else
            Icon(
              Icons.do_not_disturb_on_total_silence,
              color: Colors.white.withValues(alpha: 0.2),
              size: 12,
            ),
          const SizedBox(width: 8),
          Text(
            isLive ? "ON LIVE" : "OFF LIVE",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: isLive
                  ? const Color(0xFFFF5252)
                  : Colors.white.withValues(alpha: 0.3),
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
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PRE-RACE CHECKLIST",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 9,
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
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 20),
          _buildItem(
            context,
            "Qualifying Setup",
            setupSubmitted ? "READY" : "PENDING",
            setupSubmitted,
          ),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 20),
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
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(
                isComplete ? Icons.check : Icons.priority_high,
                size: 10,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
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
