import 'dart:math';
import '../../core/constants/symbols.dart';
import '../../core/money/money.dart';
import '../../domain/models/candle_data.dart';

/// Service providing synthetic, deterministic multi-timeframe OHLC historical series.
class HistoricalDataService {
  const HistoricalDataService();

  /// Generates a list of [CandleData] bars connecting smoothly to [currentLtp].
  List<CandleData> generateCandles({
    required String symbol,
    required Timeframe timeframe,
    required Money currentLtp,
  }) {
    final stock = Universe.bySymbol[symbol] ?? Universe.reliance;
    final basePricePaise = stock.startingPrice.paise;
    final livePaise = currentLtp.paise;

    final barConfig = _getConfig(timeframe);
    final count = barConfig.count;
    final interval = barConfig.interval;

    // Use deterministic random generator seeded by symbol & timeframe
    final seed = symbol.hashCode ^ timeframe.index ^ 42;
    final random = Random(seed);

    final now = DateTime.now();
    final candles = <CandleData>[];

    // Volatility multiplier per sector
    double volatility = 0.008;
    if (stock.sector.contains('Banking')) {
      volatility = 0.012;
    } else if (stock.sector.contains('Technology')) {
      volatility = 0.010;
    } else if (stock.sector.contains('Consumer')) {
      volatility = 0.005;
    }

    // Adjust volatility by timeframe
    switch (timeframe) {
      case Timeframe.oneDay:
        volatility *= 0.4;
        break;
      case Timeframe.oneWeek:
        volatility *= 0.8;
        break;
      case Timeframe.oneMonth:
        volatility *= 1.2;
        break;
      case Timeframe.oneYear:
        volatility *= 2.0;
        break;
      case Timeframe.all:
        volatility *= 3.0;
        break;
    }

    // Generate random walk backward from current price
    var walkPaise = livePaise.toDouble();
    final generatedCloses = <double>[walkPaise];

    for (int i = 1; i < count; i++) {
      // Mean reversion pull toward base starting price
      final drift = (basePricePaise - walkPaise) * 0.02;
      final changePct = ((random.nextDouble() * 2) - 1) * volatility;
      walkPaise = max(100.0, walkPaise - (walkPaise * changePct) - drift);
      generatedCloses.add(walkPaise);
    }

    // Reverse so chronologically ordered from oldest to newest
    final closesChronological = generatedCloses.reversed.toList();

    for (int i = 0; i < count; i++) {
      final isLast = (i == count - 1);
      final closePaise = isLast ? livePaise : closesChronological[i].round();
      final openPaise = (i == 0)
          ? (closePaise * (1.0 + ((random.nextDouble() * 0.004) - 0.002))).round()
          : closesChronological[i - 1].round();

      final highMultiplier = 1.0 + (random.nextDouble() * volatility * 0.7);
      final lowMultiplier = 1.0 - (random.nextDouble() * volatility * 0.7);

      final highPaise = max(
        max(openPaise, closePaise),
        (max(openPaise, closePaise) * highMultiplier).round(),
      );
      final lowPaise = max(
        100,
        min(
          min(openPaise, closePaise),
          (min(openPaise, closePaise) * lowMultiplier).round(),
        ),
      );

      final volume = 500 + random.nextInt(9500);
      final barTime = now.subtract(interval * (count - 1 - i));

      candles.add(CandleData(
        open: Money.fromPaise(openPaise),
        high: Money.fromPaise(highPaise),
        low: Money.fromPaise(lowPaise),
        close: Money.fromPaise(closePaise),
        volume: volume,
        timestamp: barTime,
      ));
    }

    return candles;
  }

  _TimeframeConfig _getConfig(Timeframe tf) {
    switch (tf) {
      case Timeframe.oneDay:
        return const _TimeframeConfig(count: 60, interval: Duration(minutes: 5));
      case Timeframe.oneWeek:
        return const _TimeframeConfig(count: 40, interval: Duration(hours: 3));
      case Timeframe.oneMonth:
        return const _TimeframeConfig(count: 30, interval: Duration(days: 1));
      case Timeframe.oneYear:
        return const _TimeframeConfig(count: 52, interval: Duration(days: 7));
      case Timeframe.all:
        return const _TimeframeConfig(count: 60, interval: Duration(days: 30));
    }
  }
}

class _TimeframeConfig {
  final int count;
  final Duration interval;

  const _TimeframeConfig({required this.count, required this.interval});
}
