import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:flutter_map_radius_cluster_example/main.dart';
import 'package:kdbush/kdbush.dart';
import 'package:latlong2/latlong.dart';

class RadiusClusterLayerPage extends StatefulWidget {
  static const route = 'radiusClusterLayerPage';

  const RadiusClusterLayerPage({Key? key}) : super(key: key);

  @override
  State<RadiusClusterLayerPage> createState() => _RadiusClusterLayerPageState();
}

class _RadiusClusterLayerPageState extends State<RadiusClusterLayerPage>
    with TickerProviderStateMixin {
  late final AnimatedMapController _animatedMapController;
  late final RadiusClusterController _radiusClusterController;

  bool _animateMovement = true;

  static const totalMarkers = 2000;
  final minLatLng = LatLng(49.8566, 1.3522);
  final maxLatLng = LatLng(58.3498, -10.2603);

  late final List<Marker> markers;
  late final KDBush<Marker, double> _kdbush;

  int _errorCursor = 0;

  @override
  void initState() {
    super.initState();

    _animatedMapController = AnimatedMapController(vsync: this);
    _radiusClusterController = RadiusClusterController();

    final latitudeRange = maxLatLng.latitude - minLatLng.latitude;
    final longitudeRange = maxLatLng.longitude - minLatLng.longitude;

    final stepsInEachDirection = sqrt(totalMarkers).floor();
    final latStep = latitudeRange / stepsInEachDirection;
    final lonStep = longitudeRange / stepsInEachDirection;

    markers = <Marker>[];
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
  void dispose() {
    _animatedMapController.dispose();
    _radiusClusterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialLatLng = LatLng(
      (minLatLng.latitude + maxLatLng.latitude) / 2,
      (minLatLng.longitude + maxLatLng.longitude) / 2,
    );
    return Scaffold(
      drawer: buildDrawer(context, RadiusClusterLayerPage.route),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 130),
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
          ],
        ),
      ),
      appBar: AppBar(title: const Text('Flutter Map Radius Cluster Example')),
      body: FlutterMap(
        mapController: _animatedMapController,
        options: MapOptions(
          center: LatLng((maxLatLng.latitude + minLatLng.latitude) / 2,
              (maxLatLng.longitude + minLatLng.longitude) / 2),
          zoom: 6,
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
            fixedOverlayBuilder: _searchButton,
            initialCenter: initialLatLng,
            minimumSearchDistanceDifferenceInKm: 10,
            moveMap: (center, zoom) {
              if (_animateMovement) {
                return _animatedMapController.animateTo(
                  dest: center,
                  zoom: zoom,
                );
              } else {
                _animatedMapController.move(center, zoom);
              }
            },
            onError: (error, _) {
              debugPrint('Captured search error: $error');
            },
            clusterWidgetSize: const Size(40, 40),
            anchor: AnchorPos.align(AnchorAlign.center),
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
            clusterBuilder: (context, clusterData) => Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.blue),
              child: Center(
                child: Text(
                  (clusterData as ClusterDataWithCount).markerCount.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchButton(
    BuildContext context,
    RadiusClusterController controller,
    RadiusClusterState radiusClusterState,
  ) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: _buttonFor(
        radiusClusterState.nextSearchState,
        controller.searchAtCenter,
      ),
    );
  }

  Widget _buttonFor(RadiusSearchNextSearchState state, VoidCallback search) {
    switch (state) {
      case RadiusSearchNextSearchState.ready:
        return ElevatedButton(
          onPressed: search,
          child: const Text('Search'),
        );
      case RadiusSearchNextSearchState.loading:
        return Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const Text('Loading'),
              ],
            ),
          ),
        );
      case RadiusSearchNextSearchState.error:
        return ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.red),
          ),
          onPressed: search,
          child: const Text('Search again'),
        );
      case RadiusSearchNextSearchState.disabled:
        return const ElevatedButton(
          onPressed: null,
          child: Text('Search'),
        );
    }
  }

  Future<SuperclusterImmutable<Marker>> _search(
      double radiusInKm, LatLng center) async {
    await (Future.delayed(const Duration(seconds: 2)));
    _errorCursor = (_errorCursor + 1) % 3;
    if (_errorCursor == 0) throw 'Simulated error';

    final points = <Marker>[];
    for (final index in _kdbush.withinGeographicalRadius(
        center.longitude, center.latitude, radiusInKm)) {
      points.add(markers[index]);
    }

    return SuperclusterImmutable<Marker>(
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
      extractClusterData: (marker) => ClusterDataWithCount(marker),
    )..load(points);
  }
}
