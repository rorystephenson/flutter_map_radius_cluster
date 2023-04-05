import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:supercluster/supercluster.dart';

extension ImmutableLayerExtension on ImmutableLayerElement<Marker> {
  LatLng get latLng => map(
        cluster: (cluster) => LatLng(cluster.latitude, cluster.longitude),
        point: (point) => point.originalPoint.point,
      );
}
