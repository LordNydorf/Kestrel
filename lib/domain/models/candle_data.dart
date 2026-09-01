import 'package:flutter/foundation.dart';
import '../../core/money/money.dart';

/// Supported chart timeframe resolutions.
enum Timeframe {
  oneDay('1D', '1 Day', Duration(days: 1)),
  oneWeek('1W', '1 Week', Duration(days: 7)),
  oneMonth('1M', '1 Month', Duration(days: 30)),
  oneYear('1Y', '1 Year', Duration(days: 365)),
  all('ALL', 'All Time', Duration(days: 1825));

  final String label;
  final String description;
  final Duration duration;

  const Timeframe(this.label, this.description, this.duration);
}

/// Immutable domain model representing an OHLC (Open, High, Low, Close) candlestick bar.
@immutable
class CandleData {
  final Money open;
  final Money high;
  final Money low;
  final Money close;
  final int volume;
  final DateTime timestamp;

  const CandleData({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.timestamp,
  })  : assert(high >= low, 'High price must be greater than or equal to Low price'),
        assert(high >= open && high >= close, 'High must be the peak price'),
        assert(low <= open && low <= close, 'Low must be the floor price');

  bool get isBullish => close >= open;
  bool get isBearish => close < open;

  /// Absolute price difference between high and low.
  Money get range => high - low;

  /// Absolute price difference between open and close.
  Money get bodyHeight => (close - open).abs();

  /// Signed price change from open to close.
  Money get change => close - open;

  /// Percentage change from open to close.
  double get changePercent =>
      open.isZero ? 0.0 : ((close.paise - open.paise) / open.paise) * 100.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CandleData &&
          runtimeType == other.runtimeType &&
          open == other.open &&
          high == other.high &&
          low == other.low &&
          close == other.close &&
          volume == other.volume &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(open, high, low, close, volume, timestamp);

  @override
  String toString() =>
      'CandleData(O: $open, H: $high, L: $low, C: $close, Vol: $volume, @ $timestamp)';
}
