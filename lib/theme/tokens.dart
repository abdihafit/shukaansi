/// Spacing scale (4/8 dp rhythm) shared by redesigned screens.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;
}

/// Sizes shared by the redesigned screens.
abstract final class AppSizes {
  /// Minimum touch target.
  static const touch = 48.0;

  /// Height of full-width primary and secondary buttons.
  static const button = 52.0;

  /// Portrait frame for profile photos (width / height).
  static const portrait = 4 / 5;

  /// Discover's pass and like buttons.
  static const passButton = 56.0;
  static const likeButton = 64.0;
}

/// Corner radii: small controls, inputs/buttons, cards, feature cards.
abstract final class AppRadius {
  static const small = 8.0;
  static const control = 14.0;
  static const card = 20.0;
  static const feature = 20.0;

  /// The large lead photo of a profile card.
  static const hero = 24.0;
}
