import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/application/interest_controller.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/interest.dart';
import 'package:shukaansi/redesign/member_page.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'discovery_fakes.dart';
import 'interest_fakes.dart';
import 'media_fakes.dart';
import 'profile_test.dart' as p;

AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

Future<AppLocalizations> pump(
  WidgetTester tester,
  TestInterests interests, {
  List<String> discover = const [],
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
      discovery: TestDiscovery()
        ..cards = [
          for (final uid in discover)
            interests.pool.firstWhere((c) => c.uid == uid),
        ],
      picker: TestPicker(),
      interests: interests,
    ),
  );
  await tester.pumpAndSettle();
  return strings(tester);
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

final hodan = testCard('hodan', name: 'Hodan');
final amina = testCard('amina', name: 'Amina');

void main() {
  testWidgets('like sends interest and can be withdrawn from Likes', (
    tester,
  ) async {
    final interests = TestInterests(pool: [hodan]);
    final s = await pump(tester, interests, discover: ['hodan']);
    await tester.tap(find.byTooltip(s.likeAction));
    await tester.pumpAndSettle();
    expect(interests.calls, ['like hodan']);
    expect(find.text(s.likeSent('Hodan')), findsOneWidget);
    // Discover moves on to the next member.
    expect(find.text(s.cardNameAge('Hodan', 25)), findsNothing);

    await openTab(tester, s.navLikes);
    await tester.tap(find.text('${s.likesSentTab} (1)'));
    await tester.pumpAndSettle();
    await p.tap(tester, s.cardNameAge('Hodan', 25));
    expect(find.byType(MemberPage), findsOneWidget);
    await p.tap(tester, s.withdrawInterest);
    expect(interests.calls.last, 'withdraw hodan');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(s.likesSentEmpty), findsOneWidget);
  });

  testWidgets('liking someone who liked you is a match', (tester) async {
    final interests = TestInterests(received: [hodan], pool: [hodan]);
    final s = await pump(tester, interests, discover: ['hodan']);
    // The Likes tab shows how many are waiting.
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsWidgets,
    );
    await tester.tap(find.byTooltip(s.likeAction));
    await tester.pumpAndSettle();
    expect(find.text(s.matchTitle), findsOneWidget);
    expect(find.text(s.matchBody('Hodan')), findsOneWidget);
    expect(find.text(s.matchPhotosNote), findsOneWidget);
    await p.tap(tester, s.viewMatches);
    // New matches sit at the top of Chats.
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.text(s.chatsNewMatches), findsOneWidget);
    await p.tap(tester, 'Hodan');
    // The test member is a sister without a Wali yet.
    expect(find.text(s.approvalNeedsWali), findsOneWidget);
    expect(find.text(s.messageAction), findsNothing);
  });

  testWidgets('Likes: like back or decline', (tester) async {
    final interests = TestInterests(received: [hodan, amina]);
    final s = await pump(tester, interests);
    await openTab(tester, s.navLikes);
    expect(find.text('${s.likesReceivedTab} (2)'), findsOneWidget);
    await p.tap(tester, s.cardNameAge('Amina', 25));
    await p.tap(tester, s.declineInterest);
    expect(interests.calls, ['decline amina']);
    expect(find.byType(MemberPage), findsNothing);
    await p.tap(tester, s.cardNameAge('Hodan', 25));
    await p.tap(tester, s.likeBack);
    expect(find.text(s.matchTitle), findsOneWidget);
    await p.tap(tester, s.keepBrowsing);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(s.likesReceivedEmpty), findsOneWidget);
  });

  testWidgets('a match can be ended from the profile', (tester) async {
    final interests = TestInterests(matches: [hodan]);
    final s = await pump(tester, interests);
    await openTab(tester, s.navChats);
    await p.tap(tester, 'Hodan');
    expect(find.byType(MemberPage), findsOneWidget);
    await tester.tap(find.byTooltip(s.unmatch));
    await tester.pumpAndSettle();
    await p.tap(tester, s.unmatch);
    expect(find.text(s.unmatchTitle('Hodan')), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, s.unmatch));
    await tester.pumpAndSettle();
    expect(interests.calls, ['unmatch hodan']);
    expect(find.byType(MemberPage), findsNothing);
    expect(find.text(s.chatsEmptyTitle), findsOneWidget);
  });
  testWidgets('failures are reported plainly', (tester) async {
    final interests = TestInterests(pool: [hodan]);
    final s = await pump(tester, interests, discover: ['hodan']);
    interests.fail = true;
    await tester.tap(find.byTooltip(s.likeAction));
    await tester.pumpAndSettle();
    expect(find.text(s.interestFailed), findsOneWidget);
    expect(find.byTooltip(s.likeAction), findsOneWidget);
  });

  test('likes sent at the same moment are completed into a match', () async {
    final service = TestInterests(sent: [hodan], received: [hodan]);
    final controller = InterestController(uid: 'me', service: service);
    await controller.load();
    expect(service.calls, ['complete hodan']);
    expect(controller.stateOf('hodan'), InterestState.matched);
    expect(controller.received, isEmpty);
  });

  test('blocked members disappear from every list', () async {
    final controller = InterestController(
      uid: 'me',
      service: TestInterests(received: [hodan], matches: [amina]),
    );
    await controller.load();
    controller.syncHidden({'hodan', 'amina'});
    expect(controller.received, isEmpty);
    expect(controller.matches, isEmpty);
  });

  test('match ids are the same from both sides', () {
    expect(matchIdFor('b', 'a'), 'a_b');
    expect(matchIdFor('a', 'b'), 'a_b');
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale ${brightness.name}: likes, matches and the match sheet fit',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final interests = TestInterests(
            received: [hodan],
            sent: [amina],
            matches: [testCard('maryan', name: 'Maryan', verified: true)],
          );
          final s = await pump(
            tester,
            interests,
            locale: locale,
            brightness: brightness,
            size: const Size(320, 640),
          );
          await openTab(tester, s.navLikes);
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('${s.likesSentTab} (1)'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await openTab(tester, s.navChats);
          expect(tester.takeException(), isNull);
          await openTab(tester, s.navLikes);
          await tester.tap(find.text('${s.likesReceivedTab} (1)'));
          await tester.pumpAndSettle();
          await p.tap(tester, s.cardNameAge('Hodan', 25));
          await p.tap(tester, s.likeBack);
          expect(find.text(s.matchTitle), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
