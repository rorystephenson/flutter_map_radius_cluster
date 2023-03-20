/// Options used when revealing a Marker's popup.
class ShowPopupOptions {
  final bool hideOthers;
  final bool disableAnimation;

  ShowPopupOptions({
    /// If true all other popups are hidden when revealing the target popup.
    this.hideOthers = true,

    /// If true the popup reveal animation will not be used. Has no affect if no
    /// popup animation is defined.
    this.disableAnimation = false,
  });
}
