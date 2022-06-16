import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

import '../flutter_map_radius_cluster.dart';

class RadiusClusterLayerWidget extends StatelessWidget {
  final RadiusClusterLayerOptions options;

  const RadiusClusterLayerWidget({Key? key, required this.options})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    return RadiusClusterLayer(options, mapState, mapState.onMoved);
  }
}
