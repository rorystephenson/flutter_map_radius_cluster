import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';

extension RadiusClusterStateExtension on RadiusClusterState {
  List<ImmutableLayerElement<Marker>> getLayerElementsIn(
      LatLngBounds bounds, int zoom) {
    if (supercluster == null) return [];

    return supercluster!.search(
      bounds.west,
      bounds.south,
      bounds.east,
      bounds.north,
      zoom,
    );
  }

  List<ImmutableLayerElement<Marker>> childrenOf(
          ImmutableLayerCluster<Marker> cluster) =>
      supercluster?.childrenOf(cluster) ?? [];
}
