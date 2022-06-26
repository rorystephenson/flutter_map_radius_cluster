import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

import 'radius_cluster_layer.dart';
import 'radius_cluster_layer_options.dart';
import 'state/radius_cluster_scope.dart';
import 'state/radius_cluster_state.dart';

class RadiusClusterLayerWidget extends StatelessWidget {
  final RadiusClusterLayerOptions options;

  const RadiusClusterLayerWidget({Key? key, required this.options})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.maybeOf(context)!;
    final state = RadiusClusterState.maybeOf(context);

    if (state != null) return _layer(mapState, state);

    return RadiusClusterScope(
      initialCenter: options.initialCenter,
      initialClustersAndMarkers: options.initialClustersAndMarkers,
      child: Builder(
        builder: (context) => _layer(
          mapState,
          RadiusClusterState.maybeOf(context)!,
        ),
      ),
    );
  }

  Widget _layer(MapState mapState, RadiusClusterState state) {
    return RadiusClusterLayer(
      options: options,
      mapState: mapState,
      stream: mapState.onMoved,
      initialRadiusClusterState: state,
    );
  }
}
