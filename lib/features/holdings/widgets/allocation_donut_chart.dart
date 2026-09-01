import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/services/pnl_calculator.dart';
import '../../ticket/providers/trading_providers.dart';
import '../painters/allocation_donut_painter.dart';
import '../providers/holdings_providers.dart';

class AllocationDonutChart extends ConsumerWidget {
  const AllocationDonutChart({super.key});

  static const List<Color> _palette = [
    Color(0xFF3B82F6), // Electric Blue
    Color(0xFF10B981), // Emerald
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFF64748B), // Slate
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(holdingsProvider).value ?? [];
    final currentPrices = ref.watch(universePricesMapProvider);
    final wallet = ref.watch(walletBalanceProvider).value ?? Money.zero;

    final allocations = PnlCalculator.calculateSectorAllocation(
      holdings: holdings,
      currentPrices: currentPrices,
      availableCash: wallet,
    );

    if (allocations.isEmpty) return const SizedBox.shrink();

    // Total Portfolio Value (Holdings + Cash)
    int totalPaise = wallet.paise;
    for (final h in holdings) {
      final price = currentPrices[h.symbol] ?? h.avgCost;
      totalPaise += (price.paise * h.quantity).toInt();
    }
    final totalPortfolioValue = Money.fromPaise(totalPaise);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ASSET ALLOCATION',
            style: AppTypography.labelSmall.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 16),

          // Donut Chart with Center Total Value
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(140, 140),
                    painter: AllocationDonutPainter(
                      allocations: allocations,
                      colors: _palette,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TOTAL',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        totalPortfolioValue.format(showSymbol: false),
                        style: AppTypography.numericSmall.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Legend breakdown
          for (int i = 0; i < allocations.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _palette[i % _palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      allocations[i].sector,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    allocations[i].value.format(),
                    style: AppTypography.numericSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
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
                      '${allocations[i].percentage.toStringAsFixed(1)}%',
                      style: AppTypography.numericSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
