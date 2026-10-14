import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Which brand artwork to show.
enum LogoVariant {
  /// Symbol, "Shukaansi" and the tagline.
  full,

  /// The symbol alone, for small spaces and loading.
  symbol,
}

/// The Shukaansi logo from assets/branding. The artwork is teal and gold on a
/// transparent background, so it is always placed on a light brand surface
/// (see [BrandSurface]); its teal would disappear on dark backgrounds.
class ShukaansiLogo extends StatelessWidget {
  const ShukaansiLogo({
    super.key,
    this.variant = LogoVariant.full,
    required this.height,
  });
  final LogoVariant variant;
  final double height;

  static const fullAsset = 'assets/branding/shukaansi_logo_transparent.png';

  /// Width / height of the full logo artwork.
  static const fullAspect = 2628 / 2049;

  /// Width of the full logo on the launch screens. The native splash image
  /// (assets/branding/splash_logo.png) is drawn at this same size, centred,
  /// so the hand-over from the native splash is seamless.
  static const launchWidth = 240.0;
  static const launchHeight = launchWidth / fullAspect;
  static const symbolAsset = 'assets/branding/shukaansi_symbol_transparent.png';

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      variant == LogoVariant.full ? fullAsset : symbolAsset,
      height: height,
      fit: BoxFit.contain,
      // Decode at the size shown, not the full artwork resolution.
      cacheHeight: (height * ratio).round(),
      semanticLabel: '${s.appTitle}, ${s.tagline}',
    );
  }
}

/// The ivory background used behind the logo (splash, loading, welcome), in
/// light and dark mode alike, so the artwork always reads as designed. Text
/// and buttons on it use the app's light theme.
class BrandSurface extends StatelessWidget {
  const BrandSurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: AppTheme.refinedLight,
    child: ColoredBox(color: AppColors.ivory, child: child),
  );
}

/// The symbol on an ivory circle: a small brand mark for ordinary pages
/// (sign in, forgot password) that reads in light and dark mode.
class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.ivory,
        shape: BoxShape.circle,
      ),
      child: ShukaansiLogo(variant: LogoVariant.symbol, height: size * 0.62),
    ),
  );
}

/// The full logo (with its "Halal • Serious • Together" tagline) at the top
/// of sign-in pages. In dark mode it sits on a small ivory card so the teal
/// artwork stays legible.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.height = 132});
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final logo = ShukaansiLogo(height: height);
    return Center(
      child: dark
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: logo,
              ),
            )
          : logo,
    );
  }
}
