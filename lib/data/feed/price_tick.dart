import 'package:flutter/foundation.dart';
import '../../core/money/money.dart';

/// Direction of price movement relative to the previous tick.
enum TickDirection { up, down, neutral }

/// Immutable snapshot representing a single price tick for a stock.
@immutable
class PriceTick {
  final String symbol;
  final Money ltp;
  final Money prevClose;
  final Money change;
  final double changePercent;
  final TickDirection direction;
  final DateTime timestamp;

  PriceTick({
    required this.symbol,
    required this.ltp,
    required this.prevClose,
    required this.direction,
    DateTime? timestamp,
  })  : change = ltp - prevClose,
        changePercent = prevClose.paise > 0
            ? ((ltp.paise - prevClose.paise) / prevClose.paise) * 100.0
            : 0.0,
        timestamp = timestamp ?? DateTime.now();

  /// Whether the price is positive vs previous close.
  bool get isGain => change.isPositive;

  /// Whether the price is negative vs previous close.
  bool get isLoss => change.isNegative;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceTick &&
          other.symbol == symbol &&
          other.ltp == ltp &&
          other.prevClose == prevClose &&
          other.direction == direction);

  @override
  int get hashCode => Object.hash(symbol, ltp, prevClose, direction);

  @override
  String toString() =>
      'PriceTick($symbol: ${ltp.format()}, change: ${change.format(explicitSign: true)} (${changePercent.toStringAsFixed(2)}%), direction: $direction)';
}
