import 'package:flutter_test/flutter_test.dart';
import 'package:hijrah/zakat_calculator.dart';

void main() {
  group('ZakatCalculator.income', () {
    test('calculates 2.5% of annual income above nisab', () {
      final result = ZakatCalculator.income(
        monthlySalary: 5000,
        otherAnnualIncome: 0,
        alreadyPaid: 0,
        nisab: 33996,
      );

      expect(result, 1500);
    });

    test('returns zero below nisab', () {
      final result = ZakatCalculator.income(
        monthlySalary: 2000,
        otherAnnualIncome: 0,
        alreadyPaid: 0,
        nisab: 33996,
      );

      expect(result, 0);
    });

    test('deducts the amount already paid and never goes negative', () {
      expect(
        ZakatCalculator.income(
          monthlySalary: 5000,
          otherAnnualIncome: 0,
          alreadyPaid: 500,
          nisab: 33996,
        ),
        1000,
      );
      expect(
        ZakatCalculator.income(
          monthlySalary: 5000,
          otherAnnualIncome: 0,
          alreadyPaid: 2000,
          nisab: 33996,
        ),
        0,
      );
    });
  });

  group('ZakatCalculator.savings', () {
    test('aggregates account balances before applying nisab', () {
      expect(
        ZakatCalculator.savings(
          lowestAnnualBalances: const [20000, 20000],
          nisab: 33996,
        ),
        1000,
      );
    });

    test('returns zero for aggregate savings below nisab', () {
      expect(
        ZakatCalculator.savings(
          lowestAnnualBalances: const [10000, 15000],
          nisab: 33996,
        ),
        0,
      );
    });
  });

  group('ZakatCalculator.goldItem', () {
    test('uses the 85g stored-gold threshold', () {
      expect(
        ZakatCalculator.goldItem(
          weightGrams: 84.99,
          pricePerGram: 400,
          isWorn: false,
        ),
        0,
      );
      expect(
        ZakatCalculator.goldItem(
          weightGrams: 85,
          pricePerGram: 400,
          isWorn: false,
        ),
        850,
      );
    });

    test('charges worn gold only on the weight exceeding the uruf', () {
      expect(
        ZakatCalculator.goldItem(
          weightGrams: 799.99,
          pricePerGram: 400,
          isWorn: true,
        ),
        0,
      );
      // Exactly at the uruf there is no excess, so nothing is owed.
      expect(
        ZakatCalculator.goldItem(
          weightGrams: 800,
          pricePerGram: 400,
          isWorn: true,
        ),
        0,
      );
      // 900 g against an 800 g uruf is charged on 100 g, not on 900 g.
      expect(
        ZakatCalculator.goldItem(
          weightGrams: 900,
          pricePerGram: 400,
          isWorn: true,
        ),
        1000,
      );
    });

    test('honours a state-specific uruf', () {
      // PPZ worked example for Pulau Pinang: 258 g against a 250 g uruf.
      expect(
        ZakatCalculator.goldItem(
          weightGrams: 258,
          pricePerGram: 250,
          isWorn: true,
          wornUrufGrams: 250,
        ),
        50,
      );
    });
  });
}
