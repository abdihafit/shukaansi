import 'auth_service.dart';

/// Owner account controls: email verification and permanent deletion.
/// Failures are [AuthServiceException]s with safe categories only.
abstract interface class AccountService {
  /// The signed-in email, shown only to its owner.
  String? get email;

  /// Last known verification state; may be stale until [reloadEmailVerified].
  bool get emailVerified;

  /// Refreshes the account from the provider and returns its verification state.
  Future<bool> reloadEmailVerified();

  Future<void> sendEmailVerification();

  /// Confirms the password immediately before a sensitive action.
  Future<void> reauthenticate(String password);

  /// Deletes the sign-in account. Call [reauthenticate] first.
  Future<void> deleteAccount();
}

class UnavailableAccountService implements AccountService {
  const UnavailableAccountService();
  static const _error = AuthServiceException(AuthFailure.unavailable);
  @override
  String? get email => null;
  @override
  bool get emailVerified => false;
  @override
  Future<bool> reloadEmailVerified() async => throw _error;
  @override
  Future<void> sendEmailVerification() async => throw _error;
  @override
  Future<void> reauthenticate(String password) async => throw _error;
  @override
  Future<void> deleteAccount() async => throw _error;
}
