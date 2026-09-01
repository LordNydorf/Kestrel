import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/holding.dart';
import 'package:kestrel/domain/models/order.dart';
import 'package:kestrel/data/repositories/trading_repository.dart';

/// Pure In-Memory FakeTradingRepository implementing TradingRepository contract.
class FakeTradingRepository implements TradingRepository {
  Money _wallet = Money.fromRupees(100000); // Initial ₹1,00,000.00
  Money _lockedWallet = Money.zero;
  final Map<String, Holding> _holdings = {};
  final List<Order> _orders = [];

  final StreamController<Money> _walletController =
      StreamController<Money>.broadcast();
  final StreamController<Money> _lockedWalletController =
      StreamController<Money>.broadcast();
  final StreamController<List<Holding>> _holdingsController =
      StreamController<List<Holding>>.broadcast();
  final StreamController<List<Order>> _ordersController =
      StreamController<List<Order>>.broadcast();

  @override
  Future<Money> getWalletBalance() async => _wallet;

  @override
  Future<Money> getLockedBalance() async => _lockedWallet;

  @override
  Stream<Money> watchWalletBalance() async* {
    yield _wallet;
    yield* _walletController.stream;
  }

  @override
  Stream<Money> watchLockedBalance() async* {
    yield _lockedWallet;
    yield* _lockedWalletController.stream;
  }

  @override
  Future<void> depositFunds(Money amount) async {
    _wallet = _wallet + amount;
    _walletController.add(_wallet);
  }

  @override
  Future<void> resetPortfolio() async {
    _wallet = Money.fromRupees(100000);
    _lockedWallet = Money.zero;
    _holdings.clear();
    _orders.clear();
    _walletController.add(_wallet);
    _lockedWalletController.add(_lockedWallet);
    _holdingsController.add([]);
    _ordersController.add([]);
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
  Future<List<Order>> getOrders({OrderStatus? status}) async {
    if (status == null) return List.unmodifiable(_orders);
    return _orders.where((o) => o.status == status).toList();
  }

  @override
  Future<List<Order>> getPendingOrders() async {
    return _orders.where((o) => o.isPending).toList();
  }

  @override
  Stream<List<Order>> watchOrders() async* {
    yield await getOrders();
    yield* _ordersController.stream;
  }

  @override
  Stream<List<Order>> watchPendingOrders() async* {
    yield await getPendingOrders();
    yield* _ordersController.stream.map(
      (list) => list.where((o) => o.isPending).toList(),
    );
  }

  @override
  Future<Order> placeOrder({
    required String symbol,
    required OrderSide side,
    OrderType type = OrderType.market,
    required int quantity,
    required Money price,
    Money? triggerPrice,
  }) async {
    if (type == OrderType.market) {
      return executeOrder(
        symbol: symbol,
        side: side,
        quantity: quantity,
        price: price,
      );
    }

    final orderValue = price * quantity;
    final now = DateTime.now();
    final order = Order(
      id: 'ORD-${now.millisecondsSinceEpoch}',
      symbol: symbol,
      side: side,
      type: type,
      status: OrderStatus.pending,
      quantity: quantity,
      price: price,
      triggerPrice: triggerPrice,
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
      _lockedWallet = _lockedWallet + orderValue;
      _walletController.add(_wallet);
      _lockedWalletController.add(_lockedWallet);
    } else {
      final existing = _holdings[symbol];
      if (existing == null || existing.quantity < quantity) {
        throw StateError('Cannot SELL $quantity shares of $symbol (Insufficient holdings).');
      }
    }

    _orders.insert(0, order);
    _ordersController.add(List.unmodifiable(_orders));
    return order;
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = _orders[index];
    if (!order.isPending) return;

    if (order.side == OrderSide.buy) {
      _wallet = _wallet + order.value;
      _lockedWallet = _lockedWallet - order.value;
      _walletController.add(_wallet);
      _lockedWalletController.add(_lockedWallet);
    }

    _orders[index] = order.copyWith(status: OrderStatus.cancelled);
    _ordersController.add(List.unmodifiable(_orders));
  }

  @override
  Future<void> executeTriggeredOrder({
    required String orderId,
    required Money executionPrice,
  }) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;
    final order = _orders[index];
    if (!order.isPending) return;

    final now = DateTime.now();
    final actualValue = executionPrice * order.quantity;
    var realizedPnl = Money.zero;

    if (order.side == OrderSide.buy) {
      _lockedWallet = _lockedWallet - order.value;
      final existing = _holdings[order.symbol];
      if (existing == null) {
        _holdings[order.symbol] = Holding(
          symbol: order.symbol,
          quantity: order.quantity,
          avgCost: executionPrice,
          updatedAt: now,
        );
      } else {
        final newQty = existing.quantity + order.quantity;
        final totalCostPaise = existing.investedValue.paise + actualValue.paise;
        final newAvgCostPaise = (totalCostPaise / newQty).round();
        _holdings[order.symbol] = Holding(
          symbol: order.symbol,
          quantity: newQty,
          avgCost: Money.fromPaise(newAvgCostPaise),
          updatedAt: now,
        );
      }
      _lockedWalletController.add(_lockedWallet);
    } else {
      final existing = _holdings[order.symbol]!;
      realizedPnl = (executionPrice - existing.avgCost) * order.quantity;
      _wallet = _wallet + actualValue;
      final newQty = existing.quantity - order.quantity;
      if (newQty <= 0) {
        _holdings.remove(order.symbol);
      } else {
        _holdings[order.symbol] = existing.copyWith(
          quantity: newQty,
          updatedAt: now,
        );
      }
      _walletController.add(_wallet);
    }

    _orders[index] = order.copyWith(
      status: OrderStatus.executed,
      price: executionPrice,
      value: actualValue,
      realizedPnl: realizedPnl,
      executedAt: now,
    );

    _holdingsController.add(await getHoldings());
    _ordersController.add(List.unmodifiable(_orders));
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
    var realizedPnl = Money.zero;

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

      realizedPnl = (price - existing.avgCost) * quantity;
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

    final order = Order(
      id: 'ORD-${now.millisecondsSinceEpoch}',
      symbol: symbol,
      side: side,
      type: OrderType.market,
      status: OrderStatus.executed,
      quantity: quantity,
      price: price,
      value: orderValue,
      realizedPnl: realizedPnl,
      timestamp: now,
      executedAt: now,
    );

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
    _lockedWalletController.close();
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
      await repository.executeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        quantity: 10,
        price: Money.fromRupees(2500),
      );

      await repository.executeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        quantity: 10,
        price: Money.fromRupees(3000),
      );

      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(45000));

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
          quantity: 100,
          price: Money.fromRupees(3500),
        ),
        throwsA(isA<StateError>()),
      );

      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(100000));
    });

    test('Execute partial SELL credits wallet and preserves average cost', () async {
      await repository.executeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        quantity: 20,
        price: Money.fromRupees(2750),
      );

      final sellOrder = await repository.executeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.sell,
        quantity: 5,
        price: Money.fromRupees(3200),
      );

      expect(sellOrder.value, Money.fromRupees(16000));
      expect(sellOrder.realizedPnl, Money.fromRupees(2250)); // (3200 - 2750) * 5 = +₹2,250

      final wallet = await repository.getWalletBalance();
      expect(wallet, Money.fromRupees(61000));

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
