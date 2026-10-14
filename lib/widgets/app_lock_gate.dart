import 'package:flutter/material.dart';

import '../application/app_lock_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_lock_service.dart';
import '../services/device_prefs_store.dart';
import '../theme/tokens.dart';
import 'brand/brand.dart';
import 'brand_loading.dart';

/// Gives screens below (Settings) access to the app lock.
class AppLockScope extends InheritedNotifier<AppLockController> {
  const AppLockScope({
    super.key,
    required AppLockController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLockController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLockScope>()?.notifier;
}

/// Wraps the signed-in app. While locked, an opaque lock screen covers it
/// (the app underneath keeps its place) and the phone's fingerprint, face or
/// PIN prompt opens straight away.
class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.uid,
    required this.service,
    required this.store,
    required this.onSignOut,
    required this.child,
  });
  final String uid;
  final AppLockService service;
  final DevicePrefsStore store;
  final VoidCallback onSignOut;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  late final _lock = AppLockController(
    uid: widget.uid,
    service: widget.service,
    store: widget.store,
  );
  bool _prompted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lock
      ..addListener(_changed)
      ..load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lock
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        _lock.wentToBackground();
      case AppLifecycleState.resumed:
        _lock.cameBack();
      default:
    }
  }

  /// Open the phone's prompt once each time the lock appears.
  void _changed() {
    if (!_lock.locked) {
      _prompted = false;
    } else if (!_prompted && !_lock.busy) {
      _prompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _lock.unlock(AppLocalizations.of(context).appLockReason);
      });
    }
  }

  @override
  Widget build(BuildContext context) => AppLockScope(
    controller: _lock,
    child: ListenableBuilder(
      listenable: _lock,
      builder: (context, _) {
        // Until the setting is read, show nothing private.
        if (!_lock.loaded) return const BrandLoadingPage();
        return Stack(
          children: [
            ExcludeSemantics(excluding: _lock.locked, child: widget.child),
            if (_lock.locked)
              _LockScreen(lock: _lock, onSignOut: widget.onSignOut),
          ],
        );
      },
    ),
  );
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.lock, required this.onSignOut});
  final AppLockController lock;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final failed =
        lock.lastResult == UnlockResult.failed ||
        lock.lastResult == UnlockResult.unavailable;
    return Scaffold(
      body: BrandSurface(
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      children: [
                        const ShukaansiLogo(
                          variant: LogoVariant.symbol,
                          height: 96,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Semantics(
                          header: true,
                          child: Text(
                            s.lockedTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          s.lockedBody,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (failed) ...[
                          const SizedBox(height: AppSpacing.m),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              lock.lastResult == UnlockResult.unavailable
                                  ? s.appLockUnavailable
                                  : s.unlockFailed,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xl),
                        PrimaryButton(
                          label: s.unlockAction,
                          icon: Icons.fingerprint,
                          loading: lock.busy,
                          onPressed: () => lock.unlock(s.appLockReason),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        // For anyone who can't unlock: sign out and sign in
                        // again with email and password.
                        TextButton(
                          onPressed: onSignOut,
                          child: Text(s.signOut),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
