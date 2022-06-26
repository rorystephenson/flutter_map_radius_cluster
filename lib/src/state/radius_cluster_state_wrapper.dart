import 'package:flutter/widgets.dart';
import 'package:flutter_map_radius_cluster/src/state/radius_cluster_state.dart';

import 'radius_cluster_scope.dart';

class RadiusClusterStateWrapper extends StatelessWidget {
  final Widget Function(
      BuildContext context, RadiusClusterState radiusClusterState) builder;

  const RadiusClusterStateWrapper({Key? key, required this.builder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final popupState = RadiusClusterState.maybeOf(context, listen: false);
    if (popupState != null) return builder(context, popupState);

    return RadiusClusterScope(
      child: Builder(
        builder: (BuildContext context) => builder(
          context,
          RadiusClusterState.maybeOf(context, listen: false)!,
        ),
      ),
    );
  }
}
