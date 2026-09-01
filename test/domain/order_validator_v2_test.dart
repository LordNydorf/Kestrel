import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/holding.dart';
import 'package:kestrel/domain/models/order.dart';
import 'package:kestrel/domain/services/order_validator.dart';

void main() {
  group('OrderValidator v2 Unit Tests (Limit & Stop-Loss)', () {
    final balance = Money.fromPaise(5000000); // ₹50,000.00
    final holding = Holding(
      symbol: 'RELIANCE',
      quantity: 10,
      avgCost: Money.fromPaise(280000),
      updatedAt: DateTime.now(),
    );

    test('Valid Limit BUY within wallet balance passes', () {
      final res = OrderValidator.validate(
        side: OrderSide.buy,
        type: OrderType.limit,
        symbol: 'RELIANCE',
        quantity: 10,
        price: Money.fromPaise(290000), // ₹29,000.00 total
        walletBalance: balance,
        holding: null,
      );
      expect(res.isValid, isTrue);
      expect(res.errorMessage, isNull);
    });

    test('Limit BUY exceeding wallet balance is rejected with shortfall message', () {
      final res = OrderValidator.validate(
        side: OrderSide.buy,
        type: OrderType.limit,
        symbol: 'RELIANCE',
        quantity: 20,
        price: Money.fromPaise(290000), // ₹58,000.00 total vs ₹50,000.00 balance
        walletBalance: balance,
        holding: null,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Short by ₹8,000.00'));
    });

    test('Limit SELL within held quantity passes', () {
      final res = OrderValidator.validate(
        side: OrderSide.sell,
        type: OrderType.limit,
        symbol: 'RELIANCE',
        quantity: 10,
        price: Money.fromPaise(300000),
        walletBalance: balance,
        holding: holding,
      );
      expect(res.isValid, isTrue);
    });

    test('Limit SELL exceeding held quantity fails', () {
      final res = OrderValidator.validate(
        side: OrderSide.sell,
        type: OrderType.limit,
        symbol: 'RELIANCE',
        quantity: 15,
        price: Money.fromPaise(300000),
        walletBalance: balance,
        holding: holding,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Only 10 held'));
    });

    test('Stop-Loss order requires valid trigger price', () {
      final res = OrderValidator.validate(
        side: OrderSide.sell,
        type: OrderType.stopLoss,
        symbol: 'RELIANCE',
        quantity: 5,
        price: Money.fromPaise(290000),
        triggerPrice: null, // Missing trigger
        walletBalance: balance,
        holding: holding,
      );
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('Valid trigger price is required'));
    });
  });
}
