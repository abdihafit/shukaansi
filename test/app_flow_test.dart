import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/main.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  return first > second
      ? (first + 0.05) / (second + 0.05)
      : (second + 0.05) / (first + 0.05);
}

void main() {
  for (final brightness in Brightness.values) {
    for (final language in ['English', 'Soomaali']) {
      testWidgets('$language flow in ${brightness.name} mode', (tester) async {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await tester.binding.setSurfaceSize(const Size(375, 667));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(const ShukaansiApp());
        // The splash shows the logo; its label carries the name and tagline.
        expect(
          find.bySemanticsLabel('Shukaansi, Halal • Serious • Together'),
          findsOneWidget,
        );
        final theme = Theme.of(tester.element(find.byType(Scaffold)));
        expect(theme.brightness, brightness);
        final colors = theme.colorScheme;
        expect(
          contrast(colors.primary, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(colors.onSurface, colors.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(colors.onPrimary, colors.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(colors.secondary, colors.surface),
          greaterThanOrEqualTo(3),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Choose your language'), findsOneWidget);
        for (final button in [
          find.byType(ElevatedButton),
          find.byType(OutlinedButton),
        ]) {
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        }
        await tester.tap(find.text(language));
        await tester.pumpAndSettle();
        final english = language == 'English';
        expect(
          find.text(
            english
                ? 'Assalamu alaikum, welcome to Shukaansi'
                : 'Assalaamu calaykum, ku soo dhawoow Shukaansi',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            english
                ? 'Language selected: English'
                : 'Luqadda la doortay: Soomaali',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text(english ? 'Get Started' : 'Bilow'));
        await tester.pumpAndSettle();
        expect(
          find.text(english ? 'Create account' : 'Samee akoon'),
          findsWidgets,
        );
        expect(find.byType(TextFormField), findsNWidgets(3));
        expect(
          Localizations.localeOf(tester.element(find.byType(Scaffold)))
              .languageCode,
          english ? 'en' : 'so',
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
