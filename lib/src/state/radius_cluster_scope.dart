import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supercluster/supercluster.dart';

import 'radius_cluster_state.dart';

class RadiusClusterScope extends StatelessWidget {
  final LatLng? initialCenter;
  final Supercluster<Marker>? initialClustersAndMarkers;
  final Widget child;

  const RadiusClusterScope({
    Key? key,
    this.initialCenter,
    this.initialClustersAndMarkers,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RadiusClusterState>(
      create: (context) => RadiusClusterState(
        initialCenter: initialCenter,
        initialClustersAndMarkers: initialClustersAndMarkers,
      ),
      child: child,
    );
  }
}
