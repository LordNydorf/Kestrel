import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/feed/price_tick.dart';
import '../../../domain/models/holding.dart';
import '../../market_overview/providers/price_provider.dart';

class HoldingRow extends ConsumerStatefulWidget {
  final Holding holding;
  final VoidCallback? onTap;

  const HoldingRow({
    super.key,
    required this.holding,
    this.onTap,
  });

  @override
  ConsumerState<HoldingRow> createState() => _HoldingRowState();
}

class _HoldingRowState extends ConsumerState<HoldingRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<Color?> _flashAnimation;
  Color _flashTargetColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _flashAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.transparent,
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeOutQuad,
    ));
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  void _triggerFlash(TickDirection direction) {
    if (!mounted) return;

    if (direction == TickDirection.up) {
      _flashTargetColor = AppColors.gainTint;
    } else if (direction == TickDirection.down) {
      _flashTargetColor = AppColors.lossTint;
    } else {
      return;
    }

    _flashAnimation = ColorTween(
      begin: _flashTargetColor,
      end: Colors.transparent,
    ).animate(CurvedAnimation(
      parent: _flashController,
      curve: Curves.easeOutQuad,
    ));

    _flashController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PriceTick>>(
      priceProvider(widget.holding.symbol),
      (prev, next) {
        next.whenData((tick) {
          if (tick.direction != TickDirection.neutral) {
            _triggerFlash(tick.direction);
          }
        });
      },
    );

    final liveTickAsync = ref.watch(priceProvider(widget.holding.symbol));
    final fallbackTick =
        ref.read(latestTickProvider(widget.holding.symbol));
    final livePrice = liveTickAsync.value?.ltp ??
        fallbackTick.ltp;

    final holding = widget.holding;
    final currentValue = Money.fromPaise(livePrice.paise * holding.quantity);
    final investedValue =
        Money.fromPaise(holding.avgCost.paise * holding.quantity);
    final pnlPaise = currentValue.paise - investedValue.paise;
    final unrealizedPnl = Money.fromPaise(pnlPaise);

    final pnlPercentage = investedValue.paise > 0
        ? ((currentValue.paise - investedValue.paise) / investedValue.paise) *
            100.0
        : 0.0;

    final isGain = pnlPaise > 0;
    final isLoss = pnlPaise < 0;
    final pnlColor =
        isGain ? AppColors.gain : (isLoss ? AppColors.loss : AppColors.muted);
    final directionGlyph = isGain ? '▲ +' : (isLoss ? '▼ ' : '');

    return AnimatedBuilder(
      animation: _flashAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _flashAnimation.value ?? Colors.transparent,
            border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: AppColors.surfaceHover,
          highlightColor: AppColors.surfaceHover.withValues(alpha: 0.5),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Symbol & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        holding.symbol,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${holding.quantity} ${holding.quantity == 1 ? 'share' : 'shares'} • Avg. ${holding.avgCost.format()}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right Column: Current Value & P&L
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentValue.format(),
                        style: AppTypography.numericMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        unrealizedPnl.isZero
                            ? '₹0.00 (0.00%)'
                            : '$directionGlyph${unrealizedPnl.format(explicitSign: false)} (${pnlPercentage.abs().toStringAsFixed(2)}%)',
                        style: AppTypography.numericSmall.copyWith(
                          color: pnlColor,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
