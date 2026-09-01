import 'dart:async';
import 'dart:math';
import '../../core/money/money.dart';
import '../../domain/models/holding.dart';
import '../../domain/models/order.dart';
import '../db/app_database.dart';

class TradingRepository {
  final AppDatabase _appDatabase;
  final StreamController<Money> _walletController =
      StreamController<Money>.broadcast();
  final StreamController<Money> _lockedWalletController =
      StreamController<Money>.broadcast();
  final StreamController<List<Holding>> _holdingsController =
      StreamController<List<Holding>>.broadcast();
  final StreamController<List<Order>> _ordersController =
      StreamController<List<Order>>.broadcast();

  TradingRepository(this._appDatabase);

  // ---------------------------------------------------------------------------
  // Wallet
  // ---------------------------------------------------------------------------

  Future<Money> getWalletBalance() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'wallet',
      where: 'id = 1',
      limit: 1,
    );

    if (rows.isEmpty) {
      const defaultPaise = 10000000; // ₹1,00,000.00
      await db.insert('wallet', {
        'id': 1,
        'balance_paise': defaultPaise,
        'locked_paise': 0,
      });
      return Money.fromPaise(defaultPaise);
    }

    return Money.fromPaise(rows.first['balance_paise'] as int);
  }

  Future<Money> getLockedBalance() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'wallet',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) return Money.zero;
    return Money.fromPaise(rows.first['locked_paise'] as int? ?? 0);
  }

  Stream<Money> watchWalletBalance() async* {
    yield await getWalletBalance();
    yield* _walletController.stream;
  }

  Stream<Money> watchLockedBalance() async* {
    yield await getLockedBalance();
    yield* _lockedWalletController.stream;
  }

  Future<void> depositFunds(Money amount) async {
    if (amount.isZero || amount.paise < 0) return;
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      final rows = await txn.query('wallet', where: 'id = 1', limit: 1);
      final current = rows.isNotEmpty ? rows.first['balance_paise'] as int : 10000000;
      await txn.update(
        'wallet',
        {'balance_paise': current + amount.paise},
        where: 'id = 1',
      );
    });
    await _notifyAll();
  }

  Future<void> resetPortfolio() async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.update(
        'wallet',
        {
          'balance_paise': 10000000,
          'locked_paise': 0,
        },
        where: 'id = 1',
      );
      await txn.delete('holdings');
      await txn.delete('orders');
    });
    await _notifyAll();
  }

  // ---------------------------------------------------------------------------
  // Holdings
  // ---------------------------------------------------------------------------

  Future<List<Holding>> getHoldings() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'holdings',
      where: 'quantity > 0',
      orderBy: 'symbol ASC',
    );
    return rows.map(Holding.fromMap).toList();
  }

  Future<Holding?> getHoldingBySymbol(String symbol) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'holdings',
      where: 'symbol = ?',
      whereArgs: [symbol],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Holding.fromMap(rows.first);
  }

  Stream<List<Holding>> watchHoldings() async* {
    yield await getHoldings();
    yield* _holdingsController.stream;
  }

  // ---------------------------------------------------------------------------
  // Orders
  // ---------------------------------------------------------------------------

  Future<List<Order>> getOrders({OrderStatus? status}) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'orders',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status.code] : null,
      orderBy: 'timestamp DESC',
    );
    return rows.map(Order.fromMap).toList();
  }

  Future<List<Order>> getPendingOrders() async {
    return getOrders(status: OrderStatus.pending);
  }

  Stream<List<Order>> watchOrders() async* {
    yield await getOrders();
    yield* _ordersController.stream;
  }

  Stream<List<Order>> watchPendingOrders() async* {
    yield await getPendingOrders();
    yield* _ordersController.stream.map(
      (list) => list.where((o) => o.isPending).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Order Placement & Execution
  // ---------------------------------------------------------------------------

  Future<Order> placeOrder({
    required String symbol,
    required OrderSide side,
    OrderType type = OrderType.market,
    required int quantity,
    required Money price,
    Money? triggerPrice,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Order quantity must be greater than zero.');
    }
    if (price.isZero || price.paise < 0) {
      throw ArgumentError('Order price must be greater than zero.');
    }

    if (type == OrderType.market) {
      return executeOrder(
        symbol: symbol,
        side: side,
        quantity: quantity,
        price: price,
      );
    }

    // Limit or Stop-Loss pending order
    final db = await _appDatabase.database;
    final effectivePrice = (type == OrderType.stopLoss && triggerPrice != null)
        ? triggerPrice
        : price;
    final orderValue = effectivePrice * quantity;
    final now = DateTime.now();
    final orderId = 'ORD-${now.millisecondsSinceEpoch}-${1000 + Random().nextInt(9000)}';

    final order = Order(
      id: orderId,
      symbol: symbol,
      side: side,
      type: type,
      status: OrderStatus.pending,
      quantity: quantity,
      price: price,
      triggerPrice: triggerPrice,
      value: orderValue,
      realizedPnl: Money.zero,
      timestamp: now,
    );

    await db.transaction((txn) async {
      final walletRows = await txn.query('wallet', where: 'id = 1', limit: 1);
      final currentBalancePaise =
          walletRows.isNotEmpty ? (walletRows.first['balance_paise'] as int) : 10000000;
      final currentLockedPaise =
          walletRows.isNotEmpty ? (walletRows.first['locked_paise'] as int? ?? 0) : 0;

      final holdingRows = await txn.query(
        'holdings',
        where: 'symbol = ?',
        whereArgs: [symbol],
        limit: 1,
      );

      if (side == OrderSide.buy) {
        if (orderValue.paise > currentBalancePaise) {
          throw StateError(
            'Insufficient wallet balance to place ${type.label}. '
            'Required: $orderValue, Available: ${Money.fromPaise(currentBalancePaise)}',
          );
        }

        // Lock funds
        await txn.update(
          'wallet',
          {
            'balance_paise': currentBalancePaise - orderValue.paise,
            'locked_paise': currentLockedPaise + orderValue.paise,
          },
          where: 'id = 1',
        );
      } else {
        // SELL
        if (holdingRows.isEmpty) {
          throw StateError('Cannot SELL $symbol: No holding found.');
        }
        final heldQty = holdingRows.first['quantity'] as int;
        if (quantity > heldQty) {
          throw StateError('Cannot SELL $quantity shares of $symbol (Only $heldQty held).');
        }
      }

      await txn.insert('orders', order.toMap());
    });

    await _notifyAll();
    return order;
  }

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

    final db = await _appDatabase.database;
    final orderValue = price * quantity;
    final now = DateTime.now();
    final orderId = 'ORD-${now.millisecondsSinceEpoch}-${1000 + Random().nextInt(9000)}';

    var realizedPnl = Money.zero;

    await db.transaction((txn) async {
      final walletRows = await txn.query('wallet', where: 'id = 1', limit: 1);
      final currentBalancePaise =
          walletRows.isNotEmpty ? walletRows.first['balance_paise'] as int : 10000000;

      final holdingRows = await txn.query(
        'holdings',
        where: 'symbol = ?',
        whereArgs: [symbol],
        limit: 1,
      );

      if (side == OrderSide.buy) {
        if (orderValue.paise > currentBalancePaise) {
          throw StateError(
            'Insufficient wallet balance to execute BUY order. '
            'Required: $orderValue, Available: ${Money.fromPaise(currentBalancePaise)}',
          );
        }

        final newBalancePaise = currentBalancePaise - orderValue.paise;
        await txn.update(
          'wallet',
          {'balance_paise': newBalancePaise},
          where: 'id = 1',
        );

        if (holdingRows.isEmpty) {
          await txn.insert('holdings', {
            'symbol': symbol,
            'quantity': quantity,
            'avg_cost_paise': price.paise,
            'updated_at': now.millisecondsSinceEpoch,
          });
        } else {
          final oldQty = holdingRows.first['quantity'] as int;
          final oldAvgCostPaise = holdingRows.first['avg_cost_paise'] as int;
          final newQty = oldQty + quantity;
          final totalCostPaise = (oldQty * oldAvgCostPaise) + (quantity * price.paise);
          final newAvgCostPaise = (totalCostPaise / newQty).round();

          await txn.update(
            'holdings',
            {
              'quantity': newQty,
              'avg_cost_paise': newAvgCostPaise,
              'updated_at': now.millisecondsSinceEpoch,
            },
            where: 'symbol = ?',
            whereArgs: [symbol],
          );
        }
      } else {
        // SELL
        if (holdingRows.isEmpty) {
          throw StateError('Cannot SELL $symbol: No holding found.');
        }

        final oldQty = holdingRows.first['quantity'] as int;
        final avgCostPaise = holdingRows.first['avg_cost_paise'] as int;
        if (quantity > oldQty) {
          throw StateError('Cannot SELL $quantity shares of $symbol (Only $oldQty held).');
        }

        // Realized PnL calculation
        final realizedPaise = (price.paise - avgCostPaise) * quantity;
        realizedPnl = Money.fromPaise(realizedPaise);

        final newBalancePaise = currentBalancePaise + orderValue.paise;
        await txn.update(
          'wallet',
          {'balance_paise': newBalancePaise},
          where: 'id = 1',
        );

        final newQty = oldQty - quantity;
        if (newQty == 0) {
          await txn.delete('holdings', where: 'symbol = ?', whereArgs: [symbol]);
        } else {
          await txn.update(
            'holdings',
            {
              'quantity': newQty,
              'updated_at': now.millisecondsSinceEpoch,
            },
            where: 'symbol = ?',
            whereArgs: [symbol],
          );
        }
      }

      final order = Order(
        id: orderId,
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

      await txn.insert('orders', order.toMap());
    });

    await _notifyAll();

    return Order(
      id: orderId,
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
  }

  Future<void> cancelOrder(String orderId) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      final rows = await txn.query('orders', where: 'id = ?', whereArgs: [orderId]);
      if (rows.isEmpty) return;
      final order = Order.fromMap(rows.first);
      if (!order.isPending) return;

      // If BUY order, release locked funds
      if (order.side == OrderSide.buy) {
        final walletRows = await txn.query('wallet', where: 'id = 1', limit: 1);
        if (walletRows.isNotEmpty) {
          final balance = walletRows.first['balance_paise'] as int;
          final locked = walletRows.first['locked_paise'] as int? ?? 0;
          await txn.update(
            'wallet',
            {
              'balance_paise': balance + order.value.paise,
              'locked_paise': max(0, locked - order.value.paise),
            },
            where: 'id = 1',
          );
        }
      }

      await txn.update(
        'orders',
        {'status': OrderStatus.cancelled.code},
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });

    await _notifyAll();
  }

  Future<void> executeTriggeredOrder({
    required String orderId,
    required Money executionPrice,
  }) async {
    final db = await _appDatabase.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      final rows = await txn.query('orders', where: 'id = ?', whereArgs: [orderId]);
      if (rows.isEmpty) return;
      final order = Order.fromMap(rows.first);
      if (!order.isPending) return;

      final actualValue = executionPrice * order.quantity;
      var realizedPnl = Money.zero;

      if (order.side == OrderSide.buy) {
        final walletRows = await txn.query('wallet', where: 'id = 1', limit: 1);
        final balance = walletRows.isNotEmpty ? (walletRows.first['balance_paise'] as int) : 0;
        final locked = walletRows.isNotEmpty ? (walletRows.first['locked_paise'] as int? ?? 0) : 0;

        // Refund any difference if executed below locked limit price
        final refundPaise = max(0, order.value.paise - actualValue.paise);
        await txn.update(
          'wallet',
          {
            'balance_paise': balance + refundPaise,
            'locked_paise': max(0, locked - order.value.paise),
          },
          where: 'id = 1',
        );

        // Upsert holding
        final holdingRows = await txn.query(
          'holdings',
          where: 'symbol = ?',
          whereArgs: [order.symbol],
          limit: 1,
        );

        if (holdingRows.isEmpty) {
          await txn.insert('holdings', {
            'symbol': order.symbol,
            'quantity': order.quantity,
            'avg_cost_paise': executionPrice.paise,
            'updated_at': now.millisecondsSinceEpoch,
          });
        } else {
          final oldQty = holdingRows.first['quantity'] as int;
          final oldAvgCostPaise = holdingRows.first['avg_cost_paise'] as int;
          final newQty = oldQty + order.quantity;
          final totalCostPaise =
              (oldQty * oldAvgCostPaise) + (order.quantity * executionPrice.paise);
          final newAvgCostPaise = (totalCostPaise / newQty).round();

          await txn.update(
            'holdings',
            {
              'quantity': newQty,
              'avg_cost_paise': newAvgCostPaise,
              'updated_at': now.millisecondsSinceEpoch,
            },
            where: 'symbol = ?',
            whereArgs: [order.symbol],
          );
        }
      } else {
        // SELL
        final holdingRows = await txn.query(
          'holdings',
          where: 'symbol = ?',
          whereArgs: [order.symbol],
          limit: 1,
        );
        if (holdingRows.isNotEmpty) {
          final oldQty = holdingRows.first['quantity'] as int;
          final avgCostPaise = holdingRows.first['avg_cost_paise'] as int;
          final realizedPaise = (executionPrice.paise - avgCostPaise) * order.quantity;
          realizedPnl = Money.fromPaise(realizedPaise);

          final newQty = oldQty - order.quantity;
          if (newQty <= 0) {
            await txn.delete('holdings', where: 'symbol = ?', whereArgs: [order.symbol]);
          } else {
            await txn.update(
              'holdings',
              {
                'quantity': newQty,
                'updated_at': now.millisecondsSinceEpoch,
              },
              where: 'symbol = ?',
              whereArgs: [order.symbol],
            );
          }
        }

        final walletRows = await txn.query('wallet', where: 'id = 1', limit: 1);
        final balance = walletRows.isNotEmpty ? walletRows.first['balance_paise'] as int : 0;
        await txn.update(
          'wallet',
          {'balance_paise': balance + actualValue.paise},
          where: 'id = 1',
        );
      }

      await txn.update(
        'orders',
        {
          'status': OrderStatus.executed.code,
          'price_paise': executionPrice.paise,
          'value_paise': actualValue.paise,
          'realized_pnl_paise': realizedPnl.paise,
          'executed_at': now.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });

    await _notifyAll();
  }

  Future<void> _notifyAll() async {
    final balance = await getWalletBalance();
    _walletController.add(balance);

    final locked = await getLockedBalance();
    _lockedWalletController.add(locked);

    final holdings = await getHoldings();
    _holdingsController.add(holdings);

    final orders = await getOrders();
    _ordersController.add(orders);
  }

  void dispose() {
    _walletController.close();
    _lockedWalletController.close();
    _holdingsController.close();
    _ordersController.close();
  }
}
