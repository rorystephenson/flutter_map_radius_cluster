import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:flutter_map_radius_cluster/src/state/inherited_radius_cluster_scope.dart';
import 'package:latlong2/latlong.dart';

final class RadiusClusterState {
  final LatLng? center;
  final SuperclusterImmutable<Marker>? supercluster;
  final bool searchErrored;
  final bool outsidePreviousSearchBoundary;

  RadiusSearchState? _searchStateMemo;
  RadiusSearchNextSearchState? _nextSearchStateMemo;

  RadiusClusterState({
    this.center,
    this.supercluster,
    this.searchErrored = false,
    this.outsidePreviousSearchBoundary = false,
  });

  RadiusClusterState.newSearch({
    required LatLng this.center,
    required this.outsidePreviousSearchBoundary,
  })  : supercluster = null,
        searchErrored = false;

  RadiusClusterState withSearchResult(
    SuperclusterImmutable<Marker> supercluster,
  ) =>
      RadiusClusterState(
        center: center,
        supercluster: supercluster,
        searchErrored: searchErrored,
        outsidePreviousSearchBoundary: outsidePreviousSearchBoundary,
      );

  RadiusClusterState withSearchErrored() => RadiusClusterState(
        center: center,
        supercluster: supercluster,
        searchErrored: true,
        outsidePreviousSearchBoundary: outsidePreviousSearchBoundary,
      );

  RadiusClusterState withOutsidePreviousSearchBoundary(
          bool outsidePreviousSearchBoundary) =>
      RadiusClusterState(
        center: center,
        supercluster: supercluster,
        searchErrored: searchErrored,
        outsidePreviousSearchBoundary: outsidePreviousSearchBoundary,
      );

  RadiusSearchState get searchState => _searchStateMemo ??= _searchStateImpl;

  RadiusSearchState get _searchStateImpl {
    if (supercluster != null) {
      return RadiusSearchState.complete;
    } else if (searchErrored == true) {
      return RadiusSearchState.error;
    } else if (center == null) {
      return RadiusSearchState.noSearchPerformed;
    } else {
      return RadiusSearchState.loading;
    }
  }

  RadiusSearchNextSearchState get nextSearchState =>
      _nextSearchStateMemo ??= _nextSearchStateImpl;

  RadiusSearchNextSearchState get _nextSearchStateImpl {
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

  static RadiusClusterState? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) =>
      InheritedRadiusClusterScope.maybeOf(context, listen: listen)
          ?.radiusClusterState;

  static RadiusClusterState of(
    BuildContext context, {
    bool listen = true,
  }) {
    final result = maybeOf(context, listen: listen);
    assert(result != null, 'No RadiusClusterState found in context.');
    return result!;
  }
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
