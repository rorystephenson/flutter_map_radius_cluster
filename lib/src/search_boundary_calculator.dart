import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/lat_lng_calc.dart';
import 'package:latlong2/latlong.dart';

class SearchBoundaryCalculator {
  final FlutterMapState mapState;
  final double radiusInKm;
  final double? minimumSearchDistanceDifferenceInKm;

  SearchBoundaryCalculator({
    required this.mapState,
    required this.radiusInKm,
    required this.minimumSearchDistanceDifferenceInKm,
  });

  // Returns true if the current map position is outside of the boundary of the
  /// previous search as defined by the [previousSearchCenter] and [radiusInKm].
  /// Returns true if [previousSearchCenter] is null.
  bool outsidePreviousSearchBoundary(LatLng? previousSearchCenter) {
    if (previousSearchCenter == null) return true;

    if (minimumSearchDistanceDifferenceInKm != null) {
      final distanceFromPreviousSearch = LatLngCalc.distanceInM(
        previousSearchCenter,
        mapState.center,
      );
      if (distanceFromPreviousSearch <
          minimumSearchDistanceDifferenceInKm! * 1000) {
        return false;
      }
    }

    final visibleBounds = mapState.bounds;
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
