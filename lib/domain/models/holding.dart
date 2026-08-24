import 'package:flutter/foundation.dart';
import '../../core/money/money.dart';

@immutable
class Holding {
  final String symbol;
  final int quantity;
  final Money avgCost;
  final DateTime updatedAt;

  const Holding({
    required this.symbol,
    required this.quantity,
    required this.avgCost,
    required this.updatedAt,
  });

  Money get investedValue => avgCost * quantity;

  Money currentValue(Money livePrice) => livePrice * quantity;

  Money unrealizedPnl(Money livePrice) => currentValue(livePrice) - investedValue;

  double unrealizedPnlPercentage(Money livePrice) {
    if (investedValue.isZero || avgCost.isZero) return 0.0;
    return ((livePrice.paise - avgCost.paise) / avgCost.paise) * 100.0;
  }

  factory Holding.fromMap(Map<String, dynamic> map) {
    return Holding(
      symbol: map['symbol'] as String,
      quantity: map['quantity'] as int,
      avgCost: Money.fromPaise(map['avg_cost_paise'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'quantity': quantity,
      'avg_cost_paise': avgCost.paise,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Holding copyWith({
    String? symbol,
    int? quantity,
    Money? avgCost,
    DateTime? updatedAt,
  }) {
    return Holding(
      symbol: symbol ?? this.symbol,
      quantity: quantity ?? this.quantity,
      avgCost: avgCost ?? this.avgCost,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Holding &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          quantity == other.quantity &&
          avgCost == other.avgCost;

  @override
  int get hashCode => Object.hash(symbol, quantity, avgCost);

  @override
  String toString() =>
      'Holding($symbol, qty: $quantity, avgCost: $avgCost, invested: $investedValue)';
}
