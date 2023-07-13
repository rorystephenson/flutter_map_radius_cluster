import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_radius_cluster_example/font/accurate_map_icons.dart';
import 'package:latlong2/latlong.dart';

List<Marker> generateMarkers({
  required int length,
  required LatLng center,
}) {
  final random = Random(42);
  return List<Marker>.generate(
    length,
    (_) => accurateMarker(
      LatLng(
        random.nextDouble() * 3 - 1.5 + center.latitude,
        random.nextDouble() * 3 - 1.5 + center.longitude,
      ),
    ),
  );
}

Marker accurateMarker(LatLng latLng) => Marker(
      width: 30,
      height: 30,
      builder: (context) => const Icon(
        AccurateMapIcons.locationOnBottomAligned,
        size: 30,
      ),
      anchorPos: const AnchorPos.align(AnchorAlign.top),
      point: latLng,
    );
