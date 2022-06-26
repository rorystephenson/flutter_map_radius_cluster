import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:latlong2/latlong.dart';

import 'center_zoom_tween.dart';

class CenterZoomController {
  final TickerProvider _vsync;
  final MapState mapState;

  CurvedAnimation? _animation;
  double? _velocity;
  AnimationController? _zoomController;
  Tween<CenterZoom>? _tween;

  CenterZoomController({
    required TickerProvider vsync,
    required this.mapState,
    required AnimationOptions animationOptions,
  }) : _vsync = vsync {
    this.animationOptions = animationOptions;
  }

  set animationOptions(AnimationOptions animationOptions) {
    _zoomController?.stop(canceled: false);
    _zoomController?.dispose();

    if (animationOptions is AnimationOptionsAnimate) {
      _zoomController = AnimationController(
        vsync: _vsync,
        duration: animationOptions.duration,
      );
      _zoomController!.addListener(_onMove);
      _animation = CurvedAnimation(
        parent: _zoomController!,
        curve: animationOptions.curve,
      );
      _velocity = animationOptions.velocity;
    } else if (animationOptions is AnimationOptionsNoAnimation) {
      _velocity = null;
      _zoomController = null;
      _animation = null;
    }
  }

  void dispose() {
    _zoomController?.dispose();
    _zoomController = null;
  }

  void moveTo(CenterZoom centerZoom) {
    if (_zoomController == null) {
      mapState.move(
        centerZoom.center,
        centerZoom.zoom,
        source: MapEventSource.custom,
      );
    } else {
      _animateTo(centerZoom);
    }
  }

  void _animateTo(CenterZoom centerZoom) {
    final begin = CenterZoom(
      center: mapState.center,
      zoom: mapState.zoom,
    );
    final end = CenterZoom(
      center: LatLng(centerZoom.center.latitude, centerZoom.center.longitude),
      zoom: centerZoom.zoom,
    );
    _tween = CenterZoomTween(begin: begin, end: end);
    if (_velocity != null) _setDynamicDuration(_velocity!, begin, end);

    if (_zoomController!.isAnimating || _zoomController!.isCompleted) {
      _zoomController!.reset();
    }
    _zoomController!.forward();
  }

  void _setDynamicDuration(double velocity, CenterZoom begin, CenterZoom end) {
    final pixelsTranslated =
        mapState.project(begin.center).distanceTo(mapState.project(end.center));
    final portionOfScreenTranslated =
        pixelsTranslated / ((mapState.size.x + mapState.size.y) / 2);
    final translateVelocity =
        ((portionOfScreenTranslated * 400) * velocity).round();

    final zoomDistance = (begin.zoom - end.zoom).abs();
    final zoomVelocity = 100 + (velocity * 175 * zoomDistance).round();

    _zoomController!.duration =
        Duration(milliseconds: min(max(translateVelocity, zoomVelocity), 2000));
  }

  void _onMove() {
    final centerZoom = _tween!.evaluate(_animation!);
    mapState.move(
      centerZoom.center,
      centerZoom.zoom,
      source: MapEventSource.custom,
    );
  }
}
