import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/models/matrimonial_profile.dart';
import 'package:shukaansi/screens/delete_account_screen.dart';
import 'package:shukaansi/screens/profile_onboarding.dart';
import 'package:shukaansi/services/account_service.dart';
import 'package:shukaansi/services/auth_service.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'media_fakes.dart';
import 'profile_test.dart' as p;

class TestAccount implements AccountService {
  bool verified = false;
  bool verifyOnReload = false;
  bool failNetwork = false;
  bool wrongPassword = false;
  bool failDelete = false;
  int sent = 0;
  int reauthentications = 0;
  int deletions = 0;

  void _check() {
    if (failNetwork) throw const AuthServiceException(AuthFailure.network);
  }

  @override
  String? get email => 'owner@example.com';
  @override
  bool get emailVerified => verified;
  @override
  Future<bool> reloadEmailVerified() async {
    _check();
    if (verifyOnReload) verified = true;
    return verified;
  }

  @override
  Future<void> sendEmailVerification() async {
    _check();
    sent++;
  }

  @override
  Future<void> reauthenticate(String password) async {
    reauthentications++;
    _check();
    if (wrongPassword) throw const AuthServiceException(AuthFailure.rejected);
  }

  @override
  Future<void> deleteAccount() async {
    deletions++;
    if (failDelete) throw const AuthServiceException(AuthFailure.unknown);
  }
}

Future<AppLocalizations> pumpHome(
  WidgetTester tester,
  p.TestProfiles profiles,
  TestAccount account, {
  String locale = 'en',
  TestPhotos? photos,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    p.harness(
      profiles,
      locale,
      Brightness.light,
      account: account,
      photos: photos ?? TestPhotos(),
    ),
  );
  await tester.pumpAndSettle();
  await p.openProfileTab(tester);
  return AppLocalizations.of(tester.element(find.byType(Scaffold).first));
}

p.TestProfiles completeProfile() =>
    p.TestProfiles()..stored = ProfileComplete(p.sample, p.details);

void main() {
  for (final locale in ['en', 'so']) {
    testWidgets(
      '$locale edit keeps locked fields, pre-fills every step and saves',
      (tester) async {
        final profiles = completeProfile();
        final s = await pumpHome(
          tester,
          profiles,
          TestAccount()..verified = true,
          locale: locale,
        );
        await p.tap(tester, s.profileEdit);
        expect(find.text(s.profileLockedNotice), findsOneWidget);
        expect(find.byKey(const ValueKey(ProfileGender.female)), findsNothing);
        await tester.enterText(find.byType(TextFormField).first, 'Hodan Ali');
        // Every later step is already complete, so Continue walks straight through.
        for (var step = 0; step < 8; step++) {
          await p.tap(tester, s.profileContinue);
        }
        expect(find.byType(CheckboxListTile), findsNothing);
        await p.tap(tester, s.profileSaveChanges);
        expect(profiles.updates, 1);
        expect(profiles.saves, 0);
        final saved = profiles.savedProfile!;
        expect(saved.name, 'Hodan Ali');
        expect(saved.gender, p.sample.gender);
        expect(saved.nationality, p.sample.nationality);
        expect(saved.profession, p.sample.profession);
        expect(profiles.savedDetails!.birthDate, p.details.birthDate);
        expect(profiles.savedDetails!.phoneNumber, p.details.phoneNumber);
        expect(find.text(s.profileUpdated), findsOneWidget);
        expect(find.byType(ProfileOnboarding), findsNothing);
        expect(find.text('Hodan Ali, 25'), findsOneWidget);
      },
    );
  }

  testWidgets('cancelling an edit and failed edits keep the saved profile', (
    tester,
  ) async {
    final profiles = completeProfile();
    final s = await pumpHome(tester, profiles, TestAccount()..verified = true);
    await p.tap(tester, s.profileEdit);
    await tester.enterText(find.byType(TextFormField).first, 'Changed');
    await p.tap(tester, s.profileCancelEdit);
    expect(find.byType(ProfileOnboarding), findsNothing);
    expect(find.text('${p.sample.name}, 25'), findsOneWidget);
    expect(profiles.updates, 0);

    await p.tap(tester, s.profileEdit);
    for (var step = 0; step < 8; step++) {
      await p.tap(tester, s.profileContinue);
    }
    profiles.failSave = true;
    await p.tap(tester, s.profileSaveChanges);
    expect(find.text(s.profileSaveFailed), findsOneWidget);
    expect(find.byType(ProfileOnboarding), findsOneWidget);
  });

  testWidgets('email verification can be resent and rechecked', (tester) async {
    final account = TestAccount();
    final s = await pumpHome(tester, completeProfile(), account);
    expect(find.text(s.progressAccountTodo), findsOneWidget);
    await p.tap(tester, s.progressAccount);
    expect(find.text(s.emailVerifyTitle), findsOneWidget);
    expect(find.textContaining('owner@example.com'), findsOneWidget);
    await p.tap(tester, s.emailVerifyResend);
    expect(account.sent, 1);
    expect(find.text(s.emailVerifySent), findsOneWidget);
    await p.tap(tester, s.emailVerifyCheck);
    expect(find.text(s.emailVerifyNotYet), findsOneWidget);
    account.failNetwork = true;
    await p.tap(tester, s.emailVerifyCheck);
    expect(find.text(s.accountActionFailed), findsOneWidget);
    account
      ..failNetwork = false
      ..verifyOnReload = true;
    await p.tap(tester, s.emailVerifyCheck);
    expect(find.text(s.emailVerified), findsOneWidget);
    expect(find.text(s.emailVerifyTitle), findsNothing);
  });

  testWidgets('verified accounts show a verified badge only', (tester) async {
    final s = await pumpHome(
      tester,
      completeProfile(),
      TestAccount()..verified = true,
    );
    expect(find.text(s.emailVerified), findsOneWidget);
    expect(find.text(s.emailVerifyResend), findsNothing);
  });

  testWidgets(
    'delete requires password and confirmation, survives failures and retries safely',
    (tester) async {
      final profiles = completeProfile();
      final account = TestAccount()..verified = true;
      final s = await pumpHome(tester, profiles, account);
      await p.tap(tester, s.accountDelete);
      expect(find.byType(DeleteAccountScreen), findsOneWidget);
      final field = find.byType(TextFormField);

      await p.tap(tester, s.accountDeleteButton);
      expect(find.text(s.fieldRequired), findsOneWidget);
      expect(find.text(s.accountDeleteConfirmRequired), findsOneWidget);
      expect(account.reauthentications, 0);

      await tester.enterText(field, 'wrong-password');
      await p.tapFinder(tester, find.byType(CheckboxListTile));
      account.wrongPassword = true;
      await p.tap(tester, s.accountDeleteButton);
      expect(find.text(s.accountDeleteWrongPassword), findsOneWidget);
      expect(profiles.deletes, 0);
      expect(account.deletions, 0);
      expect(
        tester.widget<TextFormField>(field).controller!.text,
        isEmpty,
        reason: 'password is cleared after each attempt',
      );

      account.wrongPassword = false;
      profiles.failDelete = true;
      await tester.enterText(field, 'secret1');
      await p.tap(tester, s.accountDeleteButton);
      expect(find.text(s.accountDeleteFailed), findsOneWidget);
      expect(account.deletions, 0);

      profiles.failDelete = false;
      account.failDelete = true;
      await tester.enterText(field, 'secret1');
      await p.tap(tester, s.accountDeleteButton);
      expect(find.text(s.accountDeletePartial), findsOneWidget);
      expect(profiles.deletes, 2);
      expect(account.deletions, 1);

      account.failDelete = false;
      await tester.enterText(field, 'secret1');
      await p.tap(tester, s.accountDeleteButton);
      expect(profiles.deletes, 2, reason: 'finished steps are not repeated');
      expect(account.deletions, 2);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving delete part-way reloads what is stored', (tester) async {
    final profiles = completeProfile();
    final account = TestAccount()
      ..verified = true
      ..failDelete = true;
    final s = await pumpHome(tester, profiles, account);
    await p.tap(tester, s.accountDelete);
    await tester.enterText(find.byType(TextFormField), 'secret1');
    await p.tapFinder(tester, find.byType(CheckboxListTile));
    await p.tap(tester, s.accountDeleteButton);
    expect(find.text(s.accountDeletePartial), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(profiles.stored, isA<ProfileMissing>());
    expect(find.byType(ProfileOnboarding), findsOneWidget);
  });

  testWidgets(
    'photos are deleted first, and a failure there removes nothing else',
    (tester) async {
      final profiles = completeProfile();
      final account = TestAccount()..verified = true;
      final photos = TestPhotos()
        ..ids = [photoId(1)]
        ..failDeleteAll = true;
      final s = await pumpHome(tester, profiles, account, photos: photos);
      await p.tap(tester, s.accountDelete);
      await tester.enterText(find.byType(TextFormField), 'secret1');
      await p.tapFinder(tester, find.byType(CheckboxListTile));
      await p.tap(tester, s.accountDeleteButton);
      expect(find.text(s.accountDeleteFailed), findsOneWidget);
      expect(photos.deleteAlls, 1);
      expect(profiles.deletes, 0);
      expect(account.deletions, 0);

      photos.failDeleteAll = false;
      await tester.enterText(find.byType(TextFormField), 'secret1');
      await p.tap(tester, s.accountDeleteButton);
      expect(photos.deleteAlls, 2);
      expect(profiles.deletes, 1);
      expect(account.deletions, 1);
    },
  );
}
