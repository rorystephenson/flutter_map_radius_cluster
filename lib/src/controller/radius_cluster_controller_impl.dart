import 'dart:async';

import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_event.dart';
import 'package:latlong2/latlong.dart';

import 'marker_identifier.dart';
import 'radius_cluster_controller.dart';
import 'show_popup_options.dart';

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
    bool centerMarker = true,
    ShowPopupOptions? showPopupOptions,
  }) {
    _streamController.add(
      RadiusClusterEvent.moveToMarker(
        markerMatcher: markerMatcher,
        centerMarker: centerMarker,
        showPopupOptions: showPopupOptions,
      ),
    );
  }

  @override
  dispose() {
    _streamController.close();
  }
}
