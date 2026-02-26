import 'package:flutter/material.dart';

class DriverStars extends StatelessWidget {
  final int currentStars;
  final int maxStars;
  final double size;

  const DriverStars({
    super.key,
    required this.currentStars,
    required this.maxStars,
    this.size = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < currentStars) {
          return Icon(Icons.star_rounded, color: Colors.blueAccent, size: size);
        } else if (index < maxStars) {
          return Icon(
            Icons.star_rounded,
            color: Colors.amber.withValues(alpha: 0.5),
            size: size,
          );
        } else {
          return Icon(
            Icons.star_outline_rounded,
            color: Colors.white.withValues(alpha: 0.2),
            size: size,
          );
        }
      }),
    );
  }
}
