import 'package:flutter/foundation.dart';
import '../../core/money/money.dart';
import '../models/holding.dart';

@immutable
class PortfolioSummary {
  final Money totalInvested;
  final Money currentValue;
  final Money unrealizedPnl;
  final double pnlPercentage;
  final int totalHoldingsCount;

  const PortfolioSummary({
    required this.totalInvested,
    required this.currentValue,
    required this.unrealizedPnl,
    required this.pnlPercentage,
    required this.totalHoldingsCount,
  });

  bool get isGain => unrealizedPnl.paise > 0;
  bool get isLoss => unrealizedPnl.paise < 0;
  bool get isNeutral => unrealizedPnl.isZero;

  static const zero = PortfolioSummary(
    totalInvested: Money.zero,
    currentValue: Money.zero,
    unrealizedPnl: Money.zero,
    pnlPercentage: 0.0,
    totalHoldingsCount: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortfolioSummary &&
          runtimeType == other.runtimeType &&
          totalInvested == other.totalInvested &&
          currentValue == other.currentValue &&
          unrealizedPnl == other.unrealizedPnl &&
          pnlPercentage == other.pnlPercentage &&
          totalHoldingsCount == other.totalHoldingsCount;

  @override
  int get hashCode => Object.hash(
        totalInvested,
        currentValue,
        unrealizedPnl,
        pnlPercentage,
        totalHoldingsCount,
      );

  @override
  String toString() =>
      'PortfolioSummary(invested: $totalInvested, current: $currentValue, pnl: $unrealizedPnl, pct: ${pnlPercentage.toStringAsFixed(2)}%)';
}

class PnlCalculator {
  const PnlCalculator._();

  static PortfolioSummary calculateSummary({
    required List<Holding> holdings,
    required Map<String, Money> currentPrices,
  }) {
    if (holdings.isEmpty) {
      return PortfolioSummary.zero;
    }

    var totalInvestedPaise = 0;
    var totalCurrentPaise = 0;
    var validCount = 0;

    for (final holding in holdings) {
      if (holding.quantity <= 0) continue;
      validCount++;

      final investedPaise = holding.avgCost.paise * holding.quantity;
      totalInvestedPaise += investedPaise;

      final livePrice = currentPrices[holding.symbol] ?? holding.avgCost;
      final currentPaise = livePrice.paise * holding.quantity;
      totalCurrentPaise += currentPaise;
    }

    if (validCount == 0 || totalInvestedPaise == 0) {
      return PortfolioSummary.zero;
    }

    final totalInvested = Money.fromPaise(totalInvestedPaise);
    final currentValue = Money.fromPaise(totalCurrentPaise);
    final pnlPaise = totalCurrentPaise - totalInvestedPaise;
    final unrealizedPnl = Money.fromPaise(pnlPaise);

    final pnlPercentage =
        ((totalCurrentPaise - totalInvestedPaise) / totalInvestedPaise) * 100.0;

    return PortfolioSummary(
      totalInvested: totalInvested,
      currentValue: currentValue,
      unrealizedPnl: unrealizedPnl,
      pnlPercentage: pnlPercentage,
      totalHoldingsCount: validCount,
    );
  }
}
