import 'package:flutter/material.dart';

class SearchCircleStyle {
  /// The width of the search circle indicator border.
  final double borderWidth;

  /// The color of the search circle indicator border when searching succeeds.
  late final Color loadedBorderColor;

  /// The color of the search circle indicator border when searching is
  /// underway.
  late final Color loadingBorderColor;

  /// The color of the search circle indicator border when searching results in
  /// an error.
  late final Color errorBorderColor;

  /// The color of the search circle indicator border which indicates where the
  /// next search will occur if the search button is pressed.
  late final Color nextSearchBorderColor;

  SearchCircleStyle({
    this.borderWidth = 10,
    Color? loadedBorderColor,
    Color? loadingBorderColor,
    Color? errorBorderColor,
    Color? nextSearchBorderColor,
  }) {
    this.loadedBorderColor =
        loadedBorderColor ?? Colors.blueAccent.withOpacity(0.4);
    this.loadingBorderColor =
        loadingBorderColor ?? Colors.grey.withOpacity(0.5);
    this.errorBorderColor =
        errorBorderColor ?? Colors.redAccent.withOpacity(0.4);
    this.nextSearchBorderColor =
        nextSearchBorderColor ?? Colors.grey.withOpacity(0.2);
  }
}
