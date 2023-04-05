import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:supercluster/supercluster.dart';

import 'map_calculator.dart';
import 'radius_cluster_layer.dart';

class ClusterWidget extends StatelessWidget {
  final LayerCluster<Marker> cluster;
  final ClusterWidgetBuilder builder;
  final VoidCallback? onTap;
  final Size size;
  final Point<double> position;

  ClusterWidget({
    Key? key,
    required MapCalculator mapCalculator,
    required this.cluster,
    required this.builder,
    required this.onTap,
    required this.size,
  })  : position = _getClusterPixel(mapCalculator, cluster),
        super(key: ValueKey(cluster.uuid));

  @override
  Widget build(BuildContext context) {
    final clusterData = cluster.clusterData as ClusterDataBase;
    return Positioned(
      width: size.width,
      height: size.height,
      left: position.x,
      top: position.y,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: builder(context, clusterData),
      ),
    );
  }

  static Point<double> _getClusterPixel(
    MapCalculator mapCalculator,
    LayerCluster<Marker> cluster,
  ) {
    final pos =
        mapCalculator.getPixelOffset(mapCalculator.clusterPoint(cluster));

    return mapCalculator.removeClusterAnchor(pos, cluster);
  }
}
