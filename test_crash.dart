import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

void main() {
  try {
    double liveDurationSeconds = 0;
    int elapsed = 0;
    final fraction = (elapsed / liveDurationSeconds).clamp(0.0, 1.0);
    debugPrint("Fraction: $fraction");
  } catch (e) {
    debugPrint("Caught expected error (NaN): $e");
  }

  try {
    double liveDurationSeconds = 0;
    int elapsed = 10;
    final fraction = (elapsed / liveDurationSeconds).clamp(0.0, 1.0);
    debugPrint("Fraction with Infinity: $fraction");
  } catch (e) {
    debugPrint("Caught error with Infinity: $e");
  }
}
