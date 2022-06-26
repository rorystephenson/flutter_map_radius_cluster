import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:latlong2/latlong.dart';

class RadiusClusterStateImpl with ChangeNotifier implements RadiusClusterState {
  bool _lastSearchErrored = false;
  LatLng? _searchCenter;
  Supercluster<Marker>? _clustersAndMarkers;

  @override
  bool get error => _lastSearchErrored;

  @override
  LatLng? get center => _searchCenter;

  @override
  Supercluster<Marker>? get clustersAndMarkers => _clustersAndMarkers;

  bool _outsidePreviousSearchBoundary = false;

  RadiusClusterStateImpl({
    LatLng? initialCenter,
    Supercluster<Marker>? initialClustersAndMarkers,
  })  : _searchCenter = initialCenter,
        _clustersAndMarkers = initialClustersAndMarkers;

  void initiateSearch(LatLng center) {
    _lastSearchErrored = false;
    _searchCenter = center;
    _clustersAndMarkers = null;
    notifyListeners();
  }

  void setSearchResult(Supercluster<Marker> clustersAndMarkers) {
    _clustersAndMarkers = clustersAndMarkers;
    notifyListeners();
  }

  void setSearchErrored() {
    _lastSearchErrored = true;
    notifyListeners();
  }

  List<ClusterOrMapPoint<Marker>> getClustersAndPointsIn(
      LatLngBounds bounds, int zoom) {
    if (_clustersAndMarkers == null) return [];

    return _clustersAndMarkers!.getClustersAndPoints(
      bounds.west,
      bounds.south,
      bounds.east,
      bounds.north,
      zoom,
    );
  }

  @override
  RadiusSearchState get searchState {
    if (_clustersAndMarkers != null) {
      return RadiusSearchState.complete;
    } else if (_lastSearchErrored == true) {
      return RadiusSearchState.error;
    } else if (_searchCenter == null) {
      return RadiusSearchState.noSearchPerformed;
    } else {
      return RadiusSearchState.loading;
    }
  }

  @override
  RadiusSearchNextSearchState get nextSearchState {
    switch (searchState) {
      case RadiusSearchState.complete:
        if (!outsidePreviousSearchBoundary) {
          return RadiusSearchNextSearchState.disabled;
        }
        return RadiusSearchNextSearchState.ready;
      case RadiusSearchState.noSearchPerformed:
        return RadiusSearchNextSearchState.ready;
      case RadiusSearchState.loading:
        return RadiusSearchNextSearchState.loading;
      case RadiusSearchState.error:
        return RadiusSearchNextSearchState.error;
    }
  }

  @override
  bool get outsidePreviousSearchBoundary => _outsidePreviousSearchBoundary;

  set outsidePreviousSearchBoundary(bool newValue) {
    if (newValue != _outsidePreviousSearchBoundary) {
      _outsidePreviousSearchBoundary = newValue;
      notifyListeners();
    }
  }
}
