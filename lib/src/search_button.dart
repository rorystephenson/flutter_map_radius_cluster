import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/src/controller/radius_cluster_controller.dart';
import 'package:flutter_map_radius_cluster/src/state/radius_cluster_state.dart';

/// This button will react to the [radiusClusterState], changing color and state
/// depending on the next search state. This button is not customisable, it is
/// intended to serve as a good default and an example of how to implement your
/// own SearchButton.
class SearchButton extends StatelessWidget {
  static const searchText = 'Search';
  static const loadingText = 'Loading';
  static const searchAgainText = 'Search again';

  final RadiusClusterController radiusClusterController;
  final RadiusClusterState radiusClusterState;

  const SearchButton({
    super.key,
    required this.radiusClusterController,
    required this.radiusClusterState,
  });

  @override
  Widget build(BuildContext context) {
    switch (radiusClusterState.nextSearchState) {
      case RadiusSearchNextSearchState.ready:
        return ElevatedButton(
          onPressed: radiusClusterController.searchAtCenter,
          child: const Text(searchText),
        );
      case RadiusSearchNextSearchState.loading:
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
              const Text(loadingText),
            ],
          ),
        );
      case RadiusSearchNextSearchState.error:
        return ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.red),
          ),
          onPressed: radiusClusterController.searchAtCenter,
          child: const Text(searchAgainText),
        );
      case RadiusSearchNextSearchState.disabled:
        return const ElevatedButton(
          onPressed: null,
          child: Text(searchText),
        );
    }
  }
}
