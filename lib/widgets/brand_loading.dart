import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import 'brand/brand.dart';

/// The brand symbol with a small spinner, for loading inside a page.
class BrandLoading extends StatelessWidget {
  const BrandLoading({super.key, this.showProgress = true});
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ShukaansiLogo(variant: LogoVariant.symbol, height: 88),
        if (showProgress) ...[
          const SizedBox(height: 32),
          SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Theme.of(context).colorScheme.primary,
              semanticsLabel: s.authLoading,
            ),
          ),
        ],
      ],
    );
  }
}

/// The launch/loading page: the full logo exactly where the native splash
/// draws it (centred, [ShukaansiLogo.launchWidth] wide) on ivory, a small teal
/// spinner below, and nothing else. If loading takes unusually long and
/// [onSignOut] is given, a quiet way out appears.
class BrandLoadingPage extends StatefulWidget {
  const BrandLoadingPage({
    super.key,
    this.semanticsLabel,
    this.onSignOut,
    this.slowAfter = const Duration(seconds: 8),
  });

  /// Says what is loading, for screen readers.
  final String? semanticsLabel;

  /// Offered only after [slowAfter]; uses the app's existing sign-out.
  final VoidCallback? onSignOut;
  final Duration slowAfter;

  @override
  State<BrandLoadingPage> createState() => _BrandLoadingPageState();
}

class _BrandLoadingPageState extends State<BrandLoadingPage> {
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    if (widget.onSignOut != null) {
      _timer = Timer(widget.slowAfter, () {
        if (mounted) setState(() => _slow = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      body: BrandSurface(
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return Stack(
              children: [
                // Centred on the whole screen, like the native splash.
                Center(
                  child: Semantics(
                    label: widget.semanticsLabel,
                    child: const ShukaansiLogo(
                      height: ShukaansiLogo.launchHeight,
                    ),
                  ),
                ),
                // Just below the logo, without moving it.
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, box) => Padding(
                      padding: EdgeInsets.only(
                        top:
                            box.maxHeight / 2 +
                            ShukaansiLogo.launchHeight / 2 +
                            AppSpacing.xxl,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: theme.colorScheme.primary,
                                semanticsLabel: s.authLoading,
                              ),
                            ),
                            AnimatedOpacity(
                              opacity: _slow ? 1 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: _slow
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.xl,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            s.loadingSlow,
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          TextButton(
                                            onPressed: widget.onSignOut,
                                            child: Text(s.signOut),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
