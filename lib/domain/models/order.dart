import 'package:flutter/foundation.dart';
import '../../core/money/money.dart';

enum OrderSide {
  buy,
  sell;

  String get label => this == OrderSide.buy ? 'BUY' : 'SELL';
}

@immutable
class Order {
  final String id;
  final String symbol;
  final OrderSide side;
  final int quantity;
  final Money price;
  final Money value;
  final DateTime timestamp;

  const Order({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.price,
    required this.value,
    required this.timestamp,
  });

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String,
      symbol: map['symbol'] as String,
      side: (map['side'] as String).toLowerCase() == 'buy'
          ? OrderSide.buy
          : OrderSide.sell,
      quantity: map['quantity'] as int,
      price: Money.fromPaise(map['price_paise'] as int),
      value: Money.fromPaise(map['value_paise'] as int),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol': symbol,
      'side': side.name.toUpperCase(),
      'quantity': quantity,
      'price_paise': price.paise,
      'value_paise': value.paise,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          symbol == other.symbol &&
          side == other.side &&
          quantity == other.quantity &&
          price == other.price &&
          value == other.value &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(id, symbol, side, quantity, price, value, timestamp);

  @override
  String toString() =>
      'Order($id, $symbol, ${side.label}, qty: $quantity, price: $price, val: $value)';
}
