import 'dart:async';

import 'package:flutter_map_radius_cluster/src/controller/marker_identifier.dart';
import 'package:latlong2/latlong.dart';

import 'radius_cluster_controller_impl.dart';

abstract class RadiusClusterController {
  factory RadiusClusterController() = RadiusClusterControllerImpl;

  /// Initiate a search at the map's current center.
  void searchAtCenter();

  /// Initiate a search at [center].
  void searchAt(LatLng center);

  /// Moves the map to make the given [marker] visible. Zoom changes and
  /// searches may occur if neccessary as described below.
  ///
  /// Zoom changes: If the marker is clustered at the current zoom the zoom
  /// will be increased to the minimum neccesary to view the Marker.
  ///
  /// Searches triggered:
  ///
  /// * If no search results are present or the marker's position is outside of
  ///   the current search boundary a new search will be triggered centred on
  ///   the marker.
  /// * If search results are present and the marker's position is within the
  ///   search results boundary but the marker is not found within the search
  ///   results a new search will be triggered on the assumption that the
  ///   marker was previously filtered out of search results.
  void moveToMarker(
    MarkerMatcher markerMatcher, {
    /// Whether the target Marker's popup should be shown if the Marker is
    /// successfully found, defaults to true. This option has no affect if
    /// popups are disabled.
    bool showPopup,

    /// If [move] is provided it will control the movement. Two movements may
    /// occur, first to center the map at the Marker's center and second to
    /// zoom in to the Marker if required. If [zoom] is provided it should
    /// handle cancelling existing movements when a movement is initiated.
    FutureOr<void> Function(LatLng center, double zoom)? move,
  });

  /// Dispose of the controller.
  void dispose();
}
