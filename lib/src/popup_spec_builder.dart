import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_radius_cluster/src/radius_cluster_layer.dart';
import 'package:flutter_map_radius_cluster/src/splay/displaced_marker.dart';
import 'package:flutter_map_radius_cluster/src/splay/expanded_cluster.dart';
import 'package:supercluster/supercluster.dart';

class PopupSpecBuilder {
  static PopupSpec forDisplacedMarker(
    DisplacedMarker displacedMarker,
    int lowestZoom,
  ) =>
      PopupSpec(
        namespace: RadiusClusterLayer.popupNamespace,
        marker: displacedMarker.marker,
        markerPointOverride: displacedMarker.displacedPoint,
        markerRotateAlignmentOveride: DisplacedMarker.rotateAlignment,
        removeMarkerRotateOrigin: true,
        markerAnchorOverride: displacedMarker.anchor,
        removeIfZoomLessThan: lowestZoom,
      );

  static List<PopupSpec> buildList({
    required Supercluster<Marker> supercluster,
    required int zoom,
    required Iterable<Marker> markers,
    required Iterable<ExpandedCluster> expandedClusters,
    required bool Function(int) canZoomHigherThan,
  }) {
    return markers
        .map((marker) => build(
              supercluster: supercluster,
              zoom: zoom,
              canZoomHigherThan: canZoomHigherThan,
              marker: marker,
              expandedClusters: expandedClusters,
            ))
        .whereType<PopupSpec>()
        .toList();
  }

  static PopupSpec? build({
    required Supercluster<Marker> supercluster,
    required int zoom,
    required Marker marker,
    required bool Function(int) canZoomHigherThan,
    required Iterable<ExpandedCluster> expandedClusters,
  }) {
    final layerPoint = supercluster.layerPointOf(marker);

    if (layerPoint == null) return null;

    if (!canZoomHigherThan(layerPoint.lowestZoom - 1)) {
      // Marker inside splay cluster.
      return _matchingDisplacedMarkerPopupSpec(
        layerPoint.originalPoint,
        expandedClusters,
      );
    } else if (layerPoint.lowestZoom > zoom) {
      // Not visible at current zoom.
      return null;
    } else {
      return forLayerPoint(layerPoint);
    }
  }

  static PopupSpec? _matchingDisplacedMarkerPopupSpec(
    Marker marker,
    Iterable<ExpandedCluster> expandedClusters,
  ) {
    for (final expandedCluster in expandedClusters) {
      final matchingDisplacedMarker =
          expandedCluster.markersToDisplacedMarkers[marker];
      if (matchingDisplacedMarker != null) {
        return forDisplacedMarker(
          matchingDisplacedMarker,
          expandedCluster.layerCluster.highestZoom,
        );
      }
    }

    return null;
  }

  static PopupSpec forLayerPoint(LayerPoint<Marker> layerPoint) => PopupSpec(
        namespace: RadiusClusterLayer.popupNamespace,
        marker: layerPoint.originalPoint,
        removeIfZoomLessThan: layerPoint.lowestZoom,
      );
}
