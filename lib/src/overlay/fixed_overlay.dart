import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_controller.dart';
import 'package:provider/provider.dart';

import '../map_calculator.dart';
import '../radius_cluster_layer_options.dart';
import '../state/radius_cluster_state.dart';
import 'search_circle_style.dart';
import 'search_radius_indicator.dart';

class FixedOverlay extends StatelessWidget {
  final MapState mapState;
  final RadiusClusterController controller;
  final MapCalculator mapCalculator;
  final SearchButtonBuilder? searchButtonBuilder;
  final double radiusInKm;
  final SearchCircleStyle searchCircleBorderStyle;
  final double? minimumSearchDistanceDifferenceInKm;

  const FixedOverlay({
    Key? key,
    required this.mapState,
    required this.controller,
    required this.mapCalculator,
    required this.searchButtonBuilder,
    required this.radiusInKm,
    required this.searchCircleBorderStyle,
    required this.minimumSearchDistanceDifferenceInKm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radiusClusterState = context.watch<RadiusClusterState>();
    final overlay = Stack(
      children: [
        if (radiusClusterState.outsidePreviousSearchBoundary)
          SearchRadiusIndicator(
            center: mapState.center,
            mapCalculator: mapCalculator,
            radiusInM: radiusInKm * 1000,
            borderColor: searchCircleBorderStyle.nextSearchBorderColor,
            borderWidth: searchCircleBorderStyle.borderWidth,
          ),
        if (searchButtonBuilder != null)
          searchButtonBuilder!(context, controller, radiusClusterState),
      ],
    );
    if (!InteractiveFlag.hasFlag(
        mapCalculator.mapState.options.interactiveFlags,
        InteractiveFlag.rotate)) {
      return overlay;
    }

    final CustomPoint<num> size = mapState.size;
    final sizeChangeDueToRotation =
        size - (mapState.originalSize ?? mapState.size) as CustomPoint<double>;
    return Positioned.fill(
      top: sizeChangeDueToRotation.y / 2,
      bottom: sizeChangeDueToRotation.y / 2,
      left: sizeChangeDueToRotation.x / 2,
      right: sizeChangeDueToRotation.x / 2,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateZ(-mapState.rotationRad),
        child: overlay,
      ),
    );
  }
}
