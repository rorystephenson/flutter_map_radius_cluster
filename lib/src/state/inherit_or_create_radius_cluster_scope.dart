import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_radius_cluster/src/state/inherited_radius_cluster_scope.dart';
import 'package:flutter_map_radius_cluster/src/state/radius_cluster_scope.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

class InheritOrCreateRadiusClusterScope extends StatelessWidget {
  final LatLng? initialCenter;
  final SuperclusterImmutable<Marker>? initialClustersAndMarkers;
  final Widget child;

  const InheritOrCreateRadiusClusterScope({
    super.key,
    required this.child,
    this.initialCenter,
    this.initialClustersAndMarkers,
  });

  @override
  Widget build(BuildContext context) {
    final radiusClusterScopeState =
        InheritedRadiusClusterScope.maybeOf(context, listen: false);

    return radiusClusterScopeState != null
        ? child
        : RadiusClusterScope(
            initialCenter: initialCenter,
            initialClustersAndMarkers: initialClustersAndMarkers,
            child: child,
          );
  }
}
