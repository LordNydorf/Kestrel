import 'package:flutter/foundation.dart';
import '../../core/constants/symbols.dart';
import '../../core/money/money.dart';
import '../models/holding.dart';
import '../models/order.dart';

/// Portfolio asset & sector allocation item.
@immutable
class SectorAllocation {
  final String sector;
  final Money value;
  final double percentage;

  const SectorAllocation({
    required this.sector,
    required this.value,
    required this.percentage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SectorAllocation &&
          runtimeType == other.runtimeType &&
          sector == other.sector &&
          value == other.value &&
          percentage == other.percentage;

  @override
  int get hashCode => Object.hash(sector, value, percentage);

  @override
  String toString() =>
      'SectorAllocation($sector: $value, ${percentage.toStringAsFixed(1)}%)';
}

@immutable
class PortfolioSummary {
  final Money totalInvested;
  final Money currentValue;
  final Money unrealizedPnl;
  final double pnlPercentage;
  final int totalHoldingsCount;
  final Money realizedPnl;
  final int totalOrdersCount;
  final int winningTradesCount;
  final int losingTradesCount;

  const PortfolioSummary({
    required this.totalInvested,
    required this.currentValue,
    required this.unrealizedPnl,
    required this.pnlPercentage,
    required this.totalHoldingsCount,
    this.realizedPnl = Money.zero,
    this.totalOrdersCount = 0,
    this.winningTradesCount = 0,
    this.losingTradesCount = 0,
  });

  bool get isGain => unrealizedPnl.paise > 0;
  bool get isLoss => unrealizedPnl.paise < 0;
  bool get isNeutral => unrealizedPnl.isZero;

  /// Combined total net P&L (Unrealized + Realized)
  Money get netPnl => unrealizedPnl + realizedPnl;

  /// Trade win-rate percentage [0 - 100%]
  double get winRate {
    final closedTrades = winningTradesCount + losingTradesCount;
    if (closedTrades == 0) return 0.0;
    return (winningTradesCount / closedTrades) * 100.0;
  }

  static const zero = PortfolioSummary(
    totalInvested: Money.zero,
    currentValue: Money.zero,
    unrealizedPnl: Money.zero,
    pnlPercentage: 0.0,
    totalHoldingsCount: 0,
    realizedPnl: Money.zero,
    totalOrdersCount: 0,
    winningTradesCount: 0,
    losingTradesCount: 0,
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
          totalHoldingsCount == other.totalHoldingsCount &&
          realizedPnl == other.realizedPnl &&
          totalOrdersCount == other.totalOrdersCount &&
          winningTradesCount == other.winningTradesCount &&
          losingTradesCount == other.losingTradesCount;

  @override
  int get hashCode => Object.hash(
        totalInvested,
        currentValue,
        unrealizedPnl,
        pnlPercentage,
        totalHoldingsCount,
        realizedPnl,
        totalOrdersCount,
        winningTradesCount,
        losingTradesCount,
      );

  @override
  String toString() =>
      'PortfolioSummary(invested: $totalInvested, current: $currentValue, unrealized: $unrealizedPnl, realized: $realizedPnl, pct: ${pnlPercentage.toStringAsFixed(2)}%)';
}

class PnlCalculator {
  const PnlCalculator._();

  static PortfolioSummary calculateSummary({
    required List<Holding> holdings,
    required Map<String, Money> currentPrices,
    List<Order> orders = const [],
  }) {
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

    final totalInvested = Money.fromPaise(totalInvestedPaise);
    final currentValue = Money.fromPaise(totalCurrentPaise);
    final pnlPaise = totalCurrentPaise - totalInvestedPaise;
    final unrealizedPnl = Money.fromPaise(pnlPaise);

    final pnlPercentage = totalInvestedPaise > 0
        ? ((totalCurrentPaise - totalInvestedPaise) / totalInvestedPaise) * 100.0
        : 0.0;

    // Realized P&L calculation from executed SELL orders
    var realizedPaise = 0;
    var winCount = 0;
    var lossCount = 0;

    for (final order in orders) {
      if (order.side == OrderSide.sell && order.isExecuted) {
        realizedPaise += order.realizedPnl.paise;
        if (order.realizedPnl.paise > 0) {
          winCount++;
        } else if (order.realizedPnl.paise < 0) {
          lossCount++;
        }
      }
    }

    return PortfolioSummary(
      totalInvested: totalInvested,
      currentValue: currentValue,
      unrealizedPnl: unrealizedPnl,
      pnlPercentage: pnlPercentage,
      totalHoldingsCount: validCount,
      realizedPnl: Money.fromPaise(realizedPaise),
      totalOrdersCount: orders.length,
      winningTradesCount: winCount,
      losingTradesCount: lossCount,
    );
  }

  /// Calculates sector allocation breakdown and cash vs equities ratio.
  static List<SectorAllocation> calculateSectorAllocation({
    required List<Holding> holdings,
    required Map<String, Money> currentPrices,
    required Money availableCash,
  }) {
    final Map<String, int> sectorValuesPaise = {};
    var totalPortfolioPaise = availableCash.paise;

    for (final holding in holdings) {
      if (holding.quantity <= 0) continue;
      final livePrice = currentPrices[holding.symbol] ?? holding.avgCost;
      final valuePaise = livePrice.paise * holding.quantity;
      final sector = Universe.bySymbol[holding.symbol]?.sector ?? 'Other';

      sectorValuesPaise[sector] = (sectorValuesPaise[sector] ?? 0) + valuePaise;
      totalPortfolioPaise += valuePaise;
    }

    if (totalPortfolioPaise == 0) return [];

    final list = <SectorAllocation>[];

    // Add Equities Sectors
    sectorValuesPaise.forEach((sector, paise) {
      final value = Money.fromPaise(paise);
      final percentage = (paise / totalPortfolioPaise) * 100.0;
      list.add(SectorAllocation(
        sector: sector,
        value: value,
        percentage: percentage,
      ));
    });

    // Add Cash Balance
    if (availableCash.paise > 0) {
      list.add(SectorAllocation(
        sector: 'Available Cash',
        value: availableCash,
        percentage: (availableCash.paise / totalPortfolioPaise) * 100.0,
      ));
    }

    // Sort descending by value
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}
