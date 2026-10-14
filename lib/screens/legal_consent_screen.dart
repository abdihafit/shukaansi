import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/legal.dart';
import '../theme/tokens.dart';
import '../widgets/pressable.dart';
import '../widgets/shukaansi_ui.dart';
import 'legal_document_screen.dart';

/// Asks the member to accept the current Terms of Use and Privacy Policy
/// before anything else. Shown inside AccountScreen so signing out remains
/// available.
class LegalConsentScreen extends StatefulWidget {
  const LegalConsentScreen({super.key, required this.onAccept});

  /// Saves the acceptance; throws if it could not be saved.
  final Future<void> Function() onAccept;

  @override
  State<LegalConsentScreen> createState() => _LegalConsentScreenState();
}

class _LegalConsentScreenState extends State<LegalConsentScreen> {
  bool _agreed = false;
  bool _busy = false;
  bool _failed = false;

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.onAccept();
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: ShukaansiIconBadge(
            icon: Icons.verified_user_outlined,
            size: 88,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Semantics(
          header: true,
          child: Text(
            s.legalTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          s.legalBody,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _DocumentCard(
          icon: Icons.handshake_outlined,
          title: s.termsOfUse,
          summary: s.legalTermsPoint,
          onOpen: () => LegalDocumentScreen.open(context, LegalDocument.terms),
        ),
        const SizedBox(height: AppSpacing.m),
        _DocumentCard(
          icon: Icons.lock_outline,
          title: s.privacyPolicy,
          summary: s.legalPrivacyPoint,
          onOpen: () =>
              LegalDocumentScreen.open(context, LegalDocument.privacy),
        ),
        const SizedBox(height: AppSpacing.l),
        CheckboxListTile(
          value: _agreed,
          onChanged: _busy ? null : (v) => setState(() => _agreed = v!),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(s.legalAgree),
        ),
        if (_failed) ...[
          const SizedBox(height: AppSpacing.s),
          Semantics(
            liveRegion: true,
            child: Text(
              s.legalSaveFailed,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.error),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.l),
        Pressable(
          enabled: _agreed && !_busy,
          child: ElevatedButton(
            onPressed: _agreed && !_busy ? _accept : null,
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(s.legalContinue),
          ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.onOpen,
  });
  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      tinted: true,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.s,
        ),
        leading: ShukaansiIconBadge(icon: icon, size: 48),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(summary),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpen,
      ),
    );
  }
}

/// Terms and privacy links for My profile.
class LegalLinksCard extends StatelessWidget {
  const LegalLinksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    Widget row(IconData icon, String title, LegalDocument document) => ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.xs,
      ),
      leading: ShukaansiIconBadge(icon: icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => LegalDocumentScreen.open(context, document),
    );
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          row(Icons.handshake_outlined, s.termsOfUse, LegalDocument.terms),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          row(Icons.lock_outline, s.privacyPolicy, LegalDocument.privacy),
        ],
      ),
    );
  }
}
