import 'package:flutter/foundation.dart';
import '../../core/money/money.dart';

enum OrderSide {
  buy,
  sell;

  String get label => this == OrderSide.buy ? 'BUY' : 'SELL';
}

enum OrderType {
  market('MARKET', 'Market Order'),
  limit('LIMIT', 'Limit Order'),
  stopLoss('STOP_LOSS', 'Stop-Loss Order');

  final String code;
  final String label;

  const OrderType(this.code, this.label);

  static OrderType fromString(String? val) {
    if (val == null) return OrderType.market;
    final normalized = val.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
    for (final type in OrderType.values) {
      if (type.code == normalized || type.name.toUpperCase() == normalized) {
        return type;
      }
    }
    return OrderType.market;
  }
}

enum OrderStatus {
  pending('PENDING', 'Pending Trigger'),
  executed('EXECUTED', 'Executed'),
  cancelled('CANCELLED', 'Cancelled'),
  rejected('REJECTED', 'Rejected');

  final String code;
  final String label;

  const OrderStatus(this.code, this.label);

  static OrderStatus fromString(String? val) {
    if (val == null) return OrderStatus.executed;
    final normalized = val.toUpperCase();
    for (final status in OrderStatus.values) {
      if (status.code == normalized || status.name.toUpperCase() == normalized) {
        return status;
      }
    }
    return OrderStatus.executed;
  }
}

@immutable
class Order {
  final String id;
  final String symbol;
  final OrderSide side;
  final OrderType type;
  final OrderStatus status;
  final int quantity;
  final Money price;
  final Money? triggerPrice;
  final Money value;
  final Money realizedPnl;
  final DateTime timestamp;
  final DateTime? executedAt;

  const Order({
    required this.id,
    required this.symbol,
    required this.side,
    this.type = OrderType.market,
    this.status = OrderStatus.executed,
    required this.quantity,
    required this.price,
    this.triggerPrice,
    required this.value,
    this.realizedPnl = Money.zero,
    required this.timestamp,
    this.executedAt,
  });

  bool get isPending => status == OrderStatus.pending;
  bool get isExecuted => status == OrderStatus.executed;
  bool get isCancelled => status == OrderStatus.cancelled;

  factory Order.fromMap(Map<String, dynamic> map) {
    final sideStr = (map['side'] as String?)?.toLowerCase() ?? 'buy';
    final typeStr = map['type'] as String?;
    final statusStr = map['status'] as String?;

    return Order(
      id: map['id'] as String,
      symbol: map['symbol'] as String,
      side: sideStr == 'buy' ? OrderSide.buy : OrderSide.sell,
      type: OrderType.fromString(typeStr),
      status: OrderStatus.fromString(statusStr),
      quantity: map['quantity'] as int,
      price: Money.fromPaise(map['price_paise'] as int? ?? 0),
      triggerPrice: map['trigger_price_paise'] != null
          ? Money.fromPaise(map['trigger_price_paise'] as int)
          : null,
      value: Money.fromPaise(map['value_paise'] as int? ?? 0),
      realizedPnl: Money.fromPaise(map['realized_pnl_paise'] as int? ?? 0),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      executedAt: map['executed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['executed_at'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol': symbol,
      'side': side.name.toUpperCase(),
      'type': type.code,
      'status': status.code,
      'quantity': quantity,
      'price_paise': price.paise,
      'trigger_price_paise': triggerPrice?.paise,
      'value_paise': value.paise,
      'realized_pnl_paise': realizedPnl.paise,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'executed_at': executedAt?.millisecondsSinceEpoch,
    };
  }

  Order copyWith({
    String? id,
    String? symbol,
    OrderSide? side,
    OrderType? type,
    OrderStatus? status,
    int? quantity,
    Money? price,
    Money? triggerPrice,
    Money? value,
    Money? realizedPnl,
    DateTime? timestamp,
    DateTime? executedAt,
  }) {
    return Order(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      side: side ?? this.side,
      type: type ?? this.type,
      status: status ?? this.status,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      triggerPrice: triggerPrice ?? this.triggerPrice,
      value: value ?? this.value,
      realizedPnl: realizedPnl ?? this.realizedPnl,
      timestamp: timestamp ?? this.timestamp,
      executedAt: executedAt ?? this.executedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          symbol == other.symbol &&
          side == other.side &&
          type == other.type &&
          status == other.status &&
          quantity == other.quantity &&
          price == other.price &&
          triggerPrice == other.triggerPrice &&
          value == other.value &&
          realizedPnl == other.realizedPnl &&
          timestamp == other.timestamp &&
          executedAt == other.executedAt;

  @override
  int get hashCode => Object.hash(
        id,
        symbol,
        side,
        type,
        status,
        quantity,
        price,
        triggerPrice,
        value,
        realizedPnl,
        timestamp,
        executedAt,
      );

  @override
  String toString() =>
      'Order($id, $symbol, ${side.label}, ${type.code}, ${status.code}, qty: $quantity, price: $price, val: $value)';
}
