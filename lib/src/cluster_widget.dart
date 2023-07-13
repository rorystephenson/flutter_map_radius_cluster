import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/anchor_util.dart';
import 'package:flutter_map_radius_cluster/src/layer_element_extension.dart';
import 'package:flutter_map_radius_cluster/src/map_camera_extension.dart';
import 'package:flutter_map_radius_cluster/src/radius_cluster_layer.dart';
import 'package:supercluster/supercluster.dart';

class ClusterWidget extends StatelessWidget {
  final LayerCluster<Marker> cluster;
  final ClusterWidgetBuilder builder;
  final VoidCallback onTap;
  final Size size;
  final Point<double> position;
  final double mapRotationRad;

  ClusterWidget({
    Key? key,
    required MapCamera camera,
    required this.cluster,
    required this.builder,
    required this.onTap,
    required this.size,
    required Anchor anchor,
  })  : position = AnchorUtil.removeAnchor(
          camera.getPixelOffset(cluster.latLng),
          size.width,
          size.height,
          anchor,
        ),
        mapRotationRad = camera.rotationRad,
        super(key: ValueKey(cluster.uuid));

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: size.width,
      height: size.height,
      left: position.x,
      top: position.y,
      child: Transform.rotate(
        angle: -mapRotationRad,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: builder(context, cluster.clusterData),
        ),
      ),
    );
  }
}
