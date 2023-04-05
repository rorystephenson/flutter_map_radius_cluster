import 'package:flutter/material.dart';

class SearchCirclePainter extends CustomPainter {
  final double pixelRadius;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderWidth;

  const SearchCirclePainter({
    required this.pixelRadius,
    this.borderWidth,
    this.fillColor,
    this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    if (fillColor != null) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor!;

      _paintCircle(canvas, pixelRadius, paint);
    }

    if (borderColor != null && borderWidth != null) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = borderColor!
        ..strokeWidth = borderWidth!;

      _paintCircle(
        canvas,
        pixelRadius + (borderWidth! / 2),
        paint,
      );
    }
  }

  void _paintCircle(Canvas canvas, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
  }

  Offset get offset => Offset(
        pixelRadius + (borderWidth ?? 0),
        pixelRadius + (borderWidth ?? 0),
      );

  @override
  bool shouldRepaint(SearchCirclePainter oldDelegate) =>
      oldDelegate.pixelRadius != pixelRadius ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}
