import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/account_service.dart';

/// Shows whether the owner's email is verified and lets them resend or recheck.
class EmailVerificationCard extends StatefulWidget {
  const EmailVerificationCard({
    super.key,
    required this.account,
    this.onVerified,
  });
  final AccountService account;

  /// Called once the email is confirmed verified, so the page can update.
  final VoidCallback? onVerified;
  @override
  State<EmailVerificationCard> createState() => _EmailVerificationCardState();
}

class _EmailVerificationCardState extends State<EmailVerificationCard> {
  late bool _verified = widget.account.emailVerified;
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  Future<void> _run(
    Future<void> Function() action,
    String Function(AppLocalizations) success,
  ) async {
    if (_busy) return;
    final s = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted) {
        setState(() {
          _message = _verified ? null : success(s);
          _messageIsError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = s.accountActionFailed;
          _messageIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() => _run(() async {
    final verified = await widget.account.reloadEmailVerified();
    if (mounted) setState(() => _verified = verified);
    if (verified) widget.onVerified?.call();
  }, (s) => s.emailVerifyNotYet);

  Future<void> _resend() =>
      _run(widget.account.sendEmailVerification, (s) => s.emailVerifySent);

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (_verified) {
      return Row(
        children: [
          ExcludeSemantics(
            child: Icon(Icons.verified_outlined, color: colors.primary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(s.emailVerified, style: theme.textTheme.titleSmall),
          ),
        ],
      );
    }
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colors.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    color: colors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      s.emailVerifyTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.emailVerifyBody(widget.account.email ?? ''),
              style: TextStyle(color: colors.onSecondaryContainer),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _busy ? null : _check,
                  child: Text(_busy ? s.authLoading : s.emailVerifyCheck),
                ),
                TextButton(
                  onPressed: _busy ? null : _resend,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onSecondaryContainer,
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(s.emailVerifyResend),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _messageIsError
                        ? colors.error
                        : colors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
