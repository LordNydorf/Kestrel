import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/symbols.dart';
import '../../../../core/money/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../domain/models/holding.dart';
import '../../market_overview/providers/price_provider.dart';

/// Position Details Bottom Sheet with Quick Actions (Add More / Square Off).
class HoldingDetailSheet extends ConsumerWidget {
  final Holding holding;

  const HoldingDetailSheet({super.key, required this.holding});

  static void show(BuildContext context, Holding holding) {
    Haptics.medium();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => HoldingDetailSheet(holding: holding),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tick = ref.watch(latestTickProvider(holding.symbol));
    final currentPrice = tick.ltp;
    final stock = Universe.bySymbol[holding.symbol];

    final investedValuePaise = (holding.avgCost.paise * holding.quantity).toInt();
    final investedValue = Money.fromPaise(investedValuePaise);

    final currentValuePaise = (currentPrice.paise * holding.quantity).toInt();
    final currentValue = Money.fromPaise(currentValuePaise);

    final pnlPaise = currentValuePaise - investedValuePaise;
    final pnl = Money.fromPaise(pnlPaise);
    final pnlPercent = investedValuePaise > 0
        ? (pnlPaise / investedValuePaise) * 100.0
        : 0.0;
    final isGain = pnlPaise >= 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet Grab Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Symbol, Name & Sector
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    holding.symbol,
                    style: AppTypography.titleLarge.copyWith(color: AppColors.accent),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stock?.name ?? 'NSE Equity', style: AppTypography.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Sector: ${stock?.sector ?? 'General'}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currentPrice.format(),
                      style: AppTypography.numericMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'LTP',
                      style: AppTypography.labelSmall.copyWith(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // P&L Summary Hero Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isGain
                    ? AppColors.gain.withValues(alpha: 0.1)
                    : AppColors.loss.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isGain
                      ? AppColors.gain.withValues(alpha: 0.3)
                      : AppColors.loss.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNREALIZED P&L',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isGain ? AppColors.gain : AppColors.loss,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pnl.format(explicitSign: true),
                        style: AppTypography.numericLarge.copyWith(
                          color: isGain ? AppColors.gain : AppColors.loss,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isGain ? AppColors.gain : AppColors.loss,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${isGain ? '+' : ''}${pnlPercent.toStringAsFixed(2)}%',
                      style: AppTypography.numericSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Position Breakdown Grid
            _DetailRow(label: 'Total Quantity', value: '${holding.quantity} shares'),
            const SizedBox(height: 8),
            _DetailRow(label: 'Average Buy Price', value: holding.avgCost.format()),
            const SizedBox(height: 8),
            _DetailRow(label: 'Total Invested', value: investedValue.format()),
            const SizedBox(height: 8),
            _DetailRow(label: 'Current Value', value: currentValue.format(), isBold: true),

            const SizedBox(height: 24),

            // Quick Actions Buttons Row
            Row(
              children: [
                // Add More (BUY)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Haptics.medium();
                      final router = GoRouter.of(context);
                      Navigator.pop(context);
                      router.push('/ticket/${holding.symbol}');
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add More'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gain,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Square Off / Exit (SELL)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Haptics.heavy();
                      final router = GoRouter.of(context);
                      Navigator.pop(context);
                      router.push('/ticket/${holding.symbol}');
                    },
                    icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                    label: const Text('Square Off'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.loss,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.muted,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: AppTypography.numericSmall.copyWith(
            color: AppColors.ink,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
