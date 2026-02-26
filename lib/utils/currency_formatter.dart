class CurrencyFormatter {
  /// Formats an amount with 'k' or 'M' suffix based on its value.
  /// If amount >= 1,000,000, it formats as $X.XXM.
  /// If amount < 1,000,000, it formats as $Xk.
  static String format(int amount) {
    if (amount >= 1000000) {
      double millions = amount / 1000000;
      return '\$${millions.toStringAsFixed(2)}M';
    } else {
      return '\$${(amount / 1000).toStringAsFixed(0)}k';
    }
  }
}
