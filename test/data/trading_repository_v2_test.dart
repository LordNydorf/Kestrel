import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/holding.dart';
import 'package:kestrel/domain/models/order.dart';
import 'trading_repository_test.dart';

void main() {
  group('TradingRepository v2 (Limit Orders, Triggers & Cancellation)', () {
    late FakeTradingRepository repository;

    setUp(() {
      repository = FakeTradingRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('Place Limit BUY locks wallet funds and saves order as PENDING', () async {
      final order = await repository.placeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        type: OrderType.limit,
        quantity: 10,
        price: Money.fromRupees(2900), // ₹29,000 total
      );

      expect(order.isPending, isTrue);
      expect(order.type, OrderType.limit);

      // Available wallet = ₹1,00,000 - ₹29,000 = ₹71,000
      final available = await repository.getWalletBalance();
      expect(available, Money.fromRupees(71000));

      // Locked balance = ₹29,000
      final locked = await repository.getLockedBalance();
      expect(locked, Money.fromRupees(29000));

      // No holdings established yet
      final holdings = await repository.getHoldings();
      expect(holdings, isEmpty);

      // Pending orders list contains order
      final pending = await repository.getPendingOrders();
      expect(pending.length, 1);
      expect(pending.first.id, order.id);
    });

    test('Cancel pending Limit BUY unlocks wallet funds and marks order CANCELLED', () async {
      final order = await repository.placeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        type: OrderType.limit,
        quantity: 10,
        price: Money.fromRupees(2900),
      );

      await repository.cancelOrder(order.id);

      // Available wallet restored to ₹1,00,000
      final available = await repository.getWalletBalance();
      expect(available, Money.fromRupees(100000));

      final locked = await repository.getLockedBalance();
      expect(locked, Money.zero);

      final orders = await repository.getOrders();
      expect(orders.first.status, OrderStatus.cancelled);
    });

    test('Execute triggered Limit BUY settles holding and releases locked funds', () async {
      final order = await repository.placeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        type: OrderType.limit,
        quantity: 10,
        price: Money.fromRupees(2900),
      );

      // Trigger executed at limit price
      await repository.executeTriggeredOrder(
        orderId: order.id,
        executionPrice: Money.fromRupees(2900),
      );

      final locked = await repository.getLockedBalance();
      expect(locked, Money.zero);

      final holding = await repository.getHoldingBySymbol('RELIANCE');
      expect(holding, isNotNull);
      expect(holding!.quantity, 10);
      expect(holding.avgCost, Money.fromRupees(2900));

      final orders = await repository.getOrders();
      expect(orders.first.isExecuted, isTrue);
    });

    test('Execute triggered Limit SELL calculates realized P&L and credits wallet', () async {
      // Seed initial holding: 10 shares @ ₹2,500
      repository.seedHolding(Holding(
        symbol: 'TCS',
        quantity: 10,
        avgCost: Money.fromRupees(2500),
        updatedAt: DateTime.now(),
      ));

      // Place Limit SELL for 5 shares @ ₹3,000
      final order = await repository.placeOrder(
        symbol: 'TCS',
        side: OrderSide.sell,
        type: OrderType.limit,
        quantity: 5,
        price: Money.fromRupees(3000),
      );

      expect(order.isPending, isTrue);

      // Trigger executed at ₹3,000
      await repository.executeTriggeredOrder(
        orderId: order.id,
        executionPrice: Money.fromRupees(3000),
      );

      // Realized P&L = (3000 - 2500) * 5 = +₹2,500
      final orders = await repository.getOrders();
      expect(orders.first.realizedPnl, Money.fromRupees(2500));

      // Wallet credited: ₹1,00,000 + (5 * ₹3,000) = ₹1,15,000
      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(115000));

      // Holding decremented to 5 shares
      final holding = await repository.getHoldingBySymbol('TCS');
      expect(holding!.quantity, 5);
      expect(holding.avgCost, Money.fromRupees(2500));
    });

    test('Deposit funds increases wallet balance', () async {
      await repository.depositFunds(Money.fromRupees(50000));
      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(150000));
    });

    test('Reset portfolio restores initial ₹1,00,000 and clears all data', () async {
      await repository.executeOrder(
        symbol: 'INFY',
        side: OrderSide.buy,
        quantity: 10,
        price: Money.fromRupees(1500),
      );

      await repository.resetPortfolio();

      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(100000));

      final locked = await repository.getLockedBalance();
      expect(locked, Money.zero);

      final holdings = await repository.getHoldings();
      expect(holdings, isEmpty);

      final orders = await repository.getOrders();
      expect(orders, isEmpty);
    });
  });
}
