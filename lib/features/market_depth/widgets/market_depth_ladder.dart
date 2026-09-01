import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/market_depth.dart';
import '../providers/depth_provider.dart';

class MarketDepthLadder extends ConsumerWidget {
  final String symbol;

  const MarketDepthLadder({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depthAsync = ref.watch(marketDepthStreamProvider(symbol));
    final fallbackDepth = ref.watch(marketDepthSnapshotProvider(symbol));
    final depth = depthAsync.value ?? fallbackDepth;

    final maxQty = max(1, depth.maxLevelQty);
    final buyerPct = (depth.buyerRatio * 100).toStringAsFixed(1);
    final sellerPct = (depth.sellerRatio * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Title + Spread Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORDER BOOK (L2 DEPTH)',
                style: AppTypography.labelSmall.copyWith(
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'Spread: ${depth.spread.format()}',
                  style: AppTypography.numericSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Column Headers
          Row(
            children: [
              // Bids Header
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Qty', style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                    Text('Bid (₹)',
                        style: AppTypography.labelSmall
                            .copyWith(fontSize: 10, color: AppColors.gain)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Asks Header
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ask (₹)',
                        style: AppTypography.labelSmall
                            .copyWith(fontSize: 10, color: AppColors.loss)),
                    Text('Qty', style: AppTypography.labelSmall.copyWith(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 12),

          // 5 Depth Rows
          for (int i = 0; i < 5; i++)
            _buildDepthRow(
              bid: i < depth.bids.length ? depth.bids[i] : null,
              ask: i < depth.asks.length ? depth.asks[i] : null,
              maxQty: maxQty,
            ),

          const Divider(height: 14),

          // Total Quantities Row
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: AppTypography.labelSmall.copyWith(fontSize: 11)),
                    Text(
                      '${depth.totalBidQty}',
                      style: AppTypography.numericSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gain,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${depth.totalAskQty}',
                      style: AppTypography.numericSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.loss,
                      ),
                    ),
                    Text('Total', style: AppTypography.labelSmall.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Buyer vs Seller Pressure Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3.0),
            child: SizedBox(
              height: 4.0,
              child: Row(
                children: [
                  Expanded(
                    flex: (depth.buyerRatio * 100).round().clamp(1, 99),
                    child: Container(color: AppColors.gain),
                  ),
                  Expanded(
                    flex: (depth.sellerRatio * 100).round().clamp(1, 99),
                    child: Container(color: AppColors.loss),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Buyer / Seller Ratio Percentages
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Buyers: $buyerPct%',
                style: AppTypography.numericSmall.copyWith(
                  fontSize: 10,
                  color: AppColors.gain,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Sellers: $sellerPct%',
                style: AppTypography.numericSmall.copyWith(
                  fontSize: 10,
                  color: AppColors.loss,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDepthRow({
    required DepthLevel? bid,
    required DepthLevel? ask,
    required int maxQty,
  }) {
    final bidRatio = bid != null ? (bid.quantity / maxQty).clamp(0.0, 1.0) : 0.0;
    final askRatio = ask != null ? (ask.quantity / maxQty).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          // Left: Bid Level
          Expanded(
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                // Background Depth Bar (extends from right to left)
                FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: bidRatio,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.gain.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        bid != null ? '${bid.quantity}' : '-',
                        style: AppTypography.numericSmall.copyWith(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        bid != null ? bid.price.format(showSymbol: false) : '-',
                        style: AppTypography.numericSmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right: Ask Level
          Expanded(
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Background Depth Bar (extends from left to right)
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: askRatio,
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.loss.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ask != null ? ask.price.format(showSymbol: false) : '-',
                        style: AppTypography.numericSmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.loss,
                        ),
                      ),
                      Text(
                        ask != null ? '${ask.quantity}' : '-',
                        style: AppTypography.numericSmall.copyWith(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
