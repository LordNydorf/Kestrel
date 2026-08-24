import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../ticket/providers/trading_providers.dart';
import '../providers/holdings_providers.dart';

class PortfolioSummaryCard extends ConsumerWidget {
  const PortfolioSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(portfolioSummaryProvider);
    final walletAsync = ref.watch(walletBalanceProvider);
    final wallet = walletAsync.value ?? ref.read(walletBalanceProvider).value;

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
          // Header Label
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
                'Overall Returns',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),

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
                      wallet?.format() ?? '₹0.00',
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
