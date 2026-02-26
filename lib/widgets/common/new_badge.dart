import 'package:flutter/material.dart';

class NewBadgeWidget extends StatefulWidget {
  final DateTime createdAt;
  final Widget child;
  final Alignment badgeAlignment;
  final EdgeInsets padding;
  final bool forceShow; // Useful for preview/development

  const NewBadgeWidget({
    super.key,
    required this.createdAt,
    required this.child,
    this.badgeAlignment = Alignment.topRight,
    this.padding = EdgeInsets.zero,
    this.forceShow = false,
  });

  @override
  State<NewBadgeWidget> createState() => _NewBadgeWidgetState();
}

class _NewBadgeWidgetState extends State<NewBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true); // Pulsing effect

    _animation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(widget.createdAt).inDays;

    // Only show if it's less than 7 days old, or if forced to show
    if (difference >= 7 && !widget.forceShow) {
      return widget.child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned.fill(
          child: Align(
            alignment: widget.badgeAlignment,
            child: Padding(
              padding: widget.padding,
              child: Transform.translate(
                offset: const Offset(8, -8), // Push it slightly outside
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber, // Golden/Amber color
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: _animation,
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        "NEW",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
