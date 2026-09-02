import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../ticket/providers/trading_providers.dart';
import '../providers/holdings_providers.dart';

class PortfolioSummaryCard extends ConsumerWidget {
  const PortfolioSummaryCard({super.key});

  void _showWalletSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Manage Virtual Funds',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Add mock paper trading capital or reset your balance:',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          Haptics.heavy();
                          await ref
                              .read(tradingRepositoryProvider)
                              .depositFunds(Money.fromRupees(50000));
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('+₹50,000 Deposit'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          Haptics.heavy();
                          await ref
                              .read(tradingRepositoryProvider)
                              .depositFunds(Money.fromRupees(100000));
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('+₹1,00,000 Deposit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.loss,
                    side: BorderSide(color: AppColors.loss.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    Haptics.heavy();
                    await ref.read(tradingRepositoryProvider).resetPortfolio();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Reset All to ₹1,00,000 (Clear Data)'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(portfolioSummaryProvider);
    final analytics = ref.watch(portfolioAnalyticsProvider);
    final walletAsync = ref.watch(walletBalanceProvider);
    final wallet = walletAsync.value ?? Money.fromRupees(100000);

    final isGain = summary.isGain;
    final isLoss = summary.isLoss;
    final pnlColor =
        isGain ? AppColors.gain : (isLoss ? AppColors.loss : AppColors.muted);
    final directionGlyph = isGain ? '▲ +' : (isLoss ? '▼ ' : '');

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Label + Manage Funds Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PORTFOLIO VALUE',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHover,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${summary.totalHoldingsCount} ${summary.totalHoldingsCount == 1 ? 'STOCK' : 'STOCKS'}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Haptics.selection();
                      _showWalletSheet(context, ref);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 12, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            'Funds',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Total Current Value (Hero Number)
          Text(
            summary.currentValue.format(),
            style: AppTypography.numericLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 32,
              letterSpacing: -0.5,
              color: AppColors.ink,
            ),
          ),

          const SizedBox(height: 6),

          // Overall Unrealized P&L
          Row(
            children: [
              Text(
                summary.unrealizedPnl.isZero
                    ? '₹0.00 (0.00%)'
                    : '$directionGlyph${summary.unrealizedPnl.format(explicitSign: false)} (${summary.pnlPercentage.abs().toStringAsFixed(2)}%)',
                style: AppTypography.numericMedium.copyWith(
                  color: pnlColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Unrealized P&L',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),

          // Realized P&L & Win Rate Pills (if closed positions exist)
          if (!summary.realizedPnl.isZero || analytics.totalClosedTrades > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (!summary.realizedPnl.isZero)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: summary.realizedPnl.paise > 0
                          ? AppColors.gainTint
                          : AppColors.lossTint,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Realized P&L: ${summary.realizedPnl.paise > 0 ? '+' : ''}${summary.realizedPnl.format()}',
                      style: AppTypography.numericSmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: summary.realizedPnl.paise > 0
                            ? AppColors.gain
                            : AppColors.loss,
                      ),
                    ),
                  ),
                if (!summary.realizedPnl.isZero && analytics.totalClosedTrades > 0)
                  const SizedBox(width: 8),
                if (analytics.totalClosedTrades > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Win Rate: ${analytics.winRatePercentage.toStringAsFixed(0)}% (${analytics.winningTrades}W / ${analytics.losingTrades}L)',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // Sub metrics: Total Invested & Available Cash
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL INVESTED',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.totalInvested.format(),
                      style: AppTypography.numericMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.border,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE CASH',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wallet.format(),
                      style: AppTypography.numericMedium.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
