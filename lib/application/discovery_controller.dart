import 'package:flutter/foundation.dart';

import '../models/discovery.dart';
import '../models/moderation.dart';
import '../services/discovery_service.dart';
import '../services/moderation_service.dart';

/// State for the Discover tab: the owner's listing status, the feed, filters,
/// cached photos and photo-request standing for each member shown.
class DiscoveryController extends ChangeNotifier {
  DiscoveryController({
    required this.uid,
    required this.service,
    this.moderation = const UnavailableModerationService(),
    this.today,
  });
  final String uid;
  final DiscoveryService service;
  final ModerationService moderation;

  /// Members blocked by, or blocking, this member; never shown.
  Set<String> hidden = const {};

  /// Overrides the current date in tests.
  final DateTime? today;

  bool syncing = false;
  bool syncFailed = false;
  ListingStatus? status;
  List<ProfileCard> cards = const [];
  bool loadingPage = false;
  bool pageFailed = false;
  bool hasMore = false;
  Object? _cursor;

  /// The member's partner preferences; they choose the "For you" feed.
  DiscoveryFilter filter = const DiscoveryFilter();

  /// Whether preferences were ever saved; "For you" invites setting them.
  bool hasPreferences = false;
  bool _preferencesLoaded = false;
  DiscoverFeed feed = DiscoverFeed.forYou;

  final Map<String, Uint8List> images = {};
  final Set<String> imageFailed = {};
  final Set<String> _imagePending = {};
  final Map<String, PhotoAccess> access = {};
  final Set<String> accessBusy = {};
  String? requestFailedFor;

  /// Set when the owner's profile or photos change; the next visit re-syncs.
  bool _stale = true;
  bool _disposed = false;

  DateTime get now => today ?? DateTime.now();
  bool get listed => status?.listed ?? false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void markStale() => _stale = true;

  /// Re-syncs and reloads only if something changed or the owner is unlisted.
  Future<void> refreshIfNeeded() async {
    if (_stale || !listed) await refresh();
  }

  Future<void> refresh() async {
    if (syncing) return;
    syncing = true;
    syncFailed = false;
    _notify();
    try {
      status = await service.syncListing(uid);
      _stale = false;
      try {
        hidden = await moderation.hiddenMembers(uid);
      } catch (_) {
        // Rules still prevent blocked members from seeing each other.
      }
      if (!_preferencesLoaded) {
        try {
          final saved = await service.loadPreferences(uid);
          _preferencesLoaded = true;
          hasPreferences = saved != null;
          filter = saved ?? const DiscoveryFilter();
        } catch (_) {
          // Browse without preferences; they load on the next refresh.
        }
      }
    } catch (_) {
      syncFailed = true;
    } finally {
      syncing = false;
      _notify();
    }
    if (listed) await _loadFirst();
  }

  Future<void> _loadFirst() async {
    cards = const [];
    _cursor = null;
    hasMore = false;
    await loadMore(force: true);
  }

  Future<void> loadMore({bool force = false}) async {
    if (loadingPage || (!force && !hasMore)) return;
    loadingPage = true;
    pageFailed = false;
    _notify();
    try {
      final page = await service.browse(
        uid,
        filter,
        after: _cursor,
        feed: feed,
      );
      // VIPs shown first may come round again on later pages.
      final shown = {for (final c in cards) c.uid};
      cards = [
        ...cards,
        ...page.cards.where(
          (card) => !hidden.contains(card.uid) && shown.add(card.uid),
        ),
      ];
      _cursor = page.cursor;
      hasMore = page.hasMore;
    } catch (_) {
      pageFailed = true;
    } finally {
      loadingPage = false;
      _notify();
    }
  }

  /// Saves new partner preferences, then reloads "For you". Returns false if
  /// they could not be saved (the feed is left unchanged).
  Future<bool> savePreferences(DiscoveryFilter value) async {
    try {
      await service.savePreferences(uid, value);
    } catch (_) {
      return false;
    }
    filter = value;
    hasPreferences = true;
    _preferencesLoaded = true;
    _notify();
    if (listed && feed == DiscoverFeed.forYou) await _loadFirst();
    return true;
  }

  Future<void> showFeed(DiscoverFeed value) async {
    if (feed == value) return;
    feed = value;
    if (listed) await _loadFirst();
  }

  /// Originals are shown unless she blurs and has not approved this viewer.
  bool showsOriginals(ProfileCard card) =>
      !card.photosBlurred || access[card.uid] == PhotoAccess.granted;

  static String imageKey(ProfileCard card, String photoId, bool blurred) =>
      '${card.uid}/$photoId/${blurred ? 'b' : 'o'}';

  /// Starts loading an image if needed; listeners are told when it arrives.
  void ensureImage(ProfileCard card, String photoId) {
    // Wait until we know whether this viewer was approved, so only the copy
    // that will actually be shown is downloaded.
    if (card.photosBlurred && !access.containsKey(card.uid)) return;
    final blurred = !showsOriginals(card);
    final key = imageKey(card, photoId, blurred);
    if (images.containsKey(key) || !_imagePending.add(key)) return;
    imageFailed.remove(key);
    service
        .photo(card.uid, photoId, blurred: blurred)
        .then((bytes) => images[key] = bytes)
        .catchError((Object _) {
          imageFailed.add(key);
          return Uint8List(0);
        })
        .whenComplete(() {
          _imagePending.remove(key);
          _notify();
        });
  }

  /// Forgets the photo standing with [uid], e.g. after a match, so it is
  /// looked up again.
  void forgetAccess(String uid) {
    access.remove(uid);
    _notify();
  }

  void retryImage(ProfileCard card, String photoId) {
    imageFailed.remove(imageKey(card, photoId, !showsOriginals(card)));
    ensureImage(card, photoId);
  }

  /// Looks up whether this viewer asked for, or was given, her photos.
  void ensureAccess(ProfileCard card) {
    if (!card.photosBlurred ||
        access.containsKey(card.uid) ||
        !accessBusy.add(card.uid)) {
      return;
    }
    service
        .photoAccess(uid, card.uid)
        .then((value) => access[card.uid] = value)
        .catchError((Object _) => access[card.uid] = PhotoAccess.none)
        .whenComplete(() {
          accessBusy.remove(card.uid);
          _notify();
        });
  }

  Future<void> _changeRequest(
    ProfileCard card,
    Future<void> Function() action,
    PhotoAccess result,
  ) async {
    if (!accessBusy.add(card.uid)) return;
    requestFailedFor = null;
    _notify();
    try {
      await action();
      access[card.uid] = result;
    } catch (_) {
      requestFailedFor = card.uid;
    } finally {
      accessBusy.remove(card.uid);
      _notify();
    }
  }

  Future<void> requestPhotos(ProfileCard card) => _changeRequest(
    card,
    () => service.requestPhotos(uid, card.uid),
    PhotoAccess.requested,
  );

  Future<void> cancelRequest(ProfileCard card) => _changeRequest(
    card,
    () => service.cancelRequest(uid, card.uid),
    PhotoAccess.none,
  );

  /// Reports [card]; optionally blocks too. Returns false on failure.
  Future<bool> report(
    ProfileCard card,
    ReportReason reason,
    String note, {
    bool alsoBlock = false,
  }) async {
    try {
      await moderation.report(uid, card.uid, reason, note);
    } catch (_) {
      return false;
    }
    return !alsoBlock || await block(card);
  }

  /// Blocks [card] and removes it from the feed. Returns false on failure.
  Future<bool> block(ProfileCard card) async {
    try {
      await moderation.block(uid, card.uid, card.profile.name);
    } catch (_) {
      return false;
    }
    hidden = {...hidden, card.uid};
    cards = cards.where((c) => c.uid != card.uid).toList();
    _notify();
    return true;
  }
}
