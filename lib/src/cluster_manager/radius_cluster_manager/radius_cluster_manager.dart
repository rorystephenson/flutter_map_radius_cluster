import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:flutter_map_radius_cluster/src/cluster_manager/radius_cluster_manager/search_button.dart';
import 'package:flutter_map_radius_cluster/src/cluster_manager/radius_cluster_manager/search_radius_indicator.dart';
import 'package:latlong2/latlong.dart';

/// *... then run a mini server which serves up the pre-generated
class RadiusClusterManager {
  static const _distanceCalculator =
      Distance(roundResult: false, calculator: Haversine());

  final VoidCallback onUpdate;
  final RadiusClusterLayerOptions options;

  bool _lastSearchErrored = false;
  LatLng? _searchCenter;
  Supercluster<Marker>? _clustersAndMarkers;

  RadiusClusterManager({
    required this.onUpdate,
    required this.options,
  })  : _searchCenter = options.initialCenter,
        _clustersAndMarkers = options.initialClustersAndMarkers {
    if (options.initialCenter != null &&
        options.initialClustersAndMarkers == null) {
      searchAt(options.initialCenter!);
    }
  }

  void searchAt(LatLng center) async {
    _lastSearchErrored = false;
    _searchCenter = center;
    _clustersAndMarkers = null;
    onUpdate();

    try {
      _clustersAndMarkers = await options.search(options.radiusInKm, center);
    } catch (error, stackTrace) {
      _lastSearchErrored = true;
      if (options.onError == null) rethrow;
      options.onError!(error, stackTrace);
    } finally {
      onUpdate();
    }
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

  double getClusterExpansionZoom(Cluster<Marker> cluster) {
    if (_clustersAndMarkers == null) throw 'No clusters loaded';

    return _clustersAndMarkers!.getClusterExpansionZoom(cluster.id).toDouble();
  }

  Widget? buildRotatedOverlay(
      BuildContext context, MapCalculator mapCalculator) {
    if (_searchCenter == null) return null;

    return SearchRadiusIndicator(
      searchCenter: _searchCenter!,
      radiusSearchState: searchState,
      distanceCalculator: _distanceCalculator,
      mapCalculator: mapCalculator,
      radiusInM: options.radiusInKm * 1000,
      loadedBorderColor: options.loadedBorderColor,
      loadingBorderColor: options.loadingBorderColor,
      errorBorderColor: options.errorBorderColor,
      borderWidth: options.searchIndicatorBorderWidth,
    );
  }

  Widget? buildNonRotatedOverlay(
      BuildContext context, MapCalculator mapCalculator) {
    return SearchButton(
      searchAt: searchAt,
      searchCenter: _searchCenter,
      radiusSearchState: searchState,
      radiusInM: options.radiusInKm * 1000,
      distanceCalculator: _distanceCalculator,
      mapCalculator: mapCalculator,
    );
  }

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
}

enum RadiusSearchState {
  complete,
  loading,
  error,
  noSearchPerformed,
}
