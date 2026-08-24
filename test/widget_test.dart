import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/app.dart';
import 'package:kestrel/core/constants/symbols.dart';
import 'package:kestrel/features/ticket/providers/trading_providers.dart';
import 'data/trading_repository_test.dart';

void main() {
  testWidgets('MarketOverviewScreen smoke test renders all 10 symbols',
      (WidgetTester tester) async {
    final fakeRepo = FakeTradingRepository();

    // Set a realistic mobile device screen height so all 10 rows are rendered
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tradingRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const KestrelApp(),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & NSE feed tag
    expect(find.text('Market'), findsWidgets);
    expect(find.text('NSE LIVE FEED'), findsOneWidget);

    // Verify all 10 symbols in the universe are rendered
    for (final stock in Universe.all) {
      expect(find.text(stock.symbol), findsOneWidget);
    }
  });
}
