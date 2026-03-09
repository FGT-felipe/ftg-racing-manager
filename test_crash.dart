void main() {
  try {
    double liveDurationSeconds = 0;
    int elapsed = 0;
    final fraction = (elapsed / liveDurationSeconds).clamp(0.0, 1.0);
    print("Fraction: $fraction");
  } catch (e) {
    print("Caught expected error (NaN): $e");
  }

  try {
    double liveDurationSeconds = 0;
    int elapsed = 10;
    final fraction = (elapsed / liveDurationSeconds).clamp(0.0, 1.0);
    print("Fraction with Infinity: $fraction");
  } catch (e) {
    print("Caught error with Infinity: $e");
  }
}
