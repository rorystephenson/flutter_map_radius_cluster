import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:latlong2/latlong.dart';

class RadiusClusterStateImpl with ChangeNotifier implements RadiusClusterState {
  bool _lastSearchErrored = false;
  LatLng? _searchCenter;
  SuperclusterImmutable<Marker>? _supercluster;

  @override
  bool get error => _lastSearchErrored;

  @override
  LatLng? get center => _searchCenter;

  @override
  SuperclusterImmutable<Marker>? get supercluster => _supercluster;

  bool _outsidePreviousSearchBoundary = false;

  RadiusClusterStateImpl({
    LatLng? initialCenter,
    SuperclusterImmutable<Marker>? initialSupercluster,
  })  : _searchCenter = initialCenter,
        _supercluster = initialSupercluster;

  void initiateSearch(LatLng center) {
    _lastSearchErrored = false;
    _searchCenter = center;
    _supercluster = null;
    notifyListeners();
  }

  void setSearchResult(SuperclusterImmutable<Marker> supercluster) {
    _supercluster = supercluster;
    notifyListeners();
  }

  void setSearchErrored() {
    _lastSearchErrored = true;
    notifyListeners();
  }

  List<ImmutableLayerElement<Marker>> getLayerElementsIn(
      LatLngBounds bounds, int zoom) {
    if (_supercluster == null) return [];

    return _supercluster!.search(
      bounds.west,
      bounds.south,
      bounds.east,
      bounds.north,
      zoom,
    );
  }

  @override
  RadiusSearchState get searchState {
    if (_supercluster != null) {
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
