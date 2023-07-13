import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LatLngCalc {
  static const _distanceCalculator =
      Distance(roundResult: false, calculator: Haversine());

  const LatLngCalc._();

  static LatLng offset(LatLng from, double meters, double bearing) =>
      _distanceCalculator.offset(from, meters, bearing);

  /// Calculates the offset from the current [camera] pixelOrigin of the
  /// [center] offset my [distanceInM] in the direction of [bearing].
  static Offset offsetFromOrigin(
    MapCamera camera,
    LatLng center,
    double distanceInM,
    double bearing,
  ) {
    final offsetLatLng = offset(center, distanceInM, bearing);
    final customPoint = camera.project(offsetLatLng) - camera.pixelOrigin;
    return Offset(customPoint.x, customPoint.y);
  }

  static double distanceInM(LatLng from, LatLng to) =>
      _distanceCalculator.distance(from, to);
}
