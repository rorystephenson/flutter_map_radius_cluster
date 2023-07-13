import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/src/options/fade_animation_options.dart';

class SearchCircleStyle {
  /// The width of the search circle indicator border. If [borderColor]
  /// is null no border is drawn.
  final double borderWidth;

  /// The color of the search circle indicator border. If this is null no border
  /// is drawn.
  final Color? borderColor;

  /// The color of the search circle fill. If this is null no fill is drawn.
  final Color? fillColor;

  /// If provided, the search circle border fades in and out with the provided
  /// options.
  final FadeAnimationOptions? fadeAnimation;

  const SearchCircleStyle({
    this.borderWidth = 0,
    this.borderColor,
    this.fillColor,
    this.fadeAnimation,
  }) : assert(borderWidth >= 0);

  const SearchCircleStyle.invisible()
      : borderWidth = 0,
        borderColor = null,
        fillColor = null,
        fadeAnimation = null;

  bool get isVisible =>
      (borderWidth > 0 && borderColor != null) || fillColor != null;

  @override
  bool operator ==(Object other) {
    return other is SearchCircleStyle &&
        other.borderWidth == borderWidth &&
        other.borderColor == borderColor &&
        other.fillColor == fillColor &&
        other.fadeAnimation == fadeAnimation;
  }

  @override
  int get hashCode => Object.hash(
        borderWidth,
        borderColor,
        fillColor,
        fadeAnimation,
      );
}
