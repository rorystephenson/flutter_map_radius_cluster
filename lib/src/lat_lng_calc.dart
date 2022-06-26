import 'package:latlong2/latlong.dart';

class LatLngCalc {
  static const _distanceCalculator =
      Distance(roundResult: false, calculator: Haversine());

  static LatLng offset(LatLng from, double meters, double bearing) =>
      _distanceCalculator.offset(from, meters, bearing);

  static double distanceInM(LatLng from, LatLng to) =>
      _distanceCalculator.distance(from, to);
}
