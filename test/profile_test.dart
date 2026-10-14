import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/data/countries.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/l10n/framework_localizations.dart';
import 'package:shukaansi/models/legal.dart';
import 'package:shukaansi/models/matrimonial_profile.dart';
import 'package:shukaansi/services/consent_service.dart';
import 'package:shukaansi/services/interest_service.dart';

import 'package:shukaansi/services/wali_service.dart';
import 'package:shukaansi/widgets/wali_card.dart';

import 'package:shukaansi/services/chat_service.dart';
import 'package:shukaansi/services/membership_service.dart';
import 'package:shukaansi/services/seen_store.dart';

import 'membership_fakes.dart';

import 'chat_fakes.dart';
import 'interest_fakes.dart';
import 'wali_fakes.dart';

import 'package:shukaansi/screens/profile_gate.dart';
import 'package:shukaansi/screens/profile_onboarding.dart';
import 'package:shukaansi/services/account_service.dart';
import 'package:shukaansi/services/discovery_service.dart';
import 'package:shukaansi/services/moderation_service.dart';
import 'package:shukaansi/services/photo_picker.dart';
import 'package:shukaansi/services/photo_service.dart';
import 'package:shukaansi/services/profile_service.dart';
import 'package:shukaansi/services/session_service.dart';
import 'package:shukaansi/theme/app_theme.dart';

final today = DateTime(2026, 9, 29);

const sample = MatrimonialProfile(
  name: 'Test Person',
  gender: ProfileGender.female,
  nationality: 'SO',
  residenceCountry: 'GB',
  city: 'London',
  ethnicity: Ethnicity.somali,
  profession: Profession.nurse,
  education: EducationLevel.bachelors,
  practice: PracticeLevel.active,
  marriageTimeline: MarriageTimeline.withinYear,
  relocation: Relocation.open,
  maritalStatus: MaritalStatus.neverMarried,
  about: 'Seeking a respectful and lasting marriage.',
);
final details = PrivateDetails(
  birthDate: DateTime.utc(2001, 1, 15),
  phoneCountry: 'GB',
  phoneNumber: '+447700900123',
);

class ProfileTestAuth extends Fake implements SessionService {
  @override
  Future<void> signOut() async {}
}

class TestProfiles implements ProfileService {
  ProfileState stored = const ProfileMissing();
  bool failLoad = false;
  bool failSave = false;
  int saves = 0;
  MatrimonialProfile? savedProfile;
  PrivateDetails? savedDetails;
  Completer<ProfileComplete>? pending;
  int updates = 0;
  int deletes = 0;
  bool failDelete = false;
  @override
  Future<ProfileState> load(String uid) async {
    if (failLoad) throw const ProfileException();
    return stored;
  }

  @override
  Future<ProfileComplete> save(
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details, {
    required bool adultConfirmed,
  }) async {
    saves++;
    if (!adultConfirmed || failSave) throw const ProfileException();
    savedProfile = profile;
    savedDetails = details;
    return pending?.future ?? ProfileComplete(profile, details);
  }

  @override
  Future<ProfileComplete> update(
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details,
  ) async {
    updates++;
    if (failSave) throw const ProfileException();
    savedProfile = profile;
    savedDetails = details;
    return (stored = ProfileComplete(profile, details));
  }

  @override
  Future<void> delete(String uid) async {
    deletes++;
    if (failDelete) throw const ProfileException();
    stored = const ProfileMissing();
  }
}

Widget harness(
  TestProfiles service,
  String locale,
  Brightness brightness, {
  AccountService account = const UnavailableAccountService(),
  PhotoService photos = const UnavailablePhotoService(),
  DiscoveryService discovery = const UnavailableDiscoveryService(),
  ModerationService moderation = const UnavailableModerationService(),
  PhotoPicker? picker,
  ConsentService? consents,
  InterestService? interests,
  WaliService? walis,
  ShareText? share,
  ChatService? chats,
  SeenStore? seenStore,
  MembershipService? memberships,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    SomaliMaterialFallback(),
    SomaliCupertinoFallback(),
    ...AppLocalizations.localizationsDelegates,
  ],
  // The same themes as the app.
  theme: brightness == Brightness.dark
      ? AppTheme.refinedDark
      : AppTheme.refinedLight,
  home: ProfileGate(
    uid: 'owner',
    auth: ProfileTestAuth(),
    profiles: service,
    account: account,
    photos: photos,
    discovery: discovery,
    moderation: moderation,
    // Most tests start after the terms were accepted.
    consents: consents ?? TestConsents(currentLegalVersion),
    interests: interests ?? TestInterests(),
    walis: walis ?? TestWalis(),
    share: share ?? (_) async {},
    chats: chats ?? TestChats(),
    seenStore: seenStore ?? MemorySeenStore(),
    memberships: memberships ?? TestMemberships(),
    picker: picker,
    today: today,
  ),
);

class TestConsents implements ConsentService {
  TestConsents([this.version]);
  int? version;
  bool failAccept = false;
  bool failRead = false;
  bool deleted = false;
  @override
  Future<int?> acceptedVersion(String uid) async {
    if (failRead) throw const ConsentException();
    return version;
  }

  @override
  Future<void> accept(String uid, int version) async {
    if (failAccept) throw const ConsentException();
    this.version = version;
  }

  @override
  Future<void> delete(String uid) async {
    deleted = true;
    version = null;
  }
}

/// Complete profiles open on Discover; most tests work on the profile tab.
Future<void> openProfileTab(WidgetTester tester) async {
  final s = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
  await tester.tap(find.text(s.navProfile));
  await tester.pumpAndSettle();
}

Future<void> tapFinder(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String text) =>
    tapFinder(tester, find.text(text).last);

Future<void> choose<T>(WidgetTester tester, T value) =>
    tapFinder(tester, find.byKey(ValueKey<T>(value)));

Future<void> pick(
  WidgetTester tester,
  String fieldKey,
  String search,
  String label,
) async {
  await tapFinder(tester, find.byKey(ValueKey(fieldKey)));
  final sheet = find.byType(BottomSheet);
  await tester.enterText(
    find.descendant(of: sheet, matching: find.byType(TextField)),
    search,
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find
        .descendant(
          of: find.descendant(of: sheet, matching: find.byType(ListTile)),
          matching: find.text(label),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  test('profile validation and data boundary', () {
    expect(sample.isValid, isTrue);
    final map = sample.toMap();
    expect(MatrimonialProfile.fromMap(map).nationality, 'SO');
    for (final field in [
      'email',
      'admin',
      'verified',
      'adultConfirmed',
      'birthDate',
      'phoneNumber',
      'phoneCountry',
      'uid',
    ]) {
      expect(map.containsKey(field), isFalse);
    }
    for (final patch in [
      {'onboardingComplete': false},
      {'name': ' '},
      {'gender': 'invalid'},
      {'about': 'short'},
      {'schemaVersion': 1},
      {'nationality': 'Somalia'},
      {'residenceCountry': 'ZZ'},
      {'ethnicity': 'other'},
      {'ethnicityOther': 'Oromo'},
      {'profession': 'other'},
      {'profession': 'astronaut'},
      {'education': 'phd'},
      {'relocation': 'maybe'},
    ]) {
      expect(
        () => MatrimonialProfile.fromMap({...map, ...patch}),
        throwsA(anything),
        reason: '$patch',
      );
    }
    final other = MatrimonialProfile.fromMap({
      ...map,
      'ethnicity': 'other',
      'ethnicityOther': 'Oromo',
      'profession': 'other',
      'professionOther': 'Tailor',
    });
    expect(other.professionOther, 'Tailor');
  });

  test('phone numbers become E.164 and dates of birth are checked', () {
    expect(PrivateDetails.toE164('GB', '07700 900123'), '+447700900123');
    expect(PrivateDetails.toE164('SO', '612345678'), '+252612345678');
    expect(PrivateDetails.toE164('IT', '0612345678'), '+390612345678');
    expect(PrivateDetails.toE164('GB', '12'), isNull);
    expect(PrivateDetails.toE164('GB', '+447700'), isNull);
    expect(PrivateDetails.toE164('XX', '07700900123'), isNull);
    expect(details.isValid(today), isTrue);
    expect(details.nationalNumber, '7700900123');
    expect(PrivateDetails.isAdult(DateTime.utc(2008, 9, 29), today), isFalse);
    expect(PrivateDetails.isAdult(DateTime.utc(2008, 9, 28), today), isTrue);
    expect(PrivateDetails.isAdult(DateTime.utc(2010, 1, 1), today), isFalse);
    expect(PrivateDetails.isAdult(DateTime.utc(1920, 1, 1), today), isFalse);
  });

  test('country data is complete and consistent', () {
    expect(Countries.all.length, greaterThan(240));
    expect(
      Countries.all.map((c) => c.code).toSet().length,
      Countries.all.length,
    );
    final somalia = Countries.byCode('SO')!;
    expect(somalia.name('so'), 'Soomaaliya');
    expect(somalia.dialCode, 252);
    expect(somalia.flag, '\u{1F1F8}\u{1F1F4}');
    expect(Countries.suggestedCodes.every(Countries.isValid), isTrue);
  });

  test('legacy profiles carry over only valid answers', () {
    final previous = LegacyProfile.fromMap({
      'name': 'Test Person',
      'gender': 'female',
      'city': ' ',
      'maritalStatus': 'unknown',
      'about': 'Seeking a respectful and lasting marriage.',
    });
    expect(previous.name, 'Test Person');
    expect(previous.gender, ProfileGender.female);
    expect(previous.city, isNull);
    expect(previous.maritalStatus, isNull);
  });

  testWidgets('completed profile routes to summary with private details', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        TestProfiles()..stored = ProfileComplete(sample, details),
        'en',
        Brightness.light,
      ),
    );
    expect(find.byType(ProfileOnboarding), findsNothing);
    await tester.pumpAndSettle();
    await openProfileTab(tester);
    expect(find.text('Test Person, 25'), findsOneWidget);
    // Details live on their own screen, opened from My profile.
    expect(find.text('+447700900123'), findsNothing);
    await tap(tester, 'Your profile');
    expect(find.text('Private to you'), findsOneWidget);
    expect(find.text('+447700900123'), findsOneWidget);
    expect(find.text('Somalia'), findsOneWidget);
    expect(find.byType(ProfileOnboarding), findsNothing);
  });

  testWidgets('load failure is not a missing profile and can retry', (
    tester,
  ) async {
    final service = TestProfiles()..failLoad = true;
    await tester.pumpWidget(harness(service, 'en', Brightness.light));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileOnboarding), findsNothing);
    service.failLoad = false;
    await tap(tester, 'Try again');
    expect(find.byType(ProfileOnboarding), findsOneWidget);
  });

  testWidgets('v1 profile opens pre-filled update flow', (tester) async {
    final service = TestProfiles()
      ..stored = const ProfileNeedsUpdate(
        LegacyProfile(
          name: 'Test Person',
          gender: ProfileGender.female,
          city: 'Hargeisa',
          maritalStatus: MaritalStatus.neverMarried,
          about: 'Seeking a respectful and lasting marriage.',
        ),
      );
    await tester.pumpWidget(harness(service, 'en', Brightness.light));
    await tester.pumpAndSettle();
    final s = AppLocalizations.of(
      tester.element(find.byType(ProfileOnboarding)),
    );
    expect(find.text(s.profileUpdateNotice), findsOneWidget);
    expect(find.text('Test Person'), findsOneWidget);
    final gender = tester.getSemantics(
      find.byKey(const ValueKey(ProfileGender.female)),
    );
    expect(gender, isSemantics(isSelected: true));
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale ${brightness.name} onboarding: every step, pickers, other answers, back, failed save, duplicate guard and completion',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 800));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final service = TestProfiles();
          await tester.pumpWidget(harness(service, locale, brightness));
          await tester.pumpAndSettle();
          final s = AppLocalizations.of(
            tester.element(find.byType(ProfileOnboarding)),
          );
          String country(String code) => Countries.byCode(code)!.name(locale);

          // 1. Basics: required errors, then name, gender and date of birth.
          await tap(tester, s.profileContinue);
          expect(find.text(s.fieldRequired), findsNWidgets(2));
          await tester.enterText(
            find.byType(TextFormField).first,
            'Test Person',
          );
          await choose(tester, ProfileGender.female);
          await tapFinder(
            tester,
            find.byKey(const ValueKey('profile-birth-date')),
          );
          await tester.tap(find.text('2001'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('15'));
          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();
          await tap(tester, s.profileContinue);

          // 2. Roots: nationality picker and "other" ethnicity.
          expect(find.text(s.profileStepRootsTitle), findsOneWidget);
          await tap(tester, s.profileContinue);
          expect(find.text(s.fieldRequired), findsNWidgets(2));
          await pick(tester, 'profile-nationality', 'Somalia', country('SO'));
          await choose(tester, Ethnicity.other);
          await tap(tester, s.profileContinue);
          expect(find.text(s.profileTextLength(2, 40)), findsOneWidget);
          await tester.enterText(find.byType(TextFormField), 'Oromo');
          await tap(tester, s.profileBack);
          expect(find.text('Test Person'), findsOneWidget);
          await tap(tester, s.profileContinue);
          expect(find.text('Oromo'), findsOneWidget);
          await tap(tester, s.profileContinue);

          // 3. Home.
          await pick(
            tester,
            'profile-residence',
            'United Kingdom',
            country('GB'),
          );
          await tester.enterText(find.byType(TextFormField), 'London');
          await tap(tester, s.profileContinue);

          // 4. Phone: country code defaults to residence; bad numbers rejected.
          expect(find.text(s.profileStepPhoneTitle), findsOneWidget);
          expect(find.textContaining('+44'), findsOneWidget);
          final phone = find.byKey(const ValueKey('profile-phone'));
          await tester.enterText(phone, '12');
          await tap(tester, s.profileContinue);
          expect(find.text(s.profilePhoneInvalid), findsOneWidget);
          await tester.enterText(phone, '07700 900123');
          await tap(tester, s.profileContinue);

          // 5. Work and study.
          await pick(
            tester,
            'profile-profession',
            s.professionNurse,
            s.professionNurse,
          );
          await choose(tester, EducationLevel.bachelors);
          await tap(tester, s.profileContinue);

          // 6. Faith and family.
          await choose(tester, PracticeLevel.active);
          await choose(tester, MaritalStatus.neverMarried);
          await tap(tester, s.profileContinue);

          // 7. Intentions.
          await choose(tester, MarriageTimeline.withinYear);
          await choose(tester, Relocation.open);
          await tap(tester, s.profileContinue);

          // 8. About.
          await tester.enterText(find.byType(TextFormField), sample.about);
          await tap(tester, s.profileContinue);

          // 9. Review, declaration, failed save, duplicate guard.
          expect(find.text('+447700900123'), findsOneWidget);
          expect(find.textContaining('Oromo'), findsOneWidget);
          await tap(tester, s.profileSave);
          expect(find.text(s.profileAdultRequired), findsOneWidget);
          expect(service.saves, 0);
          await tapFinder(tester, find.byType(CheckboxListTile));
          service.failSave = true;
          await tap(tester, s.profileSave);
          expect(find.text(s.profileSaveFailed), findsOneWidget);
          expect(find.text(s.profileCreated), findsNothing);
          service.failSave = false;
          service.pending = Completer<ProfileComplete>();
          await tester.tap(find.text(s.profileSave));
          await tester.pump();
          final button = tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, s.authLoading),
          );
          expect(button.onPressed, isNull);
          expect(service.saves, 2);

          final saved = service.savedProfile!;
          expect(saved.nationality, 'SO');
          expect(saved.residenceCountry, 'GB');
          expect(saved.ethnicity, Ethnicity.other);
          expect(saved.ethnicityOther, 'Oromo');
          expect(saved.profession, Profession.nurse);
          expect(saved.professionOther, '');
          expect(saved.relocation, Relocation.open);
          expect(service.savedDetails!.phoneNumber, '+447700900123');
          expect(service.savedDetails!.birthDate, DateTime.utc(2001, 1, 15));

          service.pending!.complete(
            ProfileComplete(saved, service.savedDetails!),
          );
          await tester.pumpAndSettle();
          expect(find.text(s.profileCreated), findsOneWidget);
          await openProfileTab(tester);
          expect(find.text('Test Person, 25'), findsOneWidget);
          expect(find.byType(ProfileOnboarding), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
