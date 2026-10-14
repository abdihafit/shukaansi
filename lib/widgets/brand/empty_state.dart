import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'buttons.dart';
import 'lifestyle_photo.dart';

/// One clear message for an empty, error or setup state, with the next step:
/// an icon in a soft mint circle, a bold title, a short message and a
/// full-width teal button. A decorative [photo] can take the icon's place.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.children = const [],
    this.photo,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Extra content between the text and the buttons (e.g. a checklist).
  final List<Widget> children;

  /// Decorative lifestyle photo shown instead of the icon circle.
  final LifestylePhoto? photo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),
              if (photo case final photo?)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: SizedBox(
                    width: double.infinity,
                    // Smaller on short screens so the button stays in view.
                    height: MediaQuery.sizeOf(context).height < 700 ? 160 : 220,
                    child: LifestyleImage(photo),
                  ),
                )
              else
                ExcludeSemantics(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 36, color: colors.primary),
                  ),
                ),
              const SizedBox(height: AppSpacing.l),
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              ...children,
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(label: actionLabel!, onPressed: onAction),
              ],
              if (secondaryLabel != null) ...[
                const SizedBox(height: AppSpacing.s),
                TextButton(
                  onPressed: onSecondary,
                  child: Text(secondaryLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
