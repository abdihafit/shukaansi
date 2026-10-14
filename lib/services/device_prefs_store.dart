import 'package:shared_preferences/shared_preferences.dart';

/// Small per-device settings for sign-in convenience. Nothing secret is kept:
/// passwords stay with the phone's own password manager.
abstract interface class DevicePrefsStore {
  /// Whether app lock is on for this account on this phone.
  Future<bool> appLock(String uid);
  Future<void> setAppLock(String uid, bool on);

  /// The last email signed in with on this phone, to fill in next time.
  Future<String?> rememberedEmail();
  Future<void> setRememberedEmail(String? email);
}

/// Kept for this run only (tests, or when the device store fails).
class MemoryDevicePrefsStore implements DevicePrefsStore {
  MemoryDevicePrefsStore({this.email});
  final locks = <String, bool>{};
  String? email;
  @override
  Future<bool> appLock(String uid) async => locks[uid] ?? false;
  @override
  Future<void> setAppLock(String uid, bool on) async => locks[uid] = on;
  @override
  Future<String?> rememberedEmail() async => email;
  @override
  Future<void> setRememberedEmail(String? value) async => email = value;
}

class PrefsDevicePrefsStore implements DevicePrefsStore {
  const PrefsDevicePrefsStore();
  static const _email = 'rememberedEmail';
  static String _lock(String uid) => 'appLock.$uid';

  // A missing preference store must never stop the app; it just forgets.
  @override
  Future<bool> appLock(String uid) async {
    try {
      return await SharedPreferencesAsync().getBool(_lock(uid)) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setAppLock(String uid, bool on) async {
    try {
      await SharedPreferencesAsync().setBool(_lock(uid), on);
    } catch (_) {}
  }

  @override
  Future<String?> rememberedEmail() async {
    try {
      return await SharedPreferencesAsync().getString(_email);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setRememberedEmail(String? email) async {
    try {
      if (email == null) {
        await SharedPreferencesAsync().remove(_email);
      } else {
        await SharedPreferencesAsync().setString(_email, email);
      }
    } catch (_) {}
  }
}
