import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/candle_data.dart';
import '../providers/chart_providers.dart';

/// High-performance CustomPainter rendering OHLC candlesticks and Technical Indicators directly to Canvas.
class CandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final int? scrubIndex;
  final ChartIndicator indicator;
  final Color gainColor;
  final Color lossColor;
  final Color gridColor;

  CandlestickPainter({
    required this.candles,
    this.scrubIndex,
    this.indicator = ChartIndicator.none,
    this.gainColor = AppColors.gain,
    this.lossColor = AppColors.loss,
    this.gridColor = AppColors.border,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final width = size.width;
    final height = size.height;

    // Find min and max price across visible candles
    int minPaise = candles.first.low.paise;
    int maxPaise = candles.first.high.paise;

    for (final c in candles) {
      if (c.low.paise < minPaise) minPaise = c.low.paise;
      if (c.high.paise > maxPaise) maxPaise = c.high.paise;
    }

    // Add 5% top/bottom padding to prevent clipping
    final priceRange = max(100, maxPaise - minPaise);
    final paddedMin = max(1, minPaise - (priceRange * 0.05).round());
    final paddedMax = maxPaise + (priceRange * 0.05).round();
    final paddedRange = paddedMax - paddedMin;

    double priceToY(int paise) {
      final normalized = (paise - paddedMin) / paddedRange;
      return height - (normalized * height);
    }

    // 1. Draw subtle horizontal grid lines (3 levels: 25%, 50%, 75%)
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      final y = height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // 2. Draw Technical Indicator Overlays (Bollinger Channel / SMA)
    final count = candles.length;
    final candleWidth = width / count;

    if (indicator == ChartIndicator.sma20 || indicator == ChartIndicator.bollinger) {
      final List<Offset> smaPoints = [];
      final List<Offset> upperPoints = [];
      final List<Offset> lowerPoints = [];

      for (int i = 0; i < count; i++) {
        final period = min(20, i + 1);
        double sum = 0.0;
        for (int j = i - period + 1; j <= i; j++) {
          sum += candles[j].close.paise;
        }
        final sma = sum / period;

        double sumSqDiff = 0.0;
        for (int j = i - period + 1; j <= i; j++) {
          final diff = candles[j].close.paise - sma;
          sumSqDiff += diff * diff;
        }
        final stdDev = sqrt(sumSqDiff / period);

        final x = (i * candleWidth) + (candleWidth / 2);
        smaPoints.add(Offset(x, priceToY(sma.round())));
        upperPoints.add(Offset(x, priceToY((sma + (2 * stdDev)).round())));
        lowerPoints.add(Offset(x, priceToY((sma - (2 * stdDev)).round())));
      }

      // Draw Bollinger Ribbon & Bands
      if (indicator == ChartIndicator.bollinger && upperPoints.length > 1) {
        final ribbonPath = Path();
        ribbonPath.moveTo(upperPoints.first.dx, upperPoints.first.dy);
        for (final p in upperPoints) {
          ribbonPath.lineTo(p.dx, p.dy);
        }
        for (int i = lowerPoints.length - 1; i >= 0; i--) {
          ribbonPath.lineTo(lowerPoints[i].dx, lowerPoints[i].dy);
        }
        ribbonPath.close();

        final ribbonPaint = Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.08)
          ..style = PaintingStyle.fill;
        canvas.drawPath(ribbonPath, ribbonPaint);

        final bandPaint = Paint()
          ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        final upperPath = Path()..moveTo(upperPoints.first.dx, upperPoints.first.dy);
        for (final p in upperPoints) {
          upperPath.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(upperPath, bandPaint);

        final lowerPath = Path()..moveTo(lowerPoints.first.dx, lowerPoints.first.dy);
        for (final p in lowerPoints) {
          lowerPath.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(lowerPath, bandPaint);
      }

      // Draw SMA Line
      if (smaPoints.length > 1) {
        final smaPath = Path()..moveTo(smaPoints.first.dx, smaPoints.first.dy);
        for (final p in smaPoints) {
          smaPath.lineTo(p.dx, p.dy);
        }
        final smaPaint = Paint()
          ..color = const Color(0xFFF59E0B)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawPath(smaPath, smaPaint);
      }
    }

    // 3. Draw Candlesticks
    final bodyWidth = max(2.0, candleWidth * 0.7);

    final gainPaint = Paint()
      ..color = gainColor
      ..style = PaintingStyle.fill;

    final lossPaint = Paint()
      ..color = lossColor
      ..style = PaintingStyle.fill;

    final wickGainPaint = Paint()
      ..color = gainColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final wickLossPaint = Paint()
      ..color = lossColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < count; i++) {
      final candle = candles[i];
      final isBullish = candle.isBullish;
      final paint = isBullish ? gainPaint : lossPaint;
      final wickPaint = isBullish ? wickGainPaint : wickLossPaint;

      final x = (i * candleWidth) + (candleWidth / 2);
      final yHigh = priceToY(candle.high.paise);
      final yLow = priceToY(candle.low.paise);
      final yOpen = priceToY(candle.open.paise);
      final yClose = priceToY(candle.close.paise);

      // Draw Center Wick
      canvas.drawLine(Offset(x, yHigh), Offset(x, yLow), wickPaint);

      // Draw Candle Body (ensure minimum 2px height for doji candles)
      final top = min(yOpen, yClose);
      final rawHeight = (yOpen - yClose).abs();
      final bodyH = max(2.0, rawHeight);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, top + (bodyH / 2)),
            width: bodyWidth,
            height: bodyH,
          ),
          const Radius.circular(1.0),
        ),
        paint,
      );
    }

    // 4. Draw Scrub Crosshair if active
    if (scrubIndex != null && scrubIndex! >= 0 && scrubIndex! < count) {
      final selected = candles[scrubIndex!];
      final scrubX = (scrubIndex! * candleWidth) + (candleWidth / 2);
      final scrubY = priceToY(selected.close.paise);

      final crosshairPaint = Paint()
        ..color = AppColors.ink.withValues(alpha: 0.6)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      // Vertical line
      canvas.drawLine(Offset(scrubX, 0), Offset(scrubX, height), crosshairPaint);

      // Horizontal line
      canvas.drawLine(Offset(0, scrubY), Offset(width, scrubY), crosshairPaint);

      // Highlight target dot
      final dotBgPaint = Paint()
        ..color = selected.isBullish ? gainColor : lossColor
        ..style = PaintingStyle.fill;
      final dotRingPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(scrubX, scrubY), 5.0, dotBgPaint);
      canvas.drawCircle(Offset(scrubX, scrubY), 5.0, dotRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.scrubIndex != scrubIndex ||
        oldDelegate.indicator != indicator ||
        oldDelegate.gainColor != gainColor ||
        oldDelegate.lossColor != lossColor;
  }
}
