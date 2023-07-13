import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:flutter_map_radius_cluster_example/example_cluster.dart';
import 'package:flutter_map_radius_cluster_example/main.dart';
import 'package:flutter_map_radius_cluster_example/randomly_generate_markers.dart';
import 'package:kdbush/kdbush.dart';
import 'package:latlong2/latlong.dart';

class FullExamplePage extends StatefulWidget {
  static const title = 'Full Example';
  static const route = 'fullExamplePage';

  const FullExamplePage({Key? key}) : super(key: key);

  @override
  State<FullExamplePage> createState() => _FullExamplePageState();
}

class _FullExamplePageState extends State<FullExamplePage>
    with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;
  late final RadiusClusterController _radiusClusterController;

  bool _animateMovement = true;

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

  bool _simulateErrors = false;

  @override
  void initState() {
    super.initState();

    _animatedMapController = AnimatedMapController(vsync: this);
    _radiusClusterController = RadiusClusterController();
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    _radiusClusterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(context, FullExamplePage.route),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: kToolbarHeight + 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FloatingActionButton.extended(
              heroTag: 'moveToRandom',
              icon: const Icon(Icons.location_pin),
              label: const Text("Move to random marker"),
              onPressed: () {
                final randomMarker =
                    markers[Random().nextInt(markers.length - 1)];
                _radiusClusterController.moveToMarker(
                  MarkerMatcher.equalsMarker(randomMarker),
                  showPopup: true,
                  moveMap: !_animateMovement
                      ? null
                      : (center, zoom) => _animatedMapController.animateTo(
                            dest: center,
                            zoom: zoom,
                          ),
                );
              },
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'animateMovement',
              icon: const Icon(Icons.animation),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Animate movement "),
                  Switch(
                      activeColor: Colors.blue.shade200,
                      activeTrackColor: Colors.black38,
                      value: _animateMovement,
                      onChanged: (newValue) {
                        setState(() {
                          _animateMovement = newValue;
                        });
                      }),
                ],
              ),
              onPressed: () {
                setState(() {
                  _animateMovement = !_animateMovement;
                });
              },
            ),
            const SizedBox(height: 8),
            FloatingActionButton.extended(
              heroTag: 'simulateErrors',
              icon: const Icon(Icons.error),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Simulate Errors "),
                  Switch(
                      activeColor: Colors.blue.shade200,
                      activeTrackColor: Colors.black38,
                      value: _simulateErrors,
                      onChanged: (newValue) {
                        setState(() {
                          _simulateErrors = newValue;
                        });
                      }),
                ],
              ),
              onPressed: () {
                setState(() {
                  _simulateErrors = !_simulateErrors;
                });
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(title: const Text(FullExamplePage.title)),
      body: FlutterMap(
        mapController: _animatedMapController.mapController,
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: 8,
          maxZoom: 15,
          onTap: (_, __) => _radiusClusterController.hideAllPopups(),
        ),
        children: <Widget>[
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          RadiusClusterLayer(
            controller: _radiusClusterController,
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
            moveMap: (center, zoom) {
              if (_animateMovement) {
                return _animatedMapController.animateTo(
                  dest: center,
                  zoom: zoom,
                );
              } else {
                _animatedMapController.mapController.move(center, zoom);
              }
            },
            onError: (error, _) {
              debugPrint('Captured search error: $error');
            },
            clusterWidgetSize: const Size(40, 40),
            clusterAnchorPos: const AnchorPos.align(AnchorAlign.center),
            popupOptions: PopupOptions(
              popupDisplayOptions: PopupDisplayOptions(
                builder: (context, marker) {
                  return Container(
                    color: Colors.white,
                    width: 200,
                    height: 100,
                    child: Text('Popup for marker at: ${marker.point}'),
                  );
                },
              ),
              selectedMarkerBuilder: (context, marker) => const Icon(
                Icons.pin_drop,
                color: Colors.red,
              ),
            ),
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
    if (_simulateErrors) throw 'Simulated error';

    // Simulated delay to show loading indicator.
    await (Future.delayed(const Duration(seconds: 1)));

    final points = <Marker>[];
    for (final index in _kdbush.withinGeographicalRadius(
      center.longitude,
      center.latitude,
      radiusInKm,
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
