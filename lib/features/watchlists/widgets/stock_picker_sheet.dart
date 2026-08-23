import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../market_overview/providers/price_provider.dart';

/// Modal bottom sheet for picking stocks from the 10-symbol universe.
class StockPickerSheet extends ConsumerWidget {
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
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StockPickerSheet(
        existingSymbols: existingSymbols,
        onStockSelected: onStockSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                    'Add Stocks',
                    style: AppTypography.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${existingSymbols.length}/10 in Watchlist',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Universe List
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: Universe.all.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final stock = Universe.all[index];
                  final isAlreadyAdded = existingSymbols.contains(stock.symbol);
                  final tick = ref.watch(latestTickProvider(stock.symbol));

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 4.0,
                    ),
                    title: Text(
                      stock.symbol,
                      style: AppTypography.titleMedium.copyWith(
                        color: isAlreadyAdded ? AppColors.muted : AppColors.ink,
                      ),
                    ),
                    subtitle: Text(
                      stock.name,
                      style: AppTypography.bodyMedium.copyWith(
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
                              Icons.add_circle_outline,
                              color: AppColors.accent,
                            ),
                            onPressed: () {
                              onStockSelected(stock.symbol);
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                    onTap: isAlreadyAdded
                        ? null
                        : () {
                            onStockSelected(stock.symbol);
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
