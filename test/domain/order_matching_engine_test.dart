import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/data/feed/price_tick.dart';
import 'package:kestrel/domain/models/order.dart';
import 'package:kestrel/domain/services/order_matching_engine.dart';

void main() {
  group('OrderMatchingEngine Unit Tests', () {
    final now = DateTime.now();

    test('Limit BUY triggers when tick price <= limit price', () {
      final order = Order(
        id: 'ORD-1',
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        type: OrderType.limit,
        status: OrderStatus.pending,
        quantity: 10,
        price: Money.fromPaise(290000), // Target ₹2,900.00
        value: Money.fromPaise(2900000),
        timestamp: now,
      );

      // 1. Tick above limit -> no trigger
      final tickAbove = PriceTick(
        symbol: 'RELIANCE',
        ltp: Money.fromPaise(291000), // ₹2,910.00
        prevClose: Money.fromPaise(295000),
        direction: TickDirection.down,
        timestamp: now,
      );
      expect(
        OrderMatchingEngine.evaluateTick(tick: tickAbove, pendingOrders: [order]),
        isEmpty,
      );

      // 2. Tick at or below limit -> triggers!
      final tickBelow = PriceTick(
        symbol: 'RELIANCE',
        ltp: Money.fromPaise(289500), // ₹2,895.00
        prevClose: Money.fromPaise(295000),
        direction: TickDirection.down,
        timestamp: now,
      );
      final results = OrderMatchingEngine.evaluateTick(
        tick: tickBelow,
        pendingOrders: [order],
      );
      expect(results.length, 1);
      expect(results.first.order.id, 'ORD-1');
      expect(results.first.executionPrice, Money.fromPaise(290000)); // Fill at limit
    });

    test('Limit SELL triggers when tick price >= limit price', () {
      final order = Order(
        id: 'ORD-2',
        symbol: 'TCS',
        side: OrderSide.sell,
        type: OrderType.limit,
        status: OrderStatus.pending,
        quantity: 5,
        price: Money.fromPaise(400000), // Target ₹4,000.00
        value: Money.fromPaise(2000000),
        timestamp: now,
      );

      // Tick below -> no trigger
      final tickBelow = PriceTick(
        symbol: 'TCS',
        ltp: Money.fromPaise(398000),
        prevClose: Money.fromPaise(385000),
        direction: TickDirection.up,
        timestamp: now,
      );
      expect(
        OrderMatchingEngine.evaluateTick(tick: tickBelow, pendingOrders: [order]),
        isEmpty,
      );

      // Tick above -> triggers!
      final tickAbove = PriceTick(
        symbol: 'TCS',
        ltp: Money.fromPaise(402000),
        prevClose: Money.fromPaise(385000),
        direction: TickDirection.up,
        timestamp: now,
      );
      final results = OrderMatchingEngine.evaluateTick(
        tick: tickAbove,
        pendingOrders: [order],
      );
      expect(results.length, 1);
      expect(results.first.order.id, 'ORD-2');
    });

    test('Stop-Loss SELL triggers when tick price <= trigger price', () {
      final order = Order(
        id: 'ORD-3',
        symbol: 'INFY',
        side: OrderSide.sell,
        type: OrderType.stopLoss,
        status: OrderStatus.pending,
        quantity: 20,
        price: Money.fromPaise(160000),
        triggerPrice: Money.fromPaise(160000), // Stop-loss at ₹1,600.00
        value: Money.fromPaise(3200000),
        timestamp: now,
      );

      // Price drops below stop-loss
      final tickDrop = PriceTick(
        symbol: 'INFY',
        ltp: Money.fromPaise(159000),
        prevClose: Money.fromPaise(165000),
        direction: TickDirection.down,
        timestamp: now,
      );
      final results = OrderMatchingEngine.evaluateTick(
        tick: tickDrop,
        pendingOrders: [order],
      );
      expect(results.length, 1);
      expect(results.first.executionPrice, Money.fromPaise(159000));
    });

    test('Ignores orders of different symbol or non-pending status', () {
      final orderOtherSymbol = Order(
        id: 'ORD-4',
        symbol: 'HDFCBANK',
        side: OrderSide.buy,
        type: OrderType.limit,
        status: OrderStatus.pending,
        quantity: 1,
        price: Money.fromPaise(200000),
        value: Money.fromPaise(200000),
        timestamp: now,
      );
      final orderExecuted = Order(
        id: 'ORD-5',
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        type: OrderType.limit,
        status: OrderStatus.executed,
        quantity: 1,
        price: Money.fromPaise(300000),
        value: Money.fromPaise(300000),
        timestamp: now,
      );

      final tick = PriceTick(
        symbol: 'RELIANCE',
        ltp: Money.fromPaise(290000),
        prevClose: Money.fromPaise(295000),
        direction: TickDirection.down,
        timestamp: now,
      );

      final results = OrderMatchingEngine.evaluateTick(
        tick: tick,
        pendingOrders: [orderOtherSymbol, orderExecuted],
      );
      expect(results, isEmpty);
    });
  });
}
