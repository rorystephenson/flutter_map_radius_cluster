import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_radius_cluster/src/center_zoom_controller.dart';
import 'package:flutter_map_radius_cluster/src/cluster_widget.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_controller.dart';
import 'package:flutter_map_radius_cluster/src/marker_widget.dart';
import 'package:flutter_map_radius_cluster/src/overlay/search_circles_overlay.dart';
import 'package:flutter_map_radius_cluster/src/rotate.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supercluster/supercluster.dart';

import 'map_calculator.dart';
import 'options/animation_options.dart';
import 'options/popup_options.dart';
import 'options/search_circle_options.dart';
import 'overlay/fixed_overlay.dart';
import 'radius_cluster_layer.dart';
import 'state/radius_cluster_state.dart';
import 'state/radius_cluster_state_impl.dart';
import 'search_boundary_calculator.dart';

class RadiusClusterLayerImpl extends StatefulWidget {
  final FlutterMapState mapState;
  final RadiusClusterState initialRadiusClusterState;
  final Stream<void> stream;

  final Future<SuperclusterImmutable<Marker>> Function(
      double radius, LatLng center) search;
  final ClusterWidgetBuilder clusterBuilder;
  final RadiusClusterController? controller;
  final double radiusInKm;
  final FixedOverlayBuilder? fixedOverlayBuilder;
  final double? minimumSearchDistanceDifferenceInKm;
  final Function(dynamic error, StackTrace stackTrace)? onError;
  final SearchCircleOptions searchCircleOptions;
  final void Function(Marker)? onMarkerTap;
  final PopupOptions? popupOptions;
  final bool? rotate;
  final Offset? rotateOrigin;
  final AlignmentGeometry? rotateAlignment;
  final Size clusterWidgetSize;
  final AnchorPos? anchor;
  final AnimationOptions clusterZoomAnimation;

  RadiusClusterLayerImpl({
    Key? key,
    required this.mapState,
    required this.initialRadiusClusterState,
    required this.search,
    required this.clusterBuilder,
    this.controller,
    required this.radiusInKm,
    this.fixedOverlayBuilder,
    this.minimumSearchDistanceDifferenceInKm,
    this.onError,
    required this.searchCircleOptions,
    this.onMarkerTap,
    this.popupOptions,
    this.rotate,
    this.rotateOrigin,
    this.rotateAlignment,
    required this.clusterWidgetSize,
    this.anchor,
    required this.clusterZoomAnimation,
  })  : stream = mapState.mapController.mapEventStream,
        super(key: key);

  @override
  State<RadiusClusterLayerImpl> createState() => _RadiusClusterLayerImplState();
}

class _RadiusClusterLayerImplState extends State<RadiusClusterLayerImpl>
    with TickerProviderStateMixin {
  late final RadiusClusterController _controller;
  late final bool _shouldDisposeController;
  late final StreamSubscription<LatLng?> _controllerSubscription;
  late final RadiusClusterStateImpl _radiusClusterStateImpl;
  late final MapCalculator _mapCalculator;
  late final SearchBoundaryCalculator _searchBoundaryCalculator;

  late CenterZoomController _centerZoomController;
  StreamSubscription<void>? _movementStreamSubscription;
  int? _hidePopupIfZoomLessThan;

  PopupState? _popupState;

  _RadiusClusterLayerImplState();

  @override
  void initState() {
    super.initState();

    _mapCalculator = MapCalculator(
      mapState: widget.mapState,
      clusterWidgetSize: widget.clusterWidgetSize,
      clusterAnchorPos: widget.anchor,
    );

    _searchBoundaryCalculator = SearchBoundaryCalculator(
      mapState: widget.mapState,
      radiusInKm: widget.radiusInKm,
      minimumSearchDistanceDifferenceInKm:
          widget.minimumSearchDistanceDifferenceInKm,
    );

    _centerZoomController = CenterZoomController(
      vsync: this,
      mapState: widget.mapState,
      animationOptions: widget.clusterZoomAnimation,
    );

    _radiusClusterStateImpl =
        widget.initialRadiusClusterState as RadiusClusterStateImpl;

    _controller = widget.controller ?? RadiusClusterController();
    _shouldDisposeController = widget.controller == null;
    _controllerSubscription = _controller.searchStream.listen(_searchAt);

    _movementStreamSubscription = widget.stream.listen(_onMove);

    if (_radiusClusterStateImpl.center != null &&
        _radiusClusterStateImpl.supercluster == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchAt(_radiusClusterStateImpl.center);
      });
    }
  }

  @override
  void didUpdateWidget(RadiusClusterLayerImpl oldWidget) {
    if (oldWidget.clusterZoomAnimation != widget.clusterZoomAnimation) {
      _centerZoomController.animationOptions = widget.clusterZoomAnimation;
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
    final popupOptions = widget.popupOptions;

    return _wrapWithPopupStateIfPopupsEnabled(
      (popupState) => Stack(
        children: [
          ..._buildClustersAndMarkers(),
          SearchCirclesOverlay(
            mapCalculator: _mapCalculator,
            radiusInM: widget.radiusInKm * 1000,
            options: widget.searchCircleOptions,
          ),
          if (widget.fixedOverlayBuilder != null)
            FixedOverlay(
              controller: _controller,
              mapCalculator: _mapCalculator,
              searchButtonBuilder: widget.fixedOverlayBuilder!,
            ),
          if (popupOptions != null)
            PopupLayer(
              popupState: _popupState!,
              popupBuilder: popupOptions.popupBuilder,
              popupSnap: popupOptions.popupSnap,
              popupController: popupOptions.popupController,
              popupAnimation: popupOptions.popupAnimation,
              markerRotate: popupOptions.markerRotate,
            )
        ],
      ),
    );
  }

  Widget _wrapWithPopupStateIfPopupsEnabled(
      Widget Function(PopupState? popupState) builder) {
    if (widget.popupOptions == null) return builder(null);

    return PopupStateWrapper(builder: (context, popupState) {
      _popupState = popupState;
      if (widget.popupOptions!.selectedMarkerBuilder != null) {
        context.watch<PopupState>();
      }
      return builder(popupState);
    });
  }

  Iterable<Widget> _buildClustersAndMarkers() {
    final paddedBounds = _mapCalculator.paddedMapBounds();
    return _radiusClusterStateImpl
        .getLayerElementsIn(
          paddedBounds,
          widget.mapState.zoom.ceil(),
        )
        .map(_buildMarkerOrCluster);
  }

  Widget _buildMarkerOrCluster(ImmutableLayerElement<Marker> layerElement) {
    return layerElement.map(
      cluster: _buildCluster,
      point: _buildMarker,
    );
  }

  Widget _buildCluster(ImmutableLayerCluster<Marker> layerCluster) {
    return ClusterWidget(
      mapCalculator: _mapCalculator,
      cluster: layerCluster,
      builder: widget.clusterBuilder,
      onTap: _onClusterTap(layerCluster),
      size: widget.clusterWidgetSize,
    );
  }

  Widget _buildMarker(ImmutableLayerPoint<Marker> layerPoint) {
    final marker = layerPoint.originalPoint;

    var markerBuilder = marker.builder;
    final popupOptions = widget.popupOptions;
    if (popupOptions?.selectedMarkerBuilder != null &&
        _popupState!.selectedMarkers.contains(marker)) {
      markerBuilder = ((context) =>
          widget.popupOptions!.selectedMarkerBuilder!(context, marker));
    }

    return MarkerWidget(
      mapCalculator: _mapCalculator,
      marker: marker,
      markerBuilder: markerBuilder,
      onTap: _onMarkerTap(layerPoint),
      size: Size(marker.width, marker.height),
      rotate: marker.rotate != true && widget.rotate != true
          ? null
          : Rotate(
              angle: -widget.mapState.rotationRad,
              origin: marker.rotateOrigin ?? widget.rotateOrigin,
              alignment: marker.rotateAlignment ?? widget.rotateAlignment,
            ),
    );
  }

  VoidCallback _onClusterTap(ImmutableLayerCluster<Marker> layerCluster) {
    return () {
      final clustersAndMarkers = _radiusClusterStateImpl.supercluster;
      if (clustersAndMarkers == null) throw 'No clusters loaded';

      final targetZoom =
          clustersAndMarkers.expansionZoomOf(layerCluster.id).toDouble();

      _centerZoomController.moveTo(
        CenterZoom(
          center: LatLng(layerCluster.latitude, layerCluster.longitude),
          zoom: targetZoom,
        ),
      );
    };
  }

  VoidCallback _onMarkerTap(ImmutableLayerPoint<Marker> layerPoint) {
    return () {
      if (widget.popupOptions != null) {
        assert(_popupState != null);

        final popupOptions = widget.popupOptions!;
        popupOptions.markerTapBehavior.apply(
          layerPoint.originalPoint,
          _popupState!,
          popupOptions.popupController,
        );
        _hidePopupIfZoomLessThan = layerPoint.lowestZoom;

        if (popupOptions.selectedMarkerBuilder != null) setState(() {});
      }

      widget.onMarkerTap?.call(layerPoint.originalPoint);
    };
  }

  void _searchAt(LatLng? center) async {
    center ??= widget.mapState.center;

    widget.popupOptions?.popupController.hideAllPopups();
    _radiusClusterStateImpl.initiateSearch(
      center,
      outsidePreviousSearchBoundary: _searchBoundaryCalculator
          .outsidePreviousSearchBoundary(_radiusClusterStateImpl.center),
    );

    try {
      _radiusClusterStateImpl.setSearchResult(
        await widget.search(widget.radiusInKm, center),
      );
    } catch (error, stackTrace) {
      _radiusClusterStateImpl.setSearchErrored();
      if (widget.onError == null) rethrow;
      widget.onError!(error, stackTrace);
    } finally {
      setState(() {});
    }
  }

  void _onMove(void _) {
    if (_hidePopupIfZoomLessThan != null &&
        widget.mapState.zoom.ceil() < _hidePopupIfZoomLessThan!) {
      widget.popupOptions?.popupController.hideAllPopups();
      _hidePopupIfZoomLessThan = null;
    }

    _radiusClusterStateImpl.onMove(
      outsidePreviousSearchBoundary: _searchBoundaryCalculator
          .outsidePreviousSearchBoundary(_radiusClusterStateImpl.center),
    );
  }
}
