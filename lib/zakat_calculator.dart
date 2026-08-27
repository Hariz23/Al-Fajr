/// Zakat calculation engine.
///
/// Rates, reliefs (pelepasan) and nisab figures are set by each state's
/// Islamic religious council (LZS, PPZ-MAIWP, MAIJ, MAINPP, etc.) and are
/// gazetted/revised periodically — sometimes yearly, sometimes more often
/// for the gold-price-linked nisab. The defaults bundled here are
/// indicative starting points (collected from published state
/// calculators, e.g. MAIJ's income-zakat calculator at
/// https://www.maij.gov.my/cal/index.html) meant to pre-fill the form —
/// they are NOT authoritative. Always surface them as editable and
/// encourage the user to confirm current figures with their state's
/// zakat authority before relying on the result to actually pay zakat.

enum WornGoldMethod {
  /// Zakat only on the weight above the worn 'uruf' threshold.
  /// Used by e.g. Selangor, WP, Johor, Negeri Sembilan.
  excess,

  /// Zakat on the full weight once it reaches the 'uruf' threshold.
  /// Used by e.g. Pulau Pinang, Perak, Perlis, Pahang, Kedah.
  full,
}

/// How annual income zakat (zakat pendapatan) is assessed.
enum IncomeCalculationMethod {
  /// "Kaedah tanpa tolakan": gross annual income x 2.5%, minus only zakat
  /// already deducted at source (e.g. a monthly payroll zakat-deduction
  /// scheme). No other reliefs are applied. Simpler, and generally
  /// results in a higher amount.
  simple,

  /// "Kaedah bersih" / net method: gross annual income minus allowable
  /// reliefs (self, spouse, children, parents, education, medical,
  /// Tabung Haji, KWSP/EPF) and any zakat already deducted at source,
  /// then x 2.5%. This mirrors MAIJ's (Johor) published calculator and
  /// is the method most state calculators default to.
  detailed,
}

/// Per-state defaults. `selfRelief` / `spouseRelief` / `childRelief` are
/// only used when [IncomeCalculationMethod.detailed] is selected — they
/// are gazetted amounts that differ (and change) by state, so treat them
/// as a starting point the user can override, not a source of truth.
class StateZakatConfig {
  const StateZakatConfig({
    required this.name,
    required this.authority,
    required this.wornGoldMethod,
    this.selfRelief = 9000,
    this.spouseRelief = 3000,
    this.childRelief = 1000,
    this.referenceUrl,
  });

  final String name;
  final String authority;
  final WornGoldMethod wornGoldMethod;
  final double selfRelief;
  final double spouseRelief;
  final double childRelief;
  final String? referenceUrl;
}

class ZakatCalculator {
  ZakatCalculator._();

  static const double rate = 0.025;
  static const double storedGoldThresholdGrams = 85;
  static const double wornGoldThresholdGrams = 800;
  static const double storedSilverThresholdGrams = 595;

  /// Reference table of state defaults, keyed by display name.
  /// Sources are a mix of each council's own published calculator/FAQ
  /// where available, and commonly-cited relief figures otherwise —
  /// treat anything without a `referenceUrl` as an unverified estimate.
  static const Map<String, StateZakatConfig> states = {
    'Selangor': StateZakatConfig(
      name: 'Selangor',
      authority: 'Lembaga Zakat Selangor (LZS)',
      wornGoldMethod: WornGoldMethod.excess,
      referenceUrl: 'https://www.zakatselangor.com.my',
    ),
    'Wilayah Persekutuan': StateZakatConfig(
      name: 'Wilayah Persekutuan',
      authority: 'Pusat Pungutan Zakat - MAIWP (PPZ-MAIWP)',
      wornGoldMethod: WornGoldMethod.excess,
      referenceUrl: 'https://www.zakat.com.my',
    ),
    'Johor': StateZakatConfig(
      name: 'Johor',
      authority: 'Majlis Agama Islam Negeri Johor (MAIJ)',
      wornGoldMethod: WornGoldMethod.excess,
      selfRelief: 9000,
      spouseRelief: 3000,
      childRelief: 1000,
      referenceUrl: 'https://www.maij.gov.my/cal/index.html',
    ),
    'Negeri Sembilan': StateZakatConfig(
      name: 'Negeri Sembilan',
      authority: 'Majlis Agama Islam Negeri Sembilan (MAINS)',
      wornGoldMethod: WornGoldMethod.excess,
      referenceUrl: 'https://www.zakatns.com.my',
    ),
    'Melaka': StateZakatConfig(
      name: 'Melaka',
      authority: 'Majlis Agama Islam Melaka (MAIM)',
      wornGoldMethod: WornGoldMethod.full,
      selfRelief: 8000,
      referenceUrl: 'https://www.zakatmelaka.gov.my',
    ),
    'Pulau Pinang': StateZakatConfig(
      name: 'Pulau Pinang',
      authority: 'Majlis Agama Islam Negeri Pulau Pinang (MAINPP)',
      wornGoldMethod: WornGoldMethod.full,
      selfRelief: 8000,
      referenceUrl: 'https://zakat.mainpp.gov.my',
    ),
    'Perak': StateZakatConfig(
      name: 'Perak',
      authority: 'Majlis Agama Islam dan Adat Melayu Perak (MAIPk)',
      wornGoldMethod: WornGoldMethod.full,
      selfRelief: 8000,
      referenceUrl: 'https://www.maipk.gov.my',
    ),
    'Perlis': StateZakatConfig(
      name: 'Perlis',
      authority: 'Majlis Agama Islam dan Adat Istiadat Melayu Perlis (MAIPs)',
      wornGoldMethod: WornGoldMethod.full,
      selfRelief: 8000,
    ),
    'Pahang': StateZakatConfig(
      name: 'Pahang',
      authority: 'Majlis Ugama Islam dan Adat Resam Melayu Pahang (MUIP)',
      wornGoldMethod: WornGoldMethod.full,
      selfRelief: 8000,
    ),
    'Kedah': StateZakatConfig(
      name: 'Kedah',
      authority: 'Majlis Agama Islam Negeri Kedah',
      wornGoldMethod: WornGoldMethod.full,
      selfRelief: 8000,
    ),
    'Terengganu': StateZakatConfig(
      name: 'Terengganu',
      authority: 'Majlis Agama Islam dan Adat Melayu Terengganu (MAIDAM)',
      wornGoldMethod: WornGoldMethod.excess,
    ),
    'Kelantan': StateZakatConfig(
      name: 'Kelantan',
      authority: 'Majlis Agama Islam dan Adat Istiadat Melayu Kelantan (MAIK)',
      wornGoldMethod: WornGoldMethod.excess,
      selfRelief: 8000,
    ),
    'Sabah': StateZakatConfig(
      name: 'Sabah',
      authority: 'Majlis Ugama Islam Sabah (MUIS) / Pusat Zakat Sabah',
      wornGoldMethod: WornGoldMethod.excess,
      selfRelief: 8000,
    ),
    'Sarawak': StateZakatConfig(
      name: 'Sarawak',
      authority: 'Tabung Baitulmal Sarawak (TBS)',
      wornGoldMethod: WornGoldMethod.excess,
      selfRelief: 8000,
      referenceUrl: 'https://www.tbs.org.my',
    ),
  };

  /// Income zakat (zakat pendapatan).
  ///
  /// [zakatAlreadyDeducted] is zakat already withheld at source (e.g. via
  /// an employer/institution payroll-deduction scheme) — this is NOT the
  /// same as a KWSP/EPF contribution. KWSP is a *relief* (only applied
  /// under [IncomeCalculationMethod.detailed]); already-deducted zakat is
  /// subtracted from the taxable base under both methods, matching how
  /// Lembaga Zakat Selangor's own worked formula treats it.
  ///
  /// Nisab is checked against the *assessable* amount (after reliefs and
  /// already-deducted zakat), not the raw gross income — this matches
  /// worked examples published by several state authorities.
  static double income({
    required double monthlySalary,
    required double otherAnnualIncome,
    required double nisab,
    IncomeCalculationMethod method = IncomeCalculationMethod.simple,
    double zakatAlreadyDeducted = 0,
    double selfRelief = 0,
    int numberOfSpouses = 0,
    double spouseReliefPerSpouse = 0,
    int numberOfChildren = 0,
    double childReliefPerChild = 0,
    double parentSupport = 0,
    double education = 0,
    double medical = 0,
    double tabungHaji = 0,
    double kwspContribution = 0,
  }) {
    final grossAnnualIncome = monthlySalary * 12 + otherAnnualIncome;

    double reliefs = 0;
    if (method == IncomeCalculationMethod.detailed) {
      reliefs = selfRelief +
          (spouseReliefPerSpouse * numberOfSpouses) +
          (childReliefPerChild * numberOfChildren) +
          parentSupport +
          education +
          medical +
          tabungHaji +
          kwspContribution;
    }

    final assessable =
        (grossAnnualIncome - reliefs - zakatAlreadyDeducted).clamp(0, double.infinity);

    if (assessable < nisab) return 0;
    return assessable * rate;
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
    WornGoldMethod wornMethod = WornGoldMethod.excess,
  }) {
    if (isWorn) {
      final uruf = wornUrufGrams ?? wornGoldThresholdGrams;
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

  /// Silver (zakat perak). Silver is generally only recognised as
  /// "stored" for zakat purposes — the worn-jewellery concession applied
  /// to gold isn't commonly extended to silver, so there's no `isWorn`
  /// branch here.
  static double silverItem({
    required double weightGrams,
    required double pricePerGram,
  }) {
    return weightGrams >= storedSilverThresholdGrams
        ? weightGrams * pricePerGram * rate
        : 0;
  }
}