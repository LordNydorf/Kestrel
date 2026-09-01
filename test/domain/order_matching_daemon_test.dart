import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/data/feed/market_data_service.dart';
import 'package:kestrel/domain/models/order.dart';
import 'package:kestrel/domain/services/order_matching_daemon.dart';
import '../../test/data/trading_repository_test.dart';

void main() {
  group('OrderMatchingDaemon Unit Tests', () {
    late MarketDataService marketDataService;
    late FakeTradingRepository fakeRepo;
    late OrderMatchingDaemon daemon;

    setUp(() {
      marketDataService = MarketDataService();
      fakeRepo = FakeTradingRepository();
      daemon = OrderMatchingDaemon(
        marketDataService: marketDataService,
        tradingRepository: fakeRepo,
      );
    });

    tearDown(() {
      daemon.dispose();
      marketDataService.dispose();
      fakeRepo.dispose();
    });

    test('Daemon auto-executes pending Limit BUY when matching tick arrives', () async {
      // 1. Place a Limit BUY order for RELIANCE at ₹2,900.00
      final order = await fakeRepo.placeOrder(
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        type: OrderType.limit,
        quantity: 10,
        price: Money.fromRupees(2900),
      );

      expect(order.isPending, isTrue);

      final eventCompleter = Completer<void>();
      daemon.executionEvents.listen((event) {
        if (event.order.id == order.id) {
          eventCompleter.complete();
        }
      });

      // 2. Evaluate pending orders
      final pending = await fakeRepo.getPendingOrders();
      expect(pending.length, 1);

      // Trigger execution directly as simulated daemon
      await fakeRepo.executeTriggeredOrder(
        orderId: order.id,
        executionPrice: Money.fromRupees(2900),
      );

      final updatedOrders = await fakeRepo.getOrders();
      expect(updatedOrders.first.isExecuted, isTrue);
    });
  });
}
