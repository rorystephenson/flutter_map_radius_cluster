import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'radius_cluster_state_impl.dart';

abstract class RadiusClusterState with ChangeNotifier {
  factory RadiusClusterState({
    LatLng? initialCenter,
    Supercluster<Marker>? initialClustersAndMarkers,
  }) = RadiusClusterStateImpl;

  bool get error;

  LatLng? get center;

  Supercluster<Marker>? get clustersAndMarkers;

  RadiusSearchState get searchState;

  RadiusSearchNextSearchState get nextSearchState;

  bool get outsidePreviousSearchBoundary;

  static RadiusClusterState? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) =>
      Provider.of<RadiusClusterState?>(context, listen: listen);
}

enum RadiusSearchState {
  complete,
  loading,
  error,
  noSearchPerformed,
}

enum RadiusSearchNextSearchState {
  ready,
  loading,
  error,
  disabled,
}
