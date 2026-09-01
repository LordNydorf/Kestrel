import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/feed/historical_data_service.dart';
import '../../../domain/models/candle_data.dart';
import '../../market_overview/providers/price_provider.dart';

enum ChartMode {
  candlestick('Candles'),
  line('Line');

  final String label;
  const ChartMode(this.label);
}

/// Provider for the singleton HistoricalDataService.
final historicalDataServiceProvider = Provider<HistoricalDataService>((ref) {
  return const HistoricalDataService();
});

/// State provider for the currently selected timeframe per symbol.
final activeTimeframeProvider =
    StateProvider.family<Timeframe, String>((ref, symbol) {
  return Timeframe.oneDay;
});

/// State provider for chart presentation mode (Candles vs Line).
final chartModeProvider = StateProvider<ChartMode>((ref) {
  return ChartMode.candlestick;
});

/// Provider supplying the real-time reactive candle series for a symbol.
final candlesProvider = Provider.family<List<CandleData>, String>((ref, symbol) {
  final service = ref.watch(historicalDataServiceProvider);
  final timeframe = ref.watch(activeTimeframeProvider(symbol));

  // Live price tick subscription
  final liveTickAsync = ref.watch(priceProvider(symbol));
  final fallbackTick = ref.watch(latestTickProvider(symbol));
  final currentLtp = liveTickAsync.value?.ltp ?? fallbackTick.ltp;

  return service.generateCandles(
    symbol: symbol,
    timeframe: timeframe,
    currentLtp: currentLtp,
  );
});
