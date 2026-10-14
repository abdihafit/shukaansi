import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/moderation.dart';
import '../services/session_service.dart';
import 'account_screen.dart';

/// Locked screen for suspended members; only signing out is possible.
class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key, required this.status, required this.auth});
  final AccountStatus status;
  final SessionService auth;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AccountScreen(
      service: auth,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Icon(Icons.block, size: 48, color: colors.error),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              s.suspendedTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(s.suspendedBody, style: theme.textTheme.bodyLarge),
          if (status.reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(s.suspendedReason(status.reason)),
          ],
          if (supportEmail.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText(s.suspendedContact(supportEmail)),
          ],
        ],
      ),
    );
  }
}
