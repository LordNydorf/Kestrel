import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/money.dart';
import '../../../domain/models/holding.dart';
import '../../../domain/services/pnl_calculator.dart';
import '../../market_overview/providers/price_provider.dart';
import '../../ticket/providers/trading_providers.dart';

enum HoldingsSortCriteria {
  pnlDesc('P&L (High → Low)'),
  pnlAsc('P&L (Low → High)'),
  symbolAsc('Symbol (A → Z)'),
  valueDesc('Value (High → Low)');

  final String label;
  const HoldingsSortCriteria(this.label);
}

final holdingsSortCriteriaProvider =
    StateProvider<HoldingsSortCriteria>((ref) => HoldingsSortCriteria.pnlDesc);

/// Reactive stream of user holdings from repository
final holdingsStreamProvider = StreamProvider<List<Holding>>((ref) {
  final repo = ref.watch(tradingRepositoryProvider);
  return repo.watchHoldings();
});

/// Computes snapshot of live prices for all symbols currently in the universe
final universePricesMapProvider = Provider<Map<String, Money>>((ref) {
  // Listen to allTicks stream to re-evaluate on each tick
  final marketData = ref.watch(marketDataServiceProvider);
  ref.watch(allTicksStreamProvider);
  return marketData.allSnapshots;
});

/// Reactive aggregate portfolio summary
final portfolioSummaryProvider = Provider<PortfolioSummary>((ref) {
  final holdingsAsync = ref.watch(holdingsStreamProvider);
  final pricesMap = ref.watch(universePricesMapProvider);

  return holdingsAsync.when(
    data: (holdings) => PnlCalculator.calculateSummary(
      holdings: holdings,
      currentPrices: pricesMap,
    ),
    loading: () => PortfolioSummary.zero,
    error: (e, st) => PortfolioSummary.zero,
  );
});

/// Helper provider to get sorted holdings list
final sortedHoldingsProvider = Provider<AsyncValue<List<Holding>>>((ref) {
  final holdingsAsync = ref.watch(holdingsStreamProvider);
  final sortCriteria = ref.watch(holdingsSortCriteriaProvider);
  final pricesMap = ref.watch(universePricesMapProvider);

  return holdingsAsync.whenData((holdings) {
    final list = List<Holding>.from(holdings);

    switch (sortCriteria) {
      case HoldingsSortCriteria.pnlDesc:
        list.sort((a, b) {
          final priceA = pricesMap[a.symbol] ?? a.avgCost;
          final priceB = pricesMap[b.symbol] ?? b.avgCost;
          final pnlA = (priceA.paise - a.avgCost.paise) * a.quantity;
          final pnlB = (priceB.paise - b.avgCost.paise) * b.quantity;
          return pnlB.compareTo(pnlA);
        });
        break;
      case HoldingsSortCriteria.pnlAsc:
        list.sort((a, b) {
          final priceA = pricesMap[a.symbol] ?? a.avgCost;
          final priceB = pricesMap[b.symbol] ?? b.avgCost;
          final pnlA = (priceA.paise - a.avgCost.paise) * a.quantity;
          final pnlB = (priceB.paise - b.avgCost.paise) * b.quantity;
          return pnlA.compareTo(pnlB);
        });
        break;
      case HoldingsSortCriteria.symbolAsc:
        list.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
      case HoldingsSortCriteria.valueDesc:
        list.sort((a, b) {
          final priceA = pricesMap[a.symbol] ?? a.avgCost;
          final priceB = pricesMap[b.symbol] ?? b.avgCost;
          final valA = priceA.paise * a.quantity;
          final valB = priceB.paise * b.quantity;
          return valB.compareTo(valA);
        });
        break;
    }

    return list;
  });
});
