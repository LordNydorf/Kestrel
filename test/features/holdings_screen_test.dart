import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kestrel/core/constants/symbols.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/holding.dart';
import 'package:kestrel/features/holdings/screens/holdings_screen.dart';
import 'package:kestrel/features/ticket/providers/trading_providers.dart';
import '../data/trading_repository_test.dart';

void main() {
  group('Holdings & Realtime P&L Widget Tests', () {
    late FakeTradingRepository fakeRepo;

    setUp(() {
      fakeRepo = FakeTradingRepository();
    });

    tearDown(() {
      fakeRepo.dispose();
    });

    testWidgets('HoldingsScreen: empty state displays zero summary & explore button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var navigatedToMarket = false;

      final testRouter = GoRouter(
        initialLocation: '/holdings',
        routes: [
          GoRoute(
            path: '/holdings',
            builder: (context, state) => const HoldingsScreen(),
          ),
          GoRoute(
            path: '/market',
            builder: (context, state) {
              navigatedToMarket = true;
              return const Scaffold(body: Text('Market Screen'));
            },
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

      // Verify Empty State Text
      expect(find.text('No Holdings in Portfolio'), findsOneWidget);
      expect(find.text('0 STOCKS'), findsOneWidget);
      expect(find.text('₹0.00'), findsWidgets);

      // Verify Explore Market button and tap
      final exploreBtn = find.byKey(const ValueKey('explore_market_button'));
      expect(exploreBtn, findsOneWidget);
      await tester.tap(exploreBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(navigatedToMarket, isTrue);
    });

    testWidgets('HoldingsScreen: renders populated holdings & summary metrics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pre-seed holdings in fake repo
      fakeRepo.seedHolding(
        Holding(
          symbol: Universe.reliance.symbol,
          quantity: 10,
          avgCost: Money.fromRupees(2500.00),
          updatedAt: DateTime.now(),
        ),
      );
      fakeRepo.seedHolding(
        Holding(
          symbol: Universe.tcs.symbol,
          quantity: 5,
          avgCost: Money.fromRupees(3500.00),
          updatedAt: DateTime.now(),
        ),
      );

      String? tappedTicketSymbol;

      final testRouter = GoRouter(
        initialLocation: '/holdings',
        routes: [
          GoRoute(
            path: '/holdings',
            builder: (context, state) => const HoldingsScreen(),
          ),
          GoRoute(
            path: '/ticket/:symbol',
            builder: (context, state) {
              tappedTicketSymbol = state.pathParameters['symbol'];
              return Scaffold(body: Text('Ticket: $tappedTicketSymbol'));
            },
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

      // Verify 2 stocks count badge
      expect(find.text('2 STOCKS'), findsOneWidget);

      // Total Invested = (10 * 2500) + (5 * 3500) = 25,000 + 17,500 = ₹42,500.00
      expect(find.text(Money.fromRupees(42500.00).format()), findsOneWidget);

      // Verify Holding Rows exist
      expect(find.byKey(const ValueKey('holding_RELIANCE')), findsOneWidget);
      expect(find.byKey(const ValueKey('holding_TCS')), findsOneWidget);

      // Verify tap opens HoldingDetailSheet
      await tester.tap(find.byKey(const ValueKey('holding_RELIANCE')));
      await tester.pumpAndSettle();

      expect(find.text('UNREALIZED P&L'), findsOneWidget);
      expect(find.text('Add More'), findsOneWidget);
      expect(find.text('Square Off'), findsOneWidget);
    });

    testWidgets('HoldingsScreen: sort menu updates sort criteria',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeRepo.seedHolding(
        Holding(
          symbol: Universe.reliance.symbol,
          quantity: 10,
          avgCost: Money.fromRupees(2500.00),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tradingRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: HoldingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Open sort menu
      await tester.tap(find.byKey(const ValueKey('holdings_sort_menu')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Select 'Symbol (A → Z)'
      await tester.tap(find.text('Symbol (A → Z)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Verify that the screen header label reflects the selected sort
      expect(find.text('Symbol (A → Z)'), findsOneWidget);
    });
  });
}
