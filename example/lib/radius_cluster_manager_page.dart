import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:kdbush/kdbush.dart';
import 'package:latlong2/latlong.dart';

class RadiusClusterLayerPage extends StatefulWidget {
  const RadiusClusterLayerPage({Key? key}) : super(key: key);

  @override
  _RadiusClusterLayerPageState createState() => _RadiusClusterLayerPageState();
}

class _RadiusClusterLayerPageState extends State<RadiusClusterLayerPage> {
  static const totalMarkers = 2000.0;
  final minLatLng = LatLng(49.8566, 1.3522);
  final maxLatLng = LatLng(58.3498, -10.2603);

  late final KDBush<Marker, double> _kdbush;

  int _errorCursor = 0;

  @override
  void initState() {
    super.initState();

    final latitudeRange = maxLatLng.latitude - minLatLng.latitude;
    final longitudeRange = maxLatLng.longitude - minLatLng.longitude;

    final stepsInEachDirection = sqrt(totalMarkers).floor();
    final latStep = latitudeRange / stepsInEachDirection;
    final lonStep = longitudeRange / stepsInEachDirection;

    final markers = <Marker>[];
    for (var i = 0; i < stepsInEachDirection; i++) {
      for (var j = 0; j < stepsInEachDirection; j++) {
        final latLng = LatLng(
          minLatLng.latitude + i * latStep,
          minLatLng.longitude + j * lonStep,
        );

        markers.add(
          Marker(
            height: 30,
            width: 30,
            point: latLng,
            builder: (ctx) => const Icon(Icons.pin_drop),
          ),
        );
      }
    }

    _kdbush = KDBush(
      points: markers,
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLatLng = LatLng(
      (minLatLng.latitude + maxLatLng.latitude) / 2,
      (minLatLng.longitude + maxLatLng.longitude) / 2,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Map Radius Cluster Example')),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng((maxLatLng.latitude + minLatLng.latitude) / 2,
              (maxLatLng.longitude + minLatLng.longitude) / 2),
          zoom: 6,
          maxZoom: 15,
          plugins: [RadiusClusterPlugin()],
        ),
        children: <Widget>[
          TileLayerWidget(
            options: TileLayerOptions(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: ['a', 'b', 'c'],
            ),
          ),
          RadiusClusterLayerWidget(
            options: RadiusClusterLayerOptions(
              radiusInKm: 100.0,
              search: _search,
              initialCenter: initialLatLng,
              minimumSearchDistanceDifferenceInKm: 10,
              onError: (error, _) {
                debugPrint('Captured search error: $error');
              },
              clusterWidgetSize: const Size(40, 40),
              anchor: AnchorPos.align(AnchorAlign.center),
              popupOptions: PopupOptions(popupBuilder: (context, marker) {
                return Container(
                  color: Colors.white,
                  width: 200,
                  height: 100,
                  child: Text('Popup for marker at: ${marker.point}'),
                );
              }),
              builder: (context, clusterData) {
                clusterData as ClusterDataWithCount;
                return Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.blue),
                  child: Center(
                    child: Text(
                      clusterData.markerCount.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Supercluster<Marker>> _search(double radiusInKm, LatLng center) async {
    await (Future.delayed(const Duration(seconds: 1)));
    _errorCursor = (_errorCursor + 1) % 3;
    if (_errorCursor == 0) throw 'Simulated error';

    final points = <Marker>[];
    for (final index in _kdbush.withinGeographicalRadius(
        center.longitude, center.latitude, radiusInKm)) {
      points.add(_kdbush.points[index]);
    }

    return Supercluster<Marker>(
      points: points,
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
      extractClusterData: (marker) => ClusterDataWithCount(marker),
    );
  }
}
