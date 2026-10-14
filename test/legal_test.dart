import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/legal.dart';
import 'package:shukaansi/screens/legal_consent_screen.dart';
import 'package:shukaansi/screens/legal_document_screen.dart';
import 'package:shukaansi/screens/profile_onboarding.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'discovery_fakes.dart';
import 'media_fakes.dart';
import 'profile_test.dart' as p;

AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

Future<void> pump(
  WidgetTester tester,
  p.TestConsents consents, {
  bool complete = false,
  String locale = 'en',
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 1600),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final profiles = p.TestProfiles();
  if (complete) profiles.stored = ProfileComplete(p.sample, p.details);
  await tester.pumpWidget(
    p.harness(
      profiles,
      locale,
      brightness,
      photos: TestPhotos(),
      discovery: TestDiscovery(),
      picker: TestPicker(),
      consents: consents,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('new members accept the terms before onboarding', (tester) async {
    final consents = p.TestConsents();
    await pump(tester, consents);
    final s = strings(tester);
    expect(find.byType(LegalConsentScreen), findsOneWidget);
    expect(find.byType(ProfileOnboarding), findsNothing);
    // Nothing can be accepted until the box is ticked.
    final button = find.widgetWithText(ElevatedButton, s.legalContinue);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
    await p.tap(tester, s.legalAgree);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(consents.version, currentLegalVersion);
    expect(find.byType(LegalConsentScreen), findsNothing);
    expect(find.byType(ProfileOnboarding), findsOneWidget);
  });

  testWidgets('members who accepted an older version are asked again', (
    tester,
  ) async {
    await pump(tester, p.TestConsents(currentLegalVersion - 1), complete: true);
    expect(find.byType(LegalConsentScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('a failed save keeps the member on the consent screen', (
    tester,
  ) async {
    final consents = p.TestConsents()..failAccept = true;
    await pump(tester, consents);
    final s = strings(tester);
    await p.tap(tester, s.legalAgree);
    await p.tap(tester, s.legalContinue);
    expect(find.text(s.legalSaveFailed), findsOneWidget);
    expect(find.byType(LegalConsentScreen), findsOneWidget);
    expect(consents.version, isNull);
  });

  testWidgets('a failed check offers a retry', (tester) async {
    final consents = p.TestConsents(currentLegalVersion)..failRead = true;
    await pump(tester, consents, complete: true);
    final s = strings(tester);
    expect(find.text(s.legalCheckFailed), findsOneWidget);
    consents.failRead = false;
    await p.tap(tester, s.retry);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  for (final locale in ['en', 'so']) {
    testWidgets('$locale: both documents open from the consent screen', (
      tester,
    ) async {
      await pump(tester, p.TestConsents(), locale: locale);
      final s = strings(tester);
      for (final (title, heading) in [
        (s.termsOfUse, locale == 'so' ? '1. Ujeeddadayada' : '1. Our purpose'),
        (s.privacyPolicy, locale == 'so' ? 'Soo koobid' : 'In short'),
      ]) {
        await p.tap(tester, title);
        expect(find.byType(LegalDocumentScreen), findsOneWidget);
        expect(find.text(heading), findsOneWidget, reason: title);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('My profile links to the terms and privacy policy', (
    tester,
  ) async {
    await pump(tester, p.TestConsents(currentLegalVersion), complete: true);
    await p.openProfileTab(tester);
    final s = strings(tester);
    expect(find.byType(LegalLinksCard), findsOneWidget);
    await p.tap(tester, s.privacyPolicy);
    expect(find.text('We never sell your data.'), findsOneWidget);
  });

  test('every bundled document exists in both languages', () {
    for (final document in LegalDocument.values) {
      expect(document.assetFor('en'), endsWith('_en.md'));
      expect(document.assetFor('so'), endsWith('_so.md'));
      expect(document.assetFor('fr'), endsWith('_en.md'));
    }
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale ${brightness.name}: consent fits a small screen, large text',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await pump(
            tester,
            p.TestConsents(),
            locale: locale,
            brightness: brightness,
            size: const Size(320, 640),
          );
          expect(tester.takeException(), isNull);
          await p.tap(tester, strings(tester).termsOfUse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
