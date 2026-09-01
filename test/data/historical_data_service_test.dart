import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/data/feed/historical_data_service.dart';
import 'package:kestrel/domain/models/candle_data.dart';

void main() {
  group('HistoricalDataService Unit Tests', () {
    const service = HistoricalDataService();
    final ltp = Money.fromPaise(295000);

    test('Generates correct candle count across all timeframes', () {
      for (final tf in Timeframe.values) {
        final candles = service.generateCandles(
          symbol: 'RELIANCE',
          timeframe: tf,
          currentLtp: ltp,
        );

        expect(candles, isNotEmpty);
        // Assert chronological order (oldest -> newest)
        for (int i = 0; i < candles.length - 1; i++) {
          expect(candles[i].timestamp.isBefore(candles[i + 1].timestamp), isTrue);
        }

        // Assert latest candle closes at current live LTP
        expect(candles.last.close, ltp);

        // Assert validity of each candle (high >= low, high >= open, etc.)
        for (final c in candles) {
          expect(c.high >= c.low, isTrue);
          expect(c.high >= c.open, isTrue);
          expect(c.high >= c.close, isTrue);
          expect(c.low <= c.open, isTrue);
          expect(c.low <= c.close, isTrue);
          expect(c.volume, greaterThan(0));
        }
      }
    });

    test('Deterministic generation: Same symbol and timeframe produces consistent historical points', () {
      final candles1 = service.generateCandles(
        symbol: 'TCS',
        timeframe: Timeframe.oneMonth,
        currentLtp: Money.fromPaise(385000),
      );
      final candles2 = service.generateCandles(
        symbol: 'TCS',
        timeframe: Timeframe.oneMonth,
        currentLtp: Money.fromPaise(385000),
      );

      expect(candles1.length, candles2.length);
      for (int i = 0; i < candles1.length; i++) {
        expect(candles1[i].open, candles2[i].open);
        expect(candles1[i].high, candles2[i].high);
        expect(candles1[i].low, candles2[i].low);
        expect(candles1[i].close, candles2[i].close);
      }
    });
  });
}
