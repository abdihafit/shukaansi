import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/moderation.dart';
import 'package:shukaansi/screens/suspended_screen.dart';
import 'package:shukaansi/services/moderation_service.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'account_test.dart' as a;
import 'discovery_fakes.dart';
import 'media_fakes.dart';
import 'profile_test.dart' as p;

class TestModeration implements ModerationService {
  AccountStatus accountStatus = AccountStatus.active;
  Set<String> hiddenIds = {};
  List<BlockedMember> blockedList = [];
  bool failReport = false;
  bool failBlock = false;
  final reports = <(String, ReportReason, String)>[];
  final blocks = <String>[];
  final unblocks = <String>[];

  @override
  Future<AccountStatus> status(String uid) async => accountStatus;
  @override
  Future<void> report(
    String reporterUid,
    String reportedUid,
    ReportReason reason,
    String note,
  ) async {
    if (failReport) throw const ModerationException();
    reports.add((reportedUid, reason, note));
  }

  @override
  Future<void> block(String blocker, String blocked, String name) async {
    if (failBlock) throw const ModerationException();
    blocks.add(blocked);
  }

  @override
  Future<void> unblock(String blocker, String blocked) async {
    unblocks.add(blocked);
    blockedList = blockedList.where((b) => b.uid != blocked).toList();
  }

  @override
  Future<List<BlockedMember>> blocked(String uid) async => blockedList;
  @override
  Future<Set<String>> hiddenMembers(String uid) async => hiddenIds;
}

Future<AppLocalizations> pump(
  WidgetTester tester,
  TestModeration moderation,
  TestDiscovery discovery,
) async {
  await tester.binding.setSurfaceSize(const Size(400, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    p.harness(
      p.TestProfiles()..stored = ProfileComplete(p.sample, p.details),
      'en',
      Brightness.light,
      account: a.TestAccount()..verified = true,
      photos: TestPhotos()..ids = [photoId(1)],
      discovery: discovery,
      moderation: moderation,
      picker: TestPicker(),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold).first));
}

void main() {
  testWidgets('suspended members see only the locked screen', (tester) async {
    final moderation = TestModeration()
      ..accountStatus = const AccountStatus(
        suspended: true,
        reason: 'Repeated harassment',
      );
    final discovery = TestDiscovery()..cards = [testCard('a', name: 'Amina')];
    final s = await pump(tester, moderation, discovery);
    expect(find.byType(SuspendedScreen), findsOneWidget);
    expect(find.text(s.suspendedTitle), findsOneWidget);
    expect(find.text(s.suspendedReason('Repeated harassment')), findsOneWidget);
    expect(
      find.text(s.suspendedContact('admin@shukaansi.com'), findRichText: true),
      findsOneWidget,
    );
    expect(find.text(s.navDiscover), findsNothing);
    expect(discovery.syncs, 0);
    expect(find.text(s.signOut), findsOneWidget);
  });

  testWidgets('blocked members in either direction never appear', (
    tester,
  ) async {
    final moderation = TestModeration()..hiddenIds = {'b'};
    final discovery = TestDiscovery()
      ..cards = [testCard('a', name: 'Amina'), testCard('b', name: 'Bilan')];
    final s = await pump(tester, moderation, discovery);
    expect(find.text(s.cardNameAge('Amina', 25)), findsOneWidget);
    expect(find.text(s.cardNameAge('Bilan', 25)), findsNothing);
  });

  testWidgets('report needs a reason, survives failure, and can also block', (
    tester,
  ) async {
    final moderation = TestModeration();
    final discovery = TestDiscovery()..cards = [testCard('a', name: 'Amina')];
    final s = await pump(tester, moderation, discovery);
    await tester.tap(find.byTooltip(s.cardMoreActions('Amina')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.reportAction));
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(ElevatedButton, s.reportSubmit);
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
    await p.tap(tester, s.reportReasonScam);
    await tester.enterText(find.byType(TextField), 'Asked for money');
    moderation.failReport = true;
    await p.tapFinder(tester, submit);
    expect(find.text(s.reportFailed), findsOneWidget);
    moderation.failReport = false;
    await p.tap(tester, s.reportAlsoBlock('Amina'));
    await p.tapFinder(tester, submit);
    expect(moderation.reports.single, (
      'a',
      ReportReason.scam,
      'Asked for money',
    ));
    expect(moderation.blocks, ['a']);
    expect(find.text(s.reportSent), findsOneWidget);
    expect(find.text(s.cardNameAge('Amina', 25)), findsNothing);
  });

  testWidgets('block asks first and removes the card', (tester) async {
    final moderation = TestModeration();
    final discovery = TestDiscovery()
      ..cards = [testCard('a', name: 'Amina'), testCard('b', name: 'Bilan')];
    final s = await pump(tester, moderation, discovery);
    Future<void> openBlock() async {
      await tester.tap(find.byTooltip(s.cardMoreActions('Amina')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(s.blockAction));
      await tester.pumpAndSettle();
    }

    await openBlock();
    expect(find.text(s.blockTitle('Amina')), findsOneWidget);
    await p.tap(tester, s.profileCancelEdit);
    expect(moderation.blocks, isEmpty);
    moderation.failBlock = true;
    await openBlock();
    await tester.tap(find.widgetWithText(TextButton, s.blockAction));
    await tester.pumpAndSettle();
    expect(find.text(s.blockFailed), findsOneWidget);
    expect(find.text(s.cardNameAge('Amina', 25)), findsOneWidget);
    moderation.failBlock = false;
    await openBlock();
    await tester.tap(find.widgetWithText(TextButton, s.blockAction));
    await tester.pumpAndSettle();
    expect(moderation.blocks, ['a']);
    expect(find.text(s.cardNameAge('Amina', 25)), findsNothing);
    expect(find.text(s.cardNameAge('Bilan', 25)), findsOneWidget);
  });

  testWidgets('blocked members can be unblocked from My profile', (
    tester,
  ) async {
    final moderation = TestModeration()
      ..blockedList = [const BlockedMember(uid: 'x', name: 'Ahmed')];
    final s = await pump(tester, moderation, TestDiscovery());
    await p.openProfileTab(tester);
    expect(find.text(s.blockedTitle), findsOneWidget);
    expect(find.text('Ahmed'), findsOneWidget);
    await p.tap(tester, s.unblockAction);
    expect(moderation.unblocks, ['x']);
    expect(find.text(s.blockedTitle), findsNothing);
  });
}
