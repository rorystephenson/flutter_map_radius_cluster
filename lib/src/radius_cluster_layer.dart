import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

import 'controller/radius_cluster_controller.dart';
import 'options/popup_options.dart';
import 'options/search_circle_options.dart';
import 'radius_cluster_layer_impl.dart';
import 'state/radius_cluster_scope.dart';
import 'state/radius_cluster_state.dart';

typedef ClusterWidgetBuilder = Widget Function(
    BuildContext context, ClusterDataBase? clusterData);

typedef FixedOverlayBuilder = Widget Function(
  BuildContext context,
  RadiusClusterController controller,
  RadiusClusterState radiusClusterState,
);

typedef ClusterTapHandler = void Function(
  ImmutableLayerCluster<Marker> cluster,
  LatLng center,
  double expansionZoom,
);

class RadiusClusterLayer extends StatelessWidget {
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

  /// Function to call when a Marker is tapped
  final void Function(Marker)? onMarkerTap;

  /// Function to call when a cluster is tapped. Use this to zoom in to view
  /// the cluster's Markers by zooming the map to the provided [expansionZoom].
  final ClusterTapHandler? onClusterTap;

  /// Popup's options that show when tapping markers or via the PopupController.
  final PopupOptions? popupOptions;

  /// If true markers will be counter rotated to the map rotation
  final bool? rotate;

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  final Offset? rotateOrigin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [rotateOrigin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? rotateAlignment;

  /// Cluster size
  final Size clusterWidgetSize;

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
    this.onMarkerTap,
    this.onClusterTap,
    this.popupOptions,
    this.rotate,
    this.rotateOrigin,
    this.rotateAlignment,
    this.clusterWidgetSize = const Size(30, 30),
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
      onMarkerTap: onMarkerTap,
      onClusterTap: onClusterTap,
      popupOptions: popupOptions,
      rotate: rotate,
      rotateOrigin: rotateOrigin,
      rotateAlignment: rotateAlignment,
      clusterWidgetSize: clusterWidgetSize,
      anchor: anchor,
    );
  }
}
