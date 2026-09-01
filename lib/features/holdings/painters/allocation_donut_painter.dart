import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../domain/services/pnl_calculator.dart';

/// CustomPainter rendering smooth proportional donut rings with sector colors.
class AllocationDonutPainter extends CustomPainter {
  final List<SectorAllocation> allocations;
  final List<Color> colors;

  AllocationDonutPainter({
    required this.allocations,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (allocations.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    const strokeWidth = 18.0;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    var startAngle = -pi / 2; // Start from 12 o'clock

    for (int i = 0; i < allocations.length; i++) {
      final alloc = allocations[i];
      final sweepAngle = (alloc.percentage / 100.0) * 2 * pi;
      if (sweepAngle <= 0) continue;

      final color = colors[i % colors.length];
      basePaint.color = color;

      // Small gap angle between sectors
      const gap = 0.04;
      final effectiveSweep = max(0.01, sweepAngle - gap);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle + (gap / 2),
        effectiveSweep,
        false,
        basePaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant AllocationDonutPainter oldDelegate) {
    return oldDelegate.allocations != allocations;
  }
}
