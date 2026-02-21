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
                Stack(
                  alignment: Alignment.center,
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
                  ],
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
                const SizedBox(height: 12),
                // Footer row with "Read full article" explicitly as a button-like text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black87),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        "READ FULL ARTICLE",
                        style: GoogleFonts.oswald(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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

  TextSpan _buildRichMessage(BuildContext context, TextStyle baseStyle) {
    if (notification.payload == null) {
      return TextSpan(text: notification.message, style: baseStyle);
    }

    final p = notification.payload!;
    final loc = AppLocalizations.of(context);

    if (notification.message == "pressNewsManagerJoin") {
      // Create a map of values to bold
      final Map<String, String> values = {
        '#MGR#': '${p['managerName'] ?? ''} ${p['managerSurname'] ?? ''}',
        '#TEAM#': p['teamName'] ?? '',
        '#LEAGUE#': p['leagueName'] ?? '',
        '#ROLE#': p['roleManager'] ?? '',
        '#D1#': p['mainDriver'] ?? '',
        '#D2#': p['secondaryDriver'] ?? '',
      };

      // Get the translated string with placeholders
      String template = loc.pressNewsManagerJoin(
        '#MGR#',
        '', // We combined name and surname in #MGR#
        '#TEAM#',
        '#LEAGUE#',
        '#ROLE#',
        '#D1#',
        '#D2#',
      );

      // Clean up adjacent placeholders if name/surname results in extra space
      template = template.replaceAll('#MGR# ', '#MGR#');

      List<InlineSpan> spans = [];
      int lastIndex = 0;

      // Simple parser to find placeholders and apply bold
      final regex = RegExp(r'#MGR#|#TEAM#|#LEAGUE#|#ROLE#|#D1#|#D2#');
      final matches = regex.allMatches(template);

      for (final match in matches) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(text: template.substring(lastIndex, match.start)));
        }
        final key = match.group(0)!;
        spans.add(
          TextSpan(
            text: values[key],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
        lastIndex = match.end;
      }

      if (lastIndex < template.length) {
        spans.add(TextSpan(text: template.substring(lastIndex)));
      }

      return TextSpan(children: spans, style: baseStyle);
    }

    return TextSpan(text: notification.message, style: baseStyle);
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
                    margin: const EdgeInsets.only(bottom: 20),
                    width: double.infinity,
                    height: 220, // Taller image
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87, width: 2),
                      image: const DecorationImage(
                        image: AssetImage('news/newManager.png'),
                        fit: BoxFit.contain, // Show full image without cropping
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  child: Text.rich(
                    _buildRichMessage(
                      context,
                      GoogleFonts.ptSerif(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.6,
                      ),
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
