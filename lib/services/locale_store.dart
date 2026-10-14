import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the member's language between launches. Only the language code
/// is stored, on the device.
abstract class LocaleStore {
  Future<String?> read();
  Future<void> write(String languageCode);
}

/// Keeps the choice for this run only; used by tests and when the device
/// store is unavailable.
class MemoryLocaleStore implements LocaleStore {
  MemoryLocaleStore([this.value]);
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String languageCode) async => value = languageCode;
}

class PrefsLocaleStore implements LocaleStore {
  const PrefsLocaleStore();
  static const _key = 'languageCode';

  @override
  Future<String?> read() async {
    try {
      return await SharedPreferencesAsync().getString(_key);
    } catch (_) {
      // A missing preference store must never stop the app from starting.
      return null;
    }
  }

  @override
  Future<void> write(String languageCode) async {
    try {
      await SharedPreferencesAsync().setString(_key, languageCode);
    } catch (_) {}
  }
}
