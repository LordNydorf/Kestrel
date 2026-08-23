import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/symbols.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/feed/price_tick.dart';
import '../../market_overview/providers/price_provider.dart';

/// Reorderable stock row for Watchlist detail view.
///
/// Subscribes directly to `priceProvider(symbol)` ensuring that
/// even after reordering, price ticks route directly to this stock symbol.
class WatchlistRow extends ConsumerStatefulWidget {
  final String symbol;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const WatchlistRow({
    super.key,
    required this.symbol,
    required this.index,
    this.onTap,
    this.onRemove,
  });

  @override
  ConsumerState<WatchlistRow> createState() => _WatchlistRowState();
}

class _WatchlistRowState extends ConsumerState<WatchlistRow>
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
    final stock = Universe.bySymbol[widget.symbol] ??
        StockDefinition(
          symbol: widget.symbol,
          name: widget.symbol,
          sector: '',
          startingPrice: Universe.reliance.startingPrice,
        );

    // Listen to ticks for animation
    ref.listen<AsyncValue<PriceTick>>(
      priceProvider(widget.symbol),
      (prev, next) {
        next.whenData((tick) {
          if (tick.direction != TickDirection.neutral) {
            _triggerFlash(tick.direction);
          }
        });
      },
    );

    final liveTickAsync = ref.watch(priceProvider(widget.symbol));
    final fallbackTick = ref.read(latestTickProvider(widget.symbol));
    final tick = liveTickAsync.value ?? fallbackTick;

    final isGain = tick.isGain;
    final isLoss = tick.isLoss;
    final changeColor =
        isGain ? AppColors.gain : (isLoss ? AppColors.loss : AppColors.muted);
    final directionGlyph = isGain ? '▲ ' : (isLoss ? '▼ ' : '');

    return Dismissible(
      key: ValueKey('dismiss_${widget.symbol}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onRemove?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: AppColors.loss,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: AnimatedBuilder(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                children: [
                  // Drag Handle
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: Container(
                      width: 36,
                      height: 44,
                      alignment: Alignment.centerLeft,
                      color: Colors.transparent,
                      child: const Icon(
                        Icons.drag_handle_rounded,
                        color: AppColors.muted,
                        size: 20,
                      ),
                    ),
                  ),

                  // Symbol & Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          stock.symbol,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stock.name,
                          style: AppTypography.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Price & Change (Fixed width)
                  SizedBox(
                    width: 130,
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
      ),
    );
  }
}
