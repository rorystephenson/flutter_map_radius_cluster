import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/options/popup_options_impl.dart';
import 'package:flutter_map_radius_cluster/src/splay/cluster_splay_delegate.dart';
import 'package:flutter_map_radius_cluster/src/splay/spread_cluster_splay_delegate.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

import 'controller/radius_cluster_controller.dart';
import 'options/popup_options.dart';
import 'options/search_circle_options.dart';
import 'radius_cluster_layer_impl.dart';
import 'state/radius_cluster_scope.dart';
import 'state/radius_cluster_state.dart';

/// Builder for the cluster widget.
typedef ClusterWidgetBuilder = Widget Function(
  BuildContext context,
  ClusterDataBase? clusterData,
);

typedef FixedOverlayBuilder = Widget Function(
  BuildContext context,
  RadiusClusterController controller,
  RadiusClusterState radiusClusterState,
);

/// See [RadiusClusterLayer.moveMap].
typedef MoveMapCallback = FutureOr<void> Function(LatLng center, double zoom);

class RadiusClusterLayer extends StatelessWidget {
  static const popupNamespace = 'flutter_map_radius_cluster';

  /// The function which returns the clusters and markers for the given radius
  /// and search center. Do not handle errors that occur as they are captured
  /// and used to determine the button and search circle indicator states. Use
  /// the [onError] callback if you wish to log/otherwise react to errors.
  final Future<SuperclusterImmutable<Marker>> Function(
      double radius, LatLng center) search;

  /// Cluster builder
  final ClusterWidgetBuilder clusterBuilder;

  /// Controller for triggering searches.
  final RadiusClusterController? controller;

  /// The cluster search radius
  final double radiusInKm;

  /// An optional builder which allows you to overlay this layer with widgets
  /// which will not rotate with the map, usually a search button.
  final FixedOverlayBuilder? fixedOverlayBuilder;

  /// The initial cluster search center. If [initialClustersAndMarkers] is not
  /// provided then a search will be performed immediately.
  final LatLng? initialCenter;

  /// The initial clusters and markers to display on the map. If this is
  /// non-null then [initialCenter] must be provided.
  final SuperclusterImmutable<Marker>? initialClustersAndMarkers;

  /// The minimum distance between searches. If the last search was successful
  /// and the last search center point is less than this distance from the
  /// current map center then the search button will be disabled and the next
  /// search indicator will be hidden.
  final double? minimumSearchDistanceDifferenceInKm;

  /// An optional callback to log/report errors that occur in the Future
  /// returned by the [search] callback.
  final Function(dynamic error, StackTrace stackTrace)? onError;

  /// The options for search circle in its various states.
  final SearchCircleOptions searchCircleOptions;

  /// When tapping a cluster or moving to a [Marker] with
  /// [RadiusClusterController]'s moveToMarker method this callback controls
  /// if/how the movement is performed. The default is to move with no
  /// animation.
  ///
  /// When moving to a splay cluster (see [clusterSplayDelegate]) or a [Marker]
  /// inside a splay cluster the splaying will start once this callback
  /// completes.
  final MoveMapCallback? moveMap;

  /// Function to call when a Marker is tapped
  final void Function(Marker)? onMarkerTap;

  /// Popup's options that show when tapping markers or via the PopupController.
  final PopupOptions? popupOptions;

  /// Cluster size
  final Size clusterWidgetSize;

  /// Splaying occurs when it is not possible to open a cluster because its
  /// points are visible at a zoom higher than the max zoom. This delegate
  /// controls the animation and style of the cluster splaying.
  final ClusterSplayDelegate clusterSplayDelegate;

  /// Cluster anchor
  final AnchorPos? anchor;

  RadiusClusterLayer({
    Key? key,
    required this.search,
    required this.clusterBuilder,
    this.controller,
    this.radiusInKm = 100,
    this.fixedOverlayBuilder,
    this.initialCenter,
    this.initialClustersAndMarkers,
    this.minimumSearchDistanceDifferenceInKm,
    this.onError,
    SearchCircleOptions? searchCircleOptions,
    Color? nextSearchIndicatorColor,
    this.moveMap,
    this.onMarkerTap,
    this.popupOptions,
    this.clusterWidgetSize = const Size(30, 30),
    this.clusterSplayDelegate = const SpreadClusterSplayDelegate(
      duration: Duration(milliseconds: 300),
      splayLineOptions: SplayLineOptions(),
    ),
    this.anchor,
  })  : assert(initialClustersAndMarkers == null || initialCenter != null,
            'If initialClustersAndMarkers is provided initialCenter is required.'),
        searchCircleOptions = searchCircleOptions ?? SearchCircleOptions(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = FlutterMapState.maybeOf(context)!;
    final state = RadiusClusterState.maybeOf(context);

    if (state != null) return _layer(mapState, state);

    return RadiusClusterScope(
      initialCenter: initialCenter,
      initialClustersAndMarkers: initialClustersAndMarkers,
      child: Builder(
        builder: (context) => _layer(
          mapState,
          RadiusClusterState.maybeOf(context)!,
        ),
      ),
    );
  }

  Widget _layer(FlutterMapState mapState, RadiusClusterState state) {
    return RadiusClusterLayerImpl(
      mapState: mapState,
      initialRadiusClusterState: state,
      search: search,
      clusterBuilder: clusterBuilder,
      controller: controller,
      radiusInKm: radiusInKm,
      fixedOverlayBuilder: fixedOverlayBuilder,
      minimumSearchDistanceDifferenceInKm: minimumSearchDistanceDifferenceInKm,
      onError: onError,
      searchCircleOptions: searchCircleOptions,
      moveMap: moveMap,
      onMarkerTap: onMarkerTap,
      popupOptions: popupOptions as PopupOptionsImpl,
      clusterWidgetSize: clusterWidgetSize,
      clusterSplayDelegate: clusterSplayDelegate,
      anchor: anchor,
    );
  }
}
