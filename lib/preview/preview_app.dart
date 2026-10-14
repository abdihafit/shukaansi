import 'package:flutter/material.dart';

import '../application/activity_controller.dart';
import '../application/chat_controller.dart';
import '../application/discovery_controller.dart';
import '../application/interest_controller.dart';
import '../application/locale_scope.dart';
import '../application/media_controller.dart';
import '../application/membership_controller.dart';
import '../application/wali_controller.dart';
import '../l10n/framework_localizations.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../redesign/chats_view.dart';
import '../redesign/discover_view.dart';
import '../redesign/likes_view.dart';
import '../redesign/member_page.dart';
import '../redesign/member_profile_view.dart';
import '../redesign/photos.dart';
import '../redesign/profile_home.dart';
import '../screens/activity_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/plans_screen.dart';
import '../screens/profile_onboarding.dart';
import '../screens/verification_screen.dart';
import '../services/profile_service.dart';
import '../services/seen_store.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/centered_content.dart';
import '../widgets/profile_media_section.dart';
import 'fixture_services.dart';
import 'fixtures.dart';

/// The development preview: the redesigned four-tab experience over
/// in-memory fictional data. Language and every action stay on the device.
class PreviewApp extends StatefulWidget {
  PreviewApp({super.key, PreviewWorld? world})
    : world = world ?? PreviewWorld();
  final PreviewWorld world;

  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  final _navigator = GlobalKey<NavigatorState>();
  Locale _locale = const Locale('en');

  Future<void> _scenarios() async {
    final context = _navigator.currentContext;
    if (context == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ScenarioSheet(world: widget.world),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      locale: _locale,
      selectLocale: (locale) => setState(() => _locale = locale),
      child: MaterialApp(
        navigatorKey: _navigator,
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        locale: _locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          SomaliMaterialFallback(),
          SomaliCupertinoFallback(),
          ...AppLocalizations.localizationsDelegates,
        ],
        theme: AppTheme.refinedLight,
        darkTheme: AppTheme.refinedDark,
        builder: (context, child) => Column(
          children: [
            _PreviewStrip(onTap: _scenarios),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: child!,
              ),
            ),
          ],
        ),
        home: ListenableBuilder(
          listenable: widget.world,
          builder: (context, _) => PreviewShell(
            key: ValueKey(widget.world.revision),
            world: widget.world,
          ),
        ),
      ),
    );
  }
}

/// "Preview · fictional profiles": always visible, opens the scenarios.
class _PreviewStrip extends StatelessWidget {
  const _PreviewStrip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            button: true,
            label: '${s.previewBadge}. ${s.previewScenarios}',
            excludeSemantics: true,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: colors.onSecondaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        s.previewBadge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.tune,
                      size: 16,
                      color: colors.onSecondaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScenarioSheet extends StatelessWidget {
  const _ScenarioSheet({required this.world});
  final PreviewWorld world;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final labels = {
      PreviewScenario.populated: s.scenarioPopulated,
      PreviewScenario.preferencesNotSet: s.scenarioPrefsNotSet,
      PreviewScenario.noMatches: s.scenarioNoMatches,
      PreviewScenario.loading: s.scenarioLoading,
      PreviewScenario.networkError: s.scenarioNetworkError,
      PreviewScenario.incompleteProfile: s.scenarioIncomplete,
      PreviewScenario.awaitingReview: s.scenarioAwaitingReview,
      PreviewScenario.emptyActivity: s.scenarioEmptyActivity,
    };
    return ListenableBuilder(
      listenable: world,
      builder: (context, _) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            0,
            AppSpacing.l,
            AppSpacing.l,
          ),
          children: [
            Text(
              s.previewScenarios,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(s.previewScenariosBody),
            const SizedBox(height: AppSpacing.s),
            RadioGroup<PreviewScenario>(
              groupValue: world.scenario,
              onChanged: (value) {
                if (value == null) return;
                world.setScenario(value);
                Navigator.of(context).pop();
              },
              child: Column(
                children: [
                  for (final MapEntry(:key, :value) in labels.entries)
                    RadioListTile<PreviewScenario>(
                      value: key,
                      title: Text(value),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.previewSimulatePremium),
              value: world.viewerPlan.name != 'free',
              onChanged: world.setPremium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Discover | Likes | Chats | Profile. New matches live at the top of Chats.
class PreviewShell extends StatefulWidget {
  const PreviewShell({super.key, required this.world});
  final PreviewWorld world;

  @override
  State<PreviewShell> createState() => _PreviewShellState();
}

class _PreviewShellState extends State<PreviewShell> {
  static const _uid = previewViewerUid;
  late final _discoveryService = PreviewDiscovery(widget.world);
  late final _memberships = PreviewMemberships(widget.world);
  late final _walis = PreviewWalis(widget.world);
  late final _interestsService = PreviewInterests(
    widget.world,
    _memberships,
    _walis,
  );
  late final _chatService = PreviewChats(
    widget.world,
    _interestsService,
    _walis,
  );
  late final _moderation = PreviewModeration(_discoveryService);
  late final _profiles = PreviewProfiles();
  late final _photos = PreviewPhotos(widget.world);
  late final _account = PreviewAccount(widget.world);

  late final _discovery = DiscoveryController(
    uid: _uid,
    service: _discoveryService,
    moderation: _moderation,
  );
  late final _interests = InterestController(
    uid: _uid,
    service: _interestsService,
  );
  late final _chats = ChatController(uid: _uid, service: _chatService);
  late final _wali = WaliController(
    uid: _uid,
    service: _walis,
    required: false,
  );
  late final _membership = MembershipController(
    uid: _uid,
    service: _memberships,
  );
  late final _media = MediaController(
    uid: _uid,
    service: _photos,
    picker: PreviewPicker(),
  );
  late final _activity = ActivityController(
    uid: _uid,
    interests: _interests,
    chats: _chats,
    wali: _wali,
    seenStore: MemorySeenStore(),
  );
  int _tab = 0;

  /// Members this viewer liked or answered here: their match was already
  /// announced by the match sheet, so no second banner.
  final _actedHere = <String>{};

  ProfileComplete get _profile => _profiles.stored as ProfileComplete;

  @override
  void initState() {
    super.initState();
    _discovery.addListener(() => _interests.syncHidden(_discovery.hidden));
    _interests.addListener(() => _actedHere.addAll(_interests.busy));
    _membership.addListener(_interests.load);
    _interests.onPremiumNeeded = (card) =>
        showPremiumNeeded(context, card, _membership);
    _activity.onFresh = _alert;
    _discovery.refresh();
    _interests
      ..load()
      ..watch();
    _wali.load();
    _chats.start();
    _membership.start();
    _media.load();
  }

  @override
  void dispose() {
    _activity.dispose();
    _discovery.dispose();
    _interests.dispose();
    _chats.dispose();
    _wali.dispose();
    _membership.dispose();
    _media.dispose();
    super.dispose();
  }

  void _select(int tab) {
    // Banners such as Discover's Undo belong to the tab they came from.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _tab = tab);
    if (tab == 1 || tab == 2) _interests.load();
    if (tab == 2) _wali.load();
  }

  void _notAvailable() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).previewNotAvailable),
        ),
      );
  }

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

  void _openActivityItem(ActivityItem item) => switch (item.kind) {
    ActivityKind.interest => _select(1),
    ActivityKind.message => _openChat(item.card),
    _ => _select(2),
  };

  Future<void> _openChat(ProfileCard card) async {
    _activity.openChatWith = card.uid;
    await ChatScreen.open(
      context,
      uid: _uid,
      card: card,
      chats: _chatService,
      discovery: _discovery,
      interests: _interests,
      wali: _wali,
    );
    _activity.openChatWith = null;
  }

  void _openMember(ProfileCard card) => MemberPage.open(
    context,
    MemberPage(
      card: card,
      discovery: _discovery,
      interests: _interests,
      wali: _wali,
      onMessage: (c) {
        Navigator.of(context).pop();
        _openChat(c);
      },
      onViewMatches: () => _select(2),
      concept: previewMember(card.uid)?.concept,
    ),
  );

  Future<void> _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void _previewOwn() {
    final s = AppLocalizations.of(context);
    _push(
      Scaffold(
        appBar: AppBar(title: Text(s.previewProfile)),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            MemberProfileView(
              card: ownCard(_uid, _profile, _media),
              photos: OwnPhotos(_media),
              today: DateTime.now(),
            ),
          ],
        ),
      ),
    );
  }

  void _edit() {
    final s = AppLocalizations.of(context);
    _push(
      Scaffold(
        appBar: AppBar(title: Text(s.profileEdit)),
        body: CenteredContent(
          child: Builder(
            builder: (route) => ProfileOnboarding(
              key: const ValueKey('preview-edit'),
              uid: _uid,
              service: _profiles,
              initial: _profile,
              onCompleted: (_) {
                Navigator.of(route).pop();
                setState(() {});
                _discovery.markStale();
              },
              onCancel: () => Navigator.of(route).pop(),
            ),
          ),
        ),
      ),
    );
  }

  void _managePhotos() {
    final s = AppLocalizations.of(context);
    _push(
      Scaffold(
        appBar: AppBar(title: Text(s.managePhotos)),
        body: CenteredContent(child: PhotosSection(controller: _media)),
      ),
    );
  }

  Future<void> _verifyPhoto() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationScreen(
          uid: _uid,
          service: _photos,
          picker: PreviewPicker(),
        ),
      ),
    );
    if (result != null) _media.verificationSubmitted(result);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final pages = [
      DiscoverView(
        discovery: _discovery,
        interests: _interests,
        onOpenProfile: () => _select(3),
        onViewMatches: () => _select(2),
        conceptFor: (uid) => previewMember(uid)?.concept,
        notifications: ActivityBell(
          activity: _activity,
          onPressed: () => _push(
            ActivityScreen(
              activity: _activity,
              discovery: _discovery,
              onOpen: (item) {
                Navigator.of(context).pop();
                _openActivityItem(item);
              },
            ),
          ),
        ),
      ),
      LikesView(
        interests: _interests,
        discovery: _discovery,
        openMember: _openMember,
        onBrowse: () => _select(0),
      ),
      ChatsView(
        chats: _chats,
        interests: _interests,
        discovery: _discovery,
        wali: _wali,
        openChat: _openChat,
        openMember: _openMember,
        onBrowse: () => _select(0),
      ),
      ProfileHomeView(
        uid: _uid,
        complete: _profile,
        media: _media,
        emailVerified: _account.emailVerified,
        discovery: _discovery,
        membership: _membership,
        moderation: _moderation,
        share: (_) async => _notAvailable(),
        onPreview: _previewOwn,
        onEdit: _edit,
        onManagePhotos: _managePhotos,
        onVerifyEmail: _notAvailable,
        onVerifyPhoto: _verifyPhoto,
        onSignOut: _notAvailable,
        onDeleteAccount: _notAvailable,
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([_interests, _chats]),
        builder: (context, _) {
          final matched = {for (final e in _interests.matches) e.card.uid};
          final talking = {for (final c in _chats.conversations) c.otherUid};
          final chatCount =
              _chats.unreadAmong(matched) + matched.difference(talking).length;
          final likes = _interests.received.length;
          Widget badged(IconData icon, int count, String label) => Badge(
            isLabelVisible: count > 0,
            label: Text('$count', semanticsLabel: label),
            child: Icon(icon),
          );
          return NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: _select,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.explore_outlined),
                selectedIcon: const Icon(Icons.explore),
                label: s.navDiscover,
              ),
              NavigationDestination(
                icon: badged(
                  Icons.favorite_border,
                  likes,
                  s.likesNewCount(likes),
                ),
                selectedIcon: badged(
                  Icons.favorite,
                  likes,
                  s.likesNewCount(likes),
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
          );
        },
      ),
    );
  }
}
