import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_radius_cluster/src/cluster_widget.dart';
import 'package:flutter_map_radius_cluster/src/flutter_map_state_extension.dart';
import 'package:flutter_map_radius_cluster/src/layer_element_extension.dart';
import 'package:flutter_map_radius_cluster/src/marker_widget.dart';
import 'package:flutter_map_radius_cluster/src/popup_spec_builder.dart';
import 'package:flutter_map_radius_cluster/src/radius_cluster_layer.dart';
import 'package:flutter_map_radius_cluster/src/splay/expanded_cluster.dart';

class ExpandableClusterWidget extends StatelessWidget {
  final FlutterMapState mapState;
  final ExpandedCluster expandedCluster;
  final ClusterWidgetBuilder builder;
  final Size size;
  final AnchorPos? anchorPos;
  final Widget Function(BuildContext, Marker) markerBuilder;
  final void Function(PopupSpec popupSpec) onMarkerTap;
  final VoidCallback onCollapse;
  final CustomPoint clusterPixelPosition;

  ExpandableClusterWidget({
    Key? key,
    required this.mapState,
    required this.expandedCluster,
    required this.builder,
    required this.size,
    required this.anchorPos,
    required this.markerBuilder,
    required this.onMarkerTap,
    required this.onCollapse,
  })  : clusterPixelPosition =
            mapState.getPixelOffset(expandedCluster.layerCluster.latLng),
        super(key: ValueKey('expandable-${expandedCluster.layerCluster.uuid}'));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: expandedCluster.animation,
      builder: (context, _) {
        final displacedMarkerOffsets = expandedCluster.displacedMarkerOffsets(
          mapState,
          clusterPixelPosition,
        );
        final splayDecoration = expandedCluster.splayDecoration(
          displacedMarkerOffsets,
        );

        return Positioned.fill(
          child: Stack(
            children: [
              if (splayDecoration != null)
                Positioned(
                  left: clusterPixelPosition.x - expandedCluster.splayDistance,
                  top: clusterPixelPosition.y - expandedCluster.splayDistance,
                  width: expandedCluster.splayDistance * 2,
                  height: expandedCluster.splayDistance * 2,
                  child: splayDecoration,
                ),
              ...displacedMarkerOffsets.map(
                (offset) => MarkerWidget.displaced(
                  displacedMarker: offset.displacedMarker,
                  position: clusterPixelPosition + offset.displacedOffset,
                  markerBuilder: (context) => markerBuilder(
                    context,
                    offset.displacedMarker.marker,
                  ),
                  onTap: () => onMarkerTap(
                    PopupSpecBuilder.forDisplacedMarker(
                      offset.displacedMarker,
                      expandedCluster.minimumVisibleZoom,
                    ),
                  ),
                  mapRotationRad: mapState.rotationRad,
                ),
              ),
              ClusterWidget(
                mapState: mapState,
                cluster: expandedCluster.layerCluster,
                builder: (context, data) =>
                    expandedCluster.buildCluster(context, builder),
                onTap: expandedCluster.isExpanded ? onCollapse : () {},
                size: size,
                anchorPos: anchorPos,
              ),
            ],
          ),
        );
      },
    );
  }
}
