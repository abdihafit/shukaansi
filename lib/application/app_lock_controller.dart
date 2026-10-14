import 'package:flutter/foundation.dart';

import '../services/app_lock_service.dart';
import '../services/device_prefs_store.dart';

/// App lock for one signed-in account on this phone: when it is on, the app
/// asks for fingerprint, face or the phone PIN when it starts and when it
/// comes back after [relockAfter] in the background. The account stays
/// signed in; the lock only hides the app until the owner confirms.
class AppLockController extends ChangeNotifier {
  AppLockController({
    required this.uid,
    required this.service,
    required this.store,
    this.relockAfter = const Duration(minutes: 5),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final String uid;
  final AppLockService service;
  final DevicePrefsStore store;
  final Duration relockAfter;
  final DateTime Function() _clock;

  bool loaded = false;
  bool available = false;
  bool enabled = false;
  bool locked = false;
  bool busy = false;
  UnlockResult? lastResult;
  DateTime? _backgroundSince;

  /// Reads the setting; a fresh start of the app is locked when it is on.
  Future<void> load() async {
    final results = await Future.wait([
      service.isAvailable(),
      store.appLock(uid),
    ]);
    available = results[0];
    enabled = results[1] && available;
    locked = enabled;
    loaded = true;
    notifyListeners();
  }

  /// Asks the phone to confirm it's the owner, then opens the app.
  Future<void> unlock(String reason) async {
    if (busy || !locked) return;
    busy = true;
    lastResult = null;
    notifyListeners();
    final result = await service.authenticate(reason);
    busy = false;
    lastResult = result;
    if (result == UnlockResult.unlocked) locked = false;
    notifyListeners();
  }

  /// Turning the lock on needs a successful check first, so nobody is locked
  /// out by a lock they can't open. Returns whether the change was made.
  Future<bool> setEnabled(bool on, String reason) async {
    if (busy) return false;
    if (on) {
      busy = true;
      notifyListeners();
      final result = await service.authenticate(reason);
      busy = false;
      lastResult = result;
      if (result != UnlockResult.unlocked) {
        notifyListeners();
        return false;
      }
    }
    enabled = on;
    await store.setAppLock(uid, on);
    notifyListeners();
    return true;
  }

  void wentToBackground() {
    // The phone's own prompt also sends the app to the background briefly;
    // that must not count as leaving.
    if (busy) return;
    _backgroundSince = _clock();
  }

  void cameBack() {
    final since = _backgroundSince;
    _backgroundSince = null;
    if (!enabled || locked || since == null) return;
    if (_clock().difference(since) >= relockAfter) {
      locked = true;
      lastResult = null;
      notifyListeners();
    }
  }
}
