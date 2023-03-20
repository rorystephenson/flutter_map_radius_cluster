import 'package:flutter/foundation.dart';
import 'package:flutter_map_radius_cluster/src/controller/marker_identifier.dart';
import 'package:flutter_map_radius_cluster/src/controller/show_popup_options.dart';
import 'package:latlong2/latlong.dart';

@immutable
abstract class RadiusClusterEvent {
  const RadiusClusterEvent._();

  const factory RadiusClusterEvent.searchAtCurrentCenter() =
      _SearchAtCurrentCenterEvent._;

  const factory RadiusClusterEvent.searchAtPosition({
    required LatLng center,
  }) = _SearchAtPositionEvent._;

  const factory RadiusClusterEvent.moveToMarker({
    required MarkerMatcher markerMatcher,
    required bool centerMarker,
    required ShowPopupOptions? showPopupOptions,
  }) = _MoveToMarkerEvent._;

  void handle({
    required VoidCallback searchAtCurrentCenter,
    required void Function({required LatLng center}) searchAtPosition,
    required void Function({
      required MarkerMatcher markerMatcher,
      required bool centerMarker,
      required ShowPopupOptions? showPopupOptions,
    })
        moveToMarker,
  }) {
    final event = this;

    if (event is _SearchAtCurrentCenterEvent) {
      searchAtCurrentCenter();
    } else if (event is _SearchAtPositionEvent) {
      searchAtPosition(center: event.center);
    } else if (event is _MoveToMarkerEvent) {
      moveToMarker(
        markerMatcher: event.markerMatcher,
        centerMarker: event.centerMarker,
        showPopupOptions: event.showPopupOptions,
      );
    } else {
      throw 'Unexpected RadiusCLusterEvent: $event';
    }
  }
}

class _SearchAtCurrentCenterEvent extends RadiusClusterEvent {
  const _SearchAtCurrentCenterEvent._() : super._();
}

class _SearchAtPositionEvent extends RadiusClusterEvent {
  final LatLng center;

  const _SearchAtPositionEvent._({
    required this.center,
  }) : super._();
}

class _MoveToMarkerEvent extends RadiusClusterEvent {
  final MarkerMatcher markerMatcher;
  final bool centerMarker;
  final ShowPopupOptions? showPopupOptions;

  const _MoveToMarkerEvent._({
    required this.markerMatcher,
    required this.centerMarker,
    required this.showPopupOptions,
  }) : super._();
}
