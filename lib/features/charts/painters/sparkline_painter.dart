import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/candle_data.dart';

/// CustomPainter rendering smooth Bézier area sparklines with vertical gradient glow.
class SparklinePainter extends CustomPainter {
  final List<CandleData> candles;
  final int? scrubIndex;
  final Color strokeColor;

  SparklinePainter({
    required this.candles,
    this.scrubIndex,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final width = size.width;
    final height = size.height;

    int minPaise = candles.first.close.paise;
    int maxPaise = candles.first.close.paise;

    for (final c in candles) {
      if (c.close.paise < minPaise) minPaise = c.close.paise;
      if (c.close.paise > maxPaise) maxPaise = c.close.paise;
    }

    final priceRange = max(100, maxPaise - minPaise);
    final paddedMin = max(1, minPaise - (priceRange * 0.08).round());
    final paddedMax = maxPaise + (priceRange * 0.08).round();
    final paddedRange = paddedMax - paddedMin;

    double priceToY(int paise) {
      final normalized = (paise - paddedMin) / paddedRange;
      return height - (normalized * height);
    }

    final count = candles.length;
    final stepX = width / (count - 1);

    // Compute coordinate points
    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = i * stepX;
      final y = priceToY(candles[i].close.paise);
      points.add(Offset(x, y));
    }

    // Build smooth cubic Bézier path
    final strokePath = Path();
    strokePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      strokePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 1. Draw Area Gradient Fill
    final fillPath = Path.from(strokePath);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          strokeColor.withValues(alpha: 0.35),
          strokeColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw Stroke Line
    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(strokePath, strokePaint);

    // 3. Draw Scrubbing indicator if active
    if (scrubIndex != null && scrubIndex! >= 0 && scrubIndex! < count) {
      final target = points[scrubIndex!];

      // Vertical crosshair
      final crosshairPaint = Paint()
        ..color = AppColors.ink.withValues(alpha: 0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(target.dx, 0), Offset(target.dx, height), crosshairPaint);

      // Glowing dot
      final dotBgPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;
      final dotRingPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(target, 5.5, dotBgPaint);
      canvas.drawCircle(target, 5.5, dotRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.scrubIndex != scrubIndex ||
        oldDelegate.strokeColor != strokeColor;
  }
}
