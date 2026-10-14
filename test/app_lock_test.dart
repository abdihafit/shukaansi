import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/application/app_lock_controller.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/screens/auth_screen.dart';
import 'package:shukaansi/services/app_lock_service.dart';
import 'package:shukaansi/services/auth_service.dart';
import 'package:shukaansi/services/device_prefs_store.dart';
import 'package:shukaansi/theme/app_theme.dart';
import 'package:shukaansi/widgets/app_lock_gate.dart';

class FakeLock implements AppLockService {
  bool available = true;
  final results = <UnlockResult>[];
  int prompts = 0;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<UnlockResult> authenticate(String reason) async {
    prompts++;
    return results.isEmpty ? UnlockResult.unlocked : results.removeAt(0);
  }
}

class FakeAuth implements AuthService {
  bool fail = false;
  @override
  bool get isConfigured => true;
  @override
  Future<void> register({required String email, required String password}) =>
      signIn(email: email, password: password);
  @override
  Future<void> signIn({required String email, required String password}) async {
    if (fail) throw const AuthServiceException(AuthFailure.rejected);
  }
}

Widget app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.refinedLight,
  home: home,
);

void main() {
  group('lock rules', () {
    late DateTime now;
    AppLockController make(FakeLock lock, MemoryDevicePrefsStore store) =>
        AppLockController(
          uid: 'me',
          service: lock,
          store: store,
          clock: () => now,
        );

    setUp(() => now = DateTime(2026, 10, 12, 9));

    test(
      'off by default; a fresh start is locked only when it is on',
      () async {
        final store = MemoryDevicePrefsStore();
        final off = make(FakeLock(), store);
        await off.load();
        expect(off.enabled, isFalse);
        expect(off.locked, isFalse);

        store.locks['me'] = true;
        final on = make(FakeLock(), store);
        await on.load();
        expect(on.locked, isTrue);
        await on.unlock('reason');
        expect(on.locked, isFalse);
      },
    );

    test('the setting is per account', () async {
      final store = MemoryDevicePrefsStore()..locks['someone-else'] = true;
      final lock = make(FakeLock(), store);
      await lock.load();
      expect(lock.locked, isFalse);
    });

    test('turning it on needs a successful check first', () async {
      final store = MemoryDevicePrefsStore();
      final fake = FakeLock()..results.add(UnlockResult.cancelled);
      final lock = make(fake, store);
      await lock.load();
      expect(await lock.setEnabled(true, 'reason'), isFalse);
      expect(store.locks['me'], isNull);
      expect(await lock.setEnabled(true, 'reason'), isTrue);
      expect(store.locks['me'], isTrue);
      // Turning it off needs no check.
      expect(await lock.setEnabled(false, 'reason'), isTrue);
      expect(fake.prompts, 2);
    });

    test('locks again only after 5 minutes away', () async {
      final store = MemoryDevicePrefsStore()..locks['me'] = true;
      final lock = make(FakeLock(), store);
      await lock.load();
      await lock.unlock('reason');

      lock.wentToBackground();
      now = now.add(const Duration(minutes: 4));
      lock.cameBack();
      expect(lock.locked, isFalse);

      lock.wentToBackground();
      now = now.add(const Duration(minutes: 5));
      lock.cameBack();
      expect(lock.locked, isTrue);
    });

    test('a failed or cancelled check keeps it locked', () async {
      final store = MemoryDevicePrefsStore()..locks['me'] = true;
      final fake = FakeLock()
        ..results.addAll([UnlockResult.failed, UnlockResult.cancelled]);
      final lock = make(fake, store);
      await lock.load();
      await lock.unlock('reason');
      expect(lock.locked, isTrue);
      await lock.unlock('reason');
      expect(lock.locked, isTrue);
      await lock.unlock('reason');
      expect(lock.locked, isFalse);
    });

    test('no fingerprint, face or screen lock: never locks', () async {
      final store = MemoryDevicePrefsStore()..locks['me'] = true;
      final lock = make(FakeLock()..available = false, store);
      await lock.load();
      expect(lock.locked, isFalse);
      expect(lock.available, isFalse);
    });
  });

  testWidgets('the lock covers the app and asks straight away', (tester) async {
    final fake = FakeLock()..results.add(UnlockResult.cancelled);
    var signedOut = 0;
    await tester.pumpWidget(
      app(
        AppLockGate(
          uid: 'me',
          service: fake,
          store: MemoryDevicePrefsStore()..locks['me'] = true,
          onSignOut: () => signedOut++,
          child: const Scaffold(body: Text('Private content')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final s = AppLocalizations.of(tester.element(find.byType(Scaffold).last));
    expect(fake.prompts, 1, reason: 'the phone prompt opens by itself');
    expect(find.text(s.lockedTitle), findsOneWidget);
    // Cancelled: still locked; the content is hidden from screen readers.
    await tester.tap(find.text(s.signOut));
    expect(signedOut, 1);
    await tester.tap(find.text(s.unlockAction));
    await tester.pumpAndSettle();
    expect(find.text(s.lockedTitle), findsNothing);
    expect(find.text('Private content'), findsOneWidget);
  });

  group('sign-in on this phone', () {
    // What the app told the phone's password manager: save or not.
    List<Object?> saves(WidgetTester tester) => [
      for (final call in tester.testTextInput.log)
        if (call.method == 'TextInput.finishAutofillContext') call.arguments,
    ];

    Future<void> signIn(WidgetTester tester, String password) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), password);
      final s = AppLocalizations.of(tester.element(find.byType(Form)));
      await tester.tap(find.widgetWithText(ElevatedButton, s.signIn));
      await tester.pumpAndSettle();
    }

    testWidgets('remembers the email; offers to save only after success', (
      tester,
    ) async {
      final prefs = MemoryDevicePrefsStore(email: 'amina@example.com');
      final auth = FakeAuth()..fail = true;
      await tester.pumpWidget(
        app(
          AuthScreen(initialMode: AuthMode.login, service: auth, prefs: prefs),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('amina@example.com'), findsOneWidget);

      await signIn(tester, 'wrong password');
      expect(saves(tester), [false], reason: 'never save a failed sign-in');

      auth.fail = false;
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'hodan@example.com',
      );
      await signIn(tester, 'correct password');
      expect(saves(tester).last, isTrue);
      expect(prefs.email, 'hodan@example.com');
    });

    testWidgets('a new account starts with an empty email', (tester) async {
      await tester.pumpWidget(
        app(
          AuthScreen(
            service: FakeAuth(),
            prefs: MemoryDevicePrefsStore(email: 'amina@example.com'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('amina@example.com'), findsNothing);
    });
  });
}
