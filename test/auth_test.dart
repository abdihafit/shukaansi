import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/application/auth_validation.dart';
import 'package:shukaansi/main.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';

Future<void> openForm(WidgetTester tester, String language) async {
  await tester.pumpWidget(const ShukaansiApp());
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
  await tester.tap(find.text(language));
  await tester.pumpAndSettle();
  await tester.tap(find.text(language == 'English' ? 'Get Started' : 'Bilow'));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('validation distinguishes registration from login without altering passwords', () {
    expect(AuthValidation.email('   '), AuthInputError.required);
    expect(AuthValidation.email('name@'), AuthInputError.invalidEmail);
    expect(AuthValidation.email(' user@example.com '), isNull);
    expect(
      AuthValidation.password('short', registering: true),
      AuthInputError.shortPassword,
    );
    expect(AuthValidation.password('short', registering: false), isNull);
    expect(AuthValidation.password('abcdef', registering: true), isNull);
    expect(AuthValidation.password('abcdefg', registering: true), isNull);
    expect(
      AuthValidation.password('a long passphrase', registering: true),
      isNull,
    );
    expect(
      AuthValidation.confirmation('word ', 'word'),
      AuthInputError.passwordMismatch,
    );
  });

  for (final language in ['English', 'Soomaali']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$language ${brightness.name}: validation, unavailable state, mode switch and back',
        (tester) async {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          await tester.binding.setSurfaceSize(const Size(375, 667));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await openForm(tester, language);
          final strings = AppLocalizations.of(
            tester.element(find.byType(Form)),
          );
          final submit = find.widgetWithText(
            ElevatedButton,
            strings.createAccount,
          );
          await tapVisible(tester, submit);
          expect(find.text(strings.fieldRequired), findsNWidgets(3));
          final fields = find.byType(TextFormField);
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText).first)
                .focusNode
                .hasFocus,
            isTrue,
          );
          await tester.enterText(fields.at(0), 'person@example.com');
          await tester.enterText(fields.at(1), 'abcdef');
          await tester.enterText(fields.at(2), 'different phrase');
          await tapVisible(tester, submit);
          expect(find.text(strings.passwordMismatch), findsOneWidget);
          await tester.enterText(fields.at(2), 'abcdef');
          await tapVisible(tester, find.byTooltip(strings.showPassword).first);
          expect(
            tester
                .widgetList<EditableText>(find.byType(EditableText))
                .elementAt(1)
                .obscureText,
            isFalse,
          );
          await tapVisible(tester, submit);
          expect(find.text(strings.authUnavailable), findsOneWidget);
          expect(
            tester.widget<TextFormField>(fields.at(1)).controller!.text,
            isEmpty,
          );
          expect(
            tester.widget<TextFormField>(fields.at(2)).controller!.text,
            isEmpty,
          );
          expect(
            tester.widget<TextFormField>(fields.first).controller!.text,
            'person@example.com',
          );
          await tapVisible(tester, find.text(strings.alreadyHaveAccount));
          expect(find.byType(TextFormField), findsNWidgets(2));
          expect(find.text(strings.authUnavailable), findsNothing);
          expect(
            tester
                .widgetList<EditableText>(find.byType(EditableText))
                .last
                .obscureText,
            isTrue,
          );
          await tester.enterText(find.byType(TextFormField).last, 'short');
          await tapVisible(
            tester,
            find.widgetWithText(ElevatedButton, strings.signIn),
          );
          expect(find.text(strings.authUnavailable), findsOneWidget);
          await tapVisible(tester, find.byType(BackButton));
          expect(find.text(strings.welcomeTitle), findsOneWidget);
          await tapVisible(tester, find.text(strings.signIn));
          expect(find.byType(TextFormField), findsNWidgets(2));
          expect(
            tester
                .widget<TextFormField>(find.byType(TextFormField).last)
                .controller!
                .text,
            isEmpty,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'large Somali form scrolls with keyboard space and reduced motion',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(667, 375));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(const ShukaansiApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Soomaali'));
      await tapVisible(tester, find.text('Bilow'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Samee akoon'),
      );
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );
}
