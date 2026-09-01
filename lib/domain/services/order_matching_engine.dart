import 'package:flutter/foundation.dart';
import '../../core/money/money.dart';
import '../../data/feed/price_tick.dart';
import '../models/order.dart';

/// Result of a matched pending order.
@immutable
class OrderMatchResult {
  final Order order;
  final Money executionPrice;
  final DateTime executionTime;

  const OrderMatchResult({
    required this.order,
    required this.executionPrice,
    required this.executionTime,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderMatchResult &&
          runtimeType == other.runtimeType &&
          order == other.order &&
          executionPrice == other.executionPrice &&
          executionTime == other.executionTime;

  @override
  int get hashCode => Object.hash(order, executionPrice, executionTime);

  @override
  String toString() =>
      'OrderMatchResult(${order.id}, price: $executionPrice, @ $executionTime)';
}

/// Pure domain service that evaluates live ticks against open pending orders.
class OrderMatchingEngine {
  const OrderMatchingEngine._();

  /// Evaluates an incoming [tick] against a collection of [pendingOrders].
  ///
  /// Returns a list of [OrderMatchResult] for all orders that meet their trigger criteria.
  static List<OrderMatchResult> evaluateTick({
    required PriceTick tick,
    required List<Order> pendingOrders,
  }) {
    final matched = <OrderMatchResult>[];
    final now = tick.timestamp;

    for (final order in pendingOrders) {
      if (order.status != OrderStatus.pending) continue;
      if (order.symbol != tick.symbol) continue;

      bool isTriggered = false;
      Money execPrice = tick.ltp;

      if (order.type == OrderType.limit) {
        if (order.side == OrderSide.buy) {
          // Limit BUY triggers if current market price drops to or below the limit price
          if (tick.ltp <= order.price) {
            isTriggered = true;
            execPrice = order.price; // Fill at limit price or better
          }
        } else {
          // Limit SELL triggers if current market price rises to or above the limit price
          if (tick.ltp >= order.price) {
            isTriggered = true;
            execPrice = order.price; // Fill at limit price or better
          }
        }
      } else if (order.type == OrderType.stopLoss) {
        final trigger = order.triggerPrice ?? order.price;
        if (order.side == OrderSide.buy) {
          // Stop-Loss BUY triggers if price rises to or above trigger price
          if (tick.ltp >= trigger) {
            isTriggered = true;
            execPrice = tick.ltp;
          }
        } else {
          // Stop-Loss SELL triggers if price drops to or below trigger price
          if (tick.ltp <= trigger) {
            isTriggered = true;
            execPrice = tick.ltp;
          }
        }
      }

      if (isTriggered) {
        matched.add(OrderMatchResult(
          order: order,
          executionPrice: execPrice,
          executionTime: now,
        ));
      }
    }

    return matched;
  }
}
