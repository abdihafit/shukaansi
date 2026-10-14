import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'application/auth_scope.dart';
import 'services/account_service.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';
import 'services/firebase_bootstrap.dart';
import 'screens/profile_gate.dart';
import 'services/app_lock_service.dart';
import 'services/device_prefs_store.dart';
import 'widgets/app_lock_gate.dart';
import 'widgets/brand_loading.dart';
import 'widgets/centered_content.dart';
import 'services/profile_service.dart';
import 'services/firestore_profile_service.dart';
import 'services/firebase_photo_service.dart';
import 'services/photo_files.dart';
import 'services/photo_service.dart';
import 'services/discovery_service.dart';
import 'services/firestore_discovery_service.dart';
import 'services/moderation_service.dart';
import 'services/locale_store.dart';
import 'services/consent_service.dart';
import 'services/interest_service.dart';
import 'services/wali_service.dart';
import 'services/chat_service.dart';
import 'services/membership_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'application/locale_scope.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/framework_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash until Firebase is ready and the first sign-in
  // state is known (see _ShukaansiAppState), so no extra loading screen
  // flashes in between.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  // The bundled font's licence, shown on the licences page.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(
      'assets/fonts/plus_jakarta_sans/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(const ['Plus Jakarta Sans'], text);
  });
  final service = await initializeAuthentication();
  const localeStore = PrefsLocaleStore();
  final savedLanguage = await localeStore.read();
  runApp(
    ShukaansiApp(
      localeStore: localeStore,
      initialLocale: savedLanguage == null ? null : Locale(savedLanguage),
      service: service,
      profiles: service.isConfigured
          ? FirestoreProfileService(
              FirebaseFirestore.instance,
              FirebaseAuth.instance,
            )
          : const UnavailableProfileService(),
      photos: service.isConfigured
          ? FirebasePhotoService(
              FirebaseFirestore.instance,
              // Free plan: images in Firestore. Once the Blaze plan and a
              // Storage bucket exist, use StoragePhotoFiles(FirebaseStorage.instance).
              FirestorePhotoFiles(FirebaseFirestore.instance),
              FirebaseAuth.instance,
            )
          : const UnavailablePhotoService(),
      discovery: service.isConfigured
          ? FirestoreDiscoveryService(
              FirebaseFirestore.instance,
              FirebaseAuth.instance,
              FirestorePhotoFiles(FirebaseFirestore.instance),
            )
          : const UnavailableDiscoveryService(),
      moderation: service.isConfigured
          ? FirestoreModerationService(
              FirebaseFirestore.instance,
              FirebaseAuth.instance,
            )
          : const UnavailableModerationService(),
      consents: service.isConfigured
          ? FirestoreConsentService(
              FirebaseFirestore.instance,
              FirebaseAuth.instance,
            )
          : const UnavailableConsentService(),
      interests: service.isConfigured
          ? FirestoreInterestService(
              FirebaseFirestore.instance,
              FirebaseAuth.instance,
            )
          : const UnavailableInterestService(),
      walis: service.isConfigured
          ? FirestoreWaliService(
              FirebaseFirestore.instance,
              FirebaseAuth.instance,
            )
          : const UnavailableWaliService(),
      chats: service.isConfigured
          ? FirestoreChatService(
              FirebaseFirestore.instance,
              FirebaseAuth.instance,
            )
          : const UnavailableChatService(),
      appLock: DeviceAppLockService(),
      devicePrefs: const PrefsDevicePrefsStore(),
      memberships: service.isConfigured
          ? FirestoreMembershipService(
              FirebaseFirestore.instance,
              FirebaseAuth.instance,
            )
          : const UnavailableMembershipService(),
    ),
  );
}

class ShukaansiApp extends StatefulWidget {
  const ShukaansiApp({
    super.key,
    this.service = const UnconfiguredAuthService(),
    this.profiles = const UnavailableProfileService(),
    this.photos = const UnavailablePhotoService(),
    this.discovery = const UnavailableDiscoveryService(),
    this.moderation = const UnavailableModerationService(),
    this.consents = const UnavailableConsentService(),
    this.interests = const UnavailableInterestService(),
    this.walis = const UnavailableWaliService(),
    this.chats = const UnavailableChatService(),
    this.memberships = const UnavailableMembershipService(),
    this.appLock = const UnavailableAppLockService(),
    this.devicePrefs,
    this.localeStore,
    this.initialLocale,
  });
  final LocaleStore? localeStore;

  /// The language saved on a previous launch, if any.
  final Locale? initialLocale;
  final AuthService service;
  final ProfileService profiles;
  final PhotoService photos;
  final DiscoveryService discovery;
  final ModerationService moderation;
  final ConsentService consents;
  final InterestService interests;
  final WaliService walis;
  final ChatService chats;
  final MembershipService memberships;

  /// Fingerprint, face or phone PIN to unlock the app (none in tests).
  final AppLockService appLock;

  /// App-lock setting and remembered email, on this phone.
  final DevicePrefsStore? devicePrefs;

  @override
  State<ShukaansiApp> createState() => _ShukaansiAppState();
}

class _ShukaansiAppState extends State<ShukaansiApp> {
  late Locale? _locale =
      AppLocalizations.supportedLocales.contains(widget.initialLocale)
      ? widget.initialLocale
      : null;
  StreamSubscription<AccountSession?>? _subscription;
  AccountSession? _session;
  bool _waiting = false;
  late final DevicePrefsStore _devicePrefs =
      widget.devicePrefs ?? MemoryDevicePrefsStore();
  bool _sessionError = false;
  int _navigationEpoch = 0;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  /// The first sign-in state is known: hand over from the native splash.
  void _ready() => FlutterNativeSplash.remove();

  void _listen() {
    final service = widget.service;
    if (service is! SessionService) {
      _ready();
      return;
    }
    _waiting = true;
    _sessionError = false;
    _subscription = service.sessions.listen(
      (session) {
        if (!mounted) return;
        setState(() {
          if (_waiting || _sessionError || _session?.uid != session?.uid) {
            _navigationEpoch++;
          }
          _session = session;
          _waiting = false;
          _sessionError = false;
        });
        _ready();
      },
      onError: (Object _, StackTrace _) {
        if (!mounted) return;
        setState(() {
          _session = null;
          _waiting = false;
          _sessionError = true;
          _navigationEpoch++;
        });
        _ready();
      },
    );
  }

  Future<void> _retrySession() async {
    await _subscription?.cancel();
    if (mounted) setState(_listen);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _selectLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    setState(() => _locale = locale);
    widget.localeStore?.write(locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      locale: _locale,
      selectLocale: _selectLocale,
      child: AuthScope(
        service: widget.service,
        child: MaterialApp(
          key: ValueKey(_navigationEpoch),
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: _locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            SomaliMaterialFallback(),
            SomaliCupertinoFallback(),
            ...AppLocalizations.localizationsDelegates,
          ],
          debugShowCheckedModeBanner: false,
          theme: AppTheme.refinedLight,
          darkTheme: AppTheme.refinedDark,
          themeMode: ThemeMode.system,
          home: _waiting || _sessionError
              ? Builder(
                  builder: (context) {
                    final strings = AppLocalizations.of(context);
                    if (!_sessionError) return const BrandLoadingPage();
                    return Scaffold(
                      body: Center(
                        child: _sessionError
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(strings.sessionFailed),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _retrySession,
                                    child: Text(strings.retry),
                                  ),
                                ],
                              )
                            : const CenteredContent(child: BrandLoading()),
                      ),
                    );
                  },
                )
              : _session != null
              ? AppLockGate(
                  key: ValueKey('lock-${_session!.uid}'),
                  uid: _session!.uid,
                  service: widget.appLock,
                  store: _devicePrefs,
                  onSignOut: () => (widget.service as SessionService).signOut(),
                  child: ProfileGate(
                    key: ValueKey(_session!.uid),
                    uid: _session!.uid,
                    auth: widget.service as SessionService,
                    profiles: widget.profiles,
                    photos: widget.photos,
                    discovery: widget.discovery,
                    moderation: widget.moderation,
                    consents: widget.consents,
                    interests: widget.interests,
                    walis: widget.walis,
                    chats: widget.chats,
                    memberships: widget.memberships,
                    account: widget.service is AccountService
                        ? widget.service as AccountService
                        : const UnavailableAccountService(),
                  ),
                )
              : const SplashScreen(),
        ),
      ),
    );
  }
}
