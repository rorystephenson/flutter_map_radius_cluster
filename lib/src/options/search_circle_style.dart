import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/src/options/fade_animation_options.dart';

class SearchCircleStyle {
  /// The width of the search circle indicator border.
  final double borderWidth;

  /// The color of the search circle indicator border.
  final Color borderColor;

  /// If provided, the search circle border fades in and out with the provided
  /// options.
  final FadeAnimationOptions? fadeAnimation;

  const SearchCircleStyle({
    this.borderWidth = 10,
    required this.borderColor,
    this.fadeAnimation,
  });
}
