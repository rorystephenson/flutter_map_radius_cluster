import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/options/search_circle_style.dart';
import 'package:flutter_map_radius_cluster/src/options/search_circle_styles.dart';
import 'package:flutter_map_radius_cluster/src/state/radius_cluster_state.dart';

import 'search_radius_indicator.dart';

class SearchCirclesOverlay extends StatelessWidget {
  final MapCamera camera;
  final double radiusInM;
  final SearchCircleStyles options;

  const SearchCirclesOverlay({
    Key? key,
    required this.camera,
    required this.radiusInM,
    required this.options,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radiusClusterState = RadiusClusterState.of(context);

    final currentSearchStyle =
        _searchCircleStyle(radiusClusterState.searchState);
    return Stack(
      children: [
        if (currentSearchStyle.isVisible && radiusClusterState.center != null)
          SearchRadiusIndicator(
            center: radiusClusterState.center!,
            camera: camera,
            radiusInM: radiusInM,
            style: currentSearchStyle,
          ),
        if (options.nextSearchCircleStyle.isVisible &&
            radiusClusterState.searchState != RadiusSearchState.loading &&
            radiusClusterState.outsidePreviousSearchBoundary)
          SearchRadiusIndicator(
            camera: camera,
            radiusInM: radiusInM,
            style: options.nextSearchCircleStyle,
          ),
      ],
    );
  }

  SearchCircleStyle _searchCircleStyle(RadiusSearchState searchState) {
    switch (searchState) {
      case RadiusSearchState.complete:
        return options.loadedCircleStyle;
      case RadiusSearchState.loading:
        return options.loadingCircleStyle;
      case RadiusSearchState.error:
        return options.errorCircleStyle;
      case RadiusSearchState.noSearchPerformed:
        throw 'Should not be drawing a circle if no search was performed';
    }
  }
}
