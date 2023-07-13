import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:flutter_map_radius_cluster/src/lat_lng_calc.dart';
import 'package:latlong2/latlong.dart';

class SearchCirclePainter extends CustomPainter {
  final MapCamera camera;
  final LatLng center;
  final double radiusInM;
  final SearchCircleStyle style;

  SearchCirclePainter({
    required this.camera,
    required this.center,
    required this.radiusInM,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.clipRect(rect);

    // Calculate the bounding rectangle of the projected circle.
    final arcRect = Rect.fromLTRB(
      LatLngCalc.offsetFromOrigin(camera, center, radiusInM, -90).dx,
      LatLngCalc.offsetFromOrigin(camera, center, radiusInM, 0).dy,
      LatLngCalc.offsetFromOrigin(camera, center, radiusInM, 90).dx,
      LatLngCalc.offsetFromOrigin(camera, center, radiusInM, 180).dy,
    );

    // Draw the fill.
    if (style.fillColor != null) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = style.fillColor!;

      canvas.drawArc(arcRect, 0, 2 * pi, true, paint);
    }

    // Draw the border.
    if (style.borderColor != null && style.borderWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = style.borderColor!
        ..strokeWidth = style.borderWidth;

      // The stroke is drawn on the circle edge so we need to move the rectangle
      // out half of the border width.
      final borderAdjustedRect = arcRect.inflate(style.borderWidth / 2);
      canvas.drawArc(borderAdjustedRect, 0, 2 * pi, false, paint);
    }
  }

  @override
  bool shouldRepaint(SearchCirclePainter oldDelegate) =>
      oldDelegate.camera != camera ||
      oldDelegate.center != center ||
      oldDelegate.radiusInM != radiusInM ||
      oldDelegate.style != style;
}
