import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/feed/market_depth_service.dart';
import '../../../domain/models/market_depth.dart';
import '../../market_overview/providers/price_provider.dart';

final marketDepthServiceProvider = Provider<MarketDepthService>((ref) {
  final marketData = ref.watch(marketDataServiceProvider);
  return MarketDepthService(marketData);
});

final marketDepthStreamProvider =
    StreamProvider.family<MarketDepth, String>((ref, symbol) {
  final depthService = ref.watch(marketDepthServiceProvider);
  return depthService.depthStreamFor(symbol);
});

final marketDepthSnapshotProvider =
    Provider.family<MarketDepth, String>((ref, symbol) {
  final depthService = ref.watch(marketDepthServiceProvider);
  final tick = ref.watch(latestTickProvider(symbol));
  return depthService.getDepthSnapshot(symbol, tick.ltp);
});
