import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/core_models.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class PressNewsCard extends StatelessWidget {
  final LeagueNotification notification;

  const PressNewsCard({super.key, required this.notification});

  String _getTranslatedMessage(BuildContext context) {
    // If there is no payload, return the base message.
    if (notification.payload == null) {
      return notification.message;
    }

    final loc = AppLocalizations.of(context);

    // We expect the message field to contain the translation key, e.g. "pressNewsManagerJoin"
    if (notification.message == "pressNewsManagerJoin") {
      final p = notification.payload!;
      // Using a fallback if data is somehow missing from payload
      return loc.pressNewsManagerJoin(
        p['managerName'] ?? '',
        p['managerSurname'] ?? '',
        p['teamName'] ?? '',
        p['leagueName'] ?? '',
        p['roleManager'] ?? '',
        p['mainDriver'] ?? '',
        p['secondaryDriver'] ?? '',
      );
    }

    // Fallback if not matching expected key
    return notification.message;
  }

  @override
  Widget build(BuildContext context) {
    final isManagerJoin = notification.type == 'MANAGER_JOIN';
    final translatedMessage = _getTranslatedMessage(context);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EA), // Off-white newspaper color
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () => _showDialog(context, translatedMessage),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "MOTORSPORT DAILY",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Divider(
                  color: Colors.black.withValues(alpha: 0.3),
                  thickness: 1,
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notification.type.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.oswald(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.merriweather(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          translatedMessage,
                          maxLines: isManagerJoin ? 3 : 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.ptSerif(
                            fontSize: 11,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (isManagerJoin) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                            image: const DecorationImage(
                              image: AssetImage('news/newManager.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Read full article",
                    style: GoogleFonts.oswald(
                      color: Colors.black87,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
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
    return DateFormat('MMM dd, yyyy').format(dt);
  }

  void _showDialog(BuildContext context, String translatedMessage) {
    final isManagerJoin = notification.type == 'MANAGER_JOIN';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFFF4F1EA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      "MOTORSPORT DAILY",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(notification.timestamp).toUpperCase(),
                      style: GoogleFonts.oswald(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        color: Colors.black54,
                      ),
                    ),
                    Divider(
                      color: Colors.black.withValues(alpha: 0.8),
                      thickness: 2,
                      height: 24,
                    ),
                  ],
                ),
              ),
              Text(
                notification.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.merriweather(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              if (isManagerJoin)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87, width: 2),
                      image: const DecorationImage(
                        image: AssetImage('news/newManager.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    translatedMessage,
                    style: GoogleFonts.ptSerif(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: Colors.black.withValues(alpha: 0.3), thickness: 1),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "CLOSE",
                    style: GoogleFonts.oswald(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
