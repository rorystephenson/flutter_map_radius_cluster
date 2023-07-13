import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_radius_cluster/src/clustered_element_layer.dart';
import 'package:flutter_map_radius_cluster/src/controller/marker_matcher.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_controller.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_controller_impl.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_event.dart';
import 'package:flutter_map_radius_cluster/src/lat_lng_calc.dart';
import 'package:flutter_map_radius_cluster/src/layer_element_extension.dart';
import 'package:flutter_map_radius_cluster/src/map_camera_extension.dart';
import 'package:flutter_map_radius_cluster/src/options/popup_options_impl.dart';
import 'package:flutter_map_radius_cluster/src/overlay/search_circles_overlay.dart';
import 'package:flutter_map_radius_cluster/src/popup_spec_builder.dart';
import 'package:flutter_map_radius_cluster/src/splay/cluster_splay_delegate.dart';
import 'package:flutter_map_radius_cluster/src/splay/expanded_cluster.dart';
import 'package:flutter_map_radius_cluster/src/splay/expanded_cluster_manager.dart';
import 'package:flutter_map_radius_cluster/src/state/inherited_radius_cluster_scope.dart';
import 'package:flutter_map_radius_cluster/src/state/radius_cluster_state_extension.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

import 'options/search_circle_styles.dart';
import 'overlay/fixed_overlay.dart';
import 'radius_cluster_layer.dart';
import 'state/radius_cluster_state.dart';

class RadiusClusterLayerImpl extends StatefulWidget {
  final MapCamera camera;
  final Stream<void> stream;

  final Future<SuperclusterImmutable<Marker>> Function(
      double radius, LatLng center) search;
  final ClusterWidgetBuilder clusterBuilder;
  final MapController mapController;
  final RadiusClusterController? controller;
  final double radiusInKm;
  final FixedOverlayBuilder? fixedOverlayBuilder;
  final double? minimumSearchDistanceDifferenceInKm;
  final Function(dynamic error, StackTrace stackTrace)? onError;
  final SearchCircleStyles searchCircleStyles;
  final MoveMapCallback? moveMap;
  final void Function(Marker)? onMarkerTap;
  final PopupOptionsImpl? popupOptions;
  final Size clusterWidgetSize;
  final ClusterSplayDelegate clusterSplayDelegate;
  final Anchor clusterAnchor;

  RadiusClusterLayerImpl({
    Key? key,
    required this.camera,
    required this.search,
    required this.clusterBuilder,
    required this.mapController,
    this.controller,
    required this.radiusInKm,
    this.fixedOverlayBuilder,
    this.minimumSearchDistanceDifferenceInKm,
    this.onError,
    required this.searchCircleStyles,
    this.moveMap,
    this.onMarkerTap,
    this.popupOptions,
    required this.clusterWidgetSize,
    required this.clusterSplayDelegate,
    required this.clusterAnchor,
  })  : stream = mapController.mapEventStream,
        super(key: key);

  @override
  State<RadiusClusterLayerImpl> createState() => _RadiusClusterLayerImplState();
}

class _RadiusClusterLayerImplState extends State<RadiusClusterLayerImpl>
    with TickerProviderStateMixin {
  bool _initialized = false;
  late final RadiusClusterControllerImpl _controller;
  late final StreamSubscription<RadiusClusterEvent> _controllerSubscription;

  late final ExpandedClusterManager _expandedClusterManager;

  StreamSubscription<void>? _movementStreamSubscription;
  int? _lastMovementZoom;
  PopupState? _popupState;
  CancelableOperation<SuperclusterImmutable<Marker>>?
      _cancelableSearchOperation;

  _RadiusClusterLayerImplState();

  @override
  void initState() {
    super.initState();

    _expandedClusterManager = ExpandedClusterManager(
      onRemoveStart: (expandedClusters) {
        // The flutter_map_marker_popup package takes care of hiding popups
        // when zooming out but when an ExpandedCluster removal is triggered by
        // RadiusClusterController.collapseSplayedClusters we need to remove the
        // popups ourselves.
        widget.popupOptions?.popupController.hidePopupsOnlyFor(
          expandedClusters
              .expand((expandedCluster) => expandedCluster.markers)
              .toList(),
        );
      },
      onRemoved: (expandedClusters) => setState(() {}),
    );

    _controller = widget.controller != null
        ? widget.controller as RadiusClusterControllerImpl
        : RadiusClusterControllerImpl(createdInternally: true);
    _controllerSubscription = _controller.stream.listen(_handleEvent);

    _movementStreamSubscription = widget.stream.listen((_) => _onMove());
  }

  @override
  void didChangeDependencies() {
    if (!_initialized) {
      final radiusClusterState = RadiusClusterState.of(context, listen: false);
      if (radiusClusterState.center != null &&
          radiusClusterState.supercluster == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchAt(radiusClusterState.center ?? widget.camera.center);
        });
      }
      _initialized = true;
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _cancelableSearchOperation?.cancel();
    _controller.disposeIfCreatedInternally();
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
          ClusteredElementLayer(
            camera: widget.camera,
            popupOptions: popupOptions,
            clusterWidgetSize: widget.clusterWidgetSize,
            popupState: popupState,
            expandedClusterManager: _expandedClusterManager,
            clusterBuilder: widget.clusterBuilder,
            onMarkerTap: _onMarkerTap,
            onClusterTap: _onClusterTap,
            clusterAnchor: widget.clusterAnchor,
          ),
          SearchCirclesOverlay(
            camera: widget.camera,
            radiusInM: widget.radiusInKm * 1000,
            options: widget.searchCircleStyles,
          ),
          if (widget.fixedOverlayBuilder != null)
            FixedOverlay(
              controller: _controller,
              camera: widget.camera,
              searchButtonBuilder: widget.fixedOverlayBuilder!,
            ),
          if (popupOptions?.popupDisplayOptions != null)
            PopupLayer(
              popupDisplayOptions: popupOptions!.popupDisplayOptions!,
            )
        ],
      ),
    );
  }

  Widget _wrapWithPopupStateIfPopupsEnabled(
      Widget Function(PopupState? popupState) builder) {
    if (widget.popupOptions == null) return builder(null);

    return InheritOrCreatePopupScope(
      popupController: widget.popupOptions!.popupController,
      builder: (context, popupState) {
        _popupState = popupState;
        if (widget.popupOptions!.selectedMarkerBuilder != null) {
          PopupState.of(context, listen: true);
        }
        return builder(popupState);
      },
    );
  }

  bool _canZoomHigherThan(int zoom) =>
      widget.camera.maxZoom == null || widget.camera.maxZoom! > zoom;

  void _onClusterTap(ImmutableLayerCluster<Marker> layerCluster) async {
    final radiusClusterState = RadiusClusterState.of(context, listen: false);
    final supercluster = radiusClusterState.supercluster;
    if (supercluster == null) return;

    if (!_canZoomHigherThan(layerCluster.highestZoom)) {
      await _moveMapIfNotAt(
        layerCluster.latLng,
        layerCluster.highestZoom.toDouble(),
      );

      final splayAnimation = _expandedClusterManager.putIfAbsent(
        layerCluster,
        () => ExpandedCluster(
          vsync: this,
          camera: widget.camera,
          layerPoints: radiusClusterState
              .childrenOf(layerCluster)
              .cast<LayerPoint<Marker>>(),
          layerCluster: layerCluster,
          clusterSplayDelegate: widget.clusterSplayDelegate,
        ),
      );
      if (splayAnimation != null) setState(() {});
    } else {
      await _moveMapIfNotAt(
        layerCluster.latLng,
        layerCluster.highestZoom + 0.5,
      );
    }
  }

  FutureOr<void> _moveMapIfNotAt(
    LatLng center,
    double zoom, {
    FutureOr<void> Function(LatLng center, double zoom)? moveMapOverride,
  }) {
    if (center == widget.camera.center && zoom == widget.camera.zoom) {
      return Future.value();
    }

    final moveMap = moveMapOverride ??
        widget.moveMap ??
        (center, zoom) => widget.mapController.move(
              center,
              zoom,
            );

    return moveMap.call(center, zoom);
  }

  void _onMarkerTap(PopupSpec popupSpec) {
    _selectMarker(popupSpec);
    widget.onMarkerTap?.call(popupSpec.marker);
  }

  void _selectMarker(PopupSpec popupSpec) {
    if (widget.popupOptions != null) {
      assert(_popupState != null);

      final popupOptions = widget.popupOptions!;
      popupOptions.markerTapBehavior.apply(
        popupSpec,
        _popupState!,
        popupOptions.popupController,
      );

      if (popupOptions.selectedMarkerBuilder != null) setState(() {});
    }
  }

  void _onMove() {
    final radiusClusterState = RadiusClusterState.of(context, listen: false);
    final outsidePreviousSearchBoundary =
        widget.camera.outsidePreviousSearchBoundary(
      previousSearchCenter: radiusClusterState.center,
      radiusInKm: widget.radiusInKm,
      minimumSearchDistanceDifferenceInKm:
          widget.minimumSearchDistanceDifferenceInKm,
    );
    if (radiusClusterState.outsidePreviousSearchBoundary !=
        outsidePreviousSearchBoundary) {
      InheritedRadiusClusterScope.of(context, listen: false)
          .setRadiusClusterState(
        radiusClusterState.withOutsidePreviousSearchBoundary(
          outsidePreviousSearchBoundary,
        ),
      );
    }

    final zoom = widget.camera.zoom.ceil();

    if (_lastMovementZoom == null || zoom < _lastMovementZoom!) {
      _expandedClusterManager.removeIfZoomGreaterThan(zoom);
    }

    _lastMovementZoom = zoom;
  }

  Future<SuperclusterImmutable<Marker>?> _searchAt(LatLng center) async {
    widget.popupOptions?.popupController.hideAllPopups();
    var radiusClusterState = RadiusClusterState.of(context, listen: false);
    final outsidePreviousSearchBoundary =
        widget.camera.outsidePreviousSearchBoundary(
      previousSearchCenter: radiusClusterState.center,
      radiusInKm: widget.radiusInKm,
      minimumSearchDistanceDifferenceInKm:
          widget.minimumSearchDistanceDifferenceInKm,
    );
    radiusClusterState = RadiusClusterState.newSearch(
      center: center,
      outsidePreviousSearchBoundary: outsidePreviousSearchBoundary,
    );
    radiusClusterState = _setRadiusClusterState(radiusClusterState);

    _cancelableSearchOperation?.cancel();
    try {
      _cancelableSearchOperation = CancelableOperation.fromFuture(
          widget.search(widget.radiusInKm, center));
      final result = await _cancelableSearchOperation!.value;
      radiusClusterState = radiusClusterState.withSearchResult(result);
      _setRadiusClusterState(radiusClusterState);

      setState(() {});
      return result;
    } catch (error, stackTrace) {
      radiusClusterState = radiusClusterState.withSearchErrored();
      _setRadiusClusterState(radiusClusterState);
      if (widget.onError == null) rethrow;
      widget.onError!(error, stackTrace);

      setState(() {});
      return null;
    }
  }

  ImmutableLayerPoint<Marker>? _findMarkerInCurrentSearchResults(
    SuperclusterImmutable<Marker>? supercluster,
    MarkerMatcher markerMatcher,
  ) {
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
    required FutureOr<void> Function(LatLng center, double zoom)? moveMap,
  }) async {
    move(LatLng center, double zoom) =>
        _moveMapIfNotAt(center, zoom, moveMapOverride: moveMap);

    final radiusClusterState = RadiusClusterState.of(context, listen: false);
    final outsideCurrentSearchBounds = _outsideCurrentSearchBounds(
      radiusClusterState,
      markerMatcher.point,
    );
    SuperclusterImmutable<Marker>? supercluster =
        radiusClusterState.supercluster;
    ImmutableLayerPoint<Marker>? foundLayerPoint;

    if (outsideCurrentSearchBounds) {
      move(markerMatcher.point, widget.camera.zoom);
      supercluster = await _searchAt(markerMatcher.point);
      if (supercluster == null) return;
      foundLayerPoint =
          _findMarkerInCurrentSearchResults(supercluster, markerMatcher);
      if (foundLayerPoint == null) return;
    } else {
      foundLayerPoint = _findMarkerInCurrentSearchResults(
        supercluster,
        markerMatcher,
      );
      if (supercluster == null || foundLayerPoint == null) {
        move(markerMatcher.point, widget.camera.zoom);
        supercluster = await _searchAt(markerMatcher.point);
        if (supercluster == null) return;
        foundLayerPoint =
            _findMarkerInCurrentSearchResults(supercluster, markerMatcher);
        if (foundLayerPoint == null) return;
      }
    }

    _moveToLayerPoint(
      supercluster,
      foundLayerPoint,
      showPopup: showPopup,
      move: move,
    );
  }

  bool _outsideCurrentSearchBounds(
          RadiusClusterState radiusClusterState, LatLng latLng) =>
      radiusClusterState.supercluster == null ||
      radiusClusterState.center == null ||
      LatLngCalc.distanceInM(radiusClusterState.center!, latLng) / 1000.0 >
          widget.radiusInKm;

  Future<void> _moveToLayerPoint(
    SuperclusterImmutable<Marker> supercluster,
    ImmutableLayerPoint<Marker> layerPoint, {
    required bool showPopup,
    required FutureOr<void> Function(LatLng center, double zoom) move,
  }) async {
    if (!_canZoomHigherThan(layerPoint.lowestZoom - 1)) {
      await _moveToSplayClusterMarker(
        supercluster: supercluster,
        layerPoint: layerPoint,
        move: move,
        showPopup: showPopup,
      );
    } else {
      await move(
        layerPoint.latLng,
        max(layerPoint.lowestZoom.toDouble(), widget.camera.zoom),
      );
      if (showPopup) {
        _selectMarker(PopupSpecBuilder.forLayerPoint(layerPoint));
      }
    }
  }

  /// Move to Marker inside splay cluster. There are three possibilities:
  ///  1. There is already an ExpandedCluster containing the Marker and it
  ///     remains expanded during movement.
  ///  2. There is already an ExpandedCluster and it closes during movement so
  ///     we must create a new one once movement finishes.
  ///  3. There is NOT already an ExpandedCluster, we should create one and add
  ///     it once movement finishes.
  Future<void> _moveToSplayClusterMarker({
    required Supercluster<Marker> supercluster,
    required LayerPoint<Marker> layerPoint,
    required FutureOr<void> Function(LatLng center, double zoom) move,
    required bool showPopup,
  }) async {
    // Find the parent.
    final layerCluster = supercluster.parentOf(layerPoint)!;

    // Shorthand for creating an ExpandedCluster.
    createExpandedCluster() => ExpandedCluster(
          vsync: this,
          camera: widget.camera,
          layerPoints:
              supercluster.childrenOf(layerCluster).cast<LayerPoint<Marker>>(),
          layerCluster: layerCluster,
          clusterSplayDelegate: widget.clusterSplayDelegate,
        );

    // Find or create the marker's ExpandedCluster and use it to find the
    // DisplacedMarker.
    final expandedClusterBeforeMovement =
        _expandedClusterManager.forLayerCluster(layerCluster);
    final createdExpandedCluster =
        expandedClusterBeforeMovement != null ? null : createExpandedCluster();
    final displacedMarker =
        (expandedClusterBeforeMovement ?? createdExpandedCluster)!
            .markersToDisplacedMarkers[layerPoint.originalPoint]!;

    // Move to the DisplacedMarker.
    await move(
      displacedMarker.displacedPoint,
      max(widget.camera.zoom, layerPoint.lowestZoom - 0.99999),
    );

    // Determine the ExpandedCluster after movement, either:
    //   1. We created one (without adding it to ExpandedClusterManager)
    //      because there was none before movement.
    //   2. Movement may have caused the ExpandedCluster to be removed in which
    //      case we create a new one.
    final splayAnimation = _expandedClusterManager.putIfAbsent(
      layerCluster,
      () => createdExpandedCluster ?? createExpandedCluster(),
    );
    if (splayAnimation != null) {
      if (!mounted) return;
      setState(() {});
      await splayAnimation;
    }

    if (showPopup) {
      final popupSpec = PopupSpecBuilder.forDisplacedMarker(
        displacedMarker,
        layerCluster.highestZoom,
      );
      _selectMarker(popupSpec);
    }
  }

  void _handleEvent(RadiusClusterEvent event) async {
    switch (event) {
      case SearchAtCurrentCenterEvent():
        _searchAt(widget.camera.center);
      case SearchAtPositionEvent():
        _searchAt(event.center);
      case CollapseSplayedClustersEvent():
        _expandedClusterManager.collapseThenRemoveAll();
      case ShowPopupsAlsoForEvent():
        if (widget.popupOptions == null) return;
        final radiusClusterState =
            RadiusClusterState.of(context, listen: false);
        if (radiusClusterState.supercluster == null) return;
        widget.popupOptions?.popupController.showPopupsAlsoForSpecs(
          PopupSpecBuilder.buildList(
            supercluster: radiusClusterState.supercluster!,
            zoom: widget.camera.zoom.ceil(),
            canZoomHigherThan: _canZoomHigherThan,
            markers: event.markers,
            expandedClusters: _expandedClusterManager.all,
          ),
          disableAnimation: event.disableAnimation,
        );
      case MoveToMarkerEvent():
        _moveToMarker(
          markerMatcher: event.markerMatcher,
          showPopup: event.showPopup,
          moveMap: event.moveMap,
        );
      case ShowPopupsOnlyForEvent():
        if (widget.popupOptions == null) return;
        final radiusClusterState =
            RadiusClusterState.of(context, listen: false);
        if (radiusClusterState.supercluster == null) return;
        widget.popupOptions?.popupController.showPopupsOnlyForSpecs(
          PopupSpecBuilder.buildList(
            supercluster: radiusClusterState.supercluster!,
            zoom: widget.camera.zoom.ceil(),
            canZoomHigherThan: _canZoomHigherThan,
            markers: event.markers,
            expandedClusters: _expandedClusterManager.all,
          ),
          disableAnimation: event.disableAnimation,
        );
      case HideAllPopupsEvent():
        if (widget.popupOptions == null) return;
        widget.popupOptions?.popupController.hideAllPopups(
          disableAnimation: event.disableAnimation,
        );
      case HidePopupsWhereEvent():
        if (widget.popupOptions == null) return;
        widget.popupOptions?.popupController.hidePopupsWhere(
          event.test,
          disableAnimation: event.disableAnimation,
        );
      case HidePopupsOnlyForEvent():
        if (widget.popupOptions == null) return;
        widget.popupOptions?.popupController.hidePopupsOnlyFor(
          event.markers,
          disableAnimation: event.disableAnimation,
        );
      case TogglePopupEvent():
        if (widget.popupOptions == null) return;
        final radiusClusterState =
            RadiusClusterState.of(context, listen: false);
        if (radiusClusterState.supercluster == null) return;
        final popupSpec = PopupSpecBuilder.build(
          supercluster: radiusClusterState.supercluster!,
          zoom: widget.camera.zoom.ceil(),
          canZoomHigherThan: _canZoomHigherThan,
          marker: event.marker,
          expandedClusters: _expandedClusterManager.all,
        );
        if (popupSpec == null) return;
        widget.popupOptions?.popupController.togglePopupSpec(
          popupSpec,
          disableAnimation: event.disableAnimation,
        );
    }
  }

  RadiusClusterState _setRadiusClusterState(
    RadiusClusterState radiusClusterState,
  ) {
    InheritedRadiusClusterScope.of(context, listen: false)
        .setRadiusClusterState(radiusClusterState);
    return radiusClusterState;
  }
}
