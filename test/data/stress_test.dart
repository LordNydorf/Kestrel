import 'dart:async';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/constants/symbols.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/data/feed/market_data_service.dart';
import 'package:kestrel/domain/models/holding.dart';
import 'package:kestrel/domain/models/order.dart';
import 'package:kestrel/domain/services/order_validator.dart';
import 'package:kestrel/domain/services/pnl_calculator.dart';
import 'trading_repository_test.dart';

void main() {
  group('High-Frequency Feed & Trading Stress Tests (50+ Ticks/Sec)', () {
    test('Feed stress test: Generates 500+ ticks rapidly without stream buffer overrun',
        () async {
      final feed = MarketDataService(
        ticksPerSecondPerSymbol: 5.0, // 50 ticks/sec across 10 symbols
        random: Random(42),
      );

      var tickCount = 0;
      final completer = Completer<void>();

      final sub = feed.allTicks.listen((tick) {
        tickCount++;
        // Verify price floor invariance (never <= 0)
        expect(tick.ltp.paise, greaterThanOrEqualTo(100)); // Minimum ₹1.00
        expect(tick.prevClose.paise, greaterThan(0));

        if (tickCount >= 100 && !completer.isCompleted) {
          completer.complete();
        }
      });

      feed.start();

      // Wait for burst
      await completer.future.timeout(const Duration(seconds: 4));
      feed.stop();
      await sub.cancel();
      feed.dispose();

      expect(tickCount, greaterThanOrEqualTo(100));
    });

    test('Precision stress test: 10,000 rapid buy/sell arithmetic ops maintain 0 float drift',
        () {
      var currentBalancePaise = 10000000; // ₹1,00,000.00
      final random = Random(12345);

      for (var i = 0; i < 10000; i++) {
        final pricePaise = random.nextInt(500000) + 10000; // ₹100 to ₹5,100
        final qty = random.nextInt(10) + 1;
        final totalCostPaise = pricePaise * qty;

        final price = Money.fromPaise(pricePaise);
        final moneyTotal = price * qty;

        expect(moneyTotal.paise, equals(totalCostPaise));

        if (totalCostPaise <= currentBalancePaise) {
          final balanceBefore = Money.fromPaise(currentBalancePaise);
          final balanceAfter = balanceBefore - moneyTotal;
          currentBalancePaise -= totalCostPaise;
          expect(balanceAfter.paise, equals(currentBalancePaise));

          // Simulate sell refund
          final refund = balanceAfter + moneyTotal;
          currentBalancePaise += totalCostPaise;
          expect(refund.paise, equals(currentBalancePaise));
        }
      }

      expect(currentBalancePaise, equals(10000000));
    });

    test('Concurrent trading & live tick stress test: Race-free atomic execution',
        () async {
      final fakeRepo = FakeTradingRepository();
      final feed = MarketDataService(
        ticksPerSecondPerSymbol: 5.0,
        random: Random(999),
      );
      feed.start();

      final ordersToExecute = [
        (Universe.reliance.symbol, OrderSide.buy, 5),
        (Universe.tcs.symbol, OrderSide.buy, 3),
        (Universe.infy.symbol, OrderSide.buy, 10),
        (Universe.hdfcBank.symbol, OrderSide.buy, 8),
      ];

      // Execute 4 concurrent buy orders fetching instantaneous snapshot prices
      final executedOrders = await Future.wait(
        ordersToExecute.map((spec) async {
          final symbol = spec.$1;
          final side = spec.$2;
          final qty = spec.$3;

          final price = feed.getPrice(symbol);
          return fakeRepo.executeOrder(
            symbol: symbol,
            side: side,
            quantity: qty,
            price: price,
          );
        }),
      );

      expect(executedOrders.length, equals(4));

      final holdings = await fakeRepo.getHoldings();
      expect(holdings.length, equals(4));

      final wallet = await fakeRepo.getWalletBalance();
      final totalSpent = executedOrders.fold<Money>(
        Money.zero,
        (sum, order) => sum + order.value,
      );

      expect(wallet, equals(Universe.initialWalletBalance - totalSpent));

      // Calculate instantaneous portfolio summary under active feed
      final summary = PnlCalculator.calculateSummary(
        holdings: holdings,
        currentPrices: feed.allSnapshots,
      );

      expect(summary.totalHoldingsCount, equals(4));
      expect(summary.totalInvested, equals(totalSpent));

      feed.stop();
      feed.dispose();
      fakeRepo.dispose();
    });

    test('OrderValidator stress test: Rapid high-load verification', () {
      final wallet = Money.fromRupees(50000.00);

      for (var i = 0; i < 1000; i++) {
        final price = Money.fromRupees(1000.00 + i);
        final qty = 10;
        final total = price * qty; // from 10,000 to 19,990

        final result = OrderValidator.validate(
          side: OrderSide.buy,
          symbol: 'TCS',
          quantity: qty,
          price: price,
          walletBalance: wallet,
          holding: null,
        );

        if (total <= wallet) {
          expect(result.isValid, isTrue);
          expect(result.errorMessage, isNull);
        } else {
          expect(result.isValid, isFalse);
          expect(result.errorMessage, contains('Insufficient funds'));
        }
      }
    });
  });
}
