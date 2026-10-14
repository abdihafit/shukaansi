import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.dart';

/// Small gold check beside a name for profiles whose photos were verified by
/// the review team. The meaning is in its label too, never colour alone.
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 20});
  static const color = AppColors.goldDark;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context).verifiedBadge,
    child: ExcludeSemantics(
      child: Icon(Icons.verified, color: color, size: size),
    ),
  );
}

/// "Photo verified" beside a member's name: gold check and the words, with a
/// tooltip saying it is photo verification, not an identity check.
class PhotoVerifiedLabel extends StatelessWidget {
  const PhotoVerifiedLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: s.photoVerifiedInfo,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        label: '${s.photoVerified}. ${s.photoVerifiedInfo}',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.goldLight.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(AppRadius.feature),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s,
              vertical: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified,
                  size: 16,
                  color: VerifiedBadge.color,
                ),
                const SizedBox(width: AppSpacing.xs),
                // Wraps rather than overflowing with long translations or
                // large text.
                Flexible(
                  child: Text(
                    s.photoVerified,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
