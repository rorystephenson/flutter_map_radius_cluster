import 'dart:async';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/controller/marker_matcher.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_event.dart';
import 'package:latlong2/latlong.dart';

import 'radius_cluster_controller.dart';

class RadiusClusterControllerImpl implements RadiusClusterController {
  final bool _createdInternally;
  final StreamController<RadiusClusterEvent> _streamController;

  RadiusClusterControllerImpl({bool createdInternally = false})
      : _createdInternally = createdInternally,
        _streamController = StreamController.broadcast();

  Stream<RadiusClusterEvent> get stream => _streamController.stream;

  @override
  void searchAtCenter() {
    _streamController.add(const SearchAtCurrentCenterEvent());
  }

  @override
  void searchAt(LatLng center) {
    _streamController.add(SearchAtPositionEvent(center));
  }

  @override
  void collapseSplayedClusters() {
    _streamController.add(const CollapseSplayedClustersEvent());
  }

  @override
  void hideAllPopups({bool disableAnimation = false}) {
    _streamController.add(
      HideAllPopupsEvent(disableAnimation: disableAnimation),
    );
  }

  @override
  void hidePopupsOnlyFor(
    List<Marker> markers, {
    bool disableAnimation = false,
  }) {
    _streamController.add(
      HidePopupsOnlyForEvent(markers, disableAnimation: disableAnimation),
    );
  }

  @override
  void hidePopupsWhere(
    bool Function(Marker marker) test, {
    bool disableAnimation = false,
  }) {
    _streamController.add(
      HidePopupsWhereEvent(test, disableAnimation: disableAnimation),
    );
  }

  @override
  void moveToMarker(
    MarkerMatcher markerMatcher, {
    bool showPopup = true,
    FutureOr<void> Function(LatLng center, double zoom)? moveMap,
  }) {
    _streamController.add(
      MoveToMarkerEvent(
        markerMatcher: markerMatcher,
        showPopup: showPopup,
        moveMap: moveMap,
      ),
    );
  }

  @override
  void showPopupsAlsoFor(
    List<Marker> markers, {
    bool disableAnimation = false,
  }) {
    _streamController.add(
      ShowPopupsAlsoForEvent(markers, disableAnimation: disableAnimation),
    );
  }

  @override
  void showPopupsOnlyFor(
    List<Marker> markers, {
    bool disableAnimation = false,
  }) {
    _streamController.add(
      ShowPopupsOnlyForEvent(markers, disableAnimation: disableAnimation),
    );
  }

  @override
  void togglePopup(Marker marker, {bool disableAnimation = false}) {
    _streamController.add(
      TogglePopupEvent(marker, disableAnimation: disableAnimation),
    );
  }

  @override
  void dispose() {
    _streamController.close();
  }

  void disposeIfCreatedInternally() {
    if (_createdInternally) dispose();
  }
}
