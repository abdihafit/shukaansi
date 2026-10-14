import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/widgets/brand/brand.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/discovery.dart';
import 'package:shukaansi/models/matrimonial_profile.dart';
import 'package:shukaansi/models/profile_media.dart';
import 'package:shukaansi/services/blur_thumbnail.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'account_test.dart' as a;
import 'discovery_fakes.dart';
import 'media_fakes.dart';
import 'profile_test.dart' as p;

Future<AppLocalizations> pumpDiscover(
  WidgetTester tester,
  TestDiscovery discovery, {
  ProfileGender gender = ProfileGender.male,
  TestPhotos? photos,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final profile = MatrimonialProfile.fromMap({
    ...p.sample.toMap(),
    'gender': gender.name,
  });
  await tester.pumpWidget(
    p.harness(
      p.TestProfiles()..stored = ProfileComplete(profile, p.details),
      'en',
      Brightness.light,
      account: a.TestAccount()..verified = true,
      photos: photos ?? (TestPhotos()..ids = [photoId(1)]),
      discovery: discovery,
      picker: TestPicker(),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold).first));
}

void main() {
  testWidgets('blurred copies are tiny PNG images', (tester) async {
    final thumbnail = (await tester.runAsync(() => blurThumbnail(png)))!;
    expect(imageContentType(thumbnail), 'image/png');
    expect(thumbnail.length, lessThan(32 * 1024));
  });

  test('age uses year and month only; filters match on the device', () {
    final today = DateTime(2026, 9, 29);
    expect(ageFromYearMonth(200101, today), 25);
    expect(ageFromYearMonth(200109, today), 25);
    expect(ageFromYearMonth(200110, today), 24);
    final card = testCard('a', marital: MaritalStatus.divorced);
    expect(const DiscoveryFilter().matches(card, today), isTrue);
    expect(const DiscoveryFilter(minAge: 26).matches(card, today), isFalse);
    expect(const DiscoveryFilter(maxAge: 24).matches(card, today), isFalse);
    expect(
      const DiscoveryFilter(maritalStatuses: {MaritalStatus.neverMarried})
          .matches(card, today),
      isFalse,
    );
    expect(
      const DiscoveryFilter(practices: {PracticeLevel.active})
          .matches(card, today),
      isTrue,
    );
    expect(const DiscoveryFilter().isDefault, isTrue);
  });

  test('listing maps never need private fields', () {
    final card = ProfileCard.fromMap('her', {
      ...testCard('x').profile.toMap(),
      'birthYearMonth': 200101,
      'photoIds': [photoId(1)],
      'photosBlurred': true,
      'verified': true,
    });
    expect(card.verified, isTrue);
    expect(card.photosBlurred, isTrue);
    expect(card.profile.name, 'Hodan');
    expect(
      () => ProfileCard.fromMap('bad', {'name': 'Missing fields'}),
      throwsA(anything),
    );
  });

  testWidgets(
    'unlisted members see what is missing and can go to their profile',
    (tester) async {
      final discovery = TestDiscovery()
        ..status = const ListingStatus({
          ListingGap.emailNotVerified,
          ListingGap.noPhoto,
        });
      final s = await pumpDiscover(tester, discovery);
      expect(find.text(s.discoverNotListedTitle), findsOneWidget);
      expect(find.text(s.discoverNeedEmail), findsOneWidget);
      expect(find.text(s.discoverNeedPhoto), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));

      discovery.status = const ListingStatus({});
      discovery.cards = [testCard('her')];
      await p.tap(tester, s.discoverCheckAgain);
      expect(find.text(s.cardNameAge('Hodan', 25)), findsOneWidget);

      discovery.status = const ListingStatus({ListingGap.noPhoto});
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pumpAndSettle();
      await p.tap(tester, s.discoverGoToProfile);
      expect(find.text(s.managePhotos), findsOneWidget);
    },
  );

  testWidgets(
    'feed shows cards, the blue check only when verified, and filters',
    (tester) async {
      final discovery = TestDiscovery()
        ..cards = [
          testCard('a', name: 'Amina', verified: true),
          testCard('b', name: 'Bilan', marital: MaritalStatus.divorced),
        ];
      final s = await pumpDiscover(tester, discovery);
      // One member at a time; the label claims photo verification only.
      expect(find.text(s.cardNameAge('Amina', 25)), findsOneWidget);
      expect(find.text(s.cardNameAge('Bilan', 25)), findsNothing);
      expect(find.byType(PhotoVerifiedLabel), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(s.photoVerified)), findsOneWidget);
      expect(
        find.text(s.cardLocation('London', 'United Kingdom')),
        findsWidgets,
      );

      await tester.tap(find.byTooltip(s.partnerPreferences));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, s.profileDivorced));
      await tester.pumpAndSettle();
      await p.tap(tester, s.prefSave);
      expect(discovery.lastFilter!.maritalStatuses, {MaritalStatus.divorced});
      expect(discovery.preferences!.maritalStatuses, {MaritalStatus.divorced});
      expect(find.text(s.prefSaved), findsOneWidget);
      expect(find.text(s.cardNameAge('Amina', 25)), findsNothing);
      expect(find.text(s.cardNameAge('Bilan', 25)), findsOneWidget);

      await tester.tap(find.byTooltip(s.partnerPreferences));
      await tester.pumpAndSettle();
      await p.tap(tester, s.discoverReset);
      await p.tap(tester, s.prefSave);
      expect(discovery.lastFilter!.isDefault, isTrue);
      expect(find.text(s.cardNameAge('Amina', 25)), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('blurred photos load only blurred copies until approved', (
    tester,
  ) async {
    final discovery = TestDiscovery()..cards = [testCard('her', blurred: true)];
    final s = await pumpDiscover(tester, discovery);
    expect(find.text(s.photosPrivateTitle), findsOneWidget);
    expect(discovery.photoLoads, isNotEmpty);
    expect(discovery.photoLoads.every((load) => load.$2), isTrue);

    discovery.failRequest = true;
    await p.tap(tester, s.photosRequest);
    expect(find.text(s.photosRequestFailed), findsOneWidget);
    discovery.failRequest = false;
    await p.tap(tester, s.photosRequest);
    expect(find.text(s.photosRequested), findsOneWidget);
    await p.tap(tester, s.photosCancelRequest);
    expect(find.text(s.photosRequest), findsOneWidget);
  });

  testWidgets('approved viewers and open profiles load originals', (
    tester,
  ) async {
    final discovery = TestDiscovery()
      ..cards = [testCard('her', blurred: true), testCard('open')]
      ..access['her'] = PhotoAccess.granted;
    final s = await pumpDiscover(tester, discovery);
    expect(find.text(s.photosPrivateTitle), findsNothing);
    expect(discovery.photoLoads.every((load) => !load.$2), isTrue);
  });

  testWidgets('sync and feed failures offer retry; empty feeds say so', (
    tester,
  ) async {
    final discovery = TestDiscovery()..failSync = true;
    final s = await pumpDiscover(tester, discovery);
    expect(find.text(s.networkErrorTitle), findsOneWidget);
    discovery.failSync = false;
    await p.tap(tester, s.retry);
    // Nobody to show and no preferences yet: setting them is the next step.
    expect(find.text(s.forYouSetupTitle), findsOneWidget);
  });

  testWidgets('women can blur photos and approve or decline requests', (
    tester,
  ) async {
    final photos = TestPhotos()..ids = [photoId(1)];
    final discovery = TestDiscovery()
      ..requests = [
        testCard(
          'm1',
          name: 'Ahmed',
          gender: ProfileGender.male,
          verified: true,
        ),
        testCard('m2', name: 'Yusuf', gender: ProfileGender.male),
      ];
    final s = await pumpDiscover(
      tester,
      discovery,
      gender: ProfileGender.female,
      photos: photos,
    );
    await p.openProfileTab(tester);
    await p.tap(tester, s.managePhotos);
    expect(find.text(s.blurTitle), findsOneWidget);
    await p.tapFinder(tester, find.byType(SwitchListTile));
    expect(photos.blurred, isTrue);

    expect(find.text(s.cardNameAge('Ahmed', 25)), findsOneWidget);
    await p.tapFinder(
      tester,
      find.widgetWithText(FilledButton, s.requestsApprove).first,
    );
    expect(discovery.calls, ['approve m1']);
    expect(find.text(s.viewersTitle), findsOneWidget);
    await p.tap(tester, s.requestsDecline);
    expect(discovery.calls.last, 'decline m2');
    expect(find.text(s.requestsEmpty), findsOneWidget);
    await p.tap(tester, s.viewersRemove);
    expect(discovery.calls.last, 'revoke m1');

    photos.failBlur = true;
    await p.tapFinder(tester, find.byType(SwitchListTile));
    expect(find.text(s.blurFailed), findsOneWidget);
  });

  testWidgets('men have no blur setting', (tester) async {
    final s = await pumpDiscover(tester, TestDiscovery());
    await p.openProfileTab(tester);
    await p.tap(tester, s.managePhotos);
    expect(find.text(s.blurTitle), findsNothing);
  });
}
