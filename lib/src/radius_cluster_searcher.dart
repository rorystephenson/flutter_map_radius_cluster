import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

import 'lat_lng_calc.dart';

class RadiusClusterSearcher {
  final FlutterMapState mapState;
  final double radiusInKm;
  final double? minimumSearchDistanceDifferenceInKm;
  final Future<SuperclusterImmutable<Marker>> Function(double radius, LatLng center)
      _search;

  RadiusClusterSearcher({
    required this.mapState,
    required this.radiusInKm,
    required this.minimumSearchDistanceDifferenceInKm,
    required Future<SuperclusterImmutable<Marker>> Function(double radius, LatLng center)
        search,
  }) : _search = search;

  LatLng get mapCenter => mapState.center;

  Future<SuperclusterImmutable<Marker>> search(LatLng latLng) {
    return _search(radiusInKm, latLng);
  }

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
      visibleBounds.northEast!,
      visibleBounds.southEast,
      visibleBounds.southWest!
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
