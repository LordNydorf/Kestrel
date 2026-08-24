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
      // Default initial balance: ₹1,00,000.00
      const defaultPaise = 10000000;
      await db.insert('wallet', {
        'id': 1,
        'balance_paise': defaultPaise,
      });
      return Money.fromPaise(defaultPaise);
    }

    return Money.fromPaise(rows.first['balance_paise'] as int);
  }

  Stream<Money> watchWalletBalance() async* {
    yield await getWalletBalance();
    yield* _walletController.stream;
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

  Future<List<Order>> getOrders() async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      'orders',
      orderBy: 'timestamp DESC',
    );
    return rows.map(Order.fromMap).toList();
  }

  Stream<List<Order>> watchOrders() async* {
    yield await getOrders();
    yield* _ordersController.stream;
  }

  // ---------------------------------------------------------------------------
  // Atomic Order Execution
  // ---------------------------------------------------------------------------

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

    final order = Order(
      id: orderId,
      symbol: symbol,
      side: side,
      quantity: quantity,
      price: price,
      value: orderValue,
      timestamp: now,
    );

    await db.transaction((txn) async {
      // 1. Fetch current wallet balance inside transaction
      final walletRows = await txn.query(
        'wallet',
        where: 'id = 1',
        limit: 1,
      );
      final currentBalancePaise = walletRows.isNotEmpty
          ? walletRows.first['balance_paise'] as int
          : 10000000;

      // 2. Fetch current holding inside transaction
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

        // Debit wallet
        final newBalancePaise = currentBalancePaise - orderValue.paise;
        await txn.update(
          'wallet',
          {'balance_paise': newBalancePaise},
          where: 'id = 1',
        );

        // Upsert holding with weighted average cost
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
        if (quantity > oldQty) {
          throw StateError(
            'Cannot SELL $quantity shares of $symbol (Only $oldQty held).',
          );
        }

        // Credit wallet
        final newBalancePaise = currentBalancePaise + orderValue.paise;
        await txn.update(
          'wallet',
          {'balance_paise': newBalancePaise},
          where: 'id = 1',
        );

        final newQty = oldQty - quantity;
        if (newQty == 0) {
          await txn.delete(
            'holdings',
            where: 'symbol = ?',
            whereArgs: [symbol],
          );
        } else {
          // Average cost remains identical on sale
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

      // 3. Record order in history
      await txn.insert('orders', order.toMap());
    });

    // Notify all active streams
    await _notifyAll();

    return order;
  }

  Future<void> _notifyAll() async {
    final balance = await getWalletBalance();
    _walletController.add(balance);

    final holdings = await getHoldings();
    _holdingsController.add(holdings);

    final orders = await getOrders();
    _ordersController.add(orders);
  }

  void dispose() {
    _walletController.close();
    _holdingsController.close();
    _ordersController.close();
  }
}
