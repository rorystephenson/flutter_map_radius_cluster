# Flutter Map Radius Cluster

A clustering plugin for [flutter_map](https://github.com/fleaflet/flutter_map) with async
marker/cluster searching within a defined radius.

## Warning

This plugin is new and the API is subject to change frequently in the near future.

## Usage

Add flutter_map and flutter_map_radius_cluster to your pubspec:

```yaml
dependencies:
  flutter_map: any
  flutter_map_radius_cluster: any # or the latest version on Pub
```

Add it to FlutterMap and configure it using `RadiusClusterLayerOptions`.

```dart
  Widget build(BuildContext context) {
  return FlutterMap(
    options: MapOptions(
      zoom: 5,
      maxZoom: 15,
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
          search: (radius, center) {
            /* ... your search implementation here */
          },
          clusterWidgetSize: const Size(40, 40),
          anchor: AnchorPos.align(AnchorAlign.center),
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
  );
}
```

### Run the example

See the `example/` folder for a working example app.
