import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:flutter_map_radius_cluster/src/lat_lng_calc.dart';
import 'package:latlong2/latlong.dart';

import 'search_circle_painter.dart';

class SearchRadiusIndicator extends StatelessWidget {
  final LatLng center;
  final MapCalculator mapCalculator;
  final double radiusInM;
  final Color borderColor;
  final double borderWidth;

  const SearchRadiusIndicator({
    super.key,
    required this.center,
    required this.mapCalculator,
    required this.radiusInM,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final centerLatLng = center;
    final circlePixel = mapCalculator.getPixelFromPoint(centerLatLng);

    final rightEdgeLatLng = LatLngCalc.offset(centerLatLng, radiusInM, 90);
    final rightEdgePixel = mapCalculator.getPixelFromPoint(rightEdgeLatLng);
    final pixelRadius = rightEdgePixel.x - circlePixel.x;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          painter: SearchCirclePainter(
            pixelRadius: pixelRadius.toDouble(),
            offset: Offset(
              circlePixel.x.toDouble(),
              circlePixel.y.toDouble(),
            ),
            borderColor: borderColor,
            borderWidth: borderWidth,
          ),
          size: constraints.biggest,
        ),
      ),
    );
  }
}
