import 'package:local_auth/local_auth.dart';

/// How an unlock attempt ended.
enum UnlockResult { unlocked, cancelled, unavailable, failed }

/// The phone's own fingerprint, face or screen-lock PIN check. The app never
/// sees or stores any biometric data or PIN; the phone only says yes or no.
abstract interface class AppLockService {
  /// True when the phone has a fingerprint, face or screen lock set up.
  Future<bool> isAvailable();

  Future<UnlockResult> authenticate(String reason);
}

class DeviceAppLockService implements AppLockService {
  DeviceAppLockService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();
  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<UnlockResult> authenticate(String reason) async {
    try {
      // biometricOnly: false lets people use their phone PIN, pattern or
      // password when fingerprint or face isn't available or fails.
      final ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      return ok ? UnlockResult.unlocked : UnlockResult.cancelled;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noCredentialsSet => UnlockResult.unavailable,
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled => UnlockResult.cancelled,
        _ => UnlockResult.failed,
      };
    } catch (_) {
      return UnlockResult.failed;
    }
  }
}

/// No lock on this platform (web admin, tests).
class UnavailableAppLockService implements AppLockService {
  const UnavailableAppLockService();
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<UnlockResult> authenticate(String reason) async =>
      UnlockResult.unavailable;
}
