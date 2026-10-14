import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/membership.dart';
import 'package:shukaansi/screens/plans_screen.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'discovery_fakes.dart';
import 'interest_fakes.dart';
import 'media_fakes.dart';
import 'membership_fakes.dart';
import 'profile_test.dart' as p;

AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

final hodan = testCard('hodan', name: 'Hodan');

Future<AppLocalizations> pump(
  WidgetTester tester, {
  TestMemberships? memberships,
  TestInterests? interests,
  List<String> discover = const [],
  String locale = 'en',
  Brightness brightness = Brightness.light,
  Size size = const Size(400, 1800),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final i = interests ?? TestInterests();
  await tester.pumpWidget(
    p.harness(
      p.TestProfiles()..stored = ProfileComplete(p.sample, p.details),
      locale,
      brightness,
      photos: TestPhotos(),
      discovery: TestDiscovery()
        ..cards = [
          for (final uid in discover) i.pool.firstWhere((c) => c.uid == uid),
        ],
      picker: TestPicker(),
      interests: i,
      memberships: memberships,
    ),
  );
  await tester.pumpAndSettle();
  return strings(tester);
}

void main() {
  test('plans expire into Free', () {
    final now = DateTime(2026, 10, 6);
    expect(Membership.free.planOn(now), MembershipPlan.free);
    final premium = Membership(
      MembershipPlan.premium,
      expiresAt: DateTime(2026, 11, 6),
    );
    expect(premium.planOn(now), MembershipPlan.premium);
    expect(premium.planOn(DateTime(2026, 12, 1)), MembershipPlan.free);
    expect(Membership.fromMap({'plan': 'gold'}).plan, MembershipPlan.free);
  });

  testWidgets('My profile shows the plan and opens the plans', (tester) async {
    final s = await pump(tester);
    await p.openProfileTab(tester);
    expect(find.text(s.membershipTitle), findsOneWidget);
    expect(find.text(s.membershipFreeBody), findsOneWidget);
    await p.tap(tester, s.viewPlans);
    expect(find.byType(PlansScreen), findsOneWidget);
    // Premium is shown first, with its price.
    expect(find.text(s.planHeadlinePremium), findsOneWidget);
    expect(find.text('£4.99'), findsOneWidget);
    await p.tap(tester, s.planVip);
    expect(find.text('£14.99'), findsOneWidget);
    expect(find.text(s.featurePriority), findsOneWidget);
    await p.tap(tester, s.planContinue(s.planVip));
    expect(find.text(s.planComingSoonTitle), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await p.tap(tester, s.compareAllPlans);
    expect(find.byType(Table), findsOneWidget);
  });

  testWidgets('a granted plan appears live and is marked current', (
    tester,
  ) async {
    final memberships = TestMemberships();
    final s = await pump(tester, memberships: memberships);
    await p.openProfileTab(tester);
    memberships.set(
      Membership(MembershipPlan.premium, expiresAt: DateTime(2030, 1, 1)),
    );
    await tester.pumpAndSettle();
    expect(find.text(s.planPremium), findsOneWidget);
    await p.tap(tester, s.viewPlans);
    expect(find.text(s.planCurrent), findsOneWidget);
  });

  testWidgets('two free members who like each other are told Premium is '
      'needed', (tester) async {
    final interests = TestInterests(received: [hodan], pool: [hodan])
      ..canMatch = false;
    final s = await pump(tester, interests: interests, discover: ['hodan']);
    await tester.tap(find.byTooltip(s.likeAction));
    await tester.pumpAndSettle();
    expect(find.text(s.mutualTitle), findsOneWidget);
    expect(find.text(s.mutualBody), findsOneWidget);
    await p.tap(tester, s.keepBrowsing);
    // The Likes tab says they both like each other and offers the plans
    // instead of "Like back".
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(s.navLikes),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(s.likesSentTab));
    await tester.pumpAndSettle();
    expect(find.text(s.likeStatusMutual), findsOneWidget);
    await p.tap(tester, s.cardNameAge('Hodan', 25));
    expect(find.text(s.likeBack), findsNothing);
    await p.tap(tester, s.viewPlans);
    expect(find.text(s.mutualTitle), findsOneWidget);
  });

  testWidgets('upgrading completes the waiting match', (tester) async {
    final interests = TestInterests(
      received: [hodan],
      sent: [hodan],
      pool: [hodan],
    )..canMatch = false;
    final memberships = TestMemberships();
    await pump(tester, interests: interests, memberships: memberships);
    expect(interests.calls, isNot(contains('complete hodan')));
    interests.canMatch = true;
    memberships.set(
      Membership(MembershipPlan.premium, expiresAt: DateTime(2030, 1, 1)),
    );
    await tester.pumpAndSettle();
    expect(interests.calls, contains('complete hodan'));
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets('$locale ${brightness.name}: plans fit a small screen', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final s = await pump(
          tester,
          locale: locale,
          brightness: brightness,
          size: const Size(320, 640),
        );
        await p.openProfileTab(tester);
        await tester.scrollUntilVisible(
          find.text(s.viewPlans),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await p.tap(tester, s.viewPlans);
        expect(tester.takeException(), isNull);
        await p.tap(tester, s.planVip);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text(s.compareAllPlans),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await p.tap(tester, s.compareAllPlans);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
