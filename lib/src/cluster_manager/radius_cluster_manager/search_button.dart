import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';
import 'package:latlong2/latlong.dart';

import 'radius_cluster_manager.dart';

class SearchButton extends StatelessWidget {
  final RadiusSearchState radiusSearchState;
  final Function(LatLng center) searchAt;
  final bool allowSearch;
  final double radiusInM;
  final MapCalculator mapCalculator;
  final DistanceCalculator distanceCalculator;

  const SearchButton({
    super.key,
    required this.radiusSearchState,
    required this.searchAt,
    required this.allowSearch,
    required this.radiusInM,
    required this.mapCalculator,
    required this.distanceCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: _button(),
    );
  }

  Widget _button() {
    switch (radiusSearchState) {
      case RadiusSearchState.complete:
      case RadiusSearchState.noSearchPerformed:
        return _loadButton();
      case RadiusSearchState.loading:
        return _loadingButton();
      case RadiusSearchState.error:
        return _errorButton();
    }
  }

  Widget _loadButton() {
    return ElevatedButton(
      onPressed: !allowSearch
          ? null
          : () {
              searchAt(mapCalculator.mapState.center);
            },
      child: const Text('Load crags'),
    );
  }

  Widget _loadingButton() {
    return ElevatedButton(
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
    );
  }

  Widget _errorButton() {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.red),
      ),
      child: const Text('Retry'),
      onPressed: () {
        searchAt(mapCalculator.mapState.center);
      },
    );
  }
}
