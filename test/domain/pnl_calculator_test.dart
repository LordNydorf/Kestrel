import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/holding.dart';
import 'package:kestrel/domain/services/pnl_calculator.dart';

void main() {
  group('PnlCalculator Domain Unit Tests', () {
    test('Empty holdings returns zero summary', () {
      final summary = PnlCalculator.calculateSummary(
        holdings: [],
        currentPrices: {},
      );

      expect(summary, equals(PortfolioSummary.zero));
      expect(summary.totalInvested.isZero, isTrue);
      expect(summary.currentValue.isZero, isTrue);
      expect(summary.unrealizedPnl.isZero, isTrue);
      expect(summary.pnlPercentage, equals(0.0));
      expect(summary.totalHoldingsCount, equals(0));
    });

    test('Single holding with gain calculates positive PnL & percentage', () {
      // Bought 10 shares of RELIANCE @ 2450.00 (Invested: 24,500.00)
      // Current live price @ 2695.00 (+10% gain) -> Current: 26,950.00
      final holding = Holding(
        symbol: 'RELIANCE',
        quantity: 10,
        avgCost: Money.fromRupees(2450.00),
        updatedAt: DateTime.now(),
      );

      final summary = PnlCalculator.calculateSummary(
        holdings: [holding],
        currentPrices: {'RELIANCE': Money.fromRupees(2695.00)},
      );

      expect(summary.totalHoldingsCount, equals(1));
      expect(summary.totalInvested, equals(Money.fromRupees(24500.00)));
      expect(summary.currentValue, equals(Money.fromRupees(26950.00)));
      expect(summary.unrealizedPnl, equals(Money.fromRupees(2450.00)));
      expect(summary.pnlPercentage, closeTo(10.0, 0.001));
      expect(summary.isGain, isTrue);
      expect(summary.isLoss, isFalse);
    });

    test('Single holding with loss calculates negative PnL', () {
      // Bought 5 shares of TCS @ 3500.00 (Invested: 17,500.00)
      // Current live price @ 3150.00 (-10% loss) -> Current: 15,750.00
      final holding = Holding(
        symbol: 'TCS',
        quantity: 5,
        avgCost: Money.fromRupees(3500.00),
        updatedAt: DateTime.now(),
      );

      final summary = PnlCalculator.calculateSummary(
        holdings: [holding],
        currentPrices: {'TCS': Money.fromRupees(3150.00)},
      );

      expect(summary.totalInvested, equals(Money.fromRupees(17500.00)));
      expect(summary.currentValue, equals(Money.fromRupees(15750.00)));
      expect(summary.unrealizedPnl, equals(Money.fromRupees(-1750.00)));
      expect(summary.pnlPercentage, closeTo(-10.0, 0.001));
      expect(summary.isLoss, isTrue);
      expect(summary.isGain, isFalse);
    });

    test('Multi-asset portfolio aggregates overall valuation and net PnL', () {
      final holdings = [
        Holding(
          symbol: 'RELIANCE',
          quantity: 10,
          avgCost: Money.fromRupees(2500.00), // Invested: 25,000.00
          updatedAt: DateTime.now(),
        ),
        Holding(
          symbol: 'INFY',
          quantity: 20,
          avgCost: Money.fromRupees(1500.00), // Invested: 30,000.00
          updatedAt: DateTime.now(),
        ),
      ];

      // Total Invested = 25,000 + 30,000 = 55,000.00
      // RELIANCE @ 2700.00 -> 27,000.00 (+2,000.00)
      // INFY @ 1400.00 -> 28,000.00 (-2,000.00)
      // Total Current = 27,000 + 28,000 = 55,000.00
      // Net PnL = 0.00
      final summary = PnlCalculator.calculateSummary(
        holdings: holdings,
        currentPrices: {
          'RELIANCE': Money.fromRupees(2700.00),
          'INFY': Money.fromRupees(1400.00),
        },
      );

      expect(summary.totalHoldingsCount, equals(2));
      expect(summary.totalInvested, equals(Money.fromRupees(55000.00)));
      expect(summary.currentValue, equals(Money.fromRupees(55000.00)));
      expect(summary.unrealizedPnl.isZero, isTrue);
      expect(summary.pnlPercentage, equals(0.0));
      expect(summary.isNeutral, isTrue);
    });

    test('Fallback to avgCost if symbol live price missing from map', () {
      final holding = Holding(
        symbol: 'ITC',
        quantity: 100,
        avgCost: Money.fromRupees(450.00),
        updatedAt: DateTime.now(),
      );

      final summary = PnlCalculator.calculateSummary(
        holdings: [holding],
        currentPrices: {}, // empty price map
      );

      expect(summary.totalInvested, equals(Money.fromRupees(45000.00)));
      expect(summary.currentValue, equals(Money.fromRupees(45000.00)));
      expect(summary.unrealizedPnl.isZero, isTrue);
    });
  });
}
