import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/feed/market_data_service.dart';
import '../../../data/feed/price_tick.dart';

/// Global singleton provider for the in-process market-data feed.
final marketDataServiceProvider = Provider<MarketDataService>((ref) {
  final service = MarketDataService();
  service.start();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Fine-grained StreamProvider for a specific stock symbol.
///
/// Ensures only widgets listening to THIS symbol rebuild on an incoming tick.
final priceProvider = StreamProvider.family<PriceTick, String>((ref, symbol) {
  final feed = ref.watch(marketDataServiceProvider);
  return feed.tickStreamFor(symbol);
});

/// Synchronous initial/fallback PriceTick accessor.
final latestTickProvider = Provider.family<PriceTick, String>((ref, symbol) {
  final feed = ref.watch(marketDataServiceProvider);
  return feed.getLatestTick(symbol);
});

/// Simulation tick-rate controller provider (1.0x, 2.5x, 5.0x for stress testing).
final tickRateControllerProvider =
    StateNotifierProvider<TickRateNotifier, double>((ref) {
  final feed = ref.watch(marketDataServiceProvider);
  return TickRateNotifier(feed);
});

class TickRateNotifier extends StateNotifier<double> {
  final MarketDataService _feed;

  TickRateNotifier(this._feed) : super(1.0);

  void setRate(double rate) {
    state = rate;
    _feed.setTickRate(rate);
  }
}
