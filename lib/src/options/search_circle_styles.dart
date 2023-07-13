import 'package:flutter/material.dart';
import 'package:flutter_map_radius_cluster/flutter_map_radius_cluster.dart';

@Deprecated(
  'Prefer SearchCircleStyles. '
  'This class has been renamed for clarity. '
  'This class is deprecated since v3.1.0.',
)
typedef SearchCircleOptions = SearchCircleStyles;

class SearchCircleStyles {
  static const defaultBorderWidth = 10.0;

  /// The style of the search circle when searching is complete.
  final SearchCircleStyle loadedCircleStyle;

  /// The style of the search circle when searching is underway.
  final SearchCircleStyle loadingCircleStyle;

  /// The style of the search circle when searching results in an error.
  final SearchCircleStyle errorCircleStyle;

  /// The style of the search circle which indicates where the next search will
  /// occur if the search button is pressed.
  final SearchCircleStyle nextSearchCircleStyle;

  const SearchCircleStyles({
    this.loadedCircleStyle = const SearchCircleStyle(
      borderWidth: 10,
      borderColor: Color(0x66448aff), // Colors.blueAccent.withOpacity(0.4)
    ),
    this.loadingCircleStyle = const SearchCircleStyle(
      borderWidth: 10,
      borderColor: Color(0x669e9e9e), // Colors.grey.withOpacity(0.4),
      fadeAnimation: FadeAnimationOptions(
        duration: Duration(milliseconds: 750),
        initialOpacity: 0.5,
        maximumOpacity: 1.0,
        minimumOpacity: 0.5,
        curve: Curves.easeInOut,
      ),
    ),
    this.errorCircleStyle = const SearchCircleStyle(
      borderWidth: 10,
      borderColor: Color(0x66ff5252), // Colors.redAccent.withOpacity(0.4),
    ),
    this.nextSearchCircleStyle = const SearchCircleStyle(
      borderWidth: 10,
      borderColor: Color(0x339e9e9e), //Colors.grey.withOpacity(0.2),
    ),
  });
}
