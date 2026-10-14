import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/wali.dart';
import 'package:shukaansi/preview/fixture_services.dart';
import 'package:shukaansi/preview/fixtures.dart';
import 'package:shukaansi/preview/preview_app.dart';
import 'package:shukaansi/preview/preview_config.dart';
import 'package:shukaansi/redesign/member_page.dart';
import 'package:shukaansi/redesign/photos.dart';
import 'package:shukaansi/widgets/brand/brand.dart';
import 'package:shukaansi/screens/chat_screen.dart';
import 'package:shukaansi/services/chat_service.dart';

/// Lets the fixtures' simulated network delays elapse, then settles.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.pumpAndSettle();
}

AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(NavigationBar)));

Future<PreviewWorld> pumpPreview(
  WidgetTester tester, {
  PreviewScenario scenario = PreviewScenario.populated,
  Size size = const Size(412, 915),
  bool waitForData = true,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final world = PreviewWorld()..scenario = scenario;
  // No Firebase.initializeApp here: any backend access would throw.
  await tester.pumpWidget(PreviewApp(world: world));
  if (waitForData) {
    await settle(tester);
  } else {
    await tester.pump(const Duration(seconds: 1));
  }
  return world;
}

Future<void> tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await settle(tester);
}

void main() {
  group('safety', () {
    test('preview is only allowed when requested and never in release', () {
      expect(previewAllowed(release: false, requested: true), isTrue);
      expect(previewAllowed(release: true, requested: true), isFalse);
      expect(previewAllowed(release: false, requested: false), isFalse);
      expect(previewAllowed(release: true, requested: false), isFalse);
      // Off by default in this build: no --dart-define was given.
      expect(previewRequested, isFalse);
    });

    test('preview code cannot reach the real backend', () {
      final banned = RegExp(
        r'firebase|cloud_firestore|share_plus|shared_preferences|'
        r'FirebaseFirestore|FirebaseAuth|SharedPreferences',
      );
      for (final file in Directory('lib/preview').listSync()) {
        final source = File(file.path).readAsStringSync();
        expect(banned.hasMatch(source), isFalse, reason: file.path);
      }
    });

    test('the preview chat service enforces the Wali rule', () async {
      final world = PreviewWorld();
      final walis = PreviewWalis(world);
      final interests = PreviewInterests(
        world,
        PreviewMemberships(world),
        walis,
      );
      final chats = PreviewChats(world, interests, walis);
      expect(walis.theirs['hodan'], WaliDecision.pending);
      await expectLater(
        chats.send(previewViewerUid, 'hodan', 'Salaam'),
        throwsA(isA<ChatException>()),
      );
      await chats.send(previewViewerUid, 'amina', 'Salaam');
      expect(chats.threads['amina']!.last.text, 'Salaam');
    });
  });

  testWidgets('four tabs reach Discover, Likes, Chats and Profile', (
    tester,
  ) async {
    await pumpPreview(tester);
    final s = strings(tester);
    expect(find.text(s.previewBadge), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text(s.navMatches), findsNothing);
    expect(find.text('Fardowsa, 28'), findsOneWidget);
    await tab(tester, s.navLikes);
    expect(find.text('Sagal, 29'), findsOneWidget);
    expect(find.text('Ladan, 26'), findsOneWidget);
    await tab(tester, s.navChats);
    expect(find.text(s.chatsNewMatches), findsOneWidget);
    expect(find.text(s.chatsActive), findsOneWidget);
    expect(find.text('Hodan'), findsOneWidget);
    await tab(tester, s.navProfile);
    expect(find.text('Yusuf, 31'), findsOneWidget);
    expect(find.text(s.profileProgressTitle), findsOneWidget);
  });

  testWidgets('pass moves on with undo; liking back a Premium member matches', (
    tester,
  ) async {
    await pumpPreview(tester);
    final s = strings(tester);
    await tester.tap(find.byTooltip(s.passAction));
    await settle(tester);
    expect(find.text('Sagal, 29'), findsOneWidget);
    expect(find.text(s.passedName('Fardowsa')), findsOneWidget);
    await tester.tap(find.byTooltip(s.likeAction));
    await settle(tester);
    // Sagal liked Yusuf and has Premium, so the match is made.
    expect(find.text(s.matchTitle), findsOneWidget);
  });

  testWidgets('two free members who like each other need Premium', (
    tester,
  ) async {
    await pumpPreview(tester);
    final s = strings(tester);
    await tab(tester, s.navLikes);
    await tester.tap(find.text('Ladan, 26'));
    await settle(tester);
    expect(find.byType(MemberPage), findsOneWidget);
    await tester.tap(find.text(s.likeBack));
    await settle(tester);
    expect(find.text(s.mutualTitle), findsOneWidget);
  });

  testWidgets('a match waiting for her Wali explains why messaging is closed', (
    tester,
  ) async {
    await pumpPreview(tester);
    final s = strings(tester);
    await tab(tester, s.navChats);
    await tester.tap(find.text('Hodan'));
    await settle(tester);
    expect(find.text(s.approvalWaitingTheirs), findsOneWidget);
    expect(find.text(s.messageAction), findsNothing);
  });

  testWidgets('messages send and a simulated reply arrives', (tester) async {
    await pumpPreview(tester);
    final s = strings(tester);
    await tab(tester, s.navChats);
    await tester.tap(find.bySemanticsLabel(RegExp('^Amina')));
    await settle(tester);
    expect(find.byType(ChatScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Insha\'Allah, that works');
    await tester.tap(find.byTooltip(s.messageSend));
    await settle(tester);
    expect(find.text('Insha\'Allah, that works'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(find.text(previewReplies[1]), findsOneWidget);
  });

  testWidgets('photos open full size; private photos do not', (tester) async {
    await pumpPreview(tester);
    final s = strings(tester);
    await tester.tap(find.bySemanticsLabel(s.openPhoto(1, 3)).first);
    await settle(tester);
    expect(find.byType(FullPhotoViewer), findsOneWidget);
    expect(find.text(s.photoOf(1, 3)), findsOneWidget);
    await tester.tap(find.byTooltip(s.closePhoto));
    await settle(tester);
    expect(find.byType(FullPhotoViewer), findsNothing);
    // Pass Fardowsa and Sagal to reach Hibo, whose photos are private.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip(s.passAction));
      await settle(tester);
    }
    expect(find.text('Hibo, 33'), findsOneWidget);
    expect(find.text(s.photosPrivateTitle), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(s.openPhoto(1, 3)).first);
    await settle(tester);
    expect(find.byType(FullPhotoViewer), findsNothing);
  });

  group('states', () {
    for (final (scenario, expected) in [
      (PreviewScenario.networkError, 'networkErrorTitle'),
      (PreviewScenario.incompleteProfile, 'discoverNotListedTitle'),
      (PreviewScenario.noMatches, 'noMatchesTitle'),
      (PreviewScenario.preferencesNotSet, 'forYouSetupTitle'),
    ]) {
      testWidgets('${scenario.name} explains itself', (tester) async {
        await pumpPreview(tester, scenario: scenario);
        final s = strings(tester);
        final text = switch (expected) {
          'networkErrorTitle' => s.networkErrorTitle,
          'discoverNotListedTitle' => s.discoverNotListedTitle,
          'noMatchesTitle' => s.noMatchesTitle,
          _ => s.forYouSetupTitle,
        };
        expect(find.text(text), findsOneWidget);
      });
    }

    testWidgets('loading shows a calm skeleton', (tester) async {
      await pumpPreview(
        tester,
        scenario: PreviewScenario.loading,
        waitForData: false,
      );
      expect(find.byType(ProfileSkeleton), findsOneWidget);
    });

    testWidgets('no likes or conversations each have a next step', (
      tester,
    ) async {
      await pumpPreview(tester, scenario: PreviewScenario.emptyActivity);
      final s = strings(tester);
      await tab(tester, s.navLikes);
      expect(find.text(s.likesReceivedEmpty), findsOneWidget);
      await tab(tester, s.navChats);
      expect(find.text(s.chatsEmptyTitle), findsOneWidget);
    });

    testWidgets('verification in review is shown on the profile', (
      tester,
    ) async {
      await pumpPreview(tester, scenario: PreviewScenario.awaitingReview);
      final s = strings(tester);
      await tab(tester, s.navProfile);
      expect(find.text(s.verifyStatusPending), findsOneWidget);
    });
  });

  for (final locale in ['en', 'so']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$locale ${dark ? 'dark' : 'light'}: small phone, large text',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 1.4;
          tester.platformDispatcher.platformBrightnessTestValue = dark
              ? Brightness.dark
              : Brightness.light;
          addTearDown(() {
            tester.platformDispatcher.clearTextScaleFactorTestValue();
            tester.platformDispatcher.clearPlatformBrightnessTestValue();
          });
          await pumpPreview(tester, size: const Size(360, 690));
          if (locale == 'so') {
            await tab(tester, strings(tester).navProfile);
            await tester.scrollUntilVisible(
              find.text(strings(tester).settingsLanguage),
              300,
              scrollable: find.byType(Scrollable).last,
            );
            await tester.tap(find.text(strings(tester).settingsLanguage));
            await settle(tester);
            await tester.tap(find.text(strings(tester).somaliLanguage));
            await settle(tester);
          }
          final s = strings(tester);
          for (final label in [
            s.navDiscover,
            s.navLikes,
            s.navChats,
            s.navProfile,
          ]) {
            await tab(tester, label);
            expect(tester.takeException(), isNull, reason: label);
          }
        },
      );
    }
  }
}
