import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';

void main() {
  group('Money Value Type Unit Tests', () {
    test('Constructors and getters work correctly', () {
      const fromPaise = Money.fromPaise(295000);
      final fromRupees = Money.fromRupees(2950.00);

      expect(fromPaise.paise, 295000);
      expect(fromPaise.inRupees, 2950.00);
      expect(fromRupees.paise, 295000);
      expect(fromPaise, equals(fromRupees));
    });

    test('Zero constant is properly represented', () {
      expect(Money.zero.paise, 0);
      expect(Money.zero.isZero, isTrue);
      expect(Money.zero.isPositive, isFalse);
      expect(Money.zero.isNegative, isFalse);
    });

    test('Addition and Subtraction eliminate float drift', () {
      // Classic floating point problem: 0.1 + 0.2 = 0.30000000000000004
      final m1 = Money.fromRupees(0.10);
      final m2 = Money.fromRupees(0.20);
      final sum = m1 + m2;

      expect(sum.paise, 30);
      expect(sum.inRupees, 0.30);
      expect(sum, equals(Money.fromRupees(0.30)));

      final diff = sum - m1;
      expect(diff, equals(m2));
    });

    test('Multiplication and Division maintain exact rounding', () {
      final price = Money.fromRupees(2950.40); // 295040 paise
      const qty = 7;
      final total = price * qty;

      expect(total.paise, 295040 * 7);
      expect(total.inRupees, 20652.80);

      final perUnit = total / qty;
      expect(perUnit, equals(price));
    });

    test('Comparisons gate orders safely without float inaccuracies', () {
      final low = Money.fromRupees(100.00);
      final high = Money.fromRupees(100.05);

      expect(low < high, isTrue);
      expect(low <= high, isTrue);
      expect(high > low, isTrue);
      expect(high >= low, isTrue);
      expect(low == high, isFalse);
      expect(low.compareTo(high), isNegative);
    });

    test('Indian Currency Formatting (en_IN)', () {
      final m1 = Money.fromRupees(100000.00); // 1 Lakh
      expect(m1.format(), '₹1,00,000.00');

      final m2 = Money.fromRupees(2950.50);
      expect(m2.format(), '₹2,950.50');

      final negative = Money.fromRupees(-1250.75);
      expect(negative.format(), '-₹1,250.75');

      final explicitPositive = Money.fromRupees(450.00);
      expect(explicitPositive.format(explicitSign: true), '+₹450.00');
    });

    test('Unary negation and absolute value', () {
      final pos = Money.fromRupees(500.00);
      final neg = -pos;

      expect(neg.paise, -50000);
      expect(neg.isNegative, isTrue);
      expect(neg.abs(), equals(pos));
    });
  });
}
