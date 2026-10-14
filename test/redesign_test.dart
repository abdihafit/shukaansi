import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/discovery.dart';
import 'package:shukaansi/models/profile_media.dart';
import 'package:shukaansi/screens/profile_details_screen.dart';
import 'package:shukaansi/screens/profile_onboarding.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'account_test.dart' as a;
import 'discovery_fakes.dart';
import 'media_fakes.dart';
import 'profile_test.dart' as p;

Future<AppLocalizations> pumpApp(
  WidgetTester tester, {
  bool emailVerified = true,
  TestPhotos? photos,
  TestDiscovery? discovery,
  String locale = 'en',
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 1600),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    p.harness(
      p.TestProfiles()..stored = ProfileComplete(p.sample, p.details),
      locale,
      brightness,
      account: a.TestAccount()..verified = emailVerified,
      photos: photos ?? TestPhotos(),
      discovery: discovery ?? TestDiscovery(),
      picker: TestPicker(),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold).first));
}

void main() {
  testWidgets('Discover readiness shows real progress and requirement states', (
    tester,
  ) async {
    final s = await pumpApp(
      tester,
      discovery: TestDiscovery()
        ..status = const ListingStatus({ListingGap.noPhoto}),
    );
    expect(find.text(s.discoverNotListedTitle), findsOneWidget);
    expect(
      tester.getSemantics(find.text(s.discoverNeedEmail)),
      isSemantics(isChecked: true, hasCheckedState: true),
    );
    expect(
      tester.getSemantics(find.text(s.discoverNeedPhoto)),
      isSemantics(isChecked: false, hasCheckedState: true),
    );
    // The next step leads to My profile, where photos are managed.
    await p.tap(tester, s.discoverGoToProfile);
    expect(find.text(s.progressAddPhoto), findsOneWidget);
    expect(find.text(s.managePhotos), findsOneWidget);
  });

  testWidgets('My profile progress keeps email, profile and verification '
      'apart', (tester) async {
    final photos = TestPhotos();
    final s = await pumpApp(tester, emailVerified: false, photos: photos);
    await p.openProfileTab(tester);
    expect(find.text('${p.sample.name}, 25'), findsOneWidget);
    expect(find.text(s.progressAccountTodo), findsOneWidget);
    expect(find.text(s.photosCount(0, maxPhotos)), findsOneWidget);
    expect(find.text(s.verifyStatusNotStarted), findsOneWidget);
    // Verification needs a main photo first; that lives with the photos.
    await p.tap(tester, s.managePhotos);
    expect(find.text(s.verifyNeedsPhoto), findsOneWidget);
  });

  testWidgets('verified email and a photo show as done', (tester) async {
    final s = await pumpApp(tester, photos: TestPhotos()..ids = [photoId(1)]);
    await p.openProfileTab(tester);
    expect(find.text(s.emailVerified), findsOneWidget);
    expect(find.text(s.progressAccountTodo), findsNothing);
    expect(find.text(s.photosCount(1, maxPhotos)), findsOneWidget);
  });
  for (final (status, label) in [
    (VerificationStatus.pending, 'In review'),
    (VerificationStatus.rejected, 'Not approved'),
  ]) {
    testWidgets('verification chip shows ${status.name}', (tester) async {
      await pumpApp(
        tester,
        photos: TestPhotos()
          ..ids = [photoId(1)]
          ..verification = Verification(status),
      );
      await p.openProfileTab(tester);
      expect(find.text(label), findsOneWidget);
    });
  }

  testWidgets('profile details are grouped and Edit opens the edit flow', (
    tester,
  ) async {
    final s = await pumpApp(tester);
    await p.openProfileTab(tester);
    await p.tap(tester, s.profileSectionPublic);
    expect(find.byType(ProfileDetailsScreen), findsOneWidget);
    for (final heading in [
      s.profileStepRootsTitle,
      s.profileStepHomeTitle,
      s.profileStepWorkTitle,
      s.profileStepFaithTitle,
      s.profileStepIntentionsTitle,
      s.profileStepAboutTitle,
      s.profileSectionPrivate,
    ]) {
      expect(find.text(heading), findsOneWidget, reason: heading);
    }
    expect(find.text(p.sample.city), findsOneWidget);
    // Static rows are not dressed up as tappable.
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    await tester.tap(find.widgetWithText(ElevatedButton, s.profileEdit));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileDetailsScreen), findsNothing);
    expect(find.byType(ProfileOnboarding), findsOneWidget);
    expect(find.text(s.profileEdit), findsWidgets);
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale ${brightness.name}: small screen and large text do not overflow',
        (tester) async {
          final s = await pumpApp(
            tester,
            locale: locale,
            brightness: brightness,
            size: const Size(320, 640),
            textScale: 1.6,
            photos: TestPhotos()..ids = [photoId(1)],
            discovery: TestDiscovery()
              ..status = const ListingStatus({ListingGap.emailNotVerified}),
          );
          expect(tester.takeException(), isNull);
          await p.openProfileTab(tester);
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.text(s.profileSectionPublic),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await p.tap(tester, s.profileSectionPublic);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
