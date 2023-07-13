import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';

class ExampleCluster extends StatelessWidget {
  final ClusterDataWithCount clusterDataWithCount;

  const ExampleCluster(this.clusterDataWithCount, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0), color: Colors.blue),
      child: Center(
        child: Text(
          clusterDataWithCount.markerCount.toString(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
