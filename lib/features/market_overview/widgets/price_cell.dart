import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/feed/price_tick.dart';
import '../providers/price_provider.dart';

/// Highly-optimized, self-contained stock row cell.
///
/// Subscribes ONLY to its specific symbol's stream so updates to RELIANCE
/// will never trigger rebuilds of TCS or the surrounding list scaffold.
class PriceCell extends ConsumerStatefulWidget {
  final StockDefinition stock;
  final VoidCallback? onTap;

  const PriceCell({
    super.key,
    required this.stock,
    this.onTap,
  });

  @override
  ConsumerState<PriceCell> createState() => _PriceCellState();
}

class _PriceCellState extends ConsumerState<PriceCell>
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
    // Listen strictly to this symbol's tick stream for animation triggers
    ref.listen<AsyncValue<PriceTick>>(
      priceProvider(widget.stock.symbol),
      (prev, next) {
        next.whenData((tick) {
          if (tick.direction != TickDirection.neutral) {
            _triggerFlash(tick.direction);
          }
        });
      },
    );

    // Watch live tick, falling back to synchronous latest tick
    final liveTickAsync = ref.watch(priceProvider(widget.stock.symbol));
    final fallbackTick = ref.read(latestTickProvider(widget.stock.symbol));
    final tick = liveTickAsync.value ?? fallbackTick;

    final isGain = tick.isGain;
    final isLoss = tick.isLoss;
    final changeColor =
        isGain ? AppColors.gain : (isLoss ? AppColors.loss : AppColors.muted);
    final directionGlyph = isGain ? '▲ ' : (isLoss ? '▼ ' : '');

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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Symbol & Company Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.stock.symbol,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.stock.name,
                        style: AppTypography.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right: Tabular LTP & Signed Change (Fixed width to avoid CLS)
                SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tick.ltp.format(),
                        style: AppTypography.numericMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$directionGlyph${tick.change.format(explicitSign: true)} (${tick.changePercent.abs().toStringAsFixed(2)}%)',
                        style: AppTypography.numericSmall.copyWith(
                          color: changeColor,
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
