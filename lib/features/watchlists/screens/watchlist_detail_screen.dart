import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/watchlist_providers.dart';
import '../widgets/stock_picker_sheet.dart';
import '../widgets/watchlist_row.dart';

/// Screen displaying the reorderable stocks within a specific watchlist.
class WatchlistDetailScreen extends ConsumerWidget {
  final int watchlistId;

  const WatchlistDetailScreen({
    super.key,
    required this.watchlistId,
  });

  void _openStockPicker(BuildContext context, WidgetRef ref, List<String> currentSymbols) {
    StockPickerSheet.show(
      context: context,
      existingSymbols: currentSymbols,
      onStockSelected: (symbol) {
        ref.read(watchlistControllerProvider.notifier).addStock(watchlistId, symbol);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlistAsync = ref.watch(watchlistDetailProvider(watchlistId));

    return watchlistAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error loading watchlist: $err')),
      ),
      data: (watchlist) {
        if (watchlist == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Watchlist not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(watchlist.name, style: AppTypography.titleLarge),
                Text(
                  '${watchlist.stockCount} ${watchlist.stockCount == 1 ? 'Instrument' : 'Instruments'}',
                  style: AppTypography.labelSmall,
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.accent),
                tooltip: 'Add Stocks',
                onPressed: () =>
                    _openStockPicker(context, ref, watchlist.symbols),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: watchlist.symbols.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.add_chart_rounded,
                              size: 40,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Stocks Added',
                            style: AppTypography.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add stocks from the 10 NSE instruments universe to monitor live prices in this list.',
                            style: AppTypography.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _openStockPicker(
                                context, ref, watchlist.symbols),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Stocks'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: watchlist.symbols.length,
                    onReorder: (oldIndex, newIndex) {
                      final updated = List<String>.from(watchlist.symbols);
                      if (oldIndex < newIndex) {
                        newIndex -= 1;
                      }
                      final item = updated.removeAt(oldIndex);
                      updated.insert(newIndex, item);

                      ref
                          .read(watchlistControllerProvider.notifier)
                          .reorderStocks(watchlistId, updated);
                    },
                    itemBuilder: (context, index) {
                      final symbol = watchlist.symbols[index];

                      return WatchlistRow(
                        key: ValueKey('wl_${watchlist.id}_$symbol'),
                        symbol: symbol,
                        index: index,
                        onTap: () {
                          context.push('/ticket/$symbol');
                        },
                        onRemove: () {
                          ref
                              .read(watchlistControllerProvider.notifier)
                              .removeStock(watchlistId, symbol);
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
