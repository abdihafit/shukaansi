import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/widgets/app_lock_gate.dart';
import 'package:shukaansi/main.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/screens/account_screen.dart';
import 'package:shukaansi/screens/auth_screen.dart';
import 'package:shukaansi/services/session_service.dart';
import 'package:shukaansi/services/profile_service.dart';
import 'package:shukaansi/screens/profile_onboarding.dart';

class PendingProfiles extends Fake implements ProfileService {
  final result = Completer<ProfileState>();
  @override
  Future<ProfileState> load(String uid) => result.future;
}

class TestSessions implements SessionService {
  final events = StreamController<AccountSession?>.broadcast();
  bool failSignOut = false;
  @override
  bool get isConfigured => true;
  @override
  Stream<AccountSession?> get sessions => events.stream;
  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {}
  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}
  @override
  Future<void> signOut() async {
    if (failSignOut) throw StateError('private error');
    events.add(null);
  }
}

void main() {
  testWidgets('late profile result cannot reopen onboarding after sign-out', (
    tester,
  ) async {
    final auth = TestSessions();
    final profiles = PendingProfiles();
    await tester.pumpWidget(ShukaansiApp(service: auth, profiles: profiles));
    auth.events.add(const AccountSession('owner'));
    await tester.pump();
    await tester.pump();
    // Signed in: the app (behind the optional app lock) is showing.
    expect(find.byType(AppLockGate), findsOneWidget);
    auth.events.add(null);
    await tester.pump();
    profiles.result.complete(const ProfileMissing());
    await tester.pump();
    expect(find.byType(ProfileOnboarding), findsNothing);
    expect(find.byType(AccountScreen), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await auth.events.close();
    expect(tester.takeException(), isNull);
  });
  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale ${brightness.name}: restored session, failed and successful sign-out',
        (tester) async {
          tester.platformDispatcher.localeTestValue = Locale(locale);
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          addTearDown(tester.platformDispatcher.clearLocaleTestValue);
          addTearDown(
            tester.platformDispatcher.clearPlatformBrightnessTestValue,
          );
          final service = TestSessions();
          await tester.pumpWidget(ShukaansiApp(service: service));
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          service.events.add(const AccountSession('restored'));
          await tester.pumpAndSettle();
          expect(find.byType(AccountScreen), findsOneWidget);
          final strings = AppLocalizations.of(
            tester.element(find.byType(AccountScreen)),
          );
          service.failSignOut = true;
          await tester.tap(find.text(strings.signOut));
          await tester.pumpAndSettle();
          expect(find.text(strings.signOutFailed), findsOneWidget);
          service.failSignOut = false;
          await tester.tap(find.text(strings.signOut));
          await tester.pump();
          expect(find.byType(AccountScreen), findsNothing);
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle();
          await tester.pumpWidget(const SizedBox());
          await service.events.close();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'form completion does not authorize; session event resets pushed routes',
    (tester) async {
      final service = TestSessions();
      await tester.pumpWidget(ShukaansiApp(service: service));
      service.events.add(null);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test@example.com');
      await tester.enterText(fields.at(1), 'abcdef');
      await tester.enterText(fields.at(2), 'abcdef');
      await tester.ensureVisible(find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(AccountScreen), findsNothing);
      service.events.add(const AccountSession('new'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsNothing);
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(AccountScreen))).canPop(),
        isFalse,
      );
      service.events.addError(StateError('private stream error'));
      await tester.pumpAndSettle();
      expect(find.byType(AccountScreen), findsNothing);
      expect(find.text('Unable to check your session.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      service.events.add(null);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await service.events.close();
      expect(tester.takeException(), isNull);
    },
  );
}
