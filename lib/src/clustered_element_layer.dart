import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:flutter_map_radius_cluster/src/cluster_widget.dart';
import 'package:flutter_map_radius_cluster/src/map_camera_extension.dart';
import 'package:flutter_map_radius_cluster/src/marker_widget.dart';
import 'package:flutter_map_radius_cluster/src/options/popup_options_impl.dart';
import 'package:flutter_map_radius_cluster/src/popup_spec_builder.dart';
import 'package:flutter_map_radius_cluster/src/splay/expandable_cluster_widget.dart';
import 'package:flutter_map_radius_cluster/src/splay/expanded_cluster.dart';
import 'package:flutter_map_radius_cluster/src/splay/expanded_cluster_manager.dart';
import 'package:flutter_map_radius_cluster/src/state/radius_cluster_state_extension.dart';

class ClusteredElementLayer extends StatelessWidget {
  final MapCamera camera;
  final PopupOptionsImpl? popupOptions;
  final Size clusterWidgetSize;
  final PopupState? popupState;
  final ExpandedClusterManager expandedClusterManager;
  final ClusterWidgetBuilder clusterBuilder;
  final void Function(PopupSpec popupSpec) onMarkerTap;
  final void Function(ImmutableLayerCluster<Marker> cluster) onClusterTap;
  final Anchor clusterAnchor;

  const ClusteredElementLayer({
    super.key,
    required this.camera,
    required this.popupOptions,
    required this.clusterWidgetSize,
    required this.popupState,
    required this.expandedClusterManager,
    required this.clusterBuilder,
    required this.onMarkerTap,
    required this.onClusterTap,
    required this.clusterAnchor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [..._buildClustersAndMarkers(RadiusClusterState.of(context))],
    );
  }

  Iterable<Widget> _buildClustersAndMarkers(
      RadiusClusterState radiusClusterState) sync* {
    final paddedBounds = camera.paddedMapBounds(clusterWidgetSize);

    final selectedMarkerBuilder =
        popupOptions != null && popupState!.selectedMarkers.isNotEmpty
            ? popupOptions!.selectedMarkerBuilder
            : null;
    List<ImmutableLayerPoint<Marker>> selectedLayerPoints = [];
    final List<ImmutableLayerCluster<Marker>> clusters = [];

    for (final layerElement in radiusClusterState.getLayerElementsIn(
      paddedBounds,
      camera.zoom.ceil(),
    )) {
      if (layerElement is ImmutableLayerCluster<Marker>) {
        clusters.add(layerElement);
        continue;
      }
      layerElement as ImmutableLayerPoint<Marker>;
      if (selectedMarkerBuilder != null &&
          popupState!.selectedMarkers.contains(layerElement.originalPoint)) {
        selectedLayerPoints.add(layerElement);
        continue;
      }
      yield _buildMarker(layerElement);
    }

    // Build selected markers.
    for (final selectedLayerPoint in selectedLayerPoints) {
      yield _buildMarker(selectedLayerPoint, selected: true);
    }

    // Build non expanded clusters.
    for (final cluster in clusters) {
      if (expandedClusterManager.contains(cluster)) continue;
      yield _buildCluster(cluster);
    }

    // Build expanded clusters.
    for (final expandedCluster in expandedClusterManager.all) {
      yield _buildExpandedCluster(expandedCluster);
    }
  }

  Widget _buildMarker(
    ImmutableLayerPoint<Marker> layerPoint, {
    bool selected = false,
  }) {
    final marker = layerPoint.originalPoint;

    final markerBuilder = !selected
        ? marker.builder
        : (context) => popupOptions!.selectedMarkerBuilder!(context, marker);

    return MarkerWidget(
      camera: camera,
      marker: marker,
      markerBuilder: markerBuilder,
      onTap: () => onMarkerTap(PopupSpecBuilder.forLayerPoint(layerPoint)),
    );
  }

  Widget _buildCluster(ImmutableLayerCluster<Marker> cluster) {
    return ClusterWidget(
      camera: camera,
      cluster: cluster,
      builder: clusterBuilder,
      onTap: () => onClusterTap(cluster),
      size: clusterWidgetSize,
      anchor: clusterAnchor,
    );
  }

  Widget _buildExpandedCluster(ExpandedCluster expandedCluster) {
    final selectedMarkerBuilder = popupOptions?.selectedMarkerBuilder;
    final Widget Function(BuildContext context, Marker marker) markerBuilder =
        selectedMarkerBuilder == null
            ? ((context, marker) => marker.builder(context))
            : ((context, marker) =>
                popupState?.selectedMarkers.contains(marker) == true
                    ? selectedMarkerBuilder(context, marker)
                    : marker.builder(context));

    return ExpandableClusterWidget(
      camera: camera,
      expandedCluster: expandedCluster,
      builder: clusterBuilder,
      size: clusterWidgetSize,
      anchor: clusterAnchor,
      markerBuilder: markerBuilder,
      onCollapse: () {
        popupOptions?.popupController
            .hidePopupsOnlyFor(expandedCluster.markers.toList());
        expandedClusterManager.collapseThenRemove(expandedCluster.layerCluster);
      },
      onMarkerTap: onMarkerTap,
    );
  }
}
