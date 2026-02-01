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
              color: teamColor.withOpacity(0.2),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  teamName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            backgroundColor: Color(0xFF1E1E1E),
            child: Icon(Icons.notifications_outlined, color: Colors.white70),
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
    final mainColor = isRaceWeekend ? Colors.redAccent : Colors.tealAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mainColor.withOpacity(0.3), width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [mainColor.withOpacity(0.1), Colors.transparent],
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
    final color = isNegative ? Colors.redAccent : Colors.greenAccent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.account_balance_wallet, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TEAM BUDGET",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "\$$budgetMillions M",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
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
                const Text(
                  "Estimated +\$1.2M",
                  style: TextStyle(color: Colors.grey, fontSize: 10),
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
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            source.toUpperCase(),
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
