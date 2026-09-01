import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/haptics.dart';
import '../../data/feed/market_data_service.dart';
import '../../data/repositories/trading_repository.dart';
import '../../features/market_overview/providers/price_provider.dart';
import '../../features/ticket/providers/trading_providers.dart';
import 'order_matching_engine.dart';

/// Background daemon that monitors live exchange ticks and auto-executes pending Limit/SL orders.
class OrderMatchingDaemon {
  final MarketDataService _marketDataService;
  final TradingRepository _tradingRepository;
  final StreamController<OrderMatchResult> _executionEventsController =
      StreamController<OrderMatchResult>.broadcast();

  StreamSubscription? _subscription;
  bool _isEvaluating = false;

  OrderMatchingDaemon({
    required MarketDataService marketDataService,
    required TradingRepository tradingRepository,
  })  : _marketDataService = marketDataService,
        _tradingRepository = tradingRepository {
    _startListening();
  }

  Stream<OrderMatchResult> get executionEvents =>
      _executionEventsController.stream;

  void _startListening() {
    _subscription = _marketDataService.allTicks.listen((tick) async {
      if (_isEvaluating) return; // Prevent concurrent re-entry
      _isEvaluating = true;

      try {
        final pendingOrders = await _tradingRepository.getPendingOrders();
        if (pendingOrders.isEmpty) return;

        final matches = OrderMatchingEngine.evaluateTick(
          tick: tick,
          pendingOrders: pendingOrders,
        );

        for (final match in matches) {
          await _tradingRepository.executeTriggeredOrder(
            orderId: match.order.id,
            executionPrice: match.executionPrice,
          );

          Haptics.heavy();
          _executionEventsController.add(match);
        }
      } catch (_) {
        // Silently suppress background execution errors
      } finally {
        _isEvaluating = false;
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _executionEventsController.close();
  }
}

/// Riverpod Provider for the singleton OrderMatchingDaemon.
final orderMatchingDaemonProvider = Provider<OrderMatchingDaemon>((ref) {
  final marketData = ref.watch(marketDataServiceProvider);
  final tradingRepo = ref.watch(tradingRepositoryProvider);

  final daemon = OrderMatchingDaemon(
    marketDataService: marketData,
    tradingRepository: tradingRepo,
  );

  ref.onDispose(() => daemon.dispose());
  return daemon;
});
