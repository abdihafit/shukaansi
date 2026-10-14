abstract interface class PasswordRecoveryService {
  bool get isConfigured;
  Future<void> sendPasswordReset({required String email});
}
