import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

import '../flutter_map_radius_cluster.dart';

class RadiusClusterPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<void> stream) {
    return RadiusClusterLayerWidget(
      options: options as RadiusClusterLayerOptions,
    );
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is RadiusClusterLayerOptions;
  }
}
