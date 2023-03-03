import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/src/lat_lng_calc.dart';
import 'package:flutter_map_radius_cluster/src/map_calculator.dart';
import 'package:flutter_map_radius_cluster/src/options/search_circle_style.dart';
import 'package:flutter_map_radius_cluster/src/overlay/fade_animation.dart';
import 'package:latlong2/latlong.dart';

import 'search_circle_painter.dart';

class SearchRadiusIndicator extends StatelessWidget {
  final LatLng center;
  final MapCalculator mapCalculator;
  final double radiusInM;
  final SearchCircleStyle style;

  const SearchRadiusIndicator({
    super.key,
    required this.center,
    required this.mapCalculator,
    required this.radiusInM,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (style.fadeAnimation == null) return _searchCircle(constraints);

          return FadeAnimation(
            options: style.fadeAnimation!,
            child: _searchCircle(constraints),
          );
        },
      ),
    );
  }

  Widget _searchCircle(BoxConstraints constraints) {
    final centerLatLng = center;
    final circlePixel = mapCalculator.getPixelFromPoint(centerLatLng);

    final rightEdgeLatLng = LatLngCalc.offset(centerLatLng, radiusInM, 90);
    final rightEdgePixel = mapCalculator.getPixelFromPoint(rightEdgeLatLng);
    final pixelRadius = rightEdgePixel.x - circlePixel.x;
    return CustomPaint(
      painter: SearchCirclePainter(
        pixelRadius: pixelRadius.toDouble(),
        offset: Offset(
          circlePixel.x.toDouble(),
          circlePixel.y.toDouble(),
        ),
        borderColor: style.borderColor,
        borderWidth: style.borderWidth,
      ),
      size: constraints.biggest,
    );
  }
}
