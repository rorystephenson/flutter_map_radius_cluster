import 'package:flutter/animation.dart';

/// Options for a continuous fading animation.
class FadeAnimationOptions {
  /// The highest opacity that the child will have during the fade.
  final double maximumOpacity;

  /// The lowest opacity that the child will have during the fade.
  final double minimumOpacity;

  /// The initial opacity that the child will have when fading starts. Defaults
  /// to the [minimumOpacity].
  final double initialOpacity;

  /// The duration of the fade animation.
  final Duration duration;

  /// The curve of the fade animation.
  final Curve curve;

  const FadeAnimationOptions({
    required this.maximumOpacity,
    required this.minimumOpacity,
    double? initialOpacity,
    this.duration = const Duration(seconds: 1),
    this.curve = Curves.easeIn,
  })  : initialOpacity = initialOpacity ?? minimumOpacity,
        assert(maximumOpacity >= 0 && maximumOpacity <= 1.0),
        assert(minimumOpacity >= 0 && minimumOpacity <= maximumOpacity),
        assert(initialOpacity == null ||
            (initialOpacity >= minimumOpacity &&
                initialOpacity <= maximumOpacity));
}
