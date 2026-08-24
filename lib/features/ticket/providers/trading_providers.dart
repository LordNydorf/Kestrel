import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/money.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/trading_repository.dart';
import '../../../domain/models/holding.dart';
import '../../../domain/models/order.dart';

final tradingRepositoryProvider = Provider<TradingRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = TradingRepository(db);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final walletBalanceProvider = StreamProvider<Money>((ref) {
  final repo = ref.watch(tradingRepositoryProvider);
  return repo.watchWalletBalance();
});

final holdingsProvider = StreamProvider<List<Holding>>((ref) {
  final repo = ref.watch(tradingRepositoryProvider);
  return repo.watchHoldings();
});

final holdingForSymbolProvider =
    Provider.family<Holding?, String>((ref, symbol) {
  final holdingsAsync = ref.watch(holdingsProvider);
  return holdingsAsync.maybeWhen(
    data: (holdings) {
      try {
        return holdings.firstWhere((h) => h.symbol == symbol);
      } catch (_) {
        return null;
      }
    },
    orElse: () => null,
  );
});

final orderHistoryProvider = StreamProvider<List<Order>>((ref) {
  final repo = ref.watch(tradingRepositoryProvider);
  return repo.watchOrders();
});

class TradingState {
  final bool isExecuting;
  final String? errorMessage;
  final Order? lastExecutedOrder;

  const TradingState({
    this.isExecuting = false,
    this.errorMessage,
    this.lastExecutedOrder,
  });

  TradingState copyWith({
    bool? isExecuting,
    String? errorMessage,
    Order? lastExecutedOrder,
  }) {
    return TradingState(
      isExecuting: isExecuting ?? this.isExecuting,
      errorMessage: errorMessage,
      lastExecutedOrder: lastExecutedOrder ?? this.lastExecutedOrder,
    );
  }
}

class TradingController extends StateNotifier<TradingState> {
  final TradingRepository _repository;

  TradingController(this._repository) : super(const TradingState());

  Future<Order?> executeOrder({
    required String symbol,
    required OrderSide side,
    required int quantity,
    required Money price,
  }) async {
    state = state.copyWith(isExecuting: true, errorMessage: null);
    try {
      final order = await _repository.executeOrder(
        symbol: symbol,
        side: side,
        quantity: quantity,
        price: price,
      );
      state = state.copyWith(
        isExecuting: false,
        lastExecutedOrder: order,
        errorMessage: null,
      );
      return order;
    } catch (e) {
      state = state.copyWith(
        isExecuting: false,
        errorMessage: e.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', ''),
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final tradingControllerProvider =
    StateNotifierProvider<TradingController, TradingState>((ref) {
  final repo = ref.watch(tradingRepositoryProvider);
  return TradingController(repo);
});
