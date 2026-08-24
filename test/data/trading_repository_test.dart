import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/holding.dart';
import 'package:kestrel/domain/models/order.dart';
import 'package:kestrel/data/repositories/trading_repository.dart';

/// Pure In-Memory FakeTradingRepository implementing TradingRepository contract.
class FakeTradingRepository implements TradingRepository {
  Money _wallet = Money.fromRupees(100000); // Initial ₹1,00,000.00
  final Map<String, Holding> _holdings = {};
  final List<Order> _orders = [];

  final StreamController<Money> _walletController =
      StreamController<Money>.broadcast();
  final StreamController<List<Holding>> _holdingsController =
      StreamController<List<Holding>>.broadcast();
  final StreamController<List<Order>> _ordersController =
      StreamController<List<Order>>.broadcast();

  @override
  Future<Money> getWalletBalance() async => _wallet;

  @override
  Stream<Money> watchWalletBalance() async* {
    yield _wallet;
    yield* _walletController.stream;
  }

  @override
  Future<List<Holding>> getHoldings() async =>
      _holdings.values.where((h) => h.quantity > 0).toList();

  @override
  Future<Holding?> getHoldingBySymbol(String symbol) async => _holdings[symbol];

  @override
  Stream<List<Holding>> watchHoldings() async* {
    yield await getHoldings();
    yield* _holdingsController.stream;
  }

  @override
  Future<List<Order>> getOrders() async => List.unmodifiable(_orders);

  @override
  Stream<List<Order>> watchOrders() async* {
    yield await getOrders();
    yield* _ordersController.stream;
  }

  @override
  Future<Order> executeOrder({
    required String symbol,
    required OrderSide side,
    required int quantity,
    required Money price,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Order quantity must be greater than zero.');
    }
    if (price.isZero || price.paise < 0) {
      throw ArgumentError('Order price must be greater than zero.');
    }

    final orderValue = price * quantity;
    final now = DateTime.now();
    final order = Order(
      id: 'ORD-${now.millisecondsSinceEpoch}',
      symbol: symbol,
      side: side,
      quantity: quantity,
      price: price,
      value: orderValue,
      timestamp: now,
    );

    if (side == OrderSide.buy) {
      if (orderValue > _wallet) {
        throw StateError(
          'Insufficient wallet balance. Required: $orderValue, Available: $_wallet',
        );
      }

      _wallet = _wallet - orderValue;

      final existing = _holdings[symbol];
      if (existing == null) {
        _holdings[symbol] = Holding(
          symbol: symbol,
          quantity: quantity,
          avgCost: price,
          updatedAt: now,
        );
      } else {
        final newQty = existing.quantity + quantity;
        final totalCostPaise =
            existing.investedValue.paise + (quantity * price.paise);
        final newAvgCostPaise = (totalCostPaise / newQty).round();

        _holdings[symbol] = Holding(
          symbol: symbol,
          quantity: newQty,
          avgCost: Money.fromPaise(newAvgCostPaise),
          updatedAt: now,
        );
      }
    } else {
      // SELL
      final existing = _holdings[symbol];
      if (existing == null || existing.quantity <= 0) {
        throw StateError('Cannot SELL $symbol: No holding found.');
      }

      if (quantity > existing.quantity) {
        throw StateError(
          'Cannot SELL $quantity shares of $symbol (Only ${existing.quantity} held).',
        );
      }

      _wallet = _wallet + orderValue;
      final newQty = existing.quantity - quantity;

      if (newQty == 0) {
        _holdings.remove(symbol);
      } else {
        _holdings[symbol] = existing.copyWith(
          quantity: newQty,
          updatedAt: now,
        );
      }
    }

    _orders.insert(0, order);

    _walletController.add(_wallet);
    _holdingsController.add(await getHoldings());
    _ordersController.add(await getOrders());

    return order;
  }

  void seedHolding(Holding holding) {
    _holdings[holding.symbol] = holding;
    _holdingsController.add(_holdings.values.where((h) => h.quantity > 0).toList());
  }

  void seedOrder(Order order) {
    _orders.insert(0, order);
    _ordersController.add(List.unmodifiable(_orders));
  }

  @override
  void dispose() {
    _walletController.close();
    _holdingsController.close();
    _ordersController.close();
  }
}

void main() {
  group('TradingRepository Contract Unit Tests', () {
    late FakeTradingRepository repository;

    setUp(() {
      repository = FakeTradingRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('Initial state: ₹1,00,000.00 wallet, 0 holdings, 0 orders', () async {
      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(100000));

      final holdings = await repository.getHoldings();
      expect(holdings, isEmpty);

      final orders = await repository.getOrders();
      expect(orders, isEmpty);
    });

    test('Execute BUY debits wallet and establishes initial holding', () async {
      final order = await repository.executeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        quantity: 10,
        price: Money.fromRupees(2500),
      );

      expect(order.symbol, 'RELIANCE');
      expect(order.side, OrderSide.buy);
      expect(order.value, Money.fromRupees(25000));

      // Wallet debited: ₹1,00,000 - ₹25,000 = ₹75,000
      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(75000));

      final holding = await repository.getHoldingBySymbol('RELIANCE');
      expect(holding, isNotNull);
      expect(holding!.quantity, 10);
      expect(holding.avgCost, Money.fromRupees(2500));
      expect(holding.investedValue, Money.fromRupees(25000));
    });

    test('Execute second BUY calculates accurate weighted average cost', () async {
      // 1st BUY: 10 @ ₹2,500 = ₹25,000
      await repository.executeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        quantity: 10,
        price: Money.fromRupees(2500),
      );

      // 2nd BUY: 10 @ ₹3,000 = ₹30,000
      // Total Qty = 20, Total Cost = ₹55,000 -> Avg Cost = ₹2,750.00
      await repository.executeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        quantity: 10,
        price: Money.fromRupees(3000),
      );

      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(45000)); // ₹1,00,000 - ₹55,000

      final holding = await repository.getHoldingBySymbol('RELIANCE');
      expect(holding!.quantity, 20);
      expect(holding.avgCost, Money.fromRupees(2750));
      expect(holding.investedValue, Money.fromRupees(55000));
    });

    test('BUY exceeding available wallet balance throws StateError', () async {
      expect(
        () => repository.executeOrder(
          symbol: 'TCS',
          side: OrderSide.buy,
          quantity: 100, // 100 * ₹3,500 = ₹3,50,000 > ₹1,00,000
          price: Money.fromRupees(3500),
        ),
        throwsA(isA<StateError>()),
      );

      // Balance remains untouched
      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(100000));
    });

    test('Execute partial SELL credits wallet and preserves average cost', () async {
      // Buy 20 @ ₹2,750
      await repository.executeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        quantity: 20,
        price: Money.fromRupees(2750),
      );

      // Sell 5 @ ₹3,200 = ₹16,000 credit
      final sellOrder = await repository.executeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.sell,
        quantity: 5,
        price: Money.fromRupees(3200),
      );

      expect(sellOrder.value, Money.fromRupees(16000));

      // Wallet: ₹45,000 + ₹16,000 = ₹61,000
      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(61000));

      // Holding: 15 shares, avgCost unchanged at ₹2,750
      final holding = await repository.getHoldingBySymbol('RELIANCE');
      expect(holding!.quantity, 15);
      expect(holding.avgCost, Money.fromRupees(2750));
    });

    test('Execute full SELL removes holding completely', () async {
      await repository.executeOrder(
        symbol: 'INFY',
        side: OrderSide.buy,
        quantity: 10,
        price: Money.fromRupees(1500),
      );

      await repository.executeOrder(
        symbol: 'INFY',
        side: OrderSide.sell,
        quantity: 10,
        price: Money.fromRupees(1600),
      );

      final holdings = await repository.getHoldings();
      expect(holdings.any((h) => h.symbol == 'INFY'), isFalse);
    });

    test('SELL with no holding or exceeding quantity throws StateError', () async {
      expect(
        () => repository.executeOrder(
          symbol: 'WIPRO',
          side: OrderSide.sell,
          quantity: 5,
          price: Money.fromRupees(500),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
