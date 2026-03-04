import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewDotWidget extends StatefulWidget {
  final String featureId;
  final Widget child;
  final Alignment badgeAlignment;
  final Offset offset;
  final double size;

  const NewDotWidget({
    super.key,
    required this.featureId,
    required this.child,
    this.badgeAlignment = Alignment.topRight,
    this.offset = const Offset(4, -4),
    this.size = 10.0,
  });

  @override
  State<NewDotWidget> createState() => _NewDotWidgetState();
}

class _NewDotWidgetState extends State<NewDotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _hasSeenFeature = true; // Default to true while loading

  @override
  void initState() {
    super.initState();
    _checkFeatureStatus();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true); // Pulsing effect

    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  Future<void> _checkFeatureStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('feature_seen_${widget.featureId}') ?? false;
    if (mounted) {
      setState(() {
        _hasSeenFeature = seen;
      });
    }
  }

  Future<void> _markAsSeen() async {
    if (_hasSeenFeature) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feature_seen_${widget.featureId}', true);

    if (mounted) {
      setState(() {
        _hasSeenFeature = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenFeature) {
      return widget.child;
    }

    return MouseRegion(
      onEnter: (_) => _markAsSeen(),
      child: GestureDetector(
        onTap: _markAsSeen,
        behavior: HitTestBehavior.translucent, // Allow taps to pass through
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            Positioned.fill(
              child: UnconstrainedBox(
                alignment: widget.badgeAlignment,
                child: Transform.translate(
                  offset: widget.offset,
                  child: FadeTransition(
                    opacity: _animation,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withValues(alpha: 0.6),
                            blurRadius: widget.size / 2,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
