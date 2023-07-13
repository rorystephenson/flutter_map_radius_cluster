import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/layer_element_extension.dart';
import 'package:flutter_map_radius_cluster/src/map_camera_extension.dart';
import 'package:flutter_map_radius_cluster/src/radius_cluster_layer.dart';
import 'package:flutter_map_radius_cluster/src/splay/cluster_splay_delegate.dart';
import 'package:flutter_map_radius_cluster/src/splay/displaced_marker.dart';
import 'package:flutter_map_radius_cluster/src/splay/displaced_marker_offset.dart';
import 'package:supercluster/supercluster.dart';

class ExpandedCluster {
  final LayerCluster<Marker> layerCluster;
  final List<DisplacedMarker> displacedMarkers;
  final Size maxMarkerSize;
  final ClusterSplayDelegate clusterSplayDelegate;
  late final Map<Marker, DisplacedMarker> markersToDisplacedMarkers;

  final AnimationController animation;
  late final CurvedAnimation _splayAnimation;
  late final CurvedAnimation _clusterOpacityAnimation;

  ExpandedCluster({
    required TickerProvider vsync,
    required this.layerCluster,
    required MapCamera camera,
    required List<LayerPoint<Marker>> layerPoints,
    required this.clusterSplayDelegate,
  })  : animation = AnimationController(
          vsync: vsync,
          duration: clusterSplayDelegate.duration,
        ),
        displacedMarkers = clusterSplayDelegate.displaceMarkers(
          layerPoints.map((e) => e.originalPoint).toList(),
          clusterPosition: layerCluster.latLng,
          project: (latLng) =>
              camera.project(latLng, layerCluster.highestZoom.toDouble()),
          unproject: (point) =>
              camera.unproject(point, layerCluster.highestZoom.toDouble()),
        ),
        maxMarkerSize = layerPoints.fold(
          Size.zero,
          (previous, layerPoint) => Size(
            max(previous.width, layerPoint.originalPoint.width),
            max(previous.height, layerPoint.originalPoint.height),
          ),
        ) {
    markersToDisplacedMarkers = {
      for (final displacedMarker in displacedMarkers)
        displacedMarker.marker: displacedMarker
    };
    _splayAnimation = CurvedAnimation(
      parent: animation,
      curve: clusterSplayDelegate.curve,
    );
    _clusterOpacityAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(0.2, 1.0, curve: clusterSplayDelegate.curve),
    );
  }

  int get minimumVisibleZoom => layerCluster.highestZoom;

  ClusterDataBase? get clusterData => layerCluster.clusterData;

  List<DisplacedMarkerOffset> displacedMarkerOffsets(
    MapCamera camera,
    CustomPoint clusterPosition,
  ) =>
      clusterSplayDelegate.displacedMarkerOffsets(
        displacedMarkers,
        animation.value,
        camera.getPixelOffset,
        clusterPosition,
      );

  Widget? splayDecoration(List<DisplacedMarkerOffset> displacedMarkerOffsets) =>
      clusterSplayDelegate.splayDecoration(displacedMarkerOffsets);

  Widget buildCluster(
    BuildContext context,
    ClusterWidgetBuilder clusterBuilder,
  ) =>
      clusterSplayDelegate.buildCluster(
        context,
        clusterBuilder,
        layerCluster.latLng,
        clusterData,
        animation.value,
      );

  double get splay => _splayAnimation.value;

  double get splayDistance => clusterSplayDelegate.distance;

  bool get isExpanded => animation.status == AnimationStatus.completed;

  bool get collapsing =>
      animation.isAnimating && animation.status == AnimationStatus.reverse;

  Iterable<Marker> get markers =>
      displacedMarkers.map((displacedMarker) => displacedMarker.marker);

  void tryCollapse(void Function(TickerFuture collapseTicker) onCollapse) {
    if (!collapsing) onCollapse(animation.reverse());
  }

  void dispose() {
    _splayAnimation.dispose();
    _clusterOpacityAnimation.dispose();
    animation.dispose();
  }
}
