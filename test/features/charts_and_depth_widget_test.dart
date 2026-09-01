import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/data/feed/market_data_service.dart';
import 'package:kestrel/domain/models/candle_data.dart';
import 'package:kestrel/features/charts/providers/chart_providers.dart';
import 'package:kestrel/features/charts/widgets/technical_chart.dart';
import 'package:kestrel/features/charts/widgets/timeframe_selector.dart';
import 'package:kestrel/features/market_depth/widgets/market_depth_ladder.dart';
import 'package:kestrel/features/ticket/screens/ticket_screen.dart';
import '../../test/data/trading_repository_test.dart';
import 'package:kestrel/features/ticket/providers/trading_providers.dart';

void main() {
  group('Technical Chart & Market Depth Widget Tests', () {
    late MarketDataService marketDataService;
    late FakeTradingRepository fakeTradingRepository;

    setUp(() {
      marketDataService = MarketDataService();
      fakeTradingRepository = FakeTradingRepository();
    });

    tearDown(() {
      marketDataService.dispose();
      fakeTradingRepository.dispose();
    });

    Widget createTestApp(Widget child) {
      return ProviderScope(
        overrides: [
          tradingRepositoryProvider.overrideWithValue(fakeTradingRepository),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('TechnicalChart renders controls, OHLC bar, and custom canvas', (tester) async {
      await tester.pumpWidget(createTestApp(
        const TechnicalChart(symbol: 'RELIANCE'),
      ));
      await tester.pumpAndSettle();

      // Timeframe pills
      expect(find.byType(TimeframeSelector), findsOneWidget);
      expect(find.text('1D'), findsOneWidget);
      expect(find.text('1W'), findsOneWidget);
      expect(find.text('1M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);

      // OHLC items
      expect(find.text('O: '), findsOneWidget);
      expect(find.text('H: '), findsOneWidget);
      expect(find.text('L: '), findsOneWidget);
      expect(find.text('C: '), findsOneWidget);

      // CustomPaint canvas
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('TimeframeSelector switches active timeframe on tap', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TimeframeSelector(symbol: 'TCS'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state is 1D
      expect(container.read(activeTimeframeProvider('TCS')), Timeframe.oneDay);

      // Tap 1W
      await tester.tap(find.byKey(const ValueKey('tf_TCS_1W')));
      await tester.pumpAndSettle();
      expect(container.read(activeTimeframeProvider('TCS')), Timeframe.oneWeek);

      // Tap 1Y
      await tester.tap(find.byKey(const ValueKey('tf_TCS_1Y')));
      await tester.pumpAndSettle();
      expect(container.read(activeTimeframeProvider('TCS')), Timeframe.oneYear);
    });

    testWidgets('MarketDepthLadder renders 5-level Bids vs Asks and spread', (tester) async {
      await tester.pumpWidget(createTestApp(
        const MarketDepthLadder(symbol: 'INFY'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('ORDER BOOK (L2 DEPTH)'), findsOneWidget);
      expect(find.textContaining('Spread: ₹'), findsOneWidget);
      expect(find.text('Bid (₹)'), findsOneWidget);
      expect(find.text('Ask (₹)'), findsOneWidget);
      expect(find.textContaining('Buyers:'), findsOneWidget);
      expect(find.textContaining('Sellers:'), findsOneWidget);
    });

    testWidgets('TicketScreen embeds TechnicalChart and MarketDepthLadder with tab switching', (tester) async {
      await tester.pumpWidget(createTestApp(
        const TicketScreen(symbol: 'RELIANCE'),
      ));
      await tester.pumpAndSettle();

      // TechnicalChart is visible by default
      expect(find.byType(TechnicalChart), findsOneWidget);
      expect(find.text('Technical Chart'), findsOneWidget);
      expect(find.text('L2 Order Book'), findsOneWidget);

      // Order type selectors and sticky button are present
      expect(find.text('MARKET'), findsOneWidget);
      expect(find.text('LIMIT'), findsOneWidget);
      expect(find.text('STOP-LOSS'), findsOneWidget);
      expect(find.textContaining('TOTAL VALUE'), findsOneWidget);

      // Switch to L2 Order Book tab
      await tester.tap(find.text('L2 Order Book'));
      await tester.pumpAndSettle();

      expect(find.byType(MarketDepthLadder), findsOneWidget);
      expect(find.byType(TechnicalChart), findsNothing);
    });
  });
}
