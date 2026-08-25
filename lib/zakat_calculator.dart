enum WornGoldMethod {
  excess, // Applies to Selangor, Wilayah Persekutuan, Johor, etc.
  full,   // Applies to Pulau Pinang, Perak, Perlis, Pahang, etc.
}

class ZakatCalculator {
  ZakatCalculator._();

  static const double rate = 0.025;
  static const double storedGoldThresholdGrams = 85;
  static const double wornGoldThresholdGrams = 800;

  static double income({
    required double monthlySalary,
    required double otherAnnualIncome,
    required double caruman, // Restored from 'alreadyPaid'
    required double nisab,
  }) {
    final annualIncome = monthlySalary * 12 + otherAnnualIncome;
    if (annualIncome < nisab) return 0;
    
    // Restored your original Caruman logic
    final totalZakatOwed = annualIncome * rate;
    final carumanAdjustment = caruman * rate;
    
    return (totalZakatOwed - carumanAdjustment).clamp(0, double.infinity);
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

  static double goldItem({
    required double weightGrams,
    required double pricePerGram,
    required bool isWorn,
    double? wornUrufGrams,
    WornGoldMethod wornMethod = WornGoldMethod.excess, // Defaults to Selangor logic
  }) {
    if (isWorn) {
      final uruf = wornUrufGrams ?? wornGoldThresholdGrams;
      
      // State Toggle Logic applied here
      if (wornMethod == WornGoldMethod.excess) {
        final excess = weightGrams - uruf;
        return excess <= 0 ? 0 : excess * pricePerGram * rate;
      } else {
        return weightGrams >= uruf ? weightGrams * pricePerGram * rate : 0;
      }
    }
    
    return weightGrams >= storedGoldThresholdGrams
        ? weightGrams * pricePerGram * rate
        : 0;
  }
}