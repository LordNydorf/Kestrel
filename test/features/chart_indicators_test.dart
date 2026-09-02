import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/domain/models/candle_data.dart';
import 'package:kestrel/features/charts/painters/candlestick_painter.dart';
import 'package:kestrel/features/charts/providers/chart_providers.dart';
import 'package:kestrel/features/charts/widgets/technical_chart.dart';

void main() {
  group('Technical Chart Indicators Widget Tests', () {
    testWidgets('TechnicalChart renders indicator selector and switches to SMA 20 & Bollinger', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TechnicalChart(symbol: 'RELIANCE'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INDICATOR:'), findsOneWidget);
      expect(find.text('None'), findsOneWidget);
      expect(find.text('SMA 20'), findsOneWidget);
      expect(find.text('Bollinger'), findsOneWidget);

      // Tap SMA 20
      await tester.tap(find.text('SMA 20'));
      await tester.pumpAndSettle();

      // Tap Bollinger
      await tester.tap(find.text('Bollinger'));
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('CandlestickPainter renders without throwing when SMA 20 is active', () {
      final now = DateTime.now();
      final candles = List.generate(
        30,
        (i) => CandleData(
          timestamp: now.add(Duration(minutes: i * 5)),
          open: Money.fromRupees(100 + i),
          high: Money.fromRupees(105 + i),
          low: Money.fromRupees(98 + i),
          close: Money.fromRupees(103 + i),
          volume: 1000,
        ),
      );

      final painter = CandlestickPainter(
        candles: candles,
        indicator: ChartIndicator.sma20,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 200));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });

    test('CandlestickPainter renders without throwing when Bollinger Bands are active', () {
      final now = DateTime.now();
      final candles = List.generate(
        30,
        (i) => CandleData(
          timestamp: now.add(Duration(minutes: i * 5)),
          open: Money.fromRupees(100 + i),
          high: Money.fromRupees(105 + i),
          low: Money.fromRupees(98 + i),
          close: Money.fromRupees(103 + i),
          volume: 1000,
        ),
      );

      final painter = CandlestickPainter(
        candles: candles,
        indicator: ChartIndicator.bollinger,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(400, 200));
      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
