import 'package:flutter_test/flutter_test.dart';
import 'package:kestrel/core/money/money.dart';
import 'package:kestrel/data/feed/market_data_service.dart';
import 'package:kestrel/data/feed/market_depth_service.dart';

void main() {
  group('MarketDepthService Unit Tests', () {
    late MarketDataService marketDataService;
    late MarketDepthService depthService;

    setUp(() {
      marketDataService = MarketDataService();
      depthService = MarketDepthService(marketDataService);
    });

    tearDown(() {
      marketDataService.dispose();
    });

    test('Generates valid 5-level Bid and Ask queues', () {
      final ltp = Money.fromPaise(295000);
      final depth = depthService.getDepthSnapshot('RELIANCE', ltp);

      expect(depth.symbol, 'RELIANCE');
      expect(depth.bids.length, 5);
      expect(depth.asks.length, 5);

      // Bids should be strictly descending in price
      for (int i = 0; i < depth.bids.length - 1; i++) {
        expect(depth.bids[i].price >= depth.bids[i + 1].price, isTrue);
      }

      // Asks should be strictly ascending in price
      for (int i = 0; i < depth.asks.length - 1; i++) {
        expect(depth.asks[i].price <= depth.asks[i + 1].price, isTrue);
      }

      // Best Ask >= Best Bid
      expect(depth.asks.first.price >= depth.bids.first.price, isTrue);

      // Volume totals match
      expect(depth.totalBidQty, greaterThan(0));
      expect(depth.totalAskQty, greaterThan(0));
      expect(depth.buyerRatio, inInclusiveRange(0.0, 1.0));
      expect(depth.sellerRatio, inInclusiveRange(0.0, 1.0));
    });
  });
}
