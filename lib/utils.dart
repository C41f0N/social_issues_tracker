String formatCompact(num value) {
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';

  String _trim(double v) {
    if (v >= 100) return v.toInt().toString(); // 100+ -> no decimals
    if (v % 1 == 0) return v.toInt().toString(); // exact integer
    return v.toStringAsFixed(1); // otherwise one decimal
  }

  if (abs >= 1e9) return '$sign${_trim(abs / 1e9)}B';
  if (abs >= 1e6) return '$sign${_trim(abs / 1e6)}M';
  if (abs >= 1e3) return '$sign${_trim(abs / 1e3)}K';
  return '$value';
}
