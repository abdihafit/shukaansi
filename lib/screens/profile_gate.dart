import 'package:flutter/material.dart';

import '../application/discovery_controller.dart';
import '../application/media_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/matrimonial_profile.dart';
import '../models/profile_media.dart';
import '../services/account_service.dart';
import '../models/moderation.dart';
import '../services/discovery_service.dart';
import '../services/moderation_service.dart';
import '../services/photo_picker.dart';
import '../services/photo_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../redesign/chats_view.dart';
import '../redesign/discover_view.dart';
import '../redesign/likes_view.dart';
import '../redesign/member_page.dart';
import '../redesign/member_profile_view.dart';
import '../redesign/photos.dart';
import '../redesign/profile_home.dart';
import '../widgets/brand_loading.dart';
import '../widgets/centered_content.dart';
import '../widgets/email_verification_card.dart';
import '../widgets/photo_privacy_section.dart';
import '../theme/tokens.dart';
import '../widgets/profile_media_section.dart';
import 'account_screen.dart';
import 'delete_account_screen.dart';
import 'suspended_screen.dart';
import 'activity_screen.dart';
import 'plans_screen.dart';
import '../application/membership_controller.dart';
import '../models/membership.dart';
import '../services/membership_service.dart';
import 'chat_screen.dart';
import '../application/activity_controller.dart';
import '../services/seen_store.dart';
import '../application/chat_controller.dart';
import '../models/discovery.dart';
import '../services/chat_service.dart';
import 'legal_consent_screen.dart';
import 'profile_details_screen.dart';
import 'wali_screens.dart';

import 'package:share_plus/share_plus.dart';

import '../application/wali_controller.dart';
import '../models/wali.dart';
import '../services/wali_service.dart';
import '../widgets/wali_card.dart';
import '../application/interest_controller.dart';
import '../services/interest_service.dart';
import '../models/legal.dart';
import '../services/consent_service.dart';
import 'profile_onboarding.dart';
import 'verification_screen.dart';

class ProfileGate extends StatefulWidget {
  const ProfileGate({
    super.key,
    required this.uid,
    required this.auth,
    required this.profiles,
    this.account = const UnavailableAccountService(),
    this.photos = const UnavailablePhotoService(),
    this.discovery = const UnavailableDiscoveryService(),
    this.moderation = const UnavailableModerationService(),
    this.consents = const UnavailableConsentService(),
    this.interests = const UnavailableInterestService(),
    this.walis = const UnavailableWaliService(),
    this.chats = const UnavailableChatService(),
    this.seenStore = const PrefsSeenStore(),
    this.memberships = const UnavailableMembershipService(),
    this.share,
    this.picker,
    this.today,
  });
  final ConsentService consents;
  final InterestService interests;
  final WaliService walis;
  final ChatService chats;

  /// Which notifications were seen; on the device.
  final SeenStore seenStore;
  final MembershipService memberships;

  /// Defaults to the phone's share sheet.
  final ShareText? share;
  final String uid;
  final SessionService auth;
  final ProfileService profiles;
  final AccountService account;
  final PhotoService photos;
  final DiscoveryService discovery;
  final ModerationService moderation;

  /// Defaults to the device gallery and camera.
  final PhotoPicker? picker;

  /// Overrides the current date in tests.
  final DateTime? today;
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  late Future<ProfileState> _load = widget.profiles.load(widget.uid);
  // True once the current Terms of Use and Privacy Policy are accepted.
  late Future<bool> _consented = _checkConsent();

  Future<bool> _checkConsent() async =>
      (await widget.consents.acceptedVersion(widget.uid) ?? 0) >=
      currentLegalVersion;

  Future<void> _acceptLegal() async {
    await widget.consents.accept(widget.uid, currentLegalVersion);
    if (!mounted) return;
    setState(() {
      _consented = Future.value(true);
    });
  }

  late bool _emailVerified = widget.account.emailVerified;
  late final PhotoPicker _picker = widget.picker ?? DevicePhotoPicker();
  // Kept across edits so photos are not downloaded again.
  late final MediaController _media = MediaController(
    uid: widget.uid,
    service: widget.photos,
    picker: _picker,
  );
  bool _mediaLoaded = false;
  late final DiscoveryController _discovery = DiscoveryController(
    uid: widget.uid,
    service: widget.discovery,
    moderation: widget.moderation,
    today: widget.today,
  );
  // Read once per session. If it cannot be read the app continues: the
  // security rules already keep suspended members out of Discover.
  late final Future<AccountStatus> _status = widget.moderation
      .status(widget.uid)
      .catchError((Object _) => AccountStatus.active);
  late final InterestController _interests = InterestController(
    uid: widget.uid,
    service: widget.interests,
  );
  bool _discoveryStarted = false;
  int _seenRevision = 0;
  int _tab = 0;
  static const _likesTab = 1;
  // New matches sit at the top of Chats.
  static const _chatsTab = 2;
  static const _profileTab = 3;

  /// Members liked or answered on this device: their match was already
  /// announced by the match sheet, so no second banner.
  final _actedHere = <String>{};

  /// The member's guardian; created once the profile (and gender) is known.
  WaliController? _wali;
  late final ChatController _chats = ChatController(
    uid: widget.uid,
    service: widget.chats,
  );

  ActivityController? _activity;
  late final MembershipController _membership = MembershipController(
    uid: widget.uid,
    service: widget.memberships,
    today: widget.today,
  );
  MembershipPlan? _seenPlan;

  /// A new plan completes waiting mutual likes and refreshes the VIP flag.
  void _planChanged() {
    final plan = _membership.plan;
    if (_seenPlan != null && plan != _seenPlan) {
      _interests.load();
      _discovery.markStale();
    }
    _seenPlan = plan;
  }

  Future<void> _openChat(ProfileCard card) async {
    _activity?.openChatWith = card.uid;
    await ChatScreen.open(
      context,
      uid: widget.uid,
      card: card,
      chats: widget.chats,
      discovery: _discovery,
      interests: _interests,
      wali: _wali,
      today: widget.today,
    );
    _activity?.openChatWith = null;
  }

  /// Goes to where a notification belongs.
  void _openActivityItem(ActivityItem item) => switch (item.kind) {
    ActivityKind.interest => _selectTab(_likesTab),
    ActivityKind.message => _openChat(item.card),
    _ => _selectTab(_chatsTab),
  };

  Future<void> _openActivity() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (route) => ActivityScreen(
        activity: _activity!,
        discovery: _discovery,
        today: widget.today,
        onOpen: (item) {
          Navigator.of(route).pop();
          _openActivityItem(item);
        },
      ),
    ),
  );

  /// A short banner for news that arrives while the app is open.
  void _alert(ActivityItem item) {
    if (!mounted) return;
    if (item.kind == ActivityKind.match && _actedHere.contains(item.card.uid)) {
      return;
    }
    final s = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(activityText(s, item)),
          action: SnackBarAction(
            label: s.activityView,
            onPressed: () => _openActivityItem(item),
          ),
        ),
      );
  }

  /// For accounts without a profile: are they a guardian?
  late final Future<GuardianAccount?> _guardian = widget.walis
      .guardian(widget.uid)
      .catchError((Object _) => null);
  GuardianAccount? _joinedAsGuardian;
  bool _settingUpWali = false;

  Future<void> _share(String text) async {
    final share = widget.share;
    if (share != null) return share(text);
    await SharePlus.instance.share(ShareParams(text: text));
  }

  /// Asks the guardian about every match that has none yet.
  void _syncWali() {
    final wali = _wali;
    if (wali == null || !wali.loaded || !_interests.loaded) return;
    wali.syncRequests(_interests.matches.map((e) => e.card.uid));
  }

  @override
  void initState() {
    super.initState();
    // A block hides the member from likes and matches too.
    _discovery.addListener(() => _interests.syncHidden(_discovery.hidden));
    _interests
      ..addListener(_syncWali)
      ..addListener(() => _actedHere.addAll(_interests.busy));
    // Photo or privacy changes unlist the profile; re-list on the next visit.
    _media.addListener(() {
      if (_media.revision != _seenRevision) {
        _seenRevision = _media.revision;
        _discovery.markStale();
      }
    });
  }

  @override
  void dispose() {
    _media.dispose();
    _discovery.dispose();
    _interests.dispose();
    _activity?.dispose();
    _membership.dispose();
    _wali?.dispose();
    _chats.dispose();
    super.dispose();
  }

  void _selectTab(int tab) {
    // Banners such as Discover's Undo belong to the tab they came from.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _tab = tab);
    if (tab == 0) _discovery.refreshIfNeeded();
    if (tab == _likesTab || tab == _chatsTab) _interests.load();
    if (tab == _chatsTab) _wali?.load().then((_) => _syncWali());
  }

  Future<void> _verify(ProfileComplete complete) async {
    final result = await Navigator.of(context).push<Verification>(
      MaterialPageRoute(
        builder: (_) => VerificationScreen(
          uid: widget.uid,
          service: widget.photos,
          picker: _picker,
          showNiqabTip: complete.profile.gender == ProfileGender.female,
        ),
      ),
    );
    if (result != null) _media.verificationSubmitted(result);
  }

  void _reload() => setState(() {
    _load = widget.profiles.load(widget.uid);
  });

  void _completed(ProfileComplete saved) => setState(() {
    _load = Future.value(saved);
  });

  /// Onboarding finished: open the app and say so.
  void _created(ProfileComplete saved) {
    _completed(saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).profileCreated)),
    );
  }

  /// Edit profile opens as its own page; saving returns to My profile.
  void _edit(ProfileComplete complete) {
    final s = AppLocalizations.of(context);
    _push(
      Scaffold(
        appBar: AppBar(title: Text(s.profileEdit)),
        body: CenteredContent(
          top: true,
          child: Builder(
            builder: (route) => ProfileOnboarding(
              key: const ValueKey('profile-edit'),
              uid: widget.uid,
              service: widget.profiles,
              initial: complete,
              today: widget.today,
              onCompleted: (saved) {
                Navigator.of(route).pop();
                _edited(saved);
              },
              onCancel: () => Navigator.of(route).pop(),
            ),
          ),
        ),
      ),
    );
  }

  void _edited(ProfileComplete saved) {
    _completed(saved);
    _discovery.markStale();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).profileUpdated)),
    );
  }

  Future<void> _deleteAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeleteAccountScreen(
          uid: widget.uid,
          account: widget.account,
          profiles: widget.profiles,
          photos: widget.photos,
          consents: widget.consents,
          interests: widget.interests,
          walis: widget.walis,
        ),
      ),
    );
    // If deletion stopped part-way, show what is actually stored now.
    if (mounted) _reload();
  }

  Future<void> _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void _openMember(ProfileCard card) => MemberPage.open(
    context,
    MemberPage(
      card: card,
      discovery: _discovery,
      interests: _interests,
      wali: _wali,
      today: widget.today,
      onMessage: (c) {
        Navigator.of(context).pop();
        _openChat(c);
      },
      onViewMatches: () => _selectTab(_chatsTab),
      onInviteWali: () {
        Navigator.of(context).pop();
        _selectTab(_profileTab);
      },
    ),
  );

  Future<void> _openDetails(ProfileComplete complete) => _push(
    Builder(
      builder: (route) => ProfileDetailsScreen(
        complete: complete,
        onEdit: () {
          Navigator.of(route).pop();
          _edit(complete);
        },
      ),
    ),
  );

  /// How other members see you, built from your saved profile and photos.
  void _previewOwn(ProfileComplete complete) {
    final s = AppLocalizations.of(context);
    _push(
      Scaffold(
        appBar: AppBar(title: Text(s.previewProfile)),
        body: ListView(
          // The card starts just under the title, like Discover.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.xs,
            AppSpacing.l,
            AppSpacing.xxl,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: MemberProfileView(
                  card: ownCard(widget.uid, complete, _media),
                  photos: OwnPhotos(_media),
                  today: widget.today ?? DateTime.now(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _managePhotos(ProfileComplete complete) {
    final s = AppLocalizations.of(context);
    _push(
      Scaffold(
        appBar: AppBar(title: Text(s.managePhotos)),
        body: CenteredContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PhotosSection(controller: _media),
              if (complete.profile.gender == ProfileGender.female) ...[
                const SizedBox(height: AppSpacing.l),
                PhotoPrivacySection(
                  uid: widget.uid,
                  media: _media,
                  discovery: widget.discovery,
                  today: widget.today,
                ),
              ],
              // Verification lives with the photos it checks: it needs a
              // main photo first and shows the review status.
              const SizedBox(height: AppSpacing.xl),
              VerificationCard(
                controller: _media,
                onStart: () => _verify(complete),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyEmail() {
    final s = AppLocalizations.of(context);
    _push(
      Scaffold(
        appBar: AppBar(title: Text(s.progressAccount)),
        body: CenteredContent(
          child: Builder(
            builder: (route) => EmailVerificationCard(
              account: widget.account,
              onVerified: () {
                setState(() => _emailVerified = true);
                _discovery.markStale();
                Navigator.of(route).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await widget.auth.signOut();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signOutFailed)),
      );
    }
  }

  Widget _shell(BuildContext context, ProfileComplete complete) {
    final s = AppLocalizations.of(context);
    if (!_discoveryStarted) {
      _discoveryStarted = true;
      _discovery.refresh();
      _interests.load();
      _wali = WaliController(
        uid: widget.uid,
        service: widget.walis,
        required: waliRequired(complete.profile.gender),
      );
      _wali!.load().then((_) => _syncWali());
      _chats.start();
      // Live updates while the app is open (push needs the Blaze plan).
      _interests.watch();
      _wali!
        ..watch()
        ..addListener(_syncWali);
      _activity = ActivityController(
        uid: widget.uid,
        interests: _interests,
        chats: _chats,
        wali: _wali,
        seenStore: widget.seenStore,
      )..onFresh = _alert;
      _membership
        ..addListener(_planChanged)
        ..start();
      _interests.onPremiumNeeded = (card) =>
          showPremiumNeeded(context, card, _membership);
    }
    if (!_mediaLoaded) {
      _mediaLoaded = true;
      _media.load();
    }
    void viewMatches() => _selectTab(_chatsTab);
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          DiscoverView(
            discovery: _discovery,
            interests: _interests,
            onOpenProfile: () => _selectTab(_profileTab),
            onViewMatches: viewMatches,
            today: widget.today,
            notifications: ActivityBell(
              activity: _activity!,
              onPressed: _openActivity,
            ),
          ),
          LikesView(
            interests: _interests,
            discovery: _discovery,
            openMember: _openMember,
            onBrowse: () => _selectTab(0),
          ),
          ChatsView(
            chats: _chats,
            interests: _interests,
            discovery: _discovery,
            wali: _wali,
            openChat: _openChat,
            openMember: _openMember,
            onBrowse: () => _selectTab(0),
            today: widget.today,
          ),
          ProfileHomeView(
            uid: widget.uid,
            complete: complete,
            media: _media,
            emailVerified: _emailVerified,
            discovery: _discovery,
            membership: _membership,
            moderation: widget.moderation,
            wali: _wali,
            share: _share,
            today: widget.today,
            onPreview: () => _previewOwn(complete),
            onDetails: () => _openDetails(complete),
            onEdit: () => _edit(complete),
            onManagePhotos: () => _managePhotos(complete),
            onVerifyEmail: _verifyEmail,
            onVerifyPhoto: () => _managePhotos(complete),
            onSignOut: _signOut,
            onDeleteAccount: _deleteAccount,
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([_interests, _chats]),
        builder: (context, _) => _navigation(s),
      ),
    );
  }

  Widget _navigation(AppLocalizations s) {
    // Likes counts new interest; Chats counts unread conversations plus new
    // matches nobody has written to yet (shown at the top of Chats).
    final waiting = _interests.received.length;
    final matched = {for (final e in _interests.matches) e.card.uid};
    final talking = {for (final c in _chats.conversations) c.otherUid};
    final chatCount =
        _chats.unreadAmong(matched) + matched.difference(talking).length;
    Widget badged(IconData icon, int count, String label) => Badge(
      isLabelVisible: count > 0,
      label: Text('$count', semanticsLabel: label),
      child: Icon(icon),
    );
    // White bar with a thin divider above it.
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: s.navDiscover,
          ),
          NavigationDestination(
            icon: badged(
              Icons.favorite_border,
              waiting,
              s.likesNewCount(waiting),
            ),
            selectedIcon: badged(
              Icons.favorite,
              waiting,
              s.likesNewCount(waiting),
            ),
            label: s.navLikes,
          ),
          NavigationDestination(
            icon: badged(
              Icons.chat_bubble_outline,
              chatCount,
              s.chatsUnreadCount(chatCount),
            ),
            selectedIcon: badged(
              Icons.chat_bubble,
              chatCount,
              s.chatsUnreadCount(chatCount),
            ),
            label: s.navChats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: s.navProfile,
          ),
        ],
      ),
    );
  }

  /// The quiet branded loading page. Sign out appears only if loading takes
  /// unusually long, as an escape hatch.
  Widget _loading([String? label]) =>
      BrandLoadingPage(semanticsLabel: label, onSignOut: _signOut);

  /// Each stage (loading, consent, onboarding, the app) fades into the next.
  Widget _fade(Widget child) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 300),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    Widget account(Widget content) =>
        AccountScreen(service: widget.auth, content: content);
    // The terms must be accepted before onboarding or anything else.
    return FutureBuilder<bool>(
      future: _consented,
      builder: (context, consent) => _fade(() {
        if (consent.connectionState != ConnectionState.done) {
          return _loading();
        }
        if (consent.hasError) {
          return account(
            Column(
              children: [
                Text(s.legalCheckFailed, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.l),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _consented = _checkConsent();
                  }),
                  child: Text(s.retry),
                ),
              ],
            ),
          );
        }
        if (consent.data != true) {
          return account(LegalConsentScreen(onAccept: _acceptLegal));
        }
        return _profileFlow(context, account);
      }()),
    );
  }

  /// No profile yet: a guardian's home, the guardian sign-up, or onboarding.
  Widget _withoutProfile(
    BuildContext context,
    Widget Function(Widget content) account,
  ) {
    final s = AppLocalizations.of(context);
    Widget guardianHome(GuardianAccount guardian) => AccountScreen(
      service: widget.auth,
      title: s.waliHomeTitle,
      content: WaliHome(
        uid: widget.uid,
        service: widget.walis,
        account: guardian,
        onDeleteAccount: _deleteAccount,
        today: widget.today,
      ),
    );
    final joined = _joinedAsGuardian;
    if (joined != null) return guardianHome(joined);
    return FutureBuilder<GuardianAccount?>(
      future: _guardian,
      builder: (context, snapshot) => _fade(() {
        if (snapshot.connectionState != ConnectionState.done) {
          return _loading();
        }
        final guardian = snapshot.data;
        if (guardian != null) return guardianHome(guardian);
        if (_settingUpWali) {
          return account(
            WaliSetup(
              uid: widget.uid,
              service: widget.walis,
              onBack: () => setState(() => _settingUpWali = false),
              onJoined: (g) => setState(() => _joinedAsGuardian = g),
            ),
          );
        }
        return AccountScreen(
          service: widget.auth,
          top: true,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WaliEntryCard(onTap: () => setState(() => _settingUpWali = true)),
              const SizedBox(height: AppSpacing.xl),
              ProfileOnboarding(
                uid: widget.uid,
                service: widget.profiles,
                onCompleted: _created,
                today: widget.today,
              ),
            ],
          ),
        );
      }()),
    );
  }

  Widget _profileFlow(
    BuildContext context,
    Widget Function(Widget content) account,
  ) {
    final s = AppLocalizations.of(context);
    return FutureBuilder<ProfileState>(
      future: _load,
      builder: (context, snapshot) => _fade(() {
        if (snapshot.connectionState != ConnectionState.done) {
          return _loading(s.profileLoading);
        }
        if (snapshot.hasError) {
          return account(
            Column(
              children: [
                Text(s.profileLoadFailed),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _reload, child: Text(s.retry)),
              ],
            ),
          );
        }
        return switch (snapshot.data!) {
          ProfileMissing() => _withoutProfile(context, account),
          ProfileNeedsUpdate(:final previous) => AccountScreen(
            service: widget.auth,
            top: true,
            content: ProfileOnboarding(
              uid: widget.uid,
              service: widget.profiles,
              onCompleted: _created,
              previous: previous,
              today: widget.today,
            ),
          ),
          final ProfileComplete complete => FutureBuilder<AccountStatus>(
            future: _status,
            builder: (context, status) => _fade(() {
              if (status.connectionState != ConnectionState.done) {
                return _loading();
              }
              if (status.data?.suspended ?? false) {
                return SuspendedScreen(status: status.data!, auth: widget.auth);
              }
              return _shell(context, complete);
            }()),
          ),
        };
      }()),
    );
  }
}
