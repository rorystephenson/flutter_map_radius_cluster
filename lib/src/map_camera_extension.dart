import 'dart:ui';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/lat_lng_calc.dart';
import 'package:latlong2/latlong.dart';

extension MapCameraExtension on MapCamera {
  CustomPoint<num> getPixelOffset(LatLng point) => project(point) - pixelOrigin;

  LatLngBounds paddedMapBounds(Size clusterWidgetSize) {
    final boundsPixelPadding = CustomPoint(
      clusterWidgetSize.width / 2,
      clusterWidgetSize.height / 2,
    );
    final bounds = pixelBounds;
    return LatLngBounds(
      unproject(bounds.topLeft - boundsPixelPadding),
      unproject(bounds.bottomRight + boundsPixelPadding),
    );
  }

  CustomPoint<num> get sizeChangeDueToRotation => size - nonRotatedSize;

  /// Returns true if the current map position is outside of the boundary of the
  /// previous search as defined by the [previousSearchCenter] and [radiusInKm].
  /// Returns true if [previousSearchCenter] is null.
  bool outsidePreviousSearchBoundary({
    required double radiusInKm,
    required LatLng? previousSearchCenter,
    required double? minimumSearchDistanceDifferenceInKm,
  }) {
    if (previousSearchCenter == null) return true;

    if (minimumSearchDistanceDifferenceInKm != null) {
      final distanceFromPreviousSearch = LatLngCalc.distanceInM(
        previousSearchCenter,
        center,
      );
      if (distanceFromPreviousSearch <
          minimumSearchDistanceDifferenceInKm * 1000) {
        return false;
      }
    }

    final corners = [
      visibleBounds.northWest,
      visibleBounds.northEast,
      visibleBounds.southEast,
      visibleBounds.southWest
    ];

    for (final corner in corners) {
      if (LatLngCalc.distanceInM(previousSearchCenter, corner) >
          radiusInKm * 1000) {
        return true;
      }
    }

    return false;
  }
}
