import 'package:flutter_map_radius_cluster/src/controller/marker_identifier.dart';
import 'package:flutter_map_radius_cluster/src/controller/show_popup_options.dart';
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
  /// Zoom changes: If the markers is clustered at the current zoom the zoom
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
    /// Whether the map should be centered on the marker. Defaults to true.
    bool centerMarker = true,

    /// If [showPopupOptions] is provided and the target marker is successfully
    /// found its popup will be shown once the map has moved to the marker. Has
    /// no affect if popups are disabled.
    ShowPopupOptions? showPopupOptions,
  });

  /// Dispose of the controller.
  void dispose();
}
