import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/order.dart';
import 'package:kestrel/features/orders/screens/orders_screen.dart';
import 'package:kestrel/features/ticket/providers/trading_providers.dart';
import '../../test/data/trading_repository_test.dart';

void main() {
  group('Orders & Activity Screen Widget Tests', () {
    late FakeTradingRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeTradingRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    Widget createTestApp(Widget child) {
      return ProviderScope(
        overrides: [
          tradingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('OrdersScreen: empty state displays explore button', (tester) async {
      await tester.pumpWidget(createTestApp(const OrdersScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Orders & Activity'), findsOneWidget);
      expect(find.text('All Orders'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Executed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('No order activity yet'), findsOneWidget);
      expect(find.text('Explore Market'), findsOneWidget);
    });

    testWidgets('OrdersScreen: renders populated orders and filters by tab', (tester) async {
      final now = DateTime.now();
      fakeRepo.seedOrder(Order(
        id: 'ORD-1',
        symbol: 'RELIANCE',
        side: OrderSide.buy,
        type: OrderType.limit,
        status: OrderStatus.pending,
        quantity: 10,
        price: Money.fromPaise(290000),
        value: Money.fromPaise(2900000),
        timestamp: now,
      ));
      fakeRepo.seedOrder(Order(
        id: 'ORD-2',
        symbol: 'TCS',
        side: OrderSide.sell,
        type: OrderType.market,
        status: OrderStatus.executed,
        quantity: 5,
        price: Money.fromPaise(380000),
        value: Money.fromPaise(1900000),
        realizedPnl: Money.fromPaise(250000),
        timestamp: now,
      ));

      await tester.pumpWidget(createTestApp(const OrdersScreen()));
      await tester.pumpAndSettle();

      // Both orders visible on All tab
      expect(find.text('RELIANCE'), findsOneWidget);
      expect(find.text('TCS'), findsOneWidget);
      expect(find.text('Cancel Order'), findsOneWidget); // Pending order action button

      // Switch to Pending filter tab
      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();

      expect(find.text('RELIANCE'), findsOneWidget);
      expect(find.text('TCS'), findsNothing);

      // Switch to Executed filter tab
      await tester.tap(find.text('Executed'));
      await tester.pumpAndSettle();

      expect(find.text('TCS'), findsOneWidget);
      expect(find.text('RELIANCE'), findsNothing);
    });
  });
}
