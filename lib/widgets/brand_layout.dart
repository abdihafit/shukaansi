import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'brand/brand.dart';

/// Layout for the brand screens before sign-in: ivory surface, the logo in
/// the upper middle, an optional message under it and the actions anchored
/// at the bottom, within thumb reach. Scrolls on short screens and with
/// large text. An optional decorative [photo] sits above the logo.
class BrandLayout extends StatelessWidget {
  const BrandLayout({
    super.key,
    this.variant = LogoVariant.full,
    this.logoHeight = 200,
    this.message,
    this.actions,
    this.photo,
  });
  final LogoVariant variant;
  final double logoHeight;

  /// Built inside the brand surface, so `Theme.of` gives its light theme
  /// (also in dark mode).
  final WidgetBuilder? message;
  final List<Widget> Function(BuildContext context)? actions;
  final LifestylePhoto? photo;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BrandSurface(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.l,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0, box.maxHeight - AppSpacing.l * 2),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          // Left out on very short (landscape) screens.
                          if (photo case final photo?
                              when box.maxHeight >= 480) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.hero,
                              ),
                              child: SizedBox(
                                // A third of short screens, so the actions
                                // stay in view; capped on tablets.
                                height: math.min(
                                  460,
                                  box.maxHeight *
                                      (box.maxHeight < 700 ? 0.3 : 0.42),
                                ),
                                width: double.infinity,
                                child: LifestyleImage(photo),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ] else
                            SizedBox(height: box.maxHeight * 0.08),
                          ShukaansiLogo(
                            variant: variant,
                            // Smaller on short screens so actions stay in view.
                            height: math.min(
                              logoHeight,
                              box.maxHeight * (photo == null ? 0.32 : 0.14),
                            ),
                          ),
                          if (message != null) ...[
                            const SizedBox(height: AppSpacing.xl),
                            message!(context),
                          ],
                        ],
                      ),
                      if (actions != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, action) in actions!(
                                context,
                              ).indexed) ...[
                                if (i > 0) const SizedBox(height: AppSpacing.m),
                                action,
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
