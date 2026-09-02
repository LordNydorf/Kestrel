import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../market_overview/providers/price_provider.dart';

/// Modal bottom sheet for picking stocks from the 10-symbol universe with instant search.
class StockPickerSheet extends ConsumerStatefulWidget {
  final List<String> existingSymbols;
  final ValueChanged<String> onStockSelected;

  const StockPickerSheet({
    super.key,
    required this.existingSymbols,
    required this.onStockSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required List<String> existingSymbols,
    required ValueChanged<String> onStockSelected,
  }) {
    Haptics.medium();
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StockPickerSheet(
        existingSymbols: existingSymbols,
        onStockSelected: onStockSelected,
      ),
    );
  }

  @override
  ConsumerState<StockPickerSheet> createState() => _StockPickerSheetState();
}

class _StockPickerSheetState extends ConsumerState<StockPickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUniverse = Universe.all.where((stock) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return stock.symbol.toLowerCase().contains(q) ||
          stock.name.toLowerCase().contains(q) ||
          stock.sector.toLowerCase().contains(q);
    }).toList();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.80,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Text(
                    'Add Stocks to Watchlist',
                    style: AppTypography.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${widget.existingSymbols.length}/10 Added',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, size: 18, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Filter by symbol or sector...',
                          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _query = val;
                          });
                        },
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                          });
                        },
                        child: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Universe List
            Flexible(
              child: filteredUniverse.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'No stocks matching "$_query"',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredUniverse.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final stock = filteredUniverse[index];
                        final isAlreadyAdded = widget.existingSymbols.contains(stock.symbol);
                        final tick = ref.watch(latestTickProvider(stock.symbol));

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 4.0,
                          ),
                          title: Row(
                            children: [
                              Text(
                                stock.symbol,
                                style: AppTypography.titleMedium.copyWith(
                                  color: isAlreadyAdded ? AppColors.muted : AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.paper,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  stock.sector,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            stock.name,
                            style: AppTypography.bodySmall.copyWith(
                              color: isAlreadyAdded
                                  ? AppColors.muted.withValues(alpha: 0.5)
                                  : AppColors.muted,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                tick.ltp.format(),
                                style: AppTypography.numericMedium.copyWith(
                                  color: isAlreadyAdded
                                      ? AppColors.muted
                                      : AppColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (isAlreadyAdded)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    'ADDED',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: AppColors.accent,
                                  ),
                                  onPressed: () {
                                    Haptics.selection();
                                    widget.onStockSelected(stock.symbol);
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                          onTap: isAlreadyAdded
                              ? null
                              : () {
                                  Haptics.selection();
                                  widget.onStockSelected(stock.symbol);
                                  Navigator.pop(context);
                                },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
