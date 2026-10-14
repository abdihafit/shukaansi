import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/chat.dart';
import 'package:shukaansi/models/matrimonial_profile.dart';
import 'package:shukaansi/models/wali.dart';
import 'package:shukaansi/screens/chat_screen.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'chat_fakes.dart';
import 'discovery_fakes.dart';
import 'interest_fakes.dart';
import 'media_fakes.dart';
import 'profile_test.dart' as p;
import 'wali_fakes.dart';

AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

final hodan = testCard('hodan', name: 'Hodan');
final ahmed = testCard('ahmed', name: 'Ahmed', gender: ProfileGender.male);
final brother = testCard(
  'me',
  name: 'Yusuf',
  gender: ProfileGender.male,
).profile;

/// A brother matched with Hodan, whose Wali approved.
Future<AppLocalizations> pumpBrother(
  WidgetTester tester,
  TestChats chats, {
  String locale = 'en',
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 1600),
  WaliDecision herWali = WaliDecision.approved,
}) => _pump(
  tester,
  chats,
  profile: brother,
  interests: TestInterests(matches: [hodan]),
  walis: TestWalis(theirs: {'hodan': herWali}),
  locale: locale,
  brightness: brightness,
  size: size,
);

Future<AppLocalizations> _pump(
  WidgetTester tester,
  TestChats chats, {
  required MatrimonialProfile profile,
  required TestInterests interests,
  required TestWalis walis,
  String locale = 'en',
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 1600),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    p.harness(
      p.TestProfiles()..stored = ProfileComplete(profile, p.details),
      locale,
      brightness,
      photos: TestPhotos(),
      discovery: TestDiscovery(),
      picker: TestPicker(),
      interests: interests,
      walis: walis,
      chats: chats,
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

void main() {
  testWidgets('an approved match starts with salaam and messages', (
    tester,
  ) async {
    final chats = TestChats();
    final s = await pumpBrother(tester, chats);
    await openTab(tester, s.navChats);
    expect(find.text(s.chatsNewMatches), findsOneWidget);
    // A new match opens their profile, with Message at the bottom.
    await p.tap(tester, 'Hodan');
    await p.tap(tester, s.messageAction);
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text(s.chatStarterTitle), findsOneWidget);
    await p.tap(tester, s.chatStarterSalaam);
    expect(find.widgetWithText(TextField, s.chatStarterSalaam), findsOneWidget);
    await tester.tap(find.byTooltip(s.messageSend));
    await tester.pumpAndSettle();
    expect(chats.sent, ['hodan: ${s.chatStarterSalaam}']);
    expect(find.text(s.chatStarterSalaam), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('^${s.messageFromYou}: ')),
      findsOneWidget,
    );

    // Her reply arrives live.
    chats.receive('hodan', 'Wa alaikum assalam');
    await tester.pumpAndSettle();
    expect(find.text('Wa alaikum assalam'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text(s.chatsActive), findsOneWidget);
    expect(find.text('Wa alaikum assalam'), findsOneWidget);
    expect(find.text(s.chatsNewMatches), findsNothing);
  });

  testWidgets('unread conversations are counted and cleared on reading', (
    tester,
  ) async {
    final chats = TestChats()..receive('hodan', 'Assalamu alaikum');
    final s = await pumpBrother(tester, chats);
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('1')),
      findsWidgets,
    );
    await openTab(tester, s.navChats);
    expect(find.bySemanticsLabel(RegExp(s.chatUnread)), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Hodan')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(s.chatUnread)), findsNothing);
  });

  testWidgets('without Wali approval the conversation stays closed', (
    tester,
  ) async {
    final s = await pumpBrother(
      tester,
      TestChats(),
      herWali: WaliDecision.pending,
    );
    await openTab(tester, s.navChats);
    // The new match explains why messaging is closed instead of offering it.
    await p.tap(tester, 'Hodan');
    expect(find.text(s.approvalWaitingTheirs), findsOneWidget);
    expect(find.text(s.messageAction), findsNothing);
    expect(find.byType(ChatScreen), findsNothing);
  });

  testWidgets('a sister waits for her own Wali', (tester) async {
    final s = await _pump(
      tester,
      TestChats(),
      profile: p.sample,
      interests: TestInterests(matches: [ahmed]),
      walis: TestWalis(
        linked: const WaliLink(waliUid: 'w', waliName: 'Abdi'),
        mine: {'ahmed': WaliDecision.pending},
      ),
    );
    await openTab(tester, s.navChats);
    await p.tap(tester, 'Ahmed');
    expect(find.text(s.approvalWaitingYours), findsOneWidget);
    expect(find.text(s.messageAction), findsNothing);
  });

  testWidgets('a failed send keeps the text and says so', (tester) async {
    final chats = TestChats()..failSend = true;
    final s = await pumpBrother(tester, chats);
    await openTab(tester, s.navChats);
    await p.tap(tester, 'Hodan');
    await p.tap(tester, s.messageAction);
    await tester.enterText(find.byType(TextField), 'Assalamu alaikum');
    await tester.tap(find.byTooltip(s.messageSend));
    await tester.pumpAndSettle();
    expect(find.text(s.messageSendFailed), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Assalamu alaikum'), findsOneWidget);
  });

  test('previews are one short line', () {
    expect(messagePreview('  Hello\n\nthere  '), 'Hello there');
    final long = messagePreview('word ' * 100);
    expect(long.length <= maxPreviewLength, isTrue);
    expect(long, isNot(endsWith(' ')));
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets('$locale ${brightness.name}: chats fit a small screen', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final chats = TestChats()
          ..receive('hodan', 'Assalamu alaikum, how are you and your family?');
        final s = await pumpBrother(
          tester,
          chats,
          locale: locale,
          brightness: brightness,
          size: const Size(320, 640),
        );
        await openTab(tester, s.navChats);
        expect(tester.takeException(), isNull);
        await tester.tap(find.bySemanticsLabel(RegExp('^Hodan')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField), 'Wa alaikum assalam');
        await tester.tap(find.byTooltip(s.messageSend));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
