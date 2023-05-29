import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/lat_lng_calc.dart';
import 'package:flutter_map_radius_cluster/src/options/search_circle_style.dart';
import 'package:flutter_map_radius_cluster/src/overlay/fade_animation.dart';
import 'package:latlong2/latlong.dart';

import 'search_circle_painter.dart';

class SearchRadiusIndicator extends StatelessWidget {
  final LatLng? center;
  final FlutterMapState mapState;
  final double radiusInM;
  final SearchCircleStyle style;

  const SearchRadiusIndicator({
    super.key,
    required this.mapState,
    required this.radiusInM,
    required this.style,

    /// Defaults to the visible center.
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final center = this.center ?? mapState.center;
    final centerPixel = mapState.project(center);
    final circleOffset = centerPixel - mapState.pixelOrigin;

    final rightEdgeLatLng = LatLngCalc.offset(center, radiusInM, 90);
    final pixelRadius =
        (mapState.project(rightEdgeLatLng).x - centerPixel.x).toDouble();

    return Positioned(
      left: circleOffset.x.toDouble() - pixelRadius - style.borderWidth,
      top: circleOffset.y.toDouble() - pixelRadius - style.borderWidth,
      child: style.fadeAnimation == null
          ? _searchCircle(pixelRadius)
          : FadeAnimation(
              options: style.fadeAnimation!,
              child: _searchCircle(pixelRadius),
            ),
    );
  }

  Widget _searchCircle(double pixelRadius) {
    final pixelDiameter = pixelRadius * 2 + style.borderWidth * 2;
    return CustomPaint(
      foregroundPainter: SearchCirclePainter(
        pixelRadius: pixelRadius,
        borderColor: style.borderColor,
        borderWidth: style.borderWidth,
      ),
      size: Size(pixelDiameter, pixelDiameter),
    );
  }
}
