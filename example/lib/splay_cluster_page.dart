import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:flutter_map_radius_cluster_example/main.dart';
import 'package:kdbush/kdbush.dart';
import 'package:latlong2/latlong.dart';

class SplayClusterPage extends StatefulWidget {
  static const title = 'Splay Cluster';
  static const route = 'splayClusterPage';

  const SplayClusterPage({Key? key}) : super(key: key);

  @override
  State<SplayClusterPage> createState() => _SplayClusterPageState();
}

class _SplayClusterPageState extends State<SplayClusterPage>
    with TickerProviderStateMixin {
  late final RadiusClusterController _radiusClusterController;
  late final AnimatedMapController _animatedMapController;

  static final points = [
    const LatLng(51.4001, -0.08001),
    const LatLng(51.4003, -0.08003),
    const LatLng(51.4005, -0.08005),
    const LatLng(51.4006, -0.08006),
    const LatLng(51.4009, -0.08009),
    const LatLng(51.5, -0.09),
    const LatLng(51.5, -0.09),
    const LatLng(51.5, -0.09),
    const LatLng(51.5, -0.09),
    const LatLng(51.5, -0.09),
    const LatLng(51.59, -0.099),
  ];
  late List<Marker> markers;
  late final KDBush<Marker, double> _kdbush;

  @override
  void initState() {
    super.initState();

    _radiusClusterController = RadiusClusterController();
    _animatedMapController = AnimatedMapController(vsync: this);

    markers = points
        .map(
          (point) => Marker(
            anchorPos: const AnchorPos.align(AnchorAlign.top),
            rotateAlignment: AnchorAlign.top.rotationAlignment,
            height: 30,
            width: 30,
            point: point,
            rotate: true,
            builder: (ctx) => const Icon(Icons.pin_drop),
          ),
        )
        .toList();

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
    return PopupScope(
      child: Scaffold(
        drawer: buildDrawer(context, SplayClusterPage.route),
        floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(top: 130),
          child: Builder(
            builder: (context) => FloatingActionButton.extended(
              icon: const Icon(Icons.location_pin),
              label: const Text("Move to random marker"),
              onPressed: () {
                _radiusClusterController.moveToMarker(
                  MarkerMatcher.equalsMarker(
                      _randomNextMarker(PopupState.of(context, listen: false))),
                );
              },
            ),
          ),
        ),
        appBar: AppBar(title: const Text(SplayClusterPage.title)),
        body: FlutterMap(
          mapController: _animatedMapController.mapController,
          options: MapOptions(
            initialCenter: const LatLng(51.4931, -0.1003),
            initialZoom: 10,
            onTap: (_, __) => _radiusClusterController.hideAllPopups(),
            maxZoom: 15,
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
              initialCenter: const LatLng(51.4931, -0.1003),
              minimumSearchDistanceDifferenceInKm: 10,
              moveMap: (center, zoom) => _animatedMapController.animateTo(
                dest: center,
                zoom: zoom,
              ),
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
              clusterBuilder: (context, clusterData) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: Colors.blue,
                ),
                child: Center(
                  child: Text(
                    (clusterData as ClusterDataWithCount)
                        .markerCount
                        .toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    await (Future.delayed(const Duration(seconds: 1)));

    final points = <Marker>[];
    for (final index in _kdbush.withinGeographicalRadius(
        center.longitude, center.latitude, radiusInKm)) {
      points.add(markers[index]);
    }

    return SuperclusterImmutable<Marker>(
      getX: (m) => m.point.longitude,
      getY: (m) => m.point.latitude,
      extractClusterData: (marker) => ClusterDataWithCount(marker),
      radius: 80,
      maxZoom: 15,
    )..load(points);
  }

  Marker _randomNextMarker(PopupState popupState) {
    final candidateMarkers = List.from(markers);

    while (candidateMarkers.isNotEmpty) {
      final randomIndex = Random().nextInt(candidateMarkers.length);
      final candidateMarker = candidateMarkers.removeAt(randomIndex);
      if (!popupState.isSelected(candidateMarker)) return candidateMarker;
    }

    throw 'No deselected markers found';
  }
}
