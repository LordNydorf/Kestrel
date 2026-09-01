import 'dart:math';
import '../../core/money/money.dart';
import '../../domain/models/market_depth.dart';
import 'market_data_service.dart';

/// Service simulating real-time Level 2 (L2) market depth ladders for Kestrel instruments.
class MarketDepthService {
  final MarketDataService _marketDataService;
  final Random _random;

  MarketDepthService(this._marketDataService, [Random? random])
      : _random = random ?? Random();

  /// Generates a [MarketDepth] snapshot for [symbol] at [currentLtp].
  MarketDepth getDepthSnapshot(String symbol, Money currentLtp) {
    final ltpPaise = currentLtp.paise;
    final now = DateTime.now();

    // Spread step: minimum 5 paise, approx 0.05% of price
    final stepPaise = max(5, (ltpPaise * 0.0005).round());

    // Best Bid is slightly below LTP, Best Ask is slightly above LTP
    final bestBidPaise = max(5, ltpPaise - (stepPaise ~/ 2));
    final bestAskPaise = ltpPaise + (stepPaise ~/ 2);

    final bids = <DepthLevel>[];
    final asks = <DepthLevel>[];
    int totalBidQty = 0;
    int totalAskQty = 0;

    for (int i = 0; i < 5; i++) {
      // Bid levels descend
      final bidPrice = Money.fromPaise(max(5, bestBidPaise - (i * stepPaise)));
      final bidQty = (100 + _random.nextInt(1500)) * (5 - i ~/ 2);
      final bidOrders = 1 + _random.nextInt(12);
      bids.add(DepthLevel(
        price: bidPrice,
        quantity: bidQty,
        ordersCount: bidOrders,
      ));
      totalBidQty += bidQty;

      // Ask levels ascend
      final askPrice = Money.fromPaise(bestAskPaise + (i * stepPaise));
      final askQty = (100 + _random.nextInt(1500)) * (5 - i ~/ 2);
      final askOrders = 1 + _random.nextInt(12);
      asks.add(DepthLevel(
        price: askPrice,
        quantity: askQty,
        ordersCount: askOrders,
      ));
      totalAskQty += askQty;
    }

    return MarketDepth(
      symbol: symbol,
      bids: bids,
      asks: asks,
      totalBidQty: totalBidQty,
      totalAskQty: totalAskQty,
      timestamp: now,
    );
  }

  /// Reactive stream of market depth updates driven by live price ticks.
  Stream<MarketDepth> depthStreamFor(String symbol) {
    return _marketDataService.tickStreamFor(symbol).map((tick) {
      return getDepthSnapshot(symbol, tick.ltp);
    });
  }
}
