import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:flutter_map_radius_cluster_example/example_cluster.dart';
import 'package:flutter_map_radius_cluster_example/main.dart';
import 'package:flutter_map_radius_cluster_example/randomly_generate_markers.dart';
import 'package:kdbush/kdbush.dart';
import 'package:latlong2/latlong.dart';

class BasicExamplePage extends StatelessWidget {
  static const title = 'Basic Example';
  static const route = 'basicExamplePage';

  static const _initialCenter = LatLng(49.8566, 1.3522);

  static final List<Marker> markers = generateMarkers(
    length: 2000,
    center: _initialCenter,
  );
  static final KDBush<Marker, double> _kdbush = KDBush(
    points: markers,
    getX: (m) => m.point.longitude,
    getY: (m) => m.point.latitude,
  );

  const BasicExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(context, BasicExamplePage.route),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      appBar: AppBar(title: const Text(BasicExamplePage.title)),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: _initialCenter,
          initialZoom: 8,
          maxZoom: 15,
        ),
        children: <Widget>[
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          RadiusClusterLayer(
            radiusInKm: 100.0,
            search: _search,
            fixedOverlayBuilder: (context, controller, radiusClusterState) =>
                Align(
              alignment: Alignment.bottomCenter,
              child: SearchButton(
                radiusClusterController: controller,
                radiusClusterState: radiusClusterState,
              ),
            ),
            initialCenter: _initialCenter,
            minimumSearchDistanceDifferenceInKm: 10,
            clusterWidgetSize: const Size(40, 40),
            clusterBuilder: (context, clusterData) => ExampleCluster(
              clusterData as ClusterDataWithCount,
            ),
          ),
        ],
      ),
    );
  }

  Future<SuperclusterImmutable<Marker>> _search(
      double radiusInKm, LatLng center) async {
    await (Future.delayed(const Duration(seconds: 1)));

    final points = <Marker>[];
    for (final index in _kdbush.withinGeographicalRadius(
      center.longitude,
      center.latitude,
      radiusInKm,
      // LatLng uses equatorial radius and we use LatLng to project the search
      // circle on the map.
      earthRadiusInKm: KDBush.equatorialRadiusInKm,
    )) {
      points.add(markers[index]);
    }

    return SuperclusterImmutable<Marker>(
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
      extractClusterData: (marker) => ClusterDataWithCount(marker),
      radius: 120,
    )..load(points);
  }
}
