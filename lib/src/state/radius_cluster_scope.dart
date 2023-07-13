import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/state/inherited_radius_cluster_scope.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

import 'radius_cluster_state.dart';

class RadiusClusterScope extends StatefulWidget {
  final LatLng? initialCenter;
  final SuperclusterImmutable<Marker>? initialClustersAndMarkers;
  final Widget child;

  const RadiusClusterScope({
    Key? key,
    this.initialCenter,
    this.initialClustersAndMarkers,
    required this.child,
  }) : super(key: key);

  @override
  State<RadiusClusterScope> createState() => _RadiusClusterScopeState();
}

class _RadiusClusterScopeState extends State<RadiusClusterScope> {
  late RadiusClusterState radiusClusterState;

  @override
  void initState() {
    super.initState();
    radiusClusterState = RadiusClusterState(
      center: widget.initialCenter,
      supercluster: widget.initialClustersAndMarkers,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InheritedRadiusClusterScope(
      radiusClusterState: radiusClusterState,
      setRadiusClusterState: (radiusClusterState) => setState(() {
        this.radiusClusterState = radiusClusterState;
      }),
      child: widget.child,
    );
  }
}
