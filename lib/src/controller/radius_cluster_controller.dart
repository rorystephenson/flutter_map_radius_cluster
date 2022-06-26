import 'dart:async';

import 'package:latlong2/latlong.dart';

class RadiusClusterController {
  final StreamController<LatLng?> _searchStreamController;

  RadiusClusterController()
      : _searchStreamController = StreamController.broadcast();

  Stream<LatLng?> get searchStream => _searchStreamController.stream;

  void searchAt(LatLng center) {
    _searchStreamController.add(center);
  }

  void searchAtCenter() {
    _searchStreamController.add(null);
  }

  dispose() {
    _searchStreamController.close();
  }
}
