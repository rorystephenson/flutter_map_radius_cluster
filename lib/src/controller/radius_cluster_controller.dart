import 'dart:async';

import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/controller/marker_matcher.dart';
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

    /// The [moveMap] callback may be provided to control the necessary map
    /// movement in order to make the [Marker] visible. If a search is required
    /// to find the Marker an initial movement will be made to center the map
    /// at the [markerMatcher] Marker's point before zooming in on the Marker
    /// once the search completes.
    ///
    /// The [center] is the marker's position whilst the [zoom] is the current
    /// zoom if the marker is visible, otherwise it is the minimum zoom
    /// necessary to uncluster the marker. If the marker is in a splay cluster
    // the cluster will be splayed once the move is complete. If no callback is
    /// provided the RadiusClusterLayer's [moveMap] is used.
    ///
    /// If [moveMap] is provided it should handle cancelling existing movements
    // when a movement is initiated.
    FutureOr<void> Function(LatLng center, double zoom)? moveMap,
  });

  /// Collapses any splayed clusters. See RadiusClusterLayer's
  /// [clusterSplayDelegate] for more information on splaying.
  void collapseSplayedClusters();

  /// Show popups for the given [markers]. If a popup is already showing for a
  /// given marker it remains visible. If a marker is not visible at the
  /// current zoom the popup for that marker will not be shown.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing the popups.
  ///
  /// Has no effect if the RadiusClusterLayer's popupOptions are null.
  void showPopupsAlsoFor(List<Marker> markers, {bool disableAnimation = false});

  /// Show popups only for the given [markers]. All other popups will be
  /// hidden. If a popup is already showing for a given marker it remains
  /// visible. If a marker is not visible at the current zoom the popup for
  /// that marker will not be shown.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing/hiding the popups.
  ///
  /// Has no effect if the RadiusClusterLayer's popupOptions are null.
  void showPopupsOnlyFor(List<Marker> markers, {bool disableAnimation = false});

  /// Hide all popups that are showing.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  ///
  /// Has no effect if the RadiusClusterLayer's popupOptions are null.
  void hideAllPopups({bool disableAnimation = false});

  /// Hide popups for which the provided [test] return true.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  ///
  /// Has no effect if the RadiusClusterLayer's popupOptions are null.
  void hidePopupsWhere(
    bool Function(Marker marker) test, {
    bool disableAnimation = false,
  });

  /// Hide popups showing for any of the given markers.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when hiding the popups.
  ///
  /// Has no effect if the RadiusClusterLayer's popupOptions are null.
  void hidePopupsOnlyFor(List<Marker> markers, {bool disableAnimation = false});

  /// Hide the popup if it is showing for the given [marker], otherwise show it
  /// for that [marker]. If the marker is not visible at the current zoom
  /// nothing happens.
  ///
  /// If [disableAnimation] is true and a popup animation is enabled then the
  /// animation will not be used when showing/hiding the popup.
  ///
  /// Has no effect if the RadiusClusterLayer's popupOptions are null.
  void togglePopup(Marker marker, {bool disableAnimation = false});

  /// Dispose of the controller.
  void dispose();
}
