import 'dart:async';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_marker_popup/extension_api.dart';
import 'package:flutter_map_radius_cluster/src/cluster_widget.dart';
import 'package:flutter_map_radius_cluster/src/controller/marker_matcher.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_controller.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_controller_impl.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_event.dart';
import 'package:flutter_map_radius_cluster/src/flutter_map_state_extension.dart';
import 'package:flutter_map_radius_cluster/src/lat_lng_calc.dart';
import 'package:flutter_map_radius_cluster/src/layer_element_extension.dart';
import 'package:flutter_map_radius_cluster/src/marker_widget.dart';
import 'package:flutter_map_radius_cluster/src/options/popup_options_impl.dart';
import 'package:flutter_map_radius_cluster/src/overlay/search_circles_overlay.dart';
import 'package:flutter_map_radius_cluster/src/popup_spec_builder.dart';
import 'package:flutter_map_radius_cluster/src/splay/cluster_splay_delegate.dart';
import 'package:flutter_map_radius_cluster/src/splay/expandable_cluster_widget.dart';
import 'package:flutter_map_radius_cluster/src/splay/expanded_cluster.dart';
import 'package:flutter_map_radius_cluster/src/splay/expanded_cluster_manager.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supercluster/supercluster.dart';

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
  final MoveMapCallback? moveMap;
  final void Function(Marker)? onMarkerTap;
  final PopupOptionsImpl? popupOptions;
  final Size clusterWidgetSize;
  final ClusterSplayDelegate clusterSplayDelegate;
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
    this.moveMap,
    this.onMarkerTap,
    this.popupOptions,
    required this.clusterWidgetSize,
    required this.clusterSplayDelegate,
    this.anchor,
  })  : stream = mapState.mapController.mapEventStream,
        super(key: key);

  @override
  State<RadiusClusterLayerImpl> createState() => _RadiusClusterLayerImplState();
}

class _RadiusClusterLayerImplState extends State<RadiusClusterLayerImpl>
    with TickerProviderStateMixin {
  late final RadiusClusterControllerImpl _controller;
  late final StreamSubscription<RadiusClusterEvent> _controllerSubscription;
  late final RadiusClusterStateImpl _radiusClusterStateImpl;
  late final SearchBoundaryCalculator _searchBoundaryCalculator;

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
        : RadiusClusterControllerImpl(createdInternally: true);
    _controllerSubscription = _controller.stream.listen(_handleEvent);

    _movementStreamSubscription = widget.stream.listen((_) => _onMove());

    if (_radiusClusterStateImpl.center != null &&
        _radiusClusterStateImpl.supercluster == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchAt(_radiusClusterStateImpl.center ?? widget.mapState.center);
      });
    }
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
    if (_radiusClusterStateImpl.supercluster != null) {
      final superclusterMaxZoom = _radiusClusterStateImpl.supercluster!.maxZoom;
      final mapMaxZoom = widget.mapState.options.maxZoom;
      assert(
        mapMaxZoom == null || superclusterMaxZoom <= mapMaxZoom,
        'The Supercluster\'s maxZoom ($superclusterMaxZoom) must not be '
        'greater than FlutterMap\'s maxZoom ($mapMaxZoom). Either increase '
        'the maxZoom of your Supercluster or remove FlutterMap\'s maxZoom.',
      );
    }
    final popupOptions = widget.popupOptions;

    return _wrapWithPopupStateIfPopupsEnabled(
      (popupState) => Stack(
        children: [
          ..._buildClustersAndMarkers(),
          SearchCirclesOverlay(
            mapState: widget.mapState,
            radiusInM: widget.radiusInKm * 1000,
            options: widget.searchCircleOptions,
          ),
          if (widget.fixedOverlayBuilder != null)
            FixedOverlay(
              controller: _controller,
              mapState: widget.mapState,
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
          context.watch<PopupState>();
        }
        return builder(popupState);
      },
    );
  }

  Iterable<Widget> _buildClustersAndMarkers() sync* {
    final paddedBounds =
        widget.mapState.paddedMapBounds(widget.clusterWidgetSize);

    final selectedMarkerBuilder =
        widget.popupOptions != null && _popupState!.selectedMarkers.isNotEmpty
            ? widget.popupOptions!.selectedMarkerBuilder
            : null;
    List<ImmutableLayerPoint<Marker>> selectedLayerPoints = [];
    final List<ImmutableLayerCluster<Marker>> clusters = [];

    for (final layerElement in _radiusClusterStateImpl.getLayerElementsIn(
      paddedBounds,
      widget.mapState.zoom.ceil(),
    )) {
      if (layerElement is ImmutableLayerCluster<Marker>) {
        clusters.add(layerElement);
        continue;
      }
      layerElement as ImmutableLayerPoint<Marker>;
      if (selectedMarkerBuilder != null &&
          _popupState!.selectedMarkers.contains(layerElement.originalPoint)) {
        selectedLayerPoints.add(layerElement);
        continue;
      }
      yield _buildMarker(layerElement);
    }

    // Build selected markers.
    for (final selectedLayerPoint in selectedLayerPoints) {
      yield _buildMarker(selectedLayerPoint, selected: true);
    }

    // Build non expanded clusters.
    for (final cluster in clusters) {
      if (_expandedClusterManager.contains(cluster)) continue;
      yield _buildCluster(cluster);
    }

    // Build expanded clusters.
    for (final expandedCluster in _expandedClusterManager.all) {
      yield _buildExpandedCluster(expandedCluster);
    }
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
      mapState: widget.mapState,
      marker: marker,
      markerBuilder: markerBuilder,
      onTap: () => _onMarkerTap(PopupSpecBuilder.forLayerPoint(layerPoint)),
    );
  }

  Widget _buildCluster(ImmutableLayerCluster<Marker> cluster) {
    return ClusterWidget(
      mapState: widget.mapState,
      cluster: cluster,
      builder: widget.clusterBuilder,
      onTap: () => _onClusterTap(cluster),
      size: widget.clusterWidgetSize,
      anchorPos: widget.anchor,
    );
  }

  Widget _buildExpandedCluster(ExpandedCluster expandedCluster) {
    final selectedMarkerBuilder = widget.popupOptions?.selectedMarkerBuilder;
    final Widget Function(BuildContext context, Marker marker) markerBuilder =
        selectedMarkerBuilder == null
            ? ((context, marker) => marker.builder(context))
            : ((context, marker) =>
                _popupState?.selectedMarkers.contains(marker) == true
                    ? selectedMarkerBuilder(context, marker)
                    : marker.builder(context));

    return ExpandableClusterWidget(
      mapState: widget.mapState,
      expandedCluster: expandedCluster,
      builder: widget.clusterBuilder,
      size: widget.clusterWidgetSize,
      anchorPos: widget.anchor,
      markerBuilder: markerBuilder,
      onCollapse: () {
        widget.popupOptions?.popupController
            .hidePopupsOnlyFor(expandedCluster.markers.toList());
        _expandedClusterManager
            .collapseThenRemove(expandedCluster.layerCluster);
      },
      onMarkerTap: _onMarkerTap,
    );
  }

  bool _canZoomHigherThan(int zoom) =>
      widget.mapState.options.maxZoom == null ||
      widget.mapState.options.maxZoom! > zoom;

  void _onClusterTap(ImmutableLayerCluster<Marker> layerCluster) async {
    final supercluster = _radiusClusterStateImpl.supercluster;
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
          mapState: widget.mapState,
          layerPoints: _radiusClusterStateImpl
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
    if (center == widget.mapState.center && zoom == widget.mapState.zoom) {
      return Future.value();
    }

    final moveMap = moveMapOverride ??
        widget.moveMap ??
        (center, zoom) => widget.mapState.move(
              center,
              zoom,
              source: MapEventSource.custom,
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
    _radiusClusterStateImpl.onMove(
      outsidePreviousSearchBoundary: _searchBoundaryCalculator
          .outsidePreviousSearchBoundary(_radiusClusterStateImpl.center),
    );

    final zoom = widget.mapState.zoom.ceil();

    if (_lastMovementZoom == null || zoom < _lastMovementZoom!) {
      _expandedClusterManager.removeIfZoomGreaterThan(zoom);
    }

    _lastMovementZoom = zoom;
  }

  Future<SuperclusterImmutable?> _searchAt(LatLng center) async {
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
    required FutureOr<void> Function(LatLng center, double zoom)? moveMap,
  }) async {
    move(LatLng center, double zoom) =>
        _moveMapIfNotAt(center, zoom, moveMapOverride: moveMap);

    ImmutableLayerPoint<Marker>? foundLayerPoint =
        _findMarkerInCurrentSearchResults(markerMatcher);

    if (_outsideCurrentSearchBounds(markerMatcher.point)) {
      move(markerMatcher.point, widget.mapState.zoom);
      await _searchAt(markerMatcher.point);
      foundLayerPoint = _findMarkerInCurrentSearchResults(markerMatcher);
      if (foundLayerPoint == null) return;
    } else {
      foundLayerPoint = _findMarkerInCurrentSearchResults(markerMatcher);
      if (foundLayerPoint == null) {
        move(markerMatcher.point, widget.mapState.zoom);
        await _searchAt(markerMatcher.point);
        foundLayerPoint = _findMarkerInCurrentSearchResults(markerMatcher);
        if (foundLayerPoint == null) return;
      }
    }

    _moveToLayerPoint(foundLayerPoint, showPopup: showPopup, move: move);
  }

  bool _outsideCurrentSearchBounds(LatLng latLng) =>
      _radiusClusterStateImpl.supercluster == null ||
      _radiusClusterStateImpl.center == null ||
      LatLngCalc.distanceInM(_radiusClusterStateImpl.center!, latLng) / 1000.0 >
          widget.radiusInKm;

  Future<void> _moveToLayerPoint(
    ImmutableLayerPoint<Marker> layerPoint, {
    required bool showPopup,
    required FutureOr<void> Function(LatLng center, double zoom) move,
  }) async {
    final supercluster = _radiusClusterStateImpl.supercluster!;

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
        max(layerPoint.lowestZoom.toDouble(), widget.mapState.zoom),
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
          mapState: widget.mapState,
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
      max(widget.mapState.zoom, layerPoint.lowestZoom - 0.99999),
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
        _searchAt(widget.mapState.center);
      case SearchAtPositionEvent():
        _searchAt(event.center);
      case CollapseSplayedClustersEvent():
        _expandedClusterManager.collapseThenRemoveAll();
      case ShowPopupsAlsoForEvent():
        if (widget.popupOptions == null) return;
        if (_radiusClusterStateImpl.supercluster == null) return;
        widget.popupOptions?.popupController.showPopupsAlsoForSpecs(
          PopupSpecBuilder.buildList(
            supercluster: _radiusClusterStateImpl.supercluster!,
            zoom: widget.mapState.zoom.ceil(),
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
        if (_radiusClusterStateImpl.supercluster == null) return;
        widget.popupOptions?.popupController.showPopupsOnlyForSpecs(
          PopupSpecBuilder.buildList(
            supercluster: _radiusClusterStateImpl.supercluster!,
            zoom: widget.mapState.zoom.ceil(),
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
        if (_radiusClusterStateImpl.supercluster == null) return;
        final popupSpec = PopupSpecBuilder.build(
          supercluster: _radiusClusterStateImpl.supercluster!,
          zoom: widget.mapState.zoom.ceil(),
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
}
