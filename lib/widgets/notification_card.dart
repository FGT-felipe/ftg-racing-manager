import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/core_models.dart';
import '../l10n/app_localizations.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'ALERT':
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.orangeAccent;
        break;
      case 'SUCCESS':
        icon = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF00C853);
        break;
      case 'TEAM':
        icon = Icons.group_outlined;
        iconColor = theme.colorScheme.secondary;
        break;
      case 'OFFICE':
        if (notification.eventType == 'RACE_RESULT') {
          icon = Icons.emoji_events_outlined;
          iconColor = const Color(0xFFFFD700); // Gold
        } else if (notification.eventType == 'QUALY_RESULT') {
          icon = Icons.timer_outlined;
          iconColor = Colors.tealAccent;
        } else {
          icon = Icons.business_center_outlined;
          iconColor = Colors.blueGrey;
        }
        break;
      case 'NEWS':
      default:
        icon = Icons.newspaper_outlined;
        iconColor = Colors.blueAccent;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? Colors.transparent
              : iconColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              notification.type.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              _formatTimestamp(context, notification.timestamp),
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.title,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      onPressed: onDismiss,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return AppLocalizations.of(context).minsAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return AppLocalizations.of(context).hoursAgo(diff.inHours);
    }
    return "${dt.day}/${dt.month}";
  }
}
