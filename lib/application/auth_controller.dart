import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.service);

  final AuthService service;
  bool _disposed = false;
  bool busy = false;
  bool completed = false;
  AuthFailure? failure;

  Future<void> submit({
    required bool registering,
    required String email,
    required String password,
  }) async {
    if (_disposed || busy) return;
    busy = true;
    completed = false;
    failure = null;
    notifyListeners();
    try {
      if (!service.isConfigured) {
        throw const AuthServiceException(AuthFailure.unavailable);
      }
      if (registering) {
        await service.register(email: email.trim(), password: password);
      } else {
        await service.signIn(email: email.trim(), password: password);
      }
      if (!_disposed) completed = true;
    } on AuthServiceException catch (error) {
      if (!_disposed) failure = error.failure;
    } catch (_) {
      // Raw exceptions can contain account information; never surface or log them.
      if (!_disposed) failure = AuthFailure.unknown;
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  void reset() {
    if (_disposed || busy) return;
    completed = false;
    failure = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
