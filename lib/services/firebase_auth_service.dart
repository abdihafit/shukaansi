import 'package:firebase_auth/firebase_auth.dart';

import 'account_service.dart';
import 'auth_service.dart';
import 'session_service.dart';
import 'password_recovery_service.dart';

class FirebaseAuthService
    implements SessionService, PasswordRecoveryService, AccountService {
  FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;

  @override
  bool get isConfigured => true;

  @override
  Stream<AccountSession?> get sessions => _auth.authStateChanges().map(
    (user) => user == null ? null : AccountSession(user.uid),
  );

  @override
  Future<void> register({required String email, required String password}) =>
      _guard(() async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Best effort: the account exists even if this email cannot be sent;
        // the owner can resend it from the profile screen.
        try {
          await credential.user?.sendEmailVerification();
        } catch (_) {}
      });

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() async {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      });

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  @override
  Future<void> sendPasswordReset({required String email}) => _guard(() async {
    try {
      // Use the project's hosted email action handler and template language.
      // Never claim that delivery occurred or expose whether the account exists.
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found' && error.code != 'user-disabled') {
        rethrow;
      }
    }
  });

  @override
  String? get email => _auth.currentUser?.email;

  @override
  bool get emailVerified => _auth.currentUser?.emailVerified ?? false;

  User get _user =>
      _auth.currentUser ??
      (throw const AuthServiceException(AuthFailure.rejected));

  @override
  Future<bool> reloadEmailVerified() async {
    await _guard(() => _user.reload());
    return emailVerified;
  }

  @override
  Future<void> sendEmailVerification() =>
      _guard(() => _user.sendEmailVerification());

  @override
  Future<void> reauthenticate(String password) => _guard(() async {
    final user = _user;
    final email = user.email;
    if (email == null) throw const AuthServiceException(AuthFailure.rejected);
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
  });

  @override
  Future<void> deleteAccount() => _guard(() => _user.delete());

  Future<void> _guard(Future<void> Function() operation) async {
    try {
      await operation();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(mapFirebaseAuthFailure(error.code));
    } on AuthServiceException {
      rethrow;
    } catch (_) {
      throw const AuthServiceException(AuthFailure.unknown);
    }
  }
}

AuthFailure mapFirebaseAuthFailure(String code) => switch (code) {
  'network-request-failed' => AuthFailure.network,
  'too-many-requests' => AuthFailure.throttled,
  'operation-not-allowed' ||
  'app-not-authorized' ||
  'invalid-api-key' => AuthFailure.unavailable,
  'invalid-email' ||
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' ||
  'user-disabled' ||
  'user-mismatch' ||
  'email-already-in-use' ||
  'weak-password' ||
  'password-does-not-meet-requirements' => AuthFailure.rejected,
  _ => AuthFailure.unknown,
};
