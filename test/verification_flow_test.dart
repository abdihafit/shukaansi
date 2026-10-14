import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/screens/verification_screen.dart';

import 'media_fakes.dart';
import 'media_test.dart' as m;
import 'profile_test.dart' as p;

void main() {
  testWidgets('the stepper follows the selfie flow', (tester) async {
    final s = await m.pumpMedia(
      tester,
      TestPhotos()..ids = [photoId(1)],
      TestPicker()..selfie = png,
    );
    await p.tap(tester, s.verifyStart);
    expect(find.text(s.verifyHeadline), findsOneWidget);
    expect(find.text(s.verifyPrivateTitle), findsOneWidget);
    expect(find.text(s.verifyCareTitle), findsOneWidget);
    for (final label in [
      '${s.verifyStepPhoto}, ${s.stepStateDone}',
      '${s.verifyStepSelfie}, ${s.stepStateCurrent}',
      '${s.verifyStepReview}, ${s.stepStateUpcoming}',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    await p.tap(tester, s.verifyTakeSelfie);
    expect(find.text(s.verifyCheckHeadline), findsOneWidget);
    expect(
      find.bySemanticsLabel('${s.verifyStepSelfie}, ${s.stepStateDone}'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('${s.verifyStepReview}, ${s.stepStateCurrent}'),
      findsOneWidget,
    );
  });

  testWidgets('after sending, the review timeline shows what comes next', (
    tester,
  ) async {
    final photos = TestPhotos()..ids = [photoId(1)];
    final s = await m.pumpMedia(tester, photos, TestPicker()..selfie = png);
    await p.tap(tester, s.verifyStart);
    await p.tap(tester, s.verifyTakeSelfie);
    await p.tap(tester, s.verifySubmit);
    expect(find.text(s.verifySubmittedChip), findsOneWidget);
    expect(find.text(s.verifySubmittedBody), findsOneWidget);
    for (final label in [
      '${s.reviewStepProfile}, ${s.stepStateDone}',
      '${s.reviewStepReview}, ${s.stepStateCurrent}',
      '${s.reviewStepBadge}, ${s.stepStateUpcoming}',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    // The system back button also returns with the submission recorded.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(VerificationScreen), findsNothing);
    expect(find.text(s.verifyPendingTitle), findsOneWidget);
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale ${brightness.name}: verification fits a small screen',
        (tester) async {
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final s = await m.pumpMedia(
            tester,
            TestPhotos()..ids = [photoId(1)],
            TestPicker()..selfie = png,
            locale: locale,
            brightness: brightness,
          );
          await tester.binding.setSurfaceSize(const Size(320, 640));
          await tester.pumpAndSettle();
          await p.tap(tester, s.verifyStart);
          expect(tester.takeException(), isNull);
          await p.tap(tester, s.verifyTakeSelfie);
          expect(tester.takeException(), isNull);
          await p.tap(tester, s.verifySubmit);
          expect(find.text(s.verifySubmittedTitle), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test('Islamic expressions mark good news, never errors', () {
    const phrases = [
      'MashaAllah', 'InshaAllah', 'Alhamdulillah', 'JazakAllahu', //
      'Mashaa Allah', 'haddii Alle idmo', 'Alxamdulillaah', 'Jazaakallaahu',
    ];
    for (final file in ['lib/l10n/app_en.arb', 'lib/l10n/app_so.arb']) {
      final strings = (jsonDecode(File(file).readAsStringSync()) as Map)
          .cast<String, Object?>();
      bool blessed(String key) => phrases.any(
        (phrase) =>
            '${strings[key]}'.toLowerCase().contains(phrase.toLowerCase()),
      );
      for (final key in [
        'profileCreated',
        'profileUpdated',
        'verifyVerified',
        'verifyPendingBody',
        'verifySubmittedBody',
        'reportSent',
      ]) {
        expect(blessed(key), isTrue, reason: '$file $key');
      }
      for (final key in strings.keys.where(
        (k) =>
            !k.startsWith('@') && RegExp(r'(Failed|Error|Invalid)').hasMatch(k),
      )) {
        expect(blessed(key), isFalse, reason: '$file $key');
      }
    }
  });
}
