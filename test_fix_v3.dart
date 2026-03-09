String formatRaceTime(double totalSeconds) {
  if (totalSeconds.isNaN || totalSeconds.isInfinite) return "--:--:--";
  final hours = (totalSeconds / 3600).floor();
  final mins = ((totalSeconds % 3600) / 60).floor();
  final secs = (totalSeconds % 60).floor();
  return '${hours.toString().padLeft(2, '0')}H:${mins.toString().padLeft(2, '0')}M:${secs.toString().padLeft(2, '0')}S';
}

void main() {}
