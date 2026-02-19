import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/core_models.dart';
import 'package:intl/intl.dart';

class PressNewsCard extends StatelessWidget {
  final LeagueNotification notification;

  const PressNewsCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case 'CRASH':
        icon = Icons.warning_rounded;
        iconColor = Colors.redAccent;
        break;
      case 'WINNER':
        icon = Icons.emoji_events_rounded;
        iconColor = Colors.amber;
        break;
      case 'MANAGER_JOIN':
        icon = Icons.person_add_rounded;
        iconColor = theme.colorScheme.secondary;
        break;
      default:
        icon = Icons.newspaper_rounded;
        iconColor = Colors.blueAccent;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _showDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: iconColor, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          notification.type.replaceAll('_', ' ').toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Read more",
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return DateFormat('MMM dd, HH:mm').format(dt);
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          notification.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.eventType != null)
                _buildInfoRow("Session", notification.eventType!),
              if (notification.pilotName != null)
                _buildInfoRow("Driver", notification.pilotName!),
              if (notification.teamName != null)
                _buildInfoRow("Team", notification.teamName!),
              if (notification.managerName != null)
                _buildInfoRow("Manager", notification.managerName!),
              _buildInfoRow(
                "Date",
                DateFormat('yyyy-MM-dd HH:mm').format(notification.timestamp),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CLOSE",
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
