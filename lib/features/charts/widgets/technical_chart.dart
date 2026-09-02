import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../painters/candlestick_painter.dart';
import '../painters/sparkline_painter.dart';
import '../providers/chart_providers.dart';
import 'timeframe_selector.dart';

class TechnicalChart extends ConsumerStatefulWidget {
  final String symbol;

  const TechnicalChart({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<TechnicalChart> createState() => _TechnicalChartState();
}

class _TechnicalChartState extends ConsumerState<TechnicalChart> {
  int? _scrubIndex;

  void _handleTouch(Offset localPosition, double width, int count) {
    if (count <= 1 || width <= 0) return;
    final normalized = (localPosition.dx / width).clamp(0.0, 1.0);
    final index = (normalized * (count - 1)).round();
    if (_scrubIndex != index) {
      Haptics.selection();
      setState(() => _scrubIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candles = ref.watch(candlesProvider(widget.symbol));
    final chartMode = ref.watch(chartModeProvider);
    final indicator = ref.watch(chartIndicatorProvider);

    if (candles.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.accent),
      );
    }

    // Candle to display in the header pill (active scrubbed candle or latest)
    final activeCandle = (_scrubIndex != null &&
            _scrubIndex! >= 0 &&
            _scrubIndex! < candles.length)
        ? candles[_scrubIndex!]
        : candles.last;

    final isPositive = activeCandle.isBullish;
    final changeColor = isPositive ? AppColors.gain : AppColors.loss;
    final dateFormat = DateFormat('MMM dd, HH:mm');

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
          // 1. Controls Header: Timeframe Selector + Mode Switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TimeframeSelector(symbol: widget.symbol),
              // Chart Mode Switch (Candles vs Line)
              Container(
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildModeButton(
                      mode: ChartMode.candlestick,
                      icon: Icons.candlestick_chart_rounded,
                      isActive: chartMode == ChartMode.candlestick,
                    ),
                    _buildModeButton(
                      mode: ChartMode.line,
                      icon: Icons.show_chart_rounded,
                      isActive: chartMode == ChartMode.line,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Technical Indicators Selector Row (Candlestick mode only)
          if (chartMode == ChartMode.candlestick) ...[
            Row(
              children: [
                Text(
                  'INDICATOR:',
                  style: AppTypography.labelSmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 8),
                for (final ind in ChartIndicator.values) ...[
                  GestureDetector(
                    onTap: () {
                      if (indicator != ind) {
                        Haptics.selection();
                        ref.read(chartIndicatorProvider.notifier).state = ind;
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6.0),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: indicator == ind
                            ? AppColors.accent.withValues(alpha: 0.2)
                            : AppColors.paper,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(
                          color: indicator == ind
                              ? AppColors.accent
                              : AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        ind.label,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: indicator == ind ? FontWeight.w700 : FontWeight.w500,
                          color: indicator == ind ? AppColors.accent : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],

          // 3. Active Candle OHLC Scrubber Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOhlcItem('O', activeCandle.open.format(showSymbol: false)),
                _buildOhlcItem('H', activeCandle.high.format(showSymbol: false)),
                _buildOhlcItem('L', activeCandle.low.format(showSymbol: false)),
                _buildOhlcItem('C', activeCandle.close.format(showSymbol: false),
                    valueColor: changeColor),
                Text(
                  dateFormat.format(activeCandle.timestamp),
                  style: AppTypography.numericSmall.copyWith(
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4. Interactive Custom Canvas Chart Area
          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                return GestureDetector(
                  onHorizontalDragStart: (details) {
                    _handleTouch(details.localPosition, width, candles.length);
                  },
                  onHorizontalDragUpdate: (details) {
                    _handleTouch(details.localPosition, width, candles.length);
                  },
                  onHorizontalDragEnd: (_) {
                    setState(() => _scrubIndex = null);
                  },
                  onTapDown: (details) {
                    _handleTouch(details.localPosition, width, candles.length);
                  },
                  onTapUp: (_) {
                    setState(() => _scrubIndex = null);
                  },
                  child: CustomPaint(
                    size: Size(width, height),
                    painter: chartMode == ChartMode.candlestick
                        ? CandlestickPainter(
                            candles: candles,
                            scrubIndex: _scrubIndex,
                            indicator: indicator,
                            gainColor: AppColors.gain,
                            lossColor: AppColors.loss,
                            gridColor: AppColors.border,
                          )
                        : SparklinePainter(
                            candles: candles,
                            scrubIndex: _scrubIndex,
                            strokeColor: (candles.last.close >= candles.first.open)
                                ? AppColors.gain
                                : AppColors.loss,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required ChartMode mode,
    required IconData icon,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Haptics.selection();
          ref.read(chartModeProvider.notifier).state = mode;
        }
      },
      child: Container(
        padding: const EdgeInsets.all(5.0),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isActive ? Colors.white : AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildOhlcItem(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTypography.labelSmall.copyWith(
            fontSize: 10,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: AppTypography.numericSmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.ink,
          ),
        ),
      ],
    );
  }
}
