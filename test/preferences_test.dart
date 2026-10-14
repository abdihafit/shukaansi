import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/discovery.dart';
import 'package:shukaansi/models/matrimonial_profile.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'discovery_fakes.dart';
import 'media_fakes.dart';
import 'profile_test.dart' as p;

AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

Future<AppLocalizations> pump(
  WidgetTester tester,
  TestDiscovery discovery, {
  String locale = 'en',
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 1600),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    p.harness(
      p.TestProfiles()..stored = ProfileComplete(p.sample, p.details),
      locale,
      brightness,
      photos: TestPhotos(),
      discovery: discovery,
      picker: TestPicker(),
    ),
  );
  await tester.pumpAndSettle();
  return strings(tester);
}

final amina = testCard('amina', name: 'Amina');
final bilan = testCard('bilan', name: 'Bilan', marital: MaritalStatus.divorced);

void main() {
  test('preferences survive a round trip and ignore bad values', () {
    const prefs = DiscoveryFilter(
      minAge: 24,
      maxAge: 35,
      countries: {'GB', 'SO'},
      maritalStatuses: {MaritalStatus.neverMarried},
      practices: {PracticeLevel.active, PracticeLevel.strict},
    );
    final back = DiscoveryFilter.fromMap(prefs.toMap());
    expect(back.minAge, 24);
    expect(back.maxAge, 35);
    expect(back.countries, {'GB', 'SO'});
    expect(back.maritalStatuses, {MaritalStatus.neverMarried});
    expect(back.practices, {PracticeLevel.active, PracticeLevel.strict});
    final odd = DiscoveryFilter.fromMap({
      'minAge': 90,
      'maxAge': 10,
      'countries': ['GB', 3],
      'maritalStatuses': ['married', 'widowed'],
    });
    expect(odd.minAge <= odd.maxAge, isTrue);
    expect(odd.countries, {'GB'});
    expect(odd.maritalStatuses, {MaritalStatus.widowed});
  });

  testWidgets('without preferences "For you" invites setting them', (
    tester,
  ) async {
    final discovery = TestDiscovery()..cards = [amina, bilan];
    final s = await pump(tester, discovery);
    expect(find.text(s.discoverForYou), findsOneWidget);
    expect(find.text(s.forYouSetupTitle), findsOneWidget);
    await p.tap(tester, s.setPreferences);
    await tester.tap(find.widgetWithText(FilterChip, s.profileDivorced));
    await tester.pumpAndSettle();
    await p.tap(tester, s.prefSave);
    expect(find.text(s.forYouSetupTitle), findsNothing);
    expect(find.text(s.cardNameAge('Bilan', 25)), findsOneWidget);
    expect(find.text(s.cardNameAge('Amina', 25)), findsNothing);
  });

  testWidgets('saved preferences choose "For you" from the start', (
    tester,
  ) async {
    final discovery = TestDiscovery()
      ..cards = [amina, bilan]
      ..preferences = const DiscoveryFilter(
        maritalStatuses: {MaritalStatus.neverMarried},
      );
    final s = await pump(tester, discovery);
    expect(find.text(s.forYouSetupTitle), findsNothing);
    expect(find.text(s.cardNameAge('Amina', 25)), findsOneWidget);
    expect(find.text(s.cardNameAge('Bilan', 25)), findsNothing);
  });

  testWidgets('"New members" shows everyone, newest first', (tester) async {
    final discovery = TestDiscovery()
      ..cards = [amina, bilan]
      ..preferences = const DiscoveryFilter(
        maritalStatuses: {MaritalStatus.neverMarried},
      );
    final s = await pump(tester, discovery);
    // The feed switcher is the Discover title menu.
    await tester.tap(find.text(s.discoverForYou));
    await tester.pumpAndSettle();
    await p.tap(tester, s.discoverNewMembers);
    expect(discovery.lastFeed, DiscoverFeed.newMembers);
    expect(find.byTooltip(s.partnerPreferences), findsNothing);
    // One member at a time, newest first; Amina's preferences do not apply.
    expect(find.text(s.cardNameAge('Bilan', 25)), findsOneWidget);
    expect(find.text(s.cardNameAge('Amina', 25)), findsNothing);
    await tester.tap(find.byTooltip(s.passAction));
    await tester.pumpAndSettle();
    expect(find.text(s.cardNameAge('Amina', 25)), findsOneWidget);
  });

  testWidgets('countries can be added, removed and are limited', (
    tester,
  ) async {
    final discovery = TestDiscovery()..cards = [amina];
    final s = await pump(tester, discovery);
    await tester.tap(find.byTooltip(s.partnerPreferences));
    await tester.pumpAndSettle();
    await p.tap(tester, s.prefAddCountry);
    await p.tap(tester, 'Somalia');
    expect(find.widgetWithText(InputChip, 'Somalia'), findsOneWidget);
    await tester.tap(find.byTooltip(s.prefRemoveCountry('Somalia')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'Somalia'), findsNothing);
    await p.tap(tester, s.prefAddCountry);
    await p.tap(tester, 'United Kingdom');
    await p.tap(tester, s.prefSave);
    expect(discovery.preferences!.countries, {'GB'});
  });

  testWidgets('My profile summarises and edits preferences', (tester) async {
    final discovery = TestDiscovery()
      ..preferences = const DiscoveryFilter(
        minAge: 25,
        maxAge: 35,
        countries: {'GB', 'SO'},
      );
    final s = await pump(tester, discovery);
    await p.openProfileTab(tester);
    expect(
      find.text('${s.prefAges(25, 35)} · ${s.prefCountryCount(2)}'),
      findsOneWidget,
    );
    await p.tap(tester, s.partnerPreferences);
    expect(find.text(s.prefSave), findsOneWidget);
  });

  testWidgets('a failed save keeps the sheet open with a message', (
    tester,
  ) async {
    final discovery = TestDiscovery()
      ..cards = [amina]
      ..failPreferences = true;
    final s = await pump(tester, discovery);
    await tester.tap(find.byTooltip(s.partnerPreferences));
    await tester.pumpAndSettle();
    await p.tap(tester, s.prefSave);
    expect(find.text(s.prefSaveFailed), findsOneWidget);
    expect(find.text(s.prefSave), findsOneWidget);
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale ${brightness.name}: feeds and preferences fit a small screen',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final s = await pump(
            tester,
            TestDiscovery()..cards = [amina],
            locale: locale,
            brightness: brightness,
            size: const Size(320, 640),
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip(s.partnerPreferences));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await p.tap(tester, s.prefAddCountry);
          await tester.tap(find.byType(ListTile).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
