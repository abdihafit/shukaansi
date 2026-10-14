import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/wali_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'shukaansi_ui.dart';

/// Shares text through the phone's share sheet (WhatsApp, SMS, ...).
typedef ShareText = Future<void> Function(String text);

/// My profile: the member's Wali, or how to invite one.
class WaliCard extends StatelessWidget {
  const WaliCard({
    super.key,
    required this.controller,
    required this.memberName,
    required this.share,
  });
  final WaliController controller;
  final String memberName;
  final ShareText share;

  Future<void> _remove(BuildContext context, String name) async {
    final s = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(s.waliRemoveTitle(name)),
        content: Text(s.waliRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(s.profileCancelEdit),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(s.waliRemove),
          ),
        ],
      ),
    );
    if (ok == true && !await controller.removeWali() && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(s.interestFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.loaded) {
          if (controller.loadFailed) {
            return SectionCard(
              child: Row(
                children: [
                  Expanded(child: Text(s.waliLoadFailed)),
                  TextButton(onPressed: controller.load, child: Text(s.retry)),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }
        final link = controller.link;
        final invite = controller.invite;
        final header = Row(
          children: [
            ShukaansiIconBadge(
              icon: Icons.family_restroom,
              color: colors.secondary,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      link == null
                          ? s.waliCardTitle
                          : s.waliLinked(link.waliName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Under the title so it never squeezes it on small phones.
                  if (link == null && controller.required) ...[
                    const SizedBox(height: AppSpacing.xs),
                    ShukaansiStatusChip(
                      label: s.waliRequiredChip,
                      icon: Icons.priority_high,
                      tone: StatusTone.attention,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
        final body = Text(
          link != null
              ? s.waliLinkedBody
              : controller.required
              ? s.waliRequiredBody
              : s.waliOptionalBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        );
        return SectionCard(
          tinted: link == null && controller.required,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: AppSpacing.s),
              body,
              const SizedBox(height: AppSpacing.m),
              if (link != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: controller.busy
                        ? null
                        : () => _remove(context, link.waliName),
                    child: Text(s.waliRemove),
                  ),
                )
              else if (invite == null)
                Pressable(
                  enabled: !controller.busy,
                  child: ElevatedButton.icon(
                    onPressed: controller.busy
                        ? null
                        : () async {
                            if (!await controller.createInvite(memberName) &&
                                context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(s.interestFailed)),
                              );
                            }
                          },
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(s.waliInvite),
                  ),
                )
              else ...[
                Text(s.waliInviteCode, style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  invite.code,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    color: colors.primary,
                  ),
                ),
                Text(
                  s.waliInviteExpires(
                    MaterialLocalizations.of(context)
                        .formatMediumDate(invite.expiresAt),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.m),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.s,
                  children: [
                    Pressable(
                      child: ElevatedButton.icon(
                        onPressed: () => share(s.waliShareMessage(invite.code)),
                        icon: const Icon(Icons.share),
                        label: Text(s.waliShareCode),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: invite.code),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(s.waliCopied)));
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(s.waliCopyCode),
                    ),
                    TextButton(
                      onPressed: controller.busy
                          ? null
                          : () => controller.createInvite(memberName),
                      child: Text(s.waliNewCode),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
