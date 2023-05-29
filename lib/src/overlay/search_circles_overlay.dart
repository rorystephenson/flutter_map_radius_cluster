import 'package:flutter/widgets.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_radius_cluster/src/options/search_circle_options.dart';
import 'package:flutter_map_radius_cluster/src/options/search_circle_style.dart';
import 'package:flutter_map_radius_cluster/src/state/radius_cluster_state.dart';
import 'package:provider/provider.dart';

import 'search_radius_indicator.dart';

class SearchCirclesOverlay extends StatelessWidget {
  final FlutterMapState mapState;
  final double radiusInM;
  final SearchCircleOptions options;

  const SearchCirclesOverlay({
    Key? key,
    required this.mapState,
    required this.radiusInM,
    required this.options,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radiusClusterState = context.watch<RadiusClusterState>();

    return Stack(
      children: [
        if (radiusClusterState.center != null)
          SearchRadiusIndicator(
            center: radiusClusterState.center!,
            mapState: mapState,
            radiusInM: radiusInM,
            style: _searchCircleStyle(radiusClusterState.searchState),
          ),
        if (radiusClusterState.searchState != RadiusSearchState.loading &&
            radiusClusterState.outsidePreviousSearchBoundary)
          SearchRadiusIndicator(
            mapState: mapState,
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
