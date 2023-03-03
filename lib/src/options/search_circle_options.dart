import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';

class SearchCircleOptions {
  /// The style of the search circle when searching is complete.
  late final SearchCircleStyle loadedCircleStyle;

  /// The style of the search circle when searching is underway.
  late final SearchCircleStyle loadingCircleStyle;

  /// The style of the search circle when searching results in an error.
  late final SearchCircleStyle errorCircleStyle;

  /// The style of the search circle which indicates where the next search will
  /// occur if the search button is pressed.
  late final SearchCircleStyle nextSearchCircleStyle;

  SearchCircleOptions({
    SearchCircleStyle? loadedCircleStyle,
    SearchCircleStyle? loadingCircleStyle,
    SearchCircleStyle? errorCircleStyle,
    SearchCircleStyle? nextSearchCircleStyle,
  }) {
    this.loadedCircleStyle = loadedCircleStyle ??
        SearchCircleStyle(
          borderColor: Colors.blueAccent.withOpacity(0.4),
        );
    this.loadingCircleStyle = loadingCircleStyle ??
        SearchCircleStyle(
          borderColor: Colors.grey.withOpacity(0.4),
          fadeAnimation: const FadeAnimationOptions(
            duration: Duration(milliseconds: 750),
            initialOpacity: 0.5,
            maximumOpacity: 1.0,
            minimumOpacity: 0.5,
            curve: Curves.easeInOut,
          ),
        );
    this.errorCircleStyle = errorCircleStyle ??
        SearchCircleStyle(
          borderColor: Colors.redAccent.withOpacity(0.4),
        );
    this.nextSearchCircleStyle = nextSearchCircleStyle ??
        SearchCircleStyle(
          borderColor: Colors.grey.withOpacity(0.2),
        );
  }
}
