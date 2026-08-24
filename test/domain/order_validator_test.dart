import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/holding.dart';
import 'package:kestrel/domain/models/order.dart';
import 'package:kestrel/domain/services/order_validator.dart';

void main() {
  group('OrderValidator Pure Domain Unit Tests', () {
    test('Buy order with sufficient balance is valid', () {
      final result = OrderValidator.validate(
        side: OrderSide.buy,
        symbol: 'RELIANCE',
        quantity: 10,
        price: Money.fromRupees(2500),
        walletBalance: Money.fromRupees(50000),
        holding: null,
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('Buy order with insufficient balance fails with shortfall details', () {
      final result = OrderValidator.validate(
        side: OrderSide.buy,
        symbol: 'RELIANCE',
        quantity: 10, // Cost = ₹25,000
        price: Money.fromRupees(2500),
        walletBalance: Money.fromRupees(20000), // Balance = ₹20,000 (Short by ₹5,000)
        holding: null,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Insufficient funds'));
      expect(result.errorMessage, contains('Short by'));
    });

    test('Quantity <= 0 is rejected immediately', () {
      final result = OrderValidator.validate(
        side: OrderSide.buy,
        symbol: 'TCS',
        quantity: 0,
        price: Money.fromRupees(3500),
        walletBalance: Money.fromRupees(50000),
        holding: null,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Quantity must be at least 1'));
    });

    test('Sell order with no holding is rejected', () {
      final result = OrderValidator.validate(
        side: OrderSide.sell,
        symbol: 'INFY',
        quantity: 5,
        price: Money.fromRupees(1500),
        walletBalance: Money.fromRupees(10000),
        holding: null,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('No holdings available'));
    });

    test('Sell order exceeding held quantity is rejected', () {
      final holding = Holding(
        symbol: 'INFY',
        quantity: 4,
        avgCost: Money.fromRupees(1400),
        updatedAt: DateTime.now(),
      );

      final result = OrderValidator.validate(
        side: OrderSide.sell,
        symbol: 'INFY',
        quantity: 5,
        price: Money.fromRupees(1500),
        walletBalance: Money.fromRupees(10000),
        holding: holding,
      );

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Cannot sell 5 shares'));
    });

    test('Sell order within held quantity is valid', () {
      final holding = Holding(
        symbol: 'INFY',
        quantity: 10,
        avgCost: Money.fromRupees(1400),
        updatedAt: DateTime.now(),
      );

      final result = OrderValidator.validate(
        side: OrderSide.sell,
        symbol: 'INFY',
        quantity: 5,
        price: Money.fromRupees(1500),
        walletBalance: Money.fromRupees(10000),
        holding: holding,
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });
  });
}
