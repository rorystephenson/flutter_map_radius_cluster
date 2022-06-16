import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:latlong2/latlong.dart';

import 'radius_cluster_manager.dart';
import 'search_circle_painter.dart';

class SearchRadiusIndicator extends StatelessWidget {
  final LatLng searchCenter;
  final RadiusSearchState radiusSearchState;
  final Distance distanceCalculator;
  final MapCalculator mapCalculator;
  final double radiusInM;
  final Color loadedBorderColor;
  final Color loadingBorderColor;
  final Color errorBorderColor;
  final double borderWidth;

  const SearchRadiusIndicator({
    super.key,
    required this.searchCenter,
    required this.radiusSearchState,
    required this.distanceCalculator,
    required this.mapCalculator,
    required this.radiusInM,
    required this.loadedBorderColor,
    required this.loadingBorderColor,
    required this.errorBorderColor,
    required this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final centerLatLng = searchCenter;
    final circlePixel = mapCalculator.getPixelFromPoint(centerLatLng);

    final rightEdgeLatLng =
        distanceCalculator.offset(centerLatLng, radiusInM, 90);
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
            borderColor: _borderColorFor(radiusSearchState),
            borderWidth: borderWidth,
          ),
          size: constraints.biggest,
        ),
      ),
    );
  }

  Color _borderColorFor(RadiusSearchState radiusSearchState) {
    switch (radiusSearchState) {
      case RadiusSearchState.complete:
        return loadedBorderColor;
      case RadiusSearchState.loading:
        return loadingBorderColor;
      case RadiusSearchState.error:
        return errorBorderColor;
      case RadiusSearchState.noSearchPerformed:
        throw 'Should not be drawing a circle if no search was performed';
    }
  }
}
