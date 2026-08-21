import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/app.dart';
import 'package:kestrel/core/constants/symbols.dart';

void main() {
  testWidgets('MarketOverviewScreen smoke test renders all 10 symbols',
      (WidgetTester tester) async {
    // Set a realistic mobile device screen height so all 10 rows are rendered
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: KestrelApp(),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Title & NSE feed tag
    expect(find.text('KESTREL'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Market'), findsOneWidget);
    expect(find.text('NSE LIVE FEED'), findsOneWidget);

    // Verify all 10 symbols in the universe are rendered
    for (final stock in Universe.all) {
      expect(find.text(stock.symbol), findsOneWidget);
    }
  });
}
