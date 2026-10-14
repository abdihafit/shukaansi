import 'package:flutter/foundation.dart';

import '../models/discovery.dart';
import '../models/wali.dart';
import '../services/seen_store.dart';
import 'chat_controller.dart';
import 'interest_controller.dart';
import 'wali_controller.dart';

enum ActivityKind {
  interest,
  match,
  yourWaliApproved,
  yourWaliDeclined,
  theirWaliApproved,
  theirWaliDeclined,
  message,
}

/// One notification, built from data the app already has.
class ActivityItem {
  const ActivityItem(this.id, this.kind, this.card, [this.at]);
  final String id;
  final ActivityKind kind;
  final ProfileCard card;

  /// When it happened, where known (guardian decisions carry no time here).
  final DateTime? at;
}

/// The notification list: new interest, matches, guardian decisions and
/// unread messages. "Seen" is remembered on the device. While the app is
/// open, [onFresh] is told about anything that newly appears.
class ActivityController extends ChangeNotifier {
  ActivityController({
    required this.uid,
    required this.interests,
    required this.chats,
    required this.seenStore,
    this.wali,
  }) {
    interests.addListener(_rebuild);
    chats.addListener(_rebuild);
    wali?.addListener(_rebuild);
    seenStore.read(uid).then((ids) {
      _seen = {..._seen, ...ids};
      _seenLoaded = true;
      _rebuild();
    });
  }
  final String uid;
  final InterestController interests;
  final ChatController chats;
  final WaliController? wali;
  final SeenStore seenStore;

  /// Called with the newest item that appeared while the app was open.
  ValueChanged<ActivityItem>? onFresh;

  /// Hides alerts for the conversation the member is reading.
  String? openChatWith;

  static const _maxRemembered = 500;
  List<ActivityItem> items = const [];
  Set<String> _seen = {};
  bool _seenLoaded = false;
  Set<String>? _known;
  bool _disposed = false;

  bool isNew(ActivityItem item) => !_seen.contains(item.id);
  int get newCount => _seenLoaded ? items.where(isNew).length : 0;

  void _rebuild() {
    if (_disposed) return;
    final matched = {for (final e in interests.matches) e.card.uid: e.card};
    final built = <ActivityItem>[
      for (final e in interests.received)
        ActivityItem('like:${e.card.uid}', ActivityKind.interest, e.card, e.at),
      for (final e in interests.matches)
        ActivityItem('match:${e.card.uid}', ActivityKind.match, e.card, e.at),
      ..._decisions(matched),
      for (final c in chats.conversations)
        if (c.unread && matched.containsKey(c.otherUid))
          ActivityItem(
            'msg:${c.otherUid}:${c.lastAt.millisecondsSinceEpoch}',
            ActivityKind.message,
            matched[c.otherUid]!,
            c.lastAt,
          ),
    ];
    // Undated guardian decisions first, then newest first.
    built.sort((a, b) {
      if (a.at == null || b.at == null) {
        return (a.at == null ? 0 : 1) - (b.at == null ? 0 : 1);
      }
      return b.at!.compareTo(a.at!);
    });
    items = built;
    _announce(built);
    notifyListeners();
  }

  Iterable<ActivityItem> _decisions(Map<String, ProfileCard> matched) sync* {
    final w = wali;
    if (w == null) return;
    for (final MapEntry(key: other, value: status) in w.mine.entries) {
      final card = matched[other];
      if (card == null || status == WaliDecision.pending) continue;
      yield ActivityItem(
        'wali-mine:$other:${status.name}',
        status == WaliDecision.approved
            ? ActivityKind.yourWaliApproved
            : ActivityKind.yourWaliDeclined,
        card,
      );
    }
    for (final MapEntry(key: other, value: status) in w.theirs.entries) {
      final card = matched[other];
      if (card == null || status == WaliDecision.pending) continue;
      yield ActivityItem(
        'wali-theirs:$other:${status.name}',
        status == WaliDecision.approved
            ? ActivityKind.theirWaliApproved
            : ActivityKind.theirWaliDeclined,
        card,
      );
    }
  }

  /// Alerts only for items that appear after the first complete load, so
  /// opening the app does not replay old news.
  void _announce(List<ActivityItem> built) {
    // Every source must have loaded once, or a late load (e.g. guardian
    // decisions) would be mistaken for news.
    final w = wali;
    final ready =
        _seenLoaded &&
        interests.loaded &&
        (chats.loaded || chats.failed) &&
        (w == null || w.loaded || w.loadFailed);
    if (!ready) return;
    final ids = {for (final i in built) i.id};
    final known = _known;
    _known = ids;
    if (known == null) return;
    for (final item in built) {
      if (known.contains(item.id) || !isNew(item)) continue;
      if (item.kind == ActivityKind.message && item.card.uid == openChatWith) {
        continue;
      }
      onFresh?.call(item);
      return;
    }
  }

  /// Marks everything currently listed as seen.
  Future<void> markAllSeen() async {
    final ids = {for (final i in items) i.id};
    if (ids.every(_seen.contains)) return;
    _seen = {..._seen, ...ids};
    if (_seen.length > _maxRemembered) {
      _seen = _seen.skip(_seen.length - _maxRemembered).toSet();
    }
    notifyListeners();
    await seenStore.write(uid, _seen);
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    interests.removeListener(_rebuild);
    chats.removeListener(_rebuild);
    wali?.removeListener(_rebuild);
    super.dispose();
  }
}
