import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import '../shukaansi_ui.dart';

/// A white rounded section (radius 20) on the warm page. Flat: the page
/// colour separates it, no outline or heavy shadow.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.tinted = false,
    this.padding = const EdgeInsets.all(AppSpacing.l),
  });
  final Widget child;
  final String? title;
  final IconData? icon;

  /// A soft mint surface for highlighted cards instead of plain white.
  final bool tinted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: tinted
          ? Color.alphaBlend(
              colors.primaryContainer.withValues(alpha: 0.6),
              colors.surfaceContainerLowest,
            )
          : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    ShukaansiIconBadge(icon: icon!),
                    const SizedBox(width: AppSpacing.m),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// A settings or navigation row: icon in a soft mint square, title, optional
/// subtitle, and a chevron when it opens something.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// Replaces the chevron (e.g. a status or a switch).
  final Widget? trailing;

  /// Defaults to the brand teal.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      minVerticalPadding: AppSpacing.m,
      leading: ExcludeSemantics(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.small + 2),
          ),
          child: Icon(icon, size: 22, color: iconColor ?? colors.primary),
        ),
      ),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing:
          trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right)),
      onTap: onTap,
    );
  }
}
