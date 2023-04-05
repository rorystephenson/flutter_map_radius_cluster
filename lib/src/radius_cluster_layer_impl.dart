import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_map_radius_cluster/src/cluster_widget.dart';
import 'package:flutter_map_radius_cluster/src/controller/marker_identifier.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_controller.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_controller_impl.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_event.dart';
import 'package:flutter_map_radius_cluster/src/immutable_layer_element_extension.dart';
import 'package:flutter_map_radius_cluster/src/lat_lng_calc.dart';
import 'package:flutter_map_radius_cluster/src/marker_widget.dart';
import 'package:flutter_map_radius_cluster/src/overlay/search_circles_overlay.dart';
import 'package:flutter_map_radius_cluster/src/rotate.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supercluster/supercluster.dart';

import 'map_calculator.dart';
import 'options/popup_options.dart';
import 'options/search_circle_options.dart';
import 'overlay/fixed_overlay.dart';
import 'radius_cluster_layer.dart';
import 'search_boundary_calculator.dart';
import 'state/radius_cluster_state.dart';
import 'state/radius_cluster_state_impl.dart';

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
  final ClusterTapHandler? onClusterTap;
  final PopupOptions? popupOptions;
  final bool? rotate;
  final Offset? rotateOrigin;
  final AlignmentGeometry? rotateAlignment;
  final Size clusterWidgetSize;
  final AnchorPos? anchor;

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
    this.onClusterTap,
    this.popupOptions,
    this.rotate,
    this.rotateOrigin,
    this.rotateAlignment,
    required this.clusterWidgetSize,
    this.anchor,
  })  : stream = mapState.mapController.mapEventStream,
        super(key: key);

  @override
  State<RadiusClusterLayerImpl> createState() => _RadiusClusterLayerImplState();
}

class _RadiusClusterLayerImplState extends State<RadiusClusterLayerImpl> {
  late final RadiusClusterControllerImpl _controller;
  late final bool _shouldDisposeController;
  late final StreamSubscription<RadiusClusterEvent> _controllerSubscription;
  late final RadiusClusterStateImpl _radiusClusterStateImpl;
  late final MapCalculator _mapCalculator;
  late final SearchBoundaryCalculator _searchBoundaryCalculator;

  StreamSubscription<void>? _movementStreamSubscription;
  int? _hidePopupIfZoomLessThan;
  PopupState? _popupState;
  CancelableOperation<SuperclusterImmutable<Marker>>?
      _cancelableSearchOperation;

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

    _radiusClusterStateImpl =
        widget.initialRadiusClusterState as RadiusClusterStateImpl;

    _controller = widget.controller != null
        ? widget.controller as RadiusClusterControllerImpl
        : RadiusClusterControllerImpl();
    _shouldDisposeController = widget.controller == null;
    _controllerSubscription = _controller.stream.listen(_handleEvent);

    _movementStreamSubscription = widget.stream.listen((_) => _onMove());

    if (_radiusClusterStateImpl.center != null &&
        _radiusClusterStateImpl.supercluster == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchAt(_radiusClusterStateImpl.center);
      });
    }
  }

  @override
  void dispose() {
    if (_shouldDisposeController) _controller.dispose();
    _controllerSubscription.cancel();
    _movementStreamSubscription?.cancel();
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

  Iterable<Widget> _buildClustersAndMarkers() sync* {
    final paddedBounds = _mapCalculator.paddedMapBounds();

    List<ImmutableLayerPoint<Marker>> selectedLayerElements = [];
    final selectedMarkerBuilder =
        widget.popupOptions != null && _popupState!.selectedMarkers.isNotEmpty
            ? widget.popupOptions!.selectedMarkerBuilder
            : null;

    for (final layerElement in _radiusClusterStateImpl.getLayerElementsIn(
      paddedBounds,
      widget.mapState.zoom.ceil(),
    )) {
      if (layerElement is ImmutableLayerCluster<Marker>) {
        yield _buildCluster(layerElement);
      } else {
        layerElement as ImmutableLayerPoint<Marker>;
        final selected = selectedMarkerBuilder != null &&
            _popupState!.selectedMarkers.contains(layerElement.originalPoint);

        if (selected) {
          selectedLayerElements.add(layerElement);
        } else {
          yield _buildMarker(layerElement);
        }
      }
    }

    // Make selected markers appear above others.
    for (final selectedLayerElement in selectedLayerElements) {
      yield _buildMarker(selectedLayerElement, selected: true);
    }
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

  Widget _buildMarker(
    ImmutableLayerPoint<Marker> layerPoint, {
    bool selected = false,
  }) {
    final marker = layerPoint.originalPoint;

    final markerBuilder = !selected
        ? marker.builder
        : (context) =>
            widget.popupOptions!.selectedMarkerBuilder!(context, marker);

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

  VoidCallback? _onClusterTap(ImmutableLayerCluster<Marker> layerCluster) {
    if (widget.onClusterTap == null) return null;

    return () {
      final clustersAndMarkers = _radiusClusterStateImpl.supercluster!;

      final targetZoom =
          clustersAndMarkers.expansionZoomOf(layerCluster.id).toDouble();

      widget.onClusterTap!.call(
        layerCluster,
        layerCluster.latLng,
        targetZoom,
      );
    };
  }

  VoidCallback _onMarkerTap(ImmutableLayerPoint<Marker> layerPoint) {
    return () {
      _selectLayerPoint(layerPoint);

      widget.onMarkerTap?.call(layerPoint.originalPoint);
    };
  }

  void _selectLayerPoint(ImmutableLayerPoint<Marker> layerPoint) {
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
  }

  void _onMove() {
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

  Future<SuperclusterImmutable?> _searchAt(LatLng? center) async {
    center ??= widget.mapState.center;

    widget.popupOptions?.popupController.hideAllPopups();
    _radiusClusterStateImpl.initiateSearch(
      center,
      outsidePreviousSearchBoundary: _searchBoundaryCalculator
          .outsidePreviousSearchBoundary(_radiusClusterStateImpl.center),
    );

    _cancelableSearchOperation?.cancel();
    try {
      _cancelableSearchOperation = CancelableOperation.fromFuture(
          widget.search(widget.radiusInKm, center));
      final result = await _cancelableSearchOperation!.value;
      _radiusClusterStateImpl.setSearchResult(result);

      setState(() {});
      return result;
    } catch (error, stackTrace) {
      _radiusClusterStateImpl.setSearchErrored();
      if (widget.onError == null) rethrow;
      widget.onError!(error, stackTrace);

      setState(() {});
      return null;
    }
  }

  ImmutableLayerPoint<Marker>? _findMarkerInCurrentSearchResults(
    MarkerMatcher markerMatcher,
  ) {
    final supercluster = _radiusClusterStateImpl.supercluster;
    if (supercluster == null) return null;

    final latLng = markerMatcher.point;
    final matchingElements = supercluster
        .search(
          latLng.longitude - 0.0000000001,
          latLng.latitude - 0.0000000001,
          latLng.longitude + 0.0000000001,
          latLng.latitude + 0.0000000001,
          supercluster.maxZoom + 1,
        )
        .where((element) => element.map(
            cluster: (_) => false,
            point: (point) => markerMatcher.matches(point.originalPoint)));

    return matchingElements.isEmpty
        ? null
        : matchingElements.first as ImmutableLayerPoint<Marker>;
  }

  void _moveToMarker({
    required MarkerMatcher markerMatcher,
    required bool showPopup,
    required FutureOr<void> Function(LatLng center, double zoom)? move,
  }) async {
    // This void check error seems to be an analyzer bug.
    // ignore: void_checks
    move ??= (center, zoom) {
      widget.mapState.mapController.move(center, zoom);
      return TickerFuture.complete();
    };

    move(markerMatcher.point, widget.mapState.zoom);

    bool searchPerformed = false;
    if (_radiusClusterStateImpl.supercluster == null ||
        _radiusClusterStateImpl.center == null ||
        LatLngCalc.distanceInM(
                    _radiusClusterStateImpl.center!, markerMatcher.point) /
                1000.0 >
            widget.radiusInKm) {
      await _searchAt(markerMatcher.point);
      searchPerformed = true;
    }

    ImmutableLayerPoint<Marker>? foundLayerPoint =
        _findMarkerInCurrentSearchResults(markerMatcher);
    if (foundLayerPoint == null) {
      if (searchPerformed) return;

      await _searchAt(markerMatcher.point);
      foundLayerPoint = _findMarkerInCurrentSearchResults(markerMatcher);
      if (foundLayerPoint == null) return;
    }

    final minimumVisibleZoom =
        max(widget.mapState.zoom, foundLayerPoint.lowestZoom - 0.99999);

    FutureOr<void>? markerMovementFuture;
    if (minimumVisibleZoom != widget.mapState.zoom ||
        foundLayerPoint.latLng != widget.mapState.center) {
      markerMovementFuture = move(
        foundLayerPoint.latLng,
        minimumVisibleZoom,
      );
    }

    if (showPopup) {
      if (widget.mapState.zoom >= minimumVisibleZoom) {
        _selectLayerPoint(foundLayerPoint);
      } else if (markerMovementFuture is Future<void>) {
        markerMovementFuture.whenComplete(() {
          _selectLayerPoint(foundLayerPoint!);
        });
      }
    }
  }

  void _handleEvent(RadiusClusterEvent event) {
    event.handle(
      searchAtCurrentCenter: () => _searchAt(null),
      searchAtPosition: ({required LatLng center}) => _searchAt(center),
      moveToMarker: _moveToMarker,
    );
  }
}
