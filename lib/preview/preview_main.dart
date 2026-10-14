import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'preview_app.dart';
import 'preview_config.dart';

/// Development-only preview of the redesigned experience, with fictional
/// in-memory profiles. It never initialises Firebase.
///
///   flutter run -t lib/preview/preview_main.dart --dart-define=SHUKAANSI_PREVIEW=true
///
/// The normal app is still `flutter run` (lib/main.dart).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(previewAllowed() ? PreviewApp() : const PreviewDisabledApp());
}

/// Shown when the preview entry point is started without the flag, or in a
/// release build.
class PreviewDisabledApp extends StatelessWidget {
  const PreviewDisabledApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) {
        final s = AppLocalizations.of(context);
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.previewDisabledTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(s.previewDisabledBody, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
