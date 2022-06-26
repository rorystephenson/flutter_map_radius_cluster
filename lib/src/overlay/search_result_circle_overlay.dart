import 'package:flutter/widgets.dart';
import 'package:flutter_map_radius_cluster/src/state/radius_cluster_state.dart';
import 'package:provider/provider.dart';

import '../map_calculator.dart';
import 'search_circle_style.dart';
import 'search_radius_indicator.dart';

class SearchResultCircleOverlay extends StatelessWidget {
  final MapCalculator mapCalculator;
  final double radiusInM;
  final SearchCircleStyle style;

  const SearchResultCircleOverlay({
    Key? key,
    required this.mapCalculator,
    required this.radiusInM,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radiusClusterState = context.watch<RadiusClusterState>();
    if (radiusClusterState.center == null) return const SizedBox.shrink();

    return SearchRadiusIndicator(
      center: radiusClusterState.center!,
      mapCalculator: mapCalculator,
      radiusInM: radiusInM,
      borderColor: _borderColor(radiusClusterState.searchState),
      borderWidth: style.borderWidth,
    );
  }

  Color _borderColor(RadiusSearchState searchState) {
    switch (searchState) {
      case RadiusSearchState.complete:
        return style.loadedBorderColor;
      case RadiusSearchState.loading:
        return style.loadingBorderColor;
      case RadiusSearchState.error:
        return style.errorBorderColor;
      case RadiusSearchState.noSearchPerformed:
        throw 'Should not be drawing a circle if no search was performed';
    }
  }
}
