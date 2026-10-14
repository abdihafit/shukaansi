import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/services/auth_service.dart';
import 'package:shukaansi/services/firebase_auth_service.dart';

class TestUser extends Fake implements User {
  @override
  String get uid => 'test-user';
}

class TestCredential extends Fake implements UserCredential {}

class TestAuth extends Fake implements FirebaseAuth {
  final events = StreamController<User?>.broadcast();
  String? code;
  String? receivedPassword;
  int registrations = 0;
  int logins = 0;
  int signOuts = 0;
  String? resetEmail;
  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    resetEmail = email;
    check();
  }

  void check() {
    if (code != null) {
      throw FirebaseAuthException(
        code: code!,
        message: 'private provider text',
      );
    }
  }

  @override
  Stream<User?> authStateChanges() => events.stream;
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    registrations++;
    receivedPassword = password;
    check();
    return TestCredential();
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    logins++;
    receivedPassword = password;
    check();
    return TestCredential();
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    check();
  }
}

void main() {
  accountTests();
  test(
    'password reset trims email and conceals missing/disabled accounts',
    () async {
      final auth = TestAuth();
      final service = FirebaseAuthService(auth);
      await service.sendPasswordReset(email: ' test@example.com ');
      expect(auth.resetEmail, 'test@example.com');
      for (final code in ['user-not-found', 'user-disabled']) {
        auth.code = code;
        await service.sendPasswordReset(email: 'test@example.com');
      }
      auth.code = 'network-request-failed';
      await expectLater(
        service.sendPasswordReset(email: 'test@example.com'),
        throwsA(
          isA<AuthServiceException>().having(
            (e) => e.failure,
            'failure',
            AuthFailure.network,
          ),
        ),
      );
      await auth.events.close();
    },
  );
  test('adapter dispatches operations and preserves passwords', () async {
    final auth = TestAuth();
    final service = FirebaseAuthService(auth);
    await service.register(email: 'test@example.com', password: ' pass ');
    expect(auth.receivedPassword, ' pass ');
    await service.signIn(email: 'test@example.com', password: ' pass ');
    await service.signOut();
    expect([auth.registrations, auth.logins, auth.signOuts], [1, 1, 1]);
    await auth.events.close();
  });
  test('session stream handles restored identity and sign-out', () async {
    final auth = TestAuth();
    final expectation = expectLater(
      FirebaseAuthService(auth).sessions.map((s) => s?.uid),
      emitsInOrder(['test-user', null]),
    );
    auth.events.add(TestUser());
    auth.events.add(null);
    await expectation;
    await auth.events.close();
  });
  for (final entry in {
    'email-already-in-use': AuthFailure.rejected,
    'user-not-found': AuthFailure.rejected,
    'wrong-password': AuthFailure.rejected,
    'invalid-credential': AuthFailure.rejected,
    'user-disabled': AuthFailure.rejected,
    'weak-password': AuthFailure.rejected,
    'network-request-failed': AuthFailure.network,
    'too-many-requests': AuthFailure.throttled,
    'operation-not-allowed': AuthFailure.unavailable,
    'unexpected': AuthFailure.unknown,
  }.entries) {
    test('sanitizes ${entry.key}', () async {
      final auth = TestAuth()..code = entry.key;
      await expectLater(
        FirebaseAuthService(auth)
            .signIn(email: 'test@example.com', password: 'unused'),
        throwsA(
          isA<AuthServiceException>().having(
            (e) => e.failure,
            'safe failure',
            entry.value,
          ),
        ),
      );
      await auth.events.close();
    });
  }
}

class AccountUser extends Fake implements User {
  bool verified = false;
  bool verifyOnReload = false;
  String? failCode;
  int verificationEmails = 0;
  int deletions = 0;
  AuthCredential? credential;

  void _check() {
    if (failCode != null) {
      throw FirebaseAuthException(code: failCode!, message: 'private');
    }
  }

  @override
  String get uid => 'account-user';
  @override
  String? get email => 'owner@example.com';
  @override
  bool get emailVerified => verified;
  @override
  Future<void> reload() async {
    _check();
    if (verifyOnReload) verified = true;
  }

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    verificationEmails++;
    _check();
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    this.credential = credential;
    _check();
    return AccountCredential(this);
  }

  @override
  Future<void> delete() async {
    deletions++;
    _check();
  }
}

class AccountCredential extends Fake implements UserCredential {
  AccountCredential(this.user);
  @override
  final User? user;
}

class AccountAuth extends TestAuth {
  AccountAuth(this.user);
  final AccountUser? user;
  @override
  User? get currentUser => user;
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    registrations++;
    return AccountCredential(user);
  }
}

void accountTests() {
  test(
    'registration sends a verification email but never fails on it',
    () async {
      final user = AccountUser();
      final service = FirebaseAuthService(AccountAuth(user));
      await service.register(email: 'owner@example.com', password: 'secret1');
      expect(user.verificationEmails, 1);
      user.failCode = 'too-many-requests';
      await service.register(email: 'owner@example.com', password: 'secret1');
      expect(user.verificationEmails, 2);
    },
  );

  test('verification state, resend, reauthentication and deletion', () async {
    final user = AccountUser()..verifyOnReload = true;
    final service = FirebaseAuthService(AccountAuth(user));
    expect(service.email, 'owner@example.com');
    expect(service.emailVerified, isFalse);
    expect(await service.reloadEmailVerified(), isTrue);
    await service.sendEmailVerification();
    expect(user.verificationEmails, 1);
    await service.reauthenticate('secret1');
    expect(user.credential, isA<EmailAuthCredential>());
    final credential = user.credential! as EmailAuthCredential;
    expect(credential.email, 'owner@example.com');
    expect(credential.password, 'secret1');
    await service.deleteAccount();
    expect(user.deletions, 1);
  });

  test('account failures map to safe categories', () async {
    final user = AccountUser();
    final service = FirebaseAuthService(AccountAuth(user));
    for (final (code, failure) in [
      ('wrong-password', AuthFailure.rejected),
      ('invalid-credential', AuthFailure.rejected),
      ('user-mismatch', AuthFailure.rejected),
      ('network-request-failed', AuthFailure.network),
      ('requires-recent-login', AuthFailure.unknown),
    ]) {
      user.failCode = code;
      await expectLater(
        service.reauthenticate('secret1'),
        throwsA(
          isA<AuthServiceException>().having(
            (e) => e.failure,
            'failure',
            failure,
          ),
        ),
      );
    }
    final signedOut = FirebaseAuthService(AccountAuth(null));
    expect(signedOut.emailVerified, isFalse);
    await expectLater(
      signedOut.deleteAccount(),
      throwsA(
        isA<AuthServiceException>().having(
          (e) => e.failure,
          'failure',
          AuthFailure.rejected,
        ),
      ),
    );
  });
}
