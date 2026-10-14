import 'auth_service.dart';

/// Identity only, never a grant of profile, moderation, or verification access.
class AccountSession {
  const AccountSession(this.uid);
  final String uid;
}

abstract interface class SessionService implements AuthService {
  Stream<AccountSession?> get sessions;
  Future<void> signOut();
}
