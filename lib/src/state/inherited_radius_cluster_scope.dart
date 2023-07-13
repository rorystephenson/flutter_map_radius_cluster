import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';

class InheritedRadiusClusterScope extends InheritedWidget {
  final RadiusClusterState radiusClusterState;
  final void Function(RadiusClusterState state) setRadiusClusterState;

  const InheritedRadiusClusterScope({
    super.key,
    required this.radiusClusterState,
    required this.setRadiusClusterState,
    required super.child,
  });

  static InheritedRadiusClusterScope? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) {
    if (listen) {
      return context
          .dependOnInheritedWidgetOfExactType<InheritedRadiusClusterScope>();
    } else {
      return context
          .getInheritedWidgetOfExactType<InheritedRadiusClusterScope>();
    }
  }

  static InheritedRadiusClusterScope of(
    BuildContext context, {
    bool listen = true,
  }) {
    final result = maybeOf(context, listen: listen);
    assert(result != null, 'No InheritedRadiusClusterScope found in context.');
    return result!;
  }

  @override
  bool updateShouldNotify(InheritedRadiusClusterScope oldWidget) =>
      oldWidget.radiusClusterState != radiusClusterState;
}
