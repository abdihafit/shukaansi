import 'password_recovery_service.dart';

enum AuthFailure { unavailable, rejected, network, throttled, unknown }

class AuthServiceException implements Exception {
  const AuthServiceException(this.failure);
  final AuthFailure failure;
}

/// Provider boundary. Implementations must map provider errors to safe categories
/// and never log credentials or expose raw provider messages to the UI.
abstract interface class AuthService {
  bool get isConfigured;
  Future<void> register({required String email, required String password});
  Future<void> signIn({required String email, required String password});
}

/// No network activity or simulated success when configuration is absent.
class UnconfiguredAuthService implements AuthService, PasswordRecoveryService {
  const UnconfiguredAuthService();

  @override
  bool get isConfigured => false;

  @override
  Future<void> sendPasswordReset({required String email}) async {
    throw const AuthServiceException(AuthFailure.unavailable);
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    throw const AuthServiceException(AuthFailure.unavailable);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    throw const AuthServiceException(AuthFailure.unavailable);
  }
}
