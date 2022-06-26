import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_radius_cluster/src/center_zoom_controller.dart';
import 'package:flutter_map_radius_cluster/src/cluster_widget.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_controller.dart';
import 'package:flutter_map_radius_cluster/src/marker_widget.dart';
import 'package:flutter_map_radius_cluster/src/overlay/fixed_overlay.dart';
import 'package:flutter_map_radius_cluster/src/overlay/search_result_circle_overlay.dart';
import 'package:flutter_map_radius_cluster/src/radius_cluster_searcher.dart';
import 'package:flutter_map_radius_cluster/src/rotate.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

import 'map_calculator.dart';
import 'radius_cluster_layer_options.dart';
import 'state/radius_cluster_state.dart';
import 'state/radius_cluster_state_impl.dart';

class RadiusClusterLayer extends StatefulWidget {
  final RadiusClusterLayerOptions options;
  final MapState mapState;
  final RadiusClusterState initialRadiusClusterState;

  final Stream<void> stream;

  const RadiusClusterLayer({
    Key? key,
    required this.options,
    required this.mapState,
    required this.stream,
    required this.initialRadiusClusterState,
  }) : super(key: key);

  @override
  State<RadiusClusterLayer> createState() => _RadiusClusterLayerState();
}

class _RadiusClusterLayerState extends State<RadiusClusterLayer>
    with TickerProviderStateMixin {
  late final RadiusClusterController _controller;
  late final bool _shouldDisposeController;
  late final StreamSubscription<LatLng?> _controllerSubscription;
  late final RadiusClusterStateImpl _radiusClusterStateImpl;
  late final MapCalculator _mapCalculator;
  late final RadiusClusterSearcher _searcher;

  late CenterZoomController _centerZoomController;
  StreamSubscription<void>? _movementStreamSubscription;
  int? _hidePopupIfZoomLessThan;

  PopupState? _popupState;

  _RadiusClusterLayerState();

  @override
  void initState() {
    super.initState();

    _mapCalculator = MapCalculator(
      mapState: widget.mapState,
      clusterWidgetSize: widget.options.clusterWidgetSize,
      clusterAnchorPos: widget.options.anchor,
    );

    _centerZoomController = CenterZoomController(
      vsync: this,
      mapState: widget.mapState,
      animationOptions: widget.options.clusterZoomAnimation,
    );

    _searcher = RadiusClusterSearcher(
      mapState: widget.mapState,
      minimumSearchDistanceDifferenceInKm:
          widget.options.minimumSearchDistanceDifferenceInKm,
      radiusInKm: widget.options.radiusInKm,
      search: widget.options.search,
    );

    _radiusClusterStateImpl =
        widget.initialRadiusClusterState as RadiusClusterStateImpl;

    _controller = widget.options.controller ?? RadiusClusterController();
    _shouldDisposeController = widget.options.controller == null;
    _controllerSubscription = _controller.searchStream.listen(_searchAt);

    _movementStreamSubscription = widget.stream.listen(_onMove);

    if (_radiusClusterStateImpl.center != null &&
        _radiusClusterStateImpl.clustersAndMarkers == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchAt(_radiusClusterStateImpl.center);
      });
    }
  }

  @override
  void didUpdateWidget(RadiusClusterLayer oldWidget) {
    if (oldWidget.options.clusterZoomAnimation !=
        widget.options.clusterZoomAnimation) {
      _centerZoomController.animationOptions =
          widget.options.clusterZoomAnimation;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    if (_shouldDisposeController) _controller.dispose();
    _controllerSubscription.cancel();
    _movementStreamSubscription?.cancel();
    _centerZoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: widget.stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        final popupOptions = widget.options.popupOptions;

        return Stack(
          children: [
            ..._buildClustersAndMarkers(),
            SearchResultCircleOverlay(
              mapCalculator: _mapCalculator,
              radiusInM: widget.options.radiusInKm * 1000,
              style: widget.options.searchCircleStyle,
            ),
            FixedOverlay(
              mapState: widget.mapState,
              controller: _controller,
              mapCalculator: _mapCalculator,
              searchButtonBuilder: widget.options.searchButtonBuilder,
              radiusInKm: widget.options.radiusInKm,
              searchCircleBorderStyle: widget.options.searchCircleStyle,
              minimumSearchDistanceDifferenceInKm:
                  widget.options.minimumSearchDistanceDifferenceInKm,
            ),
            if (popupOptions != null)
              PopupStateWrapper(
                builder: (context, popupState) {
                  _popupState = popupState;

                  return PopupLayer(
                    mapState: widget.mapState,
                    popupState: popupState,
                    popupBuilder: popupOptions.popupBuilder,
                    popupSnap: popupOptions.popupSnap,
                    popupController: popupOptions.popupController,
                    popupAnimation: popupOptions.popupAnimation,
                    markerRotate: popupOptions.markerRotate,
                  );
                },
              )
          ],
        );
      },
    );
  }

  Iterable<Widget> _buildClustersAndMarkers() {
    final paddedBounds = _mapCalculator.paddedMapBounds();
    return _radiusClusterStateImpl
        .getClustersAndPointsIn(
          paddedBounds,
          widget.mapState.zoom.ceil(),
        )
        .map(_buildMarkerOrCluster);
  }

  Widget _buildMarkerOrCluster(ClusterOrMapPoint<Marker> clusterOrMapPoint) {
    return clusterOrMapPoint.map(
      cluster: _buildMarkerClusterLayer,
      mapPoint: _buildMarkerLayer,
    );
  }

  Widget _buildMarkerClusterLayer(Cluster<Marker> cluster) {
    return ClusterWidget(
      mapCalculator: _mapCalculator,
      cluster: cluster,
      builder: widget.options.clusterBuilder,
      onTap: _onClusterTap(cluster),
      size: widget.options.clusterWidgetSize,
    );
  }

  Widget _buildMarkerLayer(MapPoint<Marker> mapPoint) {
    final marker = mapPoint.originalPoint;

    return MarkerWidget(
      mapCalculator: _mapCalculator,
      marker: marker,
      onTap: _onMarkerTap(mapPoint),
      size: Size(marker.width, marker.height),
      rotate: marker.rotate != true && widget.options.rotate != true
          ? null
          : Rotate(
              angle: -widget.mapState.rotationRad,
              origin: marker.rotateOrigin ?? widget.options.rotateOrigin,
              alignment:
                  marker.rotateAlignment ?? widget.options.rotateAlignment,
            ),
    );
  }

  VoidCallback _onClusterTap(Cluster<Marker> cluster) {
    return () {
      final clustersAndMarkers = _radiusClusterStateImpl.clustersAndMarkers;
      if (clustersAndMarkers == null) throw 'No clusters loaded';

      final targetZoom =
          clustersAndMarkers.getClusterExpansionZoom(cluster.id).toDouble();

      _centerZoomController.moveTo(
        CenterZoom(
          center: LatLng(cluster.latitude, cluster.longitude),
          zoom: targetZoom,
        ),
      );
    };
  }

  VoidCallback _onMarkerTap(MapPoint<Marker> mapPoint) {
    return () {
      if (widget.options.popupOptions != null) {
        assert(_popupState != null);

        final popupOptions = widget.options.popupOptions!;
        popupOptions.markerTapBehavior.apply(
          mapPoint.originalPoint,
          _popupState!,
          popupOptions.popupController,
        );
        _hidePopupIfZoomLessThan = mapPoint.zoom;
      }

      widget.options.onMarkerTap?.call(mapPoint.originalPoint);
    };
  }

  void _searchAt(LatLng? center) async {
    center ??= widget.mapState.center;

    _radiusClusterStateImpl.initiateSearch(center);

    try {
      _radiusClusterStateImpl.setSearchResult(await _searcher.search(center));
    } catch (error, stackTrace) {
      _radiusClusterStateImpl.setSearchErrored();
      if (widget.options.onError == null) rethrow;
      widget.options.onError!(error, stackTrace);
    } finally {
      widget.options.popupOptions?.popupController.hideAllPopups();
      setState(() {});
    }
  }

  void _onMove(void _) {
    if (_hidePopupIfZoomLessThan != null &&
        widget.mapState.zoom < _hidePopupIfZoomLessThan!) {
      debugPrint('hiding all popups');
      widget.options.popupOptions?.popupController.hideAllPopups();
      _hidePopupIfZoomLessThan = null;
    }

    _radiusClusterStateImpl.outsidePreviousSearchBoundary =
        _searcher.outsidePreviousSearchBoundary(_radiusClusterStateImpl.center);
  }
}
