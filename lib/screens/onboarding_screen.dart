import 'package:flutter/material.dart';

import '../application/locale_scope.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/brand_layout.dart';
import '../widgets/brand/brand.dart';

import 'welcome_screen.dart';

/// First choice: the app language (English or Somali).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _selectLanguage(BuildContext context, String languageCode) {
    LocaleScope.of(context).selectLocale(Locale(languageCode));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return BrandLayout(
      photo: LifestylePhoto.welcomeMan,
      variant: LogoVariant.symbol,
      logoHeight: 120,
      message: (context) {
        final theme = Theme.of(context);
        return Column(
          children: [
            Semantics(
              header: true,
              child: Text(
                strings.chooseLanguage,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              strings.chooseLanguageSomali,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
      actions: (_) => [
        ElevatedButton(
          onPressed: () => _selectLanguage(context, 'en'),
          child: Text(strings.englishLanguage),
        ),
        OutlinedButton(
          onPressed: () => _selectLanguage(context, 'so'),
          child: Text(strings.somaliLanguage),
        ),
      ],
    );
  }
}
