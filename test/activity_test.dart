import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/matrimonial_profile.dart';
import 'package:shukaansi/models/wali.dart';
import 'package:shukaansi/screens/activity_screen.dart';
import 'package:shukaansi/screens/chat_screen.dart';
import 'package:shukaansi/services/profile_service.dart';
import 'package:shukaansi/services/seen_store.dart';

import 'chat_fakes.dart';
import 'discovery_fakes.dart';
import 'interest_fakes.dart';
import 'media_fakes.dart';
import 'profile_test.dart' as p;
import 'wali_fakes.dart';

AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

final hodan = testCard('hodan', name: 'Hodan');
final amina = testCard('amina', name: 'Amina');
final brother = testCard(
  'me',
  name: 'Yusuf',
  gender: ProfileGender.male,
).profile;

Future<AppLocalizations> pump(
  WidgetTester tester, {
  required TestInterests interests,
  TestWalis? walis,
  TestChats? chats,
  SeenStore? seen,
  String locale = 'en',
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 1600),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    p.harness(
      p.TestProfiles()..stored = ProfileComplete(brother, p.details),
      locale,
      brightness,
      photos: TestPhotos(),
      discovery: TestDiscovery(),
      picker: TestPicker(),
      interests: interests,
      walis: walis ?? TestWalis(),
      chats: chats ?? TestChats(),
      seenStore: seen ?? MemorySeenStore(),
    ),
  );
  await tester.pumpAndSettle();
  return strings(tester);
}

void main() {
  testWidgets('a match made while the app is open is announced', (
    tester,
  ) async {
    final interests = TestInterests(sent: [hodan], pool: [hodan]);
    final s = await pump(tester, interests: interests);
    expect(find.byType(SnackBar), findsNothing);
    // She likes him back elsewhere: the server now has a match.
    interests
      ..sent = []
      ..matches = [hodan]
      ..emit();
    await tester.pumpAndSettle();
    expect(find.text(s.activityMatched('Hodan')), findsOneWidget);
    await tester.tap(find.text(s.activityView));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
  });

  testWidgets('old news is counted on the bell, not announced', (tester) async {
    final s = await pump(tester, interests: TestInterests(received: [amina]));
    expect(find.byType(SnackBar), findsNothing);
    expect(
      find.descendant(
        of: find.byTooltip(s.activityTitle),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip(s.activityTitle));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityScreen), findsOneWidget);
    expect(find.text(s.activityLiked('Amina')), findsOneWidget);
    expect(find.text(s.activityNew), findsOneWidget);
    expect(find.text(s.activityOpenOnly), findsOneWidget);
    // Opening an item goes where it belongs.
    await p.tap(tester, s.activityLiked('Amina'));
    expect(find.byType(ActivityScreen), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    // Seen now: the bell count is gone.
    await tester.tap(find.text(s.navDiscover));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byTooltip(s.activityTitle),
        matching: find.text('1'),
      ),
      findsNothing,
    );
  });

  testWidgets('seen notifications stay seen on the next launch', (
    tester,
  ) async {
    final seen = MemorySeenStore();
    var s = await pump(
      tester,
      interests: TestInterests(received: [amina]),
      seen: seen,
    );
    await tester.tap(find.byTooltip(s.activityTitle));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    s = await pump(
      tester,
      interests: TestInterests(received: [amina]),
      seen: seen,
    );
    expect(
      find.descendant(
        of: find.byTooltip(s.activityTitle),
        matching: find.text('1'),
      ),
      findsNothing,
    );
  });

  testWidgets('a new message is announced unless that chat is open', (
    tester,
  ) async {
    final chats = TestChats();
    final s = await pump(
      tester,
      interests: TestInterests(matches: [hodan]),
      walis: TestWalis(theirs: {'hodan': WaliDecision.approved}),
      chats: chats,
    );
    chats.receive('hodan', 'Assalamu alaikum');
    await tester.pumpAndSettle();
    expect(find.text(s.activityMessage('Hodan')), findsOneWidget);
    await tester.tap(find.text(s.activityView));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    ScaffoldMessenger.of(tester.element(find.byType(ChatScreen)))
        .clearSnackBars();
    await tester.pumpAndSettle();
    chats.receive('hodan', 'How is your family?');
    await tester.pumpAndSettle();
    expect(find.text(s.activityMessage('Hodan')), findsNothing);
  });

  testWidgets('a guardian decision is announced', (tester) async {
    final walis = TestWalis(theirs: {'hodan': WaliDecision.pending});
    final s = await pump(
      tester,
      interests: TestInterests(matches: [hodan]),
      walis: walis,
    );
    walis
      ..theirs = {'hodan': WaliDecision.approved}
      ..emit();
    await tester.pumpAndSettle();
    expect(find.text(s.activityTheirWaliApproved('Hodan')), findsOneWidget);
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets('$locale ${brightness.name}: notifications fit', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final chats = TestChats()..receive('hodan', 'Assalamu alaikum');
        final s = await pump(
          tester,
          interests: TestInterests(received: [amina], matches: [hodan]),
          walis: TestWalis(theirs: {'hodan': WaliDecision.approved}),
          chats: chats,
          locale: locale,
          brightness: brightness,
          size: const Size(320, 640),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip(s.activityTitle));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
