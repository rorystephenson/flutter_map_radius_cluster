import 'dart:async';

import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_event.dart';
import 'package:latlong2/latlong.dart';

import 'marker_identifier.dart';
import 'radius_cluster_controller.dart';

class RadiusClusterControllerImpl implements RadiusClusterController {
  final StreamController<RadiusClusterEvent> _streamController;

  RadiusClusterControllerImpl()
      : _streamController = StreamController.broadcast();

  Stream<RadiusClusterEvent> get stream => _streamController.stream;

  @override
  void searchAtCenter() {
    _streamController.add(const RadiusClusterEvent.searchAtCurrentCenter());
  }

  @override
  void searchAt(LatLng center) {
    _streamController.add(RadiusClusterEvent.searchAtPosition(center: center));
  }

  @override
  void moveToMarker(
    MarkerMatcher markerMatcher, {
    bool showPopup = true,
    FutureOr<void> Function(LatLng center, double zoom)? move,
  }) {
    _streamController.add(
      RadiusClusterEvent.moveToMarker(
        markerMatcher: markerMatcher,
        showPopup: showPopup,
        move: move,
      ),
    );
  }

  @override
  dispose() {
    _streamController.close();
  }
}
