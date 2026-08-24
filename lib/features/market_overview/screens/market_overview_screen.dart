import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../ticket/providers/trading_providers.dart';
import '../providers/price_provider.dart';
import '../widgets/price_cell.dart';

/// Market Overview Screen displaying the live ticking 10-stock NSE universe.
class MarketOverviewScreen extends ConsumerWidget {
  const MarketOverviewScreen({super.key});

  void _showStressTestDialog(BuildContext context, WidgetRef ref) {
    final currentRate = ref.read(tickRateControllerProvider);

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feed Speed / Stress Test',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Select simulation tick rate across the 10-symbol universe:',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 20),
                _RateOption(
                  label: '1.0x Normal (1 tick/sec/symbol = 10 ticks/sec)',
                  value: 1.0,
                  currentValue: currentRate,
                  onSelect: (val) {
                    ref.read(tickRateControllerProvider.notifier).setRate(val);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _RateOption(
                  label: '2.5x Fast (25 ticks/sec)',
                  value: 2.5,
                  currentValue: currentRate,
                  onSelect: (val) {
                    ref.read(tickRateControllerProvider.notifier).setRate(val);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 8),
                _RateOption(
                  label: '5.0x Turbo Stress (50 ticks/sec)',
                  value: 5.0,
                  currentValue: currentRate,
                  onSelect: (val) {
                    ref.read(tickRateControllerProvider.notifier).setRate(val);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletBalanceProvider);
    final walletBalance = walletAsync.value ?? Universe.initialWalletBalance;
    final tickRate = ref.watch(tickRateControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'KESTREL',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('Market', style: AppTypography.titleLarge),
          ],
        ),
        actions: [
          // Wallet Balance Header Pill
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(
                  walletBalance.format(),
                  style: AppTypography.numericSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),

          // Speed / Stress Test Toggle
          IconButton(
            icon: Badge(
              label: Text('${tickRate.toStringAsFixed(1)}x'),
              backgroundColor: tickRate > 1.0 ? AppColors.accent : AppColors.muted,
              child: const Icon(Icons.speed, size: 20),
            ),
            tooltip: 'Feed Speed',
            onPressed: () => _showStressTestDialog(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Market Status Subheader
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.gain,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'NSE LIVE FEED',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '10 Instruments',
                    style: AppTypography.labelSmall,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Stocks List (Keyed by symbol for stable diffing)
            Expanded(
              child: ListView.builder(
                itemCount: Universe.all.length,
                itemBuilder: (context, index) {
                  final stock = Universe.all[index];
                  return PriceCell(
                    key: ValueKey('market_stock_${stock.symbol}'),
                    stock: stock,
                    onTap: () {
                      context.push('/ticket', extra: stock);
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

class _RateOption extends StatelessWidget {
  final String label;
  final double value;
  final double currentValue;
  final ValueChanged<double> onSelect;

  const _RateOption({
    required this.label,
    required this.value,
    required this.currentValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = (currentValue - value).abs() < 0.01;

    return Material(
      color: isSelected
          ? AppColors.accent.withValues(alpha: 0.15)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.accent : AppColors.muted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleMedium.copyWith(
                    color: isSelected ? AppColors.ink : AppColors.muted,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
