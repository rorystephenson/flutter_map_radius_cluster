import 'package:flutter_map/plugin_api.dart';
import 'package:supercluster/supercluster.dart';

/// A helper class for making cluster marker count available whilst
/// optionally encapsulating user defined data.
class ClusterDataWithCount extends ClusterDataBase {
  final int markerCount;

  final ClusterDataBase Function(Marker)? _customDataExtractor;
  final ClusterDataBase? customData;

  ClusterDataWithCount(
    Marker marker, {
    ClusterDataBase Function(Marker)? customDataExtractor,
  })  : markerCount = 1,
        _customDataExtractor = customDataExtractor,
        customData = customDataExtractor?.call(marker);

  ClusterDataWithCount._combined(
    this.markerCount, {
    ClusterDataBase Function(Marker)? innerExtractor,
    this.customData,
  }) : _customDataExtractor = innerExtractor;

  @override
  ClusterDataWithCount combine(covariant ClusterDataWithCount data) {
    return ClusterDataWithCount._combined(
      markerCount + data.markerCount,
      innerExtractor: _customDataExtractor,
      customData: customData?.combine(data.customData!),
    );
  }
}
