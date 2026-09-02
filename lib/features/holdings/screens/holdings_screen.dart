import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/holdings_providers.dart';
import '../widgets/allocation_donut_chart.dart';
import '../widgets/holding_detail_sheet.dart';
import '../widgets/holding_row.dart';
import '../widgets/portfolio_summary_card.dart';

class HoldingsScreen extends ConsumerWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortedHoldingsAsync = ref.watch(sortedHoldingsProvider);
    final sortCriteria = ref.watch(holdingsSortCriteriaProvider);

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: const Text('Holdings & Portfolio'),
        actions: [
          // Sort Menu
          PopupMenuButton<HoldingsSortCriteria>(
            key: const ValueKey('holdings_sort_menu'),
            icon: const Icon(Icons.sort_rounded, color: AppColors.muted),
            color: AppColors.surface,
            tooltip: 'Sort Holdings',
            onSelected: (criteria) {
              ref.read(holdingsSortCriteriaProvider.notifier).state = criteria;
            },
            itemBuilder: (context) => HoldingsSortCriteria.values.map((c) {
              final isSelected = c == sortCriteria;
              return PopupMenuItem<HoldingsSortCriteria>(
                value: c,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.accent)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.label,
                        style: AppTypography.bodyMedium.copyWith(
                          color:
                              isSelected ? AppColors.accent : AppColors.ink,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: sortedHoldingsAsync.when(
        data: (holdings) {
          if (holdings.isEmpty) {
            return Column(
              children: [
                const PortfolioSummaryCard(),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.pie_chart_outline_rounded,
                              size: 48,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Holdings in Portfolio',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You haven\'t purchased any stocks yet. Explore the market universe to place your first trade.',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            key: const ValueKey('explore_market_button'),
                            onPressed: () {
                              context.go('/market');
                            },
                            icon: const Icon(Icons.show_chart_rounded,
                                size: 18),
                            label: const Text('Explore Market'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: PortfolioSummaryCard(),
              ),
              const SliverToBoxAdapter(
                child: AllocationDonutChart(),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'YOUR POSITIONS (${holdings.length})',
                        style: AppTypography.labelSmall.copyWith(
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        sortCriteria.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final holding = holdings[index];
                    return HoldingRow(
                      key: ValueKey('holding_${holding.symbol}'),
                      holding: holding,
                      onTap: () {
                        HoldingDetailSheet.show(context, holding);
                      },
                    );
                  },
                  childCount: holdings.length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 32),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, _) => Center(
          child: Text('Error: $err', style: AppTypography.bodyMedium),
        ),
      ),
    );
  }
}
