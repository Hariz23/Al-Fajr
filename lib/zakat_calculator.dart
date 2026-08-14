class ZakatCalculator {
  ZakatCalculator._();

  static const double rate = 0.025;
  static const double storedGoldThresholdGrams = 85;
  static const double wornGoldThresholdGrams = 800;

  static double income({
    required double monthlySalary,
    required double otherAnnualIncome,
    required double alreadyPaid,
    required double nisab,
  }) {
    final annualIncome = monthlySalary * 12 + otherAnnualIncome;
    if (annualIncome < nisab) return 0;
    return (annualIncome * rate - alreadyPaid).clamp(0, double.infinity);
  }

  static double savings({
    required Iterable<double> lowestAnnualBalances,
    required double nisab,
  }) {
    final total = lowestAnnualBalances.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    return total >= nisab ? total * rate : 0;
  }

  /// Zakat on a single gold item.
  ///
  /// The two cases use different rules, not just different thresholds:
  ///
  /// * Stored gold (`isWorn: false`) is zakatable in full once it reaches the
  ///   85 g nisab.
  /// * Worn gold (`isWorn: true`) is zakatable only on the weight *exceeding*
  ///   the uruf, which is why 900 g against an 800 g uruf is charged on 100 g.
  ///
  /// [wornUrufGrams] defaults to the Wilayah Persekutuan figure. It is a
  /// parameter because the uruf varies widely by state — 800 g in WP, 250 g in
  /// Pulau Pinang. Melaka and Perlis charge the whole amount rather than the
  /// excess, so they are not covered by this function.
  static double goldItem({
    required double weightGrams,
    required double pricePerGram,
    required bool isWorn,
    double? wornUrufGrams,
  }) {
    if (isWorn) {
      final uruf = wornUrufGrams ?? wornGoldThresholdGrams;
      final excess = weightGrams - uruf;
      return excess <= 0 ? 0 : excess * pricePerGram * rate;
    }
    return weightGrams >= storedGoldThresholdGrams
        ? weightGrams * pricePerGram * rate
        : 0;
  }
}
