void main() {
  double d1 = 0.0;
  double d2 = 0.0;
  double res = d1 / d2;
  print("0.0 / 0.0 = $res (isNaN: ${res.isNaN})");

  try {
    double clamped = res.clamp(0.0, 1.0);
    print("Clamped: $clamped");
  } catch (e) {
    print("Error clamping NaN: $e");
  }

  double inf = 1.0 / 0.0;
  print("1.0 / 0.0 = $inf (isInfinite: ${inf.isInfinite})");
  try {
    double clamped = inf.clamp(0.0, 1.0);
    print("Clamped infinity: $clamped");
  } catch (e) {
    print("Error clamping Infinity: $e");
  }
}
