import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/matrimonial_profile.dart';
import 'package:shukaansi/models/profile_media.dart';
import 'package:shukaansi/services/profile_service.dart';
import 'package:shukaansi/screens/photo_viewer.dart';
import 'package:shukaansi/screens/verification_screen.dart';

import 'account_test.dart' as a;
import 'media_fakes.dart';
import 'profile_test.dart' as p;

Future<AppLocalizations> pumpMedia(
  WidgetTester tester,
  TestPhotos photos,
  TestPicker picker, {
  String locale = 'en',
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    p.harness(
      a.completeProfile(),
      locale,
      brightness,
      account: a.TestAccount()..verified = true,
      photos: photos,
      picker: picker,
    ),
  );
  await tester.pumpAndSettle();
  await p.openProfileTab(tester);
  final s = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
  // Photos, privacy and verification share the Manage photos page.
  await p.tap(tester, s.managePhotos);
  return s;
}

Finder photoTile(AppLocalizations s, int number, {bool main = false}) =>
    find.bySemanticsLabel(
      main ? '${s.photosSlot(number)}, ${s.photosMain}' : s.photosSlot(number),
    );

void main() {
  test('only real JPEG, PNG and WebP files under 5 MB are accepted', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0]);
    final webp = Uint8List.fromList([
      ...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits, //
    ]);
    final gif = Uint8List.fromList('GIF89a'.codeUnits);
    expect(imageContentType(jpeg), 'image/jpeg');
    expect(imageContentType(png), 'image/png');
    expect(imageContentType(webp), 'image/webp');
    expect(imageContentType(gif), isNull);
    expect(isAcceptedPhoto(png), isTrue);
    expect(isAcceptedPhoto(Uint8List(0)), isFalse);
    final huge = Uint8List(maxPhotoBytes)..setAll(0, jpeg);
    expect(isAcceptedPhoto(huge), isFalse);
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale ${brightness.name}: add photos, main badge and verification gate',
        (tester) async {
          final photos = TestPhotos();
          final picker = TestPicker()..photo = png;
          final s = await pumpMedia(
            tester,
            photos,
            picker,
            locale: locale,
            brightness: brightness,
          );
          expect(find.text(s.photosTitle), findsOneWidget);
          expect(find.text(s.verifyNeedsPhoto), findsOneWidget);
          final start = find.widgetWithText(OutlinedButton, s.verifyStart);
          expect(tester.widget<OutlinedButton>(start).onPressed, isNull);

          await p.tapFinder(tester, find.bySemanticsLabel(s.photosAdd));
          expect(photos.uploads, 1);
          expect(photoTile(s, 1, main: true), findsOneWidget);
          expect(find.text(s.verifyNeedsPhoto), findsNothing);
          expect(tester.widget<OutlinedButton>(start).onPressed, isNotNull);

          await p.tapFinder(tester, find.bySemanticsLabel(s.photosAdd));
          expect(photoTile(s, 2), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('cancelled, unsupported, unopenable and failed uploads', (
    tester,
  ) async {
    final photos = TestPhotos();
    final picker = TestPicker();
    final s = await pumpMedia(tester, photos, picker);
    final add = find.bySemanticsLabel(s.photosAdd);

    await p.tapFinder(tester, add);
    expect(photos.uploads, 0, reason: 'cancelled picker does nothing');

    picker.photo = Uint8List.fromList('GIF89a'.codeUnits);
    await p.tapFinder(tester, add);
    expect(find.text(s.photosUnsupported), findsOneWidget);
    expect(photos.uploads, 0);

    picker.fail = true;
    await p.tapFinder(tester, add);
    expect(find.text(s.photosPickFailed), findsOneWidget);

    picker
      ..fail = false
      ..photo = png;
    photos.failUpload = true;
    await p.tapFinder(tester, add);
    expect(find.text(s.photosUploadFailed), findsOneWidget);
    expect(photoTile(s, 1, main: true), findsNothing);
  });

  testWidgets('make main, remove, view, and failed updates keep the order', (
    tester,
  ) async {
    final photos = TestPhotos()..ids = [photoId(1), photoId(2)];
    final s = await pumpMedia(tester, photos, TestPicker());
    expect(photoTile(s, 1, main: true), findsOneWidget);

    await p.tapFinder(tester, photoTile(s, 2));
    await p.tap(tester, s.photosMakeMain);
    expect(photos.reordered, [photoId(2), photoId(1)]);

    await p.tapFinder(tester, photoTile(s, 1, main: true));
    expect(find.text(s.photosMakeMain), findsNothing);
    await p.tap(tester, s.photosView);
    expect(find.byType(PhotoViewer), findsOneWidget);
    await p.tapFinder(tester, find.byType(CloseButton));
    expect(find.byType(PhotoViewer), findsNothing);

    photos.failUpdate = true;
    await p.tapFinder(tester, photoTile(s, 2));
    await p.tap(tester, s.photosRemove);
    expect(find.text(s.photosUpdateFailed), findsOneWidget);
    expect(photoTile(s, 2), findsOneWidget);

    photos.failUpdate = false;
    await p.tapFinder(tester, photoTile(s, 2));
    await p.tap(tester, s.photosRemove);
    expect(photos.ids, [photoId(2)]);
    expect(photoTile(s, 2), findsNothing);
    expect(photoTile(s, 1, main: true), findsOneWidget);
  });

  testWidgets('six photos hide the add tile', (tester) async {
    final photos = TestPhotos()
      ..ids = [for (var i = 1; i <= 6; i++) photoId(i)];
    final s = await pumpMedia(tester, photos, TestPicker());
    expect(photoTile(s, 6), findsOneWidget);
    expect(find.bySemanticsLabel(s.photosAdd), findsNothing);
  });

  testWidgets('load failure offers retry', (tester) async {
    final photos = TestPhotos()..failLoad = true;
    final s = await pumpMedia(tester, photos, TestPicker());
    expect(find.text(s.photosLoadFailed), findsOneWidget);
    photos
      ..failLoad = false
      ..ids = [photoId(1)];
    await p.tapFinder(
      tester,
      find.descendant(
        of: find.ancestor(
          of: find.text(s.photosLoadFailed),
          matching: find.byType(Row),
        ),
        matching: find.text(s.retry),
      ),
    );
    expect(photoTile(s, 1, main: true), findsOneWidget);
  });

  testWidgets(
    'selfie verification: camera failure, retake, failed and successful submit',
    (tester) async {
      final photos = TestPhotos()..ids = [photoId(1)];
      final picker = TestPicker()..fail = true;
      final s = await pumpMedia(tester, photos, picker);
      await p.tap(tester, s.verifyStart);
      expect(find.byType(VerificationScreen), findsOneWidget);
      expect(find.text(s.verifyTipPrivate), findsOneWidget);

      await p.tap(tester, s.verifyTakeSelfie);
      expect(find.text(s.verifyCameraFailed), findsOneWidget);

      picker
        ..fail = false
        ..selfie = png;
      await p.tap(tester, s.verifyTakeSelfie);
      expect(find.bySemanticsLabel(s.verifySelfiePreview), findsOneWidget);
      await p.tap(tester, s.verifyRetake);
      expect(find.text(s.verifySubmit), findsOneWidget);

      photos.failSubmit = true;
      await p.tap(tester, s.verifySubmit);
      expect(find.text(s.verifySubmitFailed), findsOneWidget);
      expect(find.byType(VerificationScreen), findsOneWidget);

      photos.failSubmit = false;
      await p.tap(tester, s.verifySubmit);
      expect(photos.submissions, 2);
      // The review timeline explains what happens next.
      expect(find.text(s.verifySubmittedTitle), findsOneWidget);
      expect(find.text(s.reviewStepReview), findsOneWidget);
      await p.tap(tester, s.verifyContinue);
      expect(find.byType(VerificationScreen), findsNothing);
      expect(find.text(s.verifyPendingTitle), findsOneWidget);
      expect(find.text(s.verifyStart), findsNothing);
    },
  );

  testWidgets('verified and rejected states', (tester) async {
    final photos = TestPhotos()
      ..ids = [photoId(1)]
      ..verification = const Verification(VerificationStatus.verified);
    var s = await pumpMedia(tester, photos, TestPicker());
    expect(find.text(s.verifyVerified), findsOneWidget);
    expect(find.text(s.verifyStart), findsNothing);

    photos.verification = const Verification(
      VerificationStatus.rejected,
      reviewNote: 'Face not visible',
    );
    await tester.pumpWidget(const SizedBox());
    s = await pumpMedia(tester, photos, TestPicker()..selfie = png);
    expect(find.text(s.verifyRejectedTitle), findsOneWidget);
    expect(find.text(s.verifyReviewNote('Face not visible')), findsOneWidget);
    await p.tapFinder(tester, find.widgetWithText(OutlinedButton, s.retry));
    expect(find.byType(VerificationScreen), findsOneWidget);
  });

  testWidgets('changing the main photo warns, then resets verification', (
    tester,
  ) async {
    final photos = TestPhotos()
      ..ids = [photoId(1), photoId(2), photoId(3)]
      ..verification = const Verification(VerificationStatus.verified);
    final s = await pumpMedia(tester, photos, TestPicker());
    expect(find.text(s.verifyVerified), findsOneWidget);

    // Removing a photo that is not the main one keeps verification.
    await p.tapFinder(tester, photoTile(s, 3));
    await p.tap(tester, s.photosRemove);
    expect(find.text(s.photosResetTitle), findsNothing);
    expect(find.text(s.verifyVerified), findsOneWidget);

    await p.tapFinder(tester, photoTile(s, 2));
    await p.tap(tester, s.photosMakeMain);
    expect(find.text(s.photosResetBody), findsOneWidget);
    await p.tap(tester, s.profileCancelEdit);
    expect(photos.reordered, isNull);
    expect(find.text(s.verifyVerified), findsOneWidget);

    await p.tapFinder(tester, photoTile(s, 2));
    await p.tap(tester, s.photosMakeMain);
    await p.tap(tester, s.photosResetConfirm);
    expect(photos.reordered, [photoId(2), photoId(1)]);
    expect(find.text(s.verifyVerified), findsNothing);
    expect(find.text(s.verifyTitle), findsOneWidget);
  });

  testWidgets('removing the main photo of a pending request warns too', (
    tester,
  ) async {
    final photos = TestPhotos()
      ..ids = [photoId(1), photoId(2)]
      ..verification = const Verification(VerificationStatus.pending);
    final s = await pumpMedia(tester, photos, TestPicker());
    await p.tapFinder(tester, photoTile(s, 1, main: true));
    await p.tap(tester, s.photosRemove);
    await p.tap(tester, s.photosResetConfirm);
    expect(photos.ids, [photoId(2)]);
    expect(find.text(s.verifyPendingTitle), findsNothing);
    expect(find.text(s.verifyTitle), findsOneWidget);
  });

  testWidgets('no warning without an active verification', (tester) async {
    final photos = TestPhotos()..ids = [photoId(1), photoId(2)];
    final s = await pumpMedia(tester, photos, TestPicker());
    await p.tapFinder(tester, photoTile(s, 2));
    await p.tap(tester, s.photosMakeMain);
    expect(find.text(s.photosResetTitle), findsNothing);
    expect(photos.reordered, [photoId(2), photoId(1)]);
  });

  for (final (gender, shown) in [
    (ProfileGender.female, true),
    (ProfileGender.male, false),
  ]) {
    testWidgets('niqab tip ${shown ? 'shown' : 'hidden'} for ${gender.name}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
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
          photos: TestPhotos()..ids = [photoId(1)],
          picker: TestPicker(),
        ),
      );
      await tester.pumpAndSettle();
      await p.openProfileTab(tester);
      final s = AppLocalizations.of(
        tester.element(find.byType(Scaffold).first),
      );
      await p.tap(tester, s.managePhotos);
      await p.tap(tester, s.verifyStart);
      expect(
        find.text(s.verifyTipNiqab),
        shown ? findsOneWidget : findsNothing,
      );
    });
  }
}
