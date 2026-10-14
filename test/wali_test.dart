import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/application/wali_controller.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/matrimonial_profile.dart';
import 'package:shukaansi/models/wali.dart';
import 'package:shukaansi/screens/profile_onboarding.dart';
import 'package:shukaansi/screens/wali_screens.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'discovery_fakes.dart';
import 'interest_fakes.dart';
import 'media_fakes.dart';
import 'profile_test.dart' as p;
import 'wali_fakes.dart';

AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

Future<AppLocalizations> pump(
  WidgetTester tester, {
  required TestWalis walis,
  TestInterests? interests,
  bool hasProfile = true,
  MatrimonialProfile? profile,
  List<String>? shared,
  String locale = 'en',
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 2000),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final profiles = p.TestProfiles();
  if (hasProfile) {
    profiles.stored = ProfileComplete(profile ?? p.sample, p.details);
  }
  await tester.pumpWidget(
    p.harness(
      profiles,
      locale,
      brightness,
      photos: TestPhotos(),
      discovery: TestDiscovery(),
      picker: TestPicker(),
      interests: interests,
      walis: walis,
      share: (text) async => shared?.add(text),
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

final ahmed = testCard('ahmed', name: 'Ahmed', gender: ProfileGender.male);
final hodan = testCard('hodan', name: 'Hodan');

const candidate = MatchCandidate(
  name: 'Ahmed',
  birthYearMonth: 199801,
  city: 'London',
  residenceCountry: 'GB',
  profession: Profession.engineer,
  professionOther: '',
  education: EducationLevel.masters,
  practice: PracticeLevel.active,
  maritalStatus: MaritalStatus.neverMarried,
  about: 'Seeking a righteous wife.',
  verified: true,
);

WaliRequest request(WaliDecision status) => WaliRequest(
  memberUid: 'her',
  otherUid: 'ahmed',
  waliUid: 'owner',
  status: status,
  candidate: candidate,
);

void main() {
  testWidgets('a sister is asked to invite her Wali and can share the code', (
    tester,
  ) async {
    final walis = TestWalis();
    final shared = <String>[];
    final s = await pump(tester, walis: walis, shared: shared);
    await p.openProfileTab(tester);
    expect(find.text(s.waliCardTitle), findsOneWidget);
    expect(find.text(s.waliRequiredChip), findsOneWidget);
    expect(find.text(s.waliRequiredBody), findsOneWidget);
    await p.tap(tester, s.waliInvite);
    expect(walis.calls, ['invite ${p.sample.name}']);
    expect(find.text('WXYZ6789'), findsOneWidget);
    await p.tap(tester, s.waliShareCode);
    expect(shared.single, s.waliShareMessage('WXYZ6789'));
  });

  testWidgets('brothers see the Wali as optional', (tester) async {
    final s = await pump(
      tester,
      walis: TestWalis(),
      profile: testCard('me', gender: ProfileGender.male).profile,
    );
    await p.openProfileTab(tester);
    expect(find.text(s.waliOptionalBody), findsOneWidget);
    expect(find.text(s.waliRequiredChip), findsNothing);
  });

  testWidgets('a linked Wali can be removed after confirming', (tester) async {
    final walis = TestWalis(
      linked: const WaliLink(waliUid: 'w', waliName: 'Abdi'),
    );
    final s = await pump(tester, walis: walis);
    await p.openProfileTab(tester);
    expect(find.text(s.waliLinked('Abdi')), findsOneWidget);
    await p.tap(tester, s.waliRemove);
    expect(find.text(s.waliRemoveTitle('Abdi')), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, s.waliRemove).last);
    await tester.pumpAndSettle();
    expect(walis.calls, ['remove']);
    expect(find.text(s.waliCardTitle), findsOneWidget);
  });

  testWidgets('matches show where the Wali approval stands', (tester) async {
    final walis = TestWalis(
      linked: const WaliLink(waliUid: 'w', waliName: 'Abdi'),
    );
    final s = await pump(
      tester,
      walis: walis,
      interests: TestInterests(matches: [ahmed]),
    );
    // Her Wali is asked about the match automatically.
    expect(walis.calls, contains('request ahmed'));
    await openTab(tester, s.navChats);
    await p.tap(tester, 'Ahmed');
    expect(find.text(s.approvalWaitingYours), findsOneWidget);
  });

  testWidgets('a sister without a Wali is pointed to invite one', (
    tester,
  ) async {
    final s = await pump(
      tester,
      walis: TestWalis(),
      interests: TestInterests(matches: [ahmed]),
    );
    await openTab(tester, s.navChats);
    await p.tap(tester, 'Ahmed');
    expect(find.text(s.approvalNeedsWali), findsOneWidget);
    await p.tap(tester, s.waliInvite);
    expect(find.text(s.waliRequiredBody), findsOneWidget);
  });

  test('approval states from both sides', () {
    // Shown through the controller, which the Matches screen reads.
    final cases = {
      (null, null, false): 'ready',
      (WaliDecision.declined, null, false): 'declined',
      (null, WaliDecision.pending, false): 'waitingTheirWali',
      (null, null, true): 'waitingTheirWali',
      (null, WaliDecision.approved, true): 'ready',
    };
    cases.forEach((key, expected) {
      final (mine, theirs, otherRequired) = key;
      final controller = _controller(mine: mine, theirs: theirs);
      expect(
        controller.approvalFor('x', otherRequired: otherRequired).name,
        expected,
        reason: '$key',
      );
    });
  });

  testWidgets('a guardian joins with a code and decides on matches', (
    tester,
  ) async {
    final walis = TestWalis(requests: [request(WaliDecision.pending)]);
    final s = await pump(tester, walis: walis, hasProfile: false);
    expect(find.byType(ProfileOnboarding), findsOneWidget);
    await p.tap(tester, s.roleWali);
    expect(find.byType(WaliSetup), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, s.waliYourName),
      'Abdi',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, s.waliCode),
      'zzzz2222',
    );
    await p.tap(tester, s.waliJoin);
    expect(find.text(s.waliCodeInvalid), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, s.waliCode),
      'abcd-2345',
    );
    await p.tap(tester, s.waliJoin);
    expect(find.text(s.waliGreeting('Abdi')), findsOneWidget);
    expect(find.text(s.waliGuarding('Hodan')), findsOneWidget);
    expect(find.text(s.waliRequestFor('Hodan')), findsOneWidget);
    expect(find.text(s.cardNameAge('Ahmed', 28)), findsOneWidget);
    expect(find.text(s.waliPhotosNote), findsOneWidget);
    // No Discover or tabs for a guardian.
    expect(find.byType(NavigationBar), findsNothing);
    await p.tap(tester, s.waliApprove);
    expect(walis.calls.last, 'approve ahmed');
    expect(find.text(s.waliApproved), findsOneWidget);
    expect(find.text(s.waliStatusApproved), findsOneWidget);
  });

  testWidgets('declining asks first', (tester) async {
    final walis = TestWalis(
      guardianAccount: const GuardianAccount(
        name: 'Abdi',
        members: [GuardedMember(uid: 'her', name: 'Hodan')],
      ),
      requests: [request(WaliDecision.pending)],
    );
    final s = await pump(tester, walis: walis, hasProfile: false);
    await p.tap(tester, s.waliDecline);
    expect(find.text(s.waliDeclineTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, s.waliDecline));
    await tester.pumpAndSettle();
    expect(walis.calls.last, 'decline ahmed');
    expect(find.text(s.waliStatusDeclined), findsOneWidget);
  });

  testWidgets('a guardian can step down', (tester) async {
    final walis = TestWalis(
      guardianAccount: const GuardianAccount(
        name: 'Abdi',
        members: [GuardedMember(uid: 'her', name: 'Hodan')],
      ),
    );
    final s = await pump(tester, walis: walis, hasProfile: false);
    expect(find.text(s.waliNoRequests), findsOneWidget);
    await p.tap(tester, s.waliStop('Hodan'));
    await tester.tap(find.widgetWithText(TextButton, s.waliStop('Hodan')).last);
    await tester.pumpAndSettle();
    expect(walis.calls, ['stop her']);
    expect(find.text(s.waliNoMembers), findsOneWidget);
  });

  test('invite codes are readable and normalised', () {
    for (var i = 0; i < 50; i++) {
      expect(isWaliCode(newWaliCode()), isTrue);
    }
    expect(cleanWaliCode(' abcd-2345 '), 'ABCD2345');
    expect(isWaliCode('ABCD1234'), isFalse);
    expect(isWaliCode('ABCDO234'), isFalse);
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets('$locale ${brightness.name}: Wali screens fit', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final s = await pump(
          tester,
          walis: TestWalis(
            guardianAccount: const GuardianAccount(
              name: 'Abdi',
              members: [GuardedMember(uid: 'her', name: 'Hodan')],
            ),
            requests: [
              request(WaliDecision.pending),
              request(WaliDecision.approved),
            ],
          ),
          hasProfile: false,
          locale: locale,
          brightness: brightness,
          size: const Size(320, 640),
        );
        expect(tester.takeException(), isNull);
        await p.tap(tester, s.waliAddMember);
        expect(tester.takeException(), isNull);
      });

      testWidgets('$locale ${brightness.name}: the invite card fits', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final s = await pump(
          tester,
          walis: TestWalis(),
          interests: TestInterests(matches: [ahmed]),
          locale: locale,
          brightness: brightness,
          size: const Size(320, 640),
        );
        await openTab(tester, s.navChats);
        await p.tap(tester, 'Ahmed');
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await p.openProfileTab(tester);
        await p.tap(tester, s.waliInvite);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

WaliController _controller({WaliDecision? mine, WaliDecision? theirs}) =>
    WaliController(uid: 'me', service: TestWalis(), required: false)
      ..mine = {'x': ?mine}
      ..theirs = {'x': ?theirs};
