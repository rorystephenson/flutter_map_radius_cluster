## [2.2.0]

- BREAKING: `searchCircleStyle` is now `searchCircleOptions` and allows more customisation of
            search circles in the various states. Notably search circles may now have a repeating
            fade animation. If you use the default options the loading circle indicator will use
            this animation.

## [2.1.0]

- DEPENDENCY: `flutter_map` 3.1.0
- DEPENDENCY: `supercluster` 2.1.1
- BUGFIX: Don't hide popups too early when zooming out.

## [2.0.0]

- BREAKING: `flutter_map` 3.0.0
- BREAKING: `supercluster` 2.0.0

## [1.1.0]

- Add selectedMarkerBuilder option to PopupOptions which allows selected Markers
  to have a different a behaviour/appearance if desired.
- Fix a bug where the next search indicator was in the wrong position when the
  map was rotated.

## [1.0.0]

- Allow popups to be shown outside of the map.
- The search button is now optional and completely customisable either using the builder in the
  RadiusClusterLayerOptions or using a PopupScope above the RadiusClusterLayer and listening to the
  RadiusClusterState in order to show the button outside the map if desired.

## [0.0.2]

- Fix jumpy zoom when tapping a cluster before the previous cluster tap animation finishes.
- Add next search indicator, a circle which indicates where the next search will take place if a
  search is performed.
- Add an option to prevent searching if the previous successful search is within a specified
  distance of the current map center.

## [0.0.1]

- First release
