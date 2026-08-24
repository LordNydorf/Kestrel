import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kestrel/domain/models/order.dart';
import 'package:kestrel/features/ticket/providers/trading_providers.dart';
import 'package:kestrel/features/ticket/screens/order_confirmation_screen.dart';
import 'package:kestrel/features/ticket/screens/ticket_screen.dart';
import '../data/trading_repository_test.dart';

void main() {
  group('Ticket Screen & Order Execution Widget Tests', () {
    late FakeTradingRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeTradingRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    testWidgets('TicketScreen: BUY order calculation -> execute -> confirmation receipt',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final testRouter = GoRouter(
        initialLocation: '/ticket/RELIANCE',
        routes: [
          GoRoute(
            path: '/ticket/:symbol',
            builder: (context, state) {
              final symbol = state.pathParameters['symbol'] ?? 'RELIANCE';
              return TicketScreen(symbol: symbol);
            },
          ),
          GoRoute(
            path: '/order-confirmation',
            builder: (context, state) {
              final order = state.extra as Order;
              return OrderConfirmationScreen(order: order);
            },
          ),
          GoRoute(
            path: '/holdings',
            builder: (context, state) =>
                const Scaffold(body: Text('Holdings Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tradingRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Ticket Screen header & default state
      expect(find.text('Trade RELIANCE'), findsOneWidget);
      expect(find.text('BUY'), findsOneWidget);
      expect(find.text('SELL'), findsOneWidget);

      // 2. Tap '+5' quick chip to increase quantity to 6
      await tester.tap(find.text('+5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('6'), findsOneWidget);

      // 3. Tap Primary Action Button to execute BUY order
      final buyButtonFinder = find.byType(ElevatedButton);
      expect(buyButtonFinder, findsOneWidget);
      await tester.tap(buyButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 4. Verify Order Confirmation Screen receipt is rendered
      expect(find.text('Order Executed'), findsOneWidget);
      expect(find.text('Order Confirmation'), findsOneWidget);
      expect(find.text('View Holdings'), findsOneWidget);
      expect(find.text('Back to Market'), findsOneWidget);

      // 5. Tap 'View Holdings' navigation button
      await tester.tap(find.text('View Holdings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Holdings Screen'), findsOneWidget);
    });

    testWidgets('TicketScreen: SELL toggle with 0 holdings displays validation warning',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tradingRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: TicketScreen(symbol: 'TCS'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to SELL tab
      await tester.tap(find.byKey(const ValueKey('tab_sell')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify validation warning banner
      expect(find.textContaining('No holdings available to sell'),
          findsOneWidget);

      // Verify Primary Button is disabled
      final sellButton =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(sellButton.onPressed, isNull);
    });
  });
}
