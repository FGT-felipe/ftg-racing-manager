import 'package:flutter/material.dart';
import '../../../models/core_models.dart';
import '../../../services/driver_portrait_service.dart';

class DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback? onRenew;
  final VoidCallback? onFire;

  const DriverCard({
    super.key,
    required this.driver,
    this.onRenew,
    this.onFire,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weeklyGrowth = driver.weeklyGrowth;
    final portraitUrl =
        driver.portraitUrl ??
        DriverPortraitService().getEffectivePortraitUrl(
          driverId: driver.id,
          countryCode: driver.countryCode,
          gender: driver.gender,
          age: driver.age,
        );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: DecorationImage(
                          image: portraitUrl.startsWith('http')
                              ? NetworkImage(portraitUrl) as ImageProvider
                              : AssetImage(portraitUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _getFlagEmoji(driver.countryCode),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _getFlagEmoji(driver.countryCode),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${driver.age} years old',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              driver.role,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Potential', style: theme.textTheme.labelSmall),
                    Text(
                      '${driver.potential}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            // Stats Grid
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: driver.stats.entries.map((entry) {
                final skillName = _formatSkillName(entry.key);
                final value = entry.value;
                final growth = weeklyGrowth[entry.key] ?? 0.0;

                return SizedBox(
                  width:
                      (MediaQuery.of(context).size.width - 64) /
                      2, // 2 columns approx
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(skillName, style: theme.textTheme.bodyMedium),
                      Row(
                        children: [
                          Text(
                            '$value',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          if (growth != 0)
                            Text(
                              '${growth > 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: growth > 0 ? Colors.green : Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const Divider(height: 24),
            // Footer: Contract Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contract: \$${(driver.salary / 1000).toStringAsFixed(0)}k / year',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Expires in: ${driver.contractYearsRemaining} season(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: onFire,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                      child: const Text('Fire'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onRenew,
                      child: const Text('Renew'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSkillName(String key) {
    return key[0].toUpperCase() + key.substring(1);
  }

  String _getFlagEmoji(String countryCode) {
    const flags = {
      'BR': '🇧🇷',
      'AR': '🇦🇷',
      'CO': '🇨🇴',
      'MX': '🇲🇽',
      'UY': '🇺🇾',
      'CL': '🇨🇱',
    };
    return flags[countryCode.toUpperCase()] ?? '🏳️';
  }
}
