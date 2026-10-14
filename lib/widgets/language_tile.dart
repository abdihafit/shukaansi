import 'package:flutter/material.dart';

import '../application/locale_scope.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import 'shukaansi_ui.dart';

/// Shows the app language and lets the member switch it. The choice is
/// saved by the app so it is kept on the next launch.
class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key});

  static String _name(AppLocalizations s, String code) =>
      code == 'so' ? s.somaliLanguage : s.englishLanguage;

  Future<void> _choose(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final current = Localizations.localeOf(context).languageCode;
    final scope = LocaleScope.of(context);
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.s,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  s.chooseLanguage,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            for (final code in ['en', 'so'])
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                selected: code == current,
                title: Text(_name(s, code)),
                trailing: code == current
                    ? const Icon(Icons.check_circle)
                    : const Icon(Icons.radio_button_unchecked),
                onTap: () => Navigator.of(context).pop(code),
              ),
            const SizedBox(height: AppSpacing.s),
          ],
        ),
      ),
    );
    if (picked != null && picked != current) {
      scope.selectLocale(Locale(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SectionCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.xs,
        ),
        leading: const ShukaansiIconBadge(icon: Icons.language),
        title: Text(s.settingsLanguage),
        subtitle: Text(_name(s, Localizations.localeOf(context).languageCode)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _choose(context),
      ),
    );
  }
}
