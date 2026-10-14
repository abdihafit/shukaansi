import 'dart:async';
import 'dart:typed_data';

import '../models/chat.dart';
import '../models/discovery.dart';
import '../models/interest.dart';
import '../models/matrimonial_profile.dart';
import '../models/membership.dart';
import '../models/moderation.dart';
import '../models/profile_media.dart';
import '../models/wali.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/discovery_service.dart';
import '../services/interest_service.dart';
import '../services/membership_service.dart';
import '../services/moderation_service.dart';
import '../services/photo_picker.dart';
import '../services/photo_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../services/wali_service.dart';
import 'fixtures.dart';
import 'synthetic_photos.dart';

/// In-memory stand-ins for every backend service, used only by the
/// development preview. They never touch Firebase, the network, payments or
/// notifications, and they follow the same rules as the real services
/// (Premium on either side for a match, Wali approval before sisters can
/// message, private photos stay private).

/// Network-dependent calls honour the loading and failure scenarios.
Future<T> _online<T>(PreviewWorld world, T Function() result) async {
  switch (world.scenario) {
    case PreviewScenario.loading:
      return Completer<T>().future; // never completes: stays loading
    case PreviewScenario.networkError:
      throw const _Offline();
    default:
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return result();
  }
}

class _Offline implements Exception {
  const _Offline();
}

Uint8List _photoBytes(String id) {
  final viewer = viewerPhotoSpecs[id];
  if (viewer != null) return syntheticPortrait(viewer);
  final dash = id.lastIndexOf('-');
  final member = previewMember(id.substring(0, dash));
  final index = int.tryParse(id.substring(dash + 1)) ?? 1;
  final palette = member?.palette ?? previewMembers.first.palette;
  return syntheticPortrait(palette[(index - 1) % palette.length]);
}

class PreviewDiscovery implements DiscoveryService {
  PreviewDiscovery(this.world);
  final PreviewWorld world;
  final Map<String, PhotoAccess> _access = {};
  DiscoveryFilter? _saved;
  bool _savedOnce = false;
  Set<String> hidden = {};

  @override
  Future<ListingStatus> syncListing(String uid) => _online(world, () {
    if (world.scenario == PreviewScenario.incompleteProfile) {
      return const ListingStatus({
        ListingGap.emailNotVerified,
        ListingGap.noPhoto,
      });
    }
    return const ListingStatus({});
  });

  @override
  Future<DiscoveryPage> browse(
    String uid,
    DiscoveryFilter filter, {
    Object? after,
    DiscoverFeed feed = DiscoverFeed.forYou,
  }) => _online(world, () {
    if (world.scenario == PreviewScenario.noMatches) {
      return const DiscoveryPage([]);
    }
    final now = DateTime.now();
    final all = previewMembers
        .map((m) => m.card)
        .where((c) => !hidden.contains(c.uid));
    final cards = feed == DiscoverFeed.newMembers
        ? all.toList().reversed.toList()
        : all
              .where(
                (c) =>
                    filter.matches(c, now) &&
                    (filter.countries.isEmpty ||
                        filter.countries.contains(c.profile.residenceCountry)),
              )
              .toList();
    return DiscoveryPage(cards);
  });

  @override
  Future<Uint8List> photo(
    String ownerUid,
    String photoId, {
    bool blurred = false,
  }) async {
    final member = previewMember(ownerUid);
    // Never hand out an original that this viewer may not see.
    if (!blurred && member != null && member.card.photosBlurred) {
      if (_access[ownerUid] != PhotoAccess.granted) {
        throw const DiscoveryException();
      }
    }
    return _photoBytes(photoId);
  }

  @override
  Future<PhotoAccess> photoAccess(String viewerUid, String ownerUid) async =>
      _access[ownerUid] ?? PhotoAccess.none;

  @override
  Future<void> requestPhotos(String viewerUid, String ownerUid) async {
    _access[ownerUid] = PhotoAccess.requested;
  }

  @override
  Future<void> cancelRequest(String viewerUid, String ownerUid) async {
    _access.remove(ownerUid);
  }

  @override
  Future<List<ProfileCard>> photoRequests(String ownerUid) async => [];
  @override
  Future<List<ProfileCard>> photoViewers(String ownerUid) async => [];
  @override
  Future<void> approve(String ownerUid, String viewerUid) async {}
  @override
  Future<void> decline(String ownerUid, String viewerUid) async {}
  @override
  Future<void> revoke(String ownerUid, String viewerUid) async {}

  @override
  Future<DiscoveryFilter?> loadPreferences(String uid) => _online(world, () {
    if (_savedOnce) return _saved;
    if (world.scenario == PreviewScenario.preferencesNotSet) return null;
    return const DiscoveryFilter(minAge: 24, maxAge: 35);
  });

  @override
  Future<void> savePreferences(String uid, DiscoveryFilter preferences) async {
    _saved = preferences;
    _savedOnce = true;
  }
}

class PreviewInterests implements InterestService {
  PreviewInterests(this.world, this.memberships, this.walis) {
    if (!world.activityEmpty) {
      received = {'sagal', 'ladan'};
      sent = {'ifrah'};
      matches = {'amina', 'hodan', 'nasra'};
    }
  }
  final PreviewWorld world;
  final PreviewMemberships memberships;
  final PreviewWalis walis;
  Set<String> received = {};
  Set<String> sent = {};
  Set<String> matches = {};
  final _changes = StreamController<void>.broadcast();

  List<InterestEntry> _entries(Iterable<String> ids, int minutesAgo) => [
    for (final (i, id) in ids.indexed)
      if (previewMember(id) case final m?)
        InterestEntry(
          m.card,
          DateTime.now().subtract(Duration(minutes: minutesAgo + i * 90)),
        ),
  ];

  @override
  Future<InterestSnapshot> load(String uid) => _online(world, () {
    return InterestSnapshot(
      received: _entries(received.difference(matches), 40),
      sent: _entries(sent.difference(matches), 600),
      matches: _entries(matches, 1500),
    );
  });

  @override
  Stream<void> changes(String uid) => _changes.stream;

  bool _premium(String uid) =>
      memberships.plan != MembershipPlan.free ||
      (previewMember(uid)?.plan ?? MembershipPlan.free) != MembershipPlan.free;

  @override
  Future<LikeResult> like(String uid, String other) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    sent.add(other);
    if (!received.contains(other)) return LikeResult.liked;
    if (!_premium(other)) return LikeResult.mutualNeedsPremium;
    _match(other);
    return LikeResult.matched;
  }

  void _match(String other) {
    matches.add(other);
    // Her Wali is asked to approve before messaging can start.
    walis.theirs[other] = WaliDecision.pending;
  }

  @override
  Future<void> withdraw(String uid, String other) async => sent.remove(other);

  @override
  Future<void> decline(String uid, String other) async =>
      received.remove(other);

  @override
  Future<void> unmatch(String uid, String other) async {
    matches.remove(other);
    sent.remove(other);
    received.remove(other);
    walis.theirs.remove(other);
  }

  @override
  Future<void> completeMatch(String uid, String other) async {
    if (!_premium(other)) throw const InterestException();
    _match(other);
  }

  @override
  Future<void> deleteAll(String uid) async => throw const InterestException();
}

class PreviewChats implements ChatService {
  PreviewChats(this.world, this.interests, this.walis) {
    if (!world.activityEmpty) {
      final now = DateTime.now();
      for (final MapEntry(key: other, value: thread)
          in previewThreads.entries) {
        threads[other] = [
          for (final (i, (from, text, ago)) in thread.indexed)
            ChatMessage(
              id: '$other-$i',
              from: from,
              text: text,
              sentAt: now.subtract(Duration(minutes: ago)),
            ),
        ];
      }
      readAt['amina'] = now;
    }
  }
  final PreviewWorld world;
  final PreviewInterests interests;
  final PreviewWalis walis;
  final Map<String, List<ChatMessage>> threads = {};
  final Map<String, DateTime> readAt = {};
  final _changes = StreamController<void>.broadcast();
  var _replies = 0;

  List<ChatSummary> _summaries() => [
    for (final MapEntry(key: other, value: list) in threads.entries)
      if (list.isNotEmpty)
        ChatSummary(
          otherUid: other,
          lastText: messagePreview(list.last.text),
          lastFrom: list.last.from,
          lastAt: list.last.sentAt!,
          readAt: readAt[other],
        ),
  ]..sort((a, b) => b.lastAt.compareTo(a.lastAt));

  @override
  Stream<List<ChatSummary>> conversations(String uid) async* {
    if (world.scenario == PreviewScenario.networkError) {
      throw const ChatException();
    }
    yield _summaries();
    await for (final _ in _changes.stream) {
      yield _summaries();
    }
  }

  @override
  Stream<List<ChatMessage>> messages(String uid, String other) async* {
    yield [...?threads[other]];
    await for (final _ in _changes.stream) {
      yield [...?threads[other]];
    }
  }

  /// The same gate as the security rules: a match, and her Wali's approval.
  bool _allowed(String other) =>
      interests.matches.contains(other) &&
      walis.theirs[other] == WaliDecision.approved;

  @override
  Future<void> send(String uid, String other, String text) async {
    if (!_allowed(other)) throw const ChatException();
    (threads[other] ??= []).add(
      ChatMessage(
        id: 'sent-${DateTime.now().microsecondsSinceEpoch}',
        from: uid,
        text: text.trim(),
        sentAt: DateTime.now(),
      ),
    );
    readAt[other] = DateTime.now();
    _changes.add(null);
    // A simulated reply, so the conversation feels alive in the preview.
    Timer(const Duration(seconds: 2), () {
      if (!_allowed(other)) return;
      threads[other]!.add(
        ChatMessage(
          id: 'reply-${_replies++}',
          from: other,
          text: previewReplies[_replies % previewReplies.length],
          sentAt: DateTime.now(),
        ),
      );
      _changes.add(null);
    });
  }

  @override
  Future<void> markRead(String uid, String other) async {
    final last = threads[other]?.lastOrNull?.sentAt;
    if (last == null || readAt[other] == last) return;
    readAt[other] = last;
    _changes.add(null);
  }
}

class PreviewWalis implements WaliService {
  PreviewWalis(this.world) : theirs = world.walisFor();
  final PreviewWorld world;

  /// Decisions by the sisters' Walis about matches with the viewer.
  final Map<String, WaliDecision> theirs;
  WaliInvite? _invite;
  final _changes = StreamController<void>.broadcast();

  @override
  Future<WaliLink?> link(String uid) => _online(world, () => null);
  @override
  Future<WaliInvite?> invite(String uid) async => _invite;
  @override
  Future<WaliInvite> createInvite(String uid, String memberName) async =>
      _invite = WaliInvite(
        code: 'PRVW2345',
        expiresAt: DateTime.now().add(waliInviteValidity),
      );
  @override
  Future<void> removeWali(String uid) async {}
  @override
  Future<Map<String, WaliDecision>> myDecisions(String uid) async => {};
  @override
  Future<Map<String, WaliDecision>> theirDecisions(String uid) async =>
      Map.of(theirs);
  @override
  Future<void> requestApproval(
    String uid,
    String otherUid,
    String waliUid,
  ) async {}
  @override
  Stream<void> changes(String uid) => _changes.stream;
  @override
  Future<GuardianAccount?> guardian(String uid) async => null;
  @override
  Future<GuardianAccount> becomeGuardian(
    String uid,
    String name,
    String code,
  ) => throw const WaliException();
  @override
  Future<List<WaliRequest>> guardianRequests(String uid) async => [];
  @override
  Future<void> decide(String uid, WaliRequest request, bool approve) async {}
  @override
  Future<void> stopGuarding(String uid, String memberUid) async {}
  @override
  Future<void> deleteAll(String uid) async => throw const WaliException();
}

class PreviewMemberships implements MembershipService {
  PreviewMemberships(this.world);
  final PreviewWorld world;
  MembershipPlan get plan => world.viewerPlan;

  Membership get _current => plan == MembershipPlan.free
      ? Membership.free
      : Membership(
          plan,
          expiresAt: DateTime.now().add(const Duration(days: 30)),
        );

  @override
  Stream<Membership> watch(String uid) async* {
    yield _current;
    final changes = StreamController<Membership>();
    void listener() => changes.add(_current);
    world.addListener(listener);
    try {
      yield* changes.stream;
    } finally {
      world.removeListener(listener);
    }
  }
}

class PreviewModeration implements ModerationService {
  PreviewModeration(this.discovery);
  final PreviewDiscovery discovery;
  final Map<String, String> _blocked = {};
  final reports = <String>[];

  @override
  Future<AccountStatus> status(String uid) async => AccountStatus.active;
  @override
  Future<void> report(
    String reporterUid,
    String reportedUid,
    ReportReason reason,
    String note,
  ) async => reports.add('$reportedUid ${reason.name}');
  @override
  Future<void> block(String blockerUid, String blockedUid, String name) async {
    _blocked[blockedUid] = name;
    discovery.hidden = {...discovery.hidden, blockedUid};
  }

  @override
  Future<void> unblock(String blockerUid, String blockedUid) async {
    _blocked.remove(blockedUid);
    discovery.hidden = {...discovery.hidden}..remove(blockedUid);
  }

  @override
  Future<List<BlockedMember>> blocked(String uid) async => [
    for (final MapEntry(:key, :value) in _blocked.entries)
      BlockedMember(uid: key, name: value),
  ];
  @override
  Future<Set<String>> hiddenMembers(String uid) async => {..._blocked.keys};
}

class PreviewProfiles implements ProfileService {
  ProfileState stored = ProfileComplete(previewViewer, previewViewerDetails);

  @override
  Future<ProfileState> load(String uid) async => stored;
  @override
  Future<ProfileComplete> save(
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details, {
    required bool adultConfirmed,
  }) async => _store(profile, details);
  @override
  Future<ProfileComplete> update(
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details,
  ) async => _store(profile, details);

  ProfileComplete _store(MatrimonialProfile profile, PrivateDetails details) {
    final complete = ProfileComplete(profile, details);
    stored = complete;
    return complete;
  }

  @override
  Future<void> delete(String uid) async => throw const ProfileException();
}

class PreviewPhotos implements PhotoService {
  PreviewPhotos(this.world)
    : ids = world.scenario == PreviewScenario.incompleteProfile
          ? []
          : ['me-1', 'me-2'],
      verification = switch (world.scenario) {
        PreviewScenario.awaitingReview => const Verification(
          VerificationStatus.pending,
        ),
        PreviewScenario.incompleteProfile => Verification.none,
        _ => const Verification(VerificationStatus.verified),
      };
  final PreviewWorld world;
  List<String> ids;
  Verification verification;
  bool blurred = false;
  final Map<String, Uint8List> _added = {};

  @override
  Future<ProfileMedia> load(String uid) async => ProfileMedia(
    photoIds: [...ids],
    verification: verification,
    blurred: blurred,
  );
  @override
  Future<Uint8List> download(String uid, String photoId) async =>
      _added[photoId] ?? _photoBytes(photoId);
  @override
  Future<List<String>> addPhoto(
    String uid,
    Uint8List bytes, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
    final id = 'added-${ids.length + 1}';
    _added[id] = bytes;
    return ids = [...ids, id];
  }

  PhotoUpdate _save(List<String> next) {
    final reset =
        mainPhotoOf(ids) != mainPhotoOf(next) &&
        verification.status != VerificationStatus.none;
    ids = next;
    if (reset) verification = Verification.none;
    return PhotoUpdate([...next], verificationReset: reset);
  }

  @override
  Future<PhotoUpdate> reorder(String uid, List<String> photoIds) async =>
      _save([...photoIds]);
  @override
  Future<PhotoUpdate> removePhoto(String uid, String photoId) async =>
      _save([...ids]..remove(photoId));
  @override
  Future<void> setBlurred(String uid, bool value) async => blurred = value;
  @override
  Future<Verification> submitVerification(
    String uid,
    Uint8List selfie, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(1);
    return verification = const Verification(VerificationStatus.pending);
  }

  @override
  Future<void> deleteAll(String uid) async => throw const PhotoException();
}

/// "Picks" a synthetic photo instead of opening the gallery or camera.
class PreviewPicker implements PhotoPicker {
  @override
  Future<Uint8List?> pickPhoto() async => _photoBytes('me-2');
  @override
  Future<Uint8List?> takeSelfie() async => _photoBytes('me-1');
}

class PreviewAccount implements AccountService {
  PreviewAccount(this.world);
  final PreviewWorld world;
  @override
  String? get email => 'yusuf@example.com';
  @override
  bool get emailVerified => world.scenario != PreviewScenario.incompleteProfile;
  @override
  Future<bool> reloadEmailVerified() async => emailVerified;
  @override
  Future<void> sendEmailVerification() async {}
  @override
  Future<void> reauthenticate(String password) async =>
      throw const AuthServiceException(AuthFailure.unavailable);
  @override
  Future<void> deleteAccount() async =>
      throw const AuthServiceException(AuthFailure.unavailable);
}

class PreviewSession implements SessionService {
  @override
  bool get isConfigured => false;
  @override
  Stream<AccountSession?> get sessions =>
      Stream.value(const AccountSession(previewViewerUid));
  @override
  Future<void> signOut() async {}
  @override
  Future<void> register({required String email, required String password}) =>
      throw const AuthServiceException(AuthFailure.unavailable);
  @override
  Future<void> signIn({required String email, required String password}) =>
      throw const AuthServiceException(AuthFailure.unavailable);
}
