import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/options/search_circle_style.dart';
import 'package:flutter_map_radius_cluster/src/overlay/fade_animation.dart';
import 'package:latlong2/latlong.dart';

import 'search_circle_painter.dart';

class SearchRadiusIndicator extends StatelessWidget {
  final LatLng? center;
  final MapCamera camera;
  final double radiusInM;
  final SearchCircleStyle style;

  const SearchRadiusIndicator({
    super.key,
    required this.camera,
    required this.radiusInM,
    required this.style,

    /// Defaults to the visible center.
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    final center = this.center ?? camera.center;

    return Positioned(
      left: 0,
      top: 0,
      child: _wrapWithFadeIfEnabled(
        CustomPaint(
          foregroundPainter: SearchCirclePainter(
            camera: camera,
            radiusInM: radiusInM,
            center: center,
            style: style,
          ),
          size: Size(camera.size.x, camera.size.y),
        ),
      ),
    );
  }

  Widget _wrapWithFadeIfEnabled(Widget child) => style.fadeAnimation == null
      ? child
      : FadeAnimation(
          options: style.fadeAnimation!,
          child: child,
        );
}
