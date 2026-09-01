import 'package:flutter/foundation.dart';
import '../../core/money/money.dart';

/// Single level in the order book.
@immutable
class DepthLevel {
  final Money price;
  final int quantity;
  final int ordersCount;

  const DepthLevel({
    required this.price,
    required this.quantity,
    this.ordersCount = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepthLevel &&
          runtimeType == other.runtimeType &&
          price == other.price &&
          quantity == other.quantity &&
          ordersCount == other.ordersCount;

  @override
  int get hashCode => Object.hash(price, quantity, ordersCount);

  @override
  String toString() =>
      'DepthLevel(price: $price, qty: $quantity, orders: $ordersCount)';
}

/// Level 2 (L2) market depth snapshot containing Top 5 Bids and Top 5 Asks.
@immutable
class MarketDepth {
  final String symbol;
  final List<DepthLevel> bids;
  final List<DepthLevel> asks;
  final int totalBidQty;
  final int totalAskQty;
  final DateTime timestamp;

  const MarketDepth({
    required this.symbol,
    required this.bids,
    required this.asks,
    required this.totalBidQty,
    required this.totalAskQty,
    required this.timestamp,
  });

  /// The difference between lowest ask and highest bid.
  Money get spread {
    if (bids.isEmpty || asks.isEmpty) return Money.zero;
    final diff = asks.first.price - bids.first.price;
    return diff.isNegative ? Money.zero : diff;
  }

  /// Highest single quantity in either bids or asks (for relative bar width scaling).
  int get maxLevelQty {
    int maxQty = 1;
    for (final b in bids) {
      if (b.quantity > maxQty) maxQty = b.quantity;
    }
    for (final a in asks) {
      if (a.quantity > maxQty) maxQty = a.quantity;
    }
    return maxQty;
  }

  /// Buyer demand percentage [0.0 - 1.0].
  double get buyerRatio {
    final total = totalBidQty + totalAskQty;
    if (total == 0) return 0.5;
    return totalBidQty / total;
  }

  /// Seller supply percentage [0.0 - 1.0].
  double get sellerRatio => 1.0 - buyerRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketDepth &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          listEquals(bids, other.bids) &&
          listEquals(asks, other.asks) &&
          totalBidQty == other.totalBidQty &&
          totalAskQty == other.totalAskQty &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(
        symbol,
        Object.hashAll(bids),
        Object.hashAll(asks),
        totalBidQty,
        totalAskQty,
        timestamp,
      );

  @override
  String toString() =>
      'MarketDepth($symbol, Bids: ${bids.length}, Asks: ${asks.length}, Spread: $spread)';
}
