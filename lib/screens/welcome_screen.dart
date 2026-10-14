import 'package:flutter/material.dart';

import '../application/auth_scope.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/brand/brand.dart';
import '../widgets/brand_layout.dart';
import 'auth_screen.dart';

/// The brand, a short greeting, then "Get started" or "Sign in".
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return BrandLayout(
      photo: LifestylePhoto.welcomeWoman,
      logoHeight: 230,
      message: (context) {
        final theme = Theme.of(context);
        return Column(
          children: [
            Semantics(
              header: true,
              child: Text(
                strings.welcomeTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.selectedLanguage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
      actions: (_) => [
        ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AuthScreen(service: AuthScope.of(context)),
            ),
          ),
          child: Text(strings.getStarted),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AuthScreen(
                initialMode: AuthMode.login,
                service: AuthScope.of(context),
              ),
            ),
          ),
          child: Text(strings.signIn),
        ),
      ],
    );
  }
}
