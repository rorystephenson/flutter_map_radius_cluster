## [3.0.0]

This version includes two major changes. Dart 3.0.0 is now required and points which are too close
to uncluster at maximum zoom can now be splayed. When a splay cluster is tapped the inner points
are revealed.

- FEATURE: Added clusterSplayDelegate to control cluster splaying. See the documentation for more
           information. The example app has a new page to demonstrate splaying.
- FEATURE: Added collapseSplayedClusters() to SuperclusterController. 
- FEATURE: Added an assertion to check that the supercluster's maximum zoom is not higher than the
  FlutterMap maxZoom (if set). There is no reason to have the supercluster maxZoom higher and it
  breaks splay cluster behaviour.
- FEATURE: Setting cluster data (Supercluster's extractClusterData) is now optional.
- BREAKINGL Requires dart 3 and flutter 3.1.
- BREAKING: Updated to kdbush 0.0.5.
- BREAKING: Updated to supercluster 2.1.1.
- BREAKING: Updated to flutter_map 4.0.0.
- BREAKING: Updated flutter_map_marker_popup to 5.0.0, breaking changes:
  - The popupBuilder, popupSnap and popupAnimation options from PopupOptions are now combined in to
    a single option: popupDisplayOptions.
  - PopupMarkerLayerOptions.rotationAlignmentFor has been replaced with a new rotateAlignment
    extension method on AnchorAlign. So
    PopupMarkerLayerOptions.rotationAlignmentFor(AnchorAlign.top) becomes
    AnchorAlign.top.rotationAlignment.
- BREAKING: Popups are now controlled via the RadiusClusterController. This is necessary to properly
  support displaying popups for splayed markers.
- BREAKING: The following marker rotation options have been removed, they should be set on the
  markers themselves:
  - rotate
  - rotateOrigin
  - rotateAlignment
- BREAKING: RadiusClusterLayer's onClusterTap is now replaced with moveMap. The moveMap callback
  defines how RadiusClusterLayer moves the map.
- BREAKING: RadiusClusterController.moveToMarker's move option has been renamed to moveMap.


## [2.4.0]

 - BREAKING: Clusters no longer have a tap behaviour by default. Previously tapping a cluster
             zoomed in until its markers were visible but now this is optional behaviour that can
             be implented using onClusterTap which provides the minimum zoom required to view the
             cluster's points. See the example app for examples of both animated and non-animated
             zooming.
 - BREAKING: RadiusClusterController moveToMarker's arguments have changed. The popup behaviour is
             now the same as the RadiusClusterLayer's popupOptions and showing popups is controlled
             with the showPopup option. The style of movement can be changed using the [move]
             callback, see the documentation and the example app for more information.
 - BREAKING: ClusterZoomAnimation has been removed, movement animations can now be configured by
             the user, see the two previous points.
 - FEATURE: Various performance improvements around rendering of search circles.
 - FEATURE: All movement is now controlled by the user which means they may now choose to use an
            animated flutter map movement plugin like flutter_map_aniamtions to animate movement.

## [2.3.0]

- FEATURE: Added RadiusClusterController.moveToMarker which allows the map to be moved to a marker
           and, if required to make the marker visible, trigger searching and zooming.
- BREAKING: Remove stream getter from RadiusClusterController since the stream only exists for
            passing events to RadiusClusterLayer.

## [2.2.1]

- FEATURE: Make selected markers appear above others.

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
