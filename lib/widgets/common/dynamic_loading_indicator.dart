import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';

class DynamicLoadingIndicator extends StatefulWidget {
  final List<String>? customPhrases;
  final Duration switchDuration;

  const DynamicLoadingIndicator({
    super.key,
    this.customPhrases,
    this.switchDuration = const Duration(seconds: 3),
  });

  @override
  State<DynamicLoadingIndicator> createState() =>
      _DynamicLoadingIndicatorState();
}

class _DynamicLoadingIndicatorState extends State<DynamicLoadingIndicator> {
  int _currentPhraseIndex = 0;
  Timer? _loadingTimer;

  @override
  void initState() {
    super.initState();
    _startLoadingTimer();
  }

  void _startLoadingTimer() {
    _loadingTimer = Timer.periodic(widget.switchDuration, (timer) {
      if (mounted) {
        setState(() {
          int count = widget.customPhrases?.length ?? 8;
          _currentPhraseIndex = (_currentPhraseIndex + 1) % count;
        });
      }
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  String _getPhrase(BuildContext context, int index) {
    if (widget.customPhrases != null) {
      if (index >= 0 && index < widget.customPhrases!.length) {
        return widget.customPhrases![index];
      }
      return "";
    }

    final loc = AppLocalizations.of(context);

    switch (index) {
      case 0:
        return loc.loadingPhrase1;
      case 1:
        return loc.loadingPhrase2;
      case 2:
        return loc.loadingPhrase3;
      case 3:
        return loc.loadingPhrase4;
      case 4:
        return loc.loadingPhrase5;
      case 5:
        return loc.loadingPhrase6;
      case 6:
        return loc.loadingPhrase7;
      case 7:
        return loc.loadingPhrase8;
      default:
        return loc.loadingPhrase1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF00C853)),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              _getPhrase(context, _currentPhraseIndex),
              key: ValueKey<int>(_currentPhraseIndex),
              style: GoogleFonts.raleway(
                fontSize: 14,
                color: Colors.white70,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
