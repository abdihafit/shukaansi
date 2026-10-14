import 'package:shared_preferences/shared_preferences.dart';

/// Remembers which notifications the member has already seen, on this device
/// only.
abstract class SeenStore {
  Future<Set<String>> read(String uid);
  Future<void> write(String uid, Set<String> ids);
}

class MemorySeenStore implements SeenStore {
  final Map<String, Set<String>> _ids = {};
  @override
  Future<Set<String>> read(String uid) async => {...?_ids[uid]};
  @override
  Future<void> write(String uid, Set<String> ids) async => _ids[uid] = {...ids};
}

class PrefsSeenStore implements SeenStore {
  const PrefsSeenStore();
  static String _key(String uid) => 'seenActivity_$uid';

  @override
  Future<Set<String>> read(String uid) async {
    try {
      return (await SharedPreferencesAsync().getStringList(_key(uid)))
              ?.toSet() ??
          {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> write(String uid, Set<String> ids) async {
    try {
      await SharedPreferencesAsync().setStringList(_key(uid), ids.toList());
    } catch (_) {}
  }
}
