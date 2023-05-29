import 'dart:async';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/controller/marker_matcher.dart';
import 'package:latlong2/latlong.dart';

sealed class RadiusClusterEvent {
  const RadiusClusterEvent();
}

class SearchAtCurrentCenterEvent extends RadiusClusterEvent {
  const SearchAtCurrentCenterEvent();
}

class SearchAtPositionEvent extends RadiusClusterEvent {
  final LatLng center;

  const SearchAtPositionEvent(this.center);
}

class CollapseSplayedClustersEvent extends RadiusClusterEvent {
  const CollapseSplayedClustersEvent();
}

class MoveToMarkerEvent extends RadiusClusterEvent {
  final MarkerMatcher markerMatcher;
  final bool showPopup;
  final FutureOr<void> Function(LatLng center, double zoom)? moveMap;

  const MoveToMarkerEvent({
    required this.markerMatcher,
    required this.showPopup,
    required this.moveMap,
  });
}

class ShowPopupsAlsoForEvent extends RadiusClusterEvent {
  final List<Marker> markers;
  final bool disableAnimation;

  const ShowPopupsAlsoForEvent(
    this.markers, {
    required this.disableAnimation,
  });
}

class ShowPopupsOnlyForEvent extends RadiusClusterEvent {
  final List<Marker> markers;
  final bool disableAnimation;

  const ShowPopupsOnlyForEvent(
    this.markers, {
    required this.disableAnimation,
  });
}

class HideAllPopupsEvent extends RadiusClusterEvent {
  final bool disableAnimation;

  const HideAllPopupsEvent({required this.disableAnimation});
}

class HidePopupsWhereEvent extends RadiusClusterEvent {
  final bool Function(Marker marker) test;
  final bool disableAnimation;

  const HidePopupsWhereEvent(
    this.test, {
    required this.disableAnimation,
  });
}

class HidePopupsOnlyForEvent extends RadiusClusterEvent {
  final List<Marker> markers;

  final bool disableAnimation;

  const HidePopupsOnlyForEvent(
    this.markers, {
    required this.disableAnimation,
  });
}

class TogglePopupEvent extends RadiusClusterEvent {
  final Marker marker;
  final bool disableAnimation;

  const TogglePopupEvent(
    this.marker, {
    required this.disableAnimation,
  });
}
