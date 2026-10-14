import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/discovery.dart';
import '../models/interest.dart';
import '../services/interest_service.dart';

/// Likes and matches for the signed-in member, shared by Discover, Likes and
/// Matches so every tab shows the same state.
class InterestController extends ChangeNotifier {
  InterestController({required this.uid, required this.service});
  final String uid;
  final InterestService service;

  InterestSnapshot snapshot = const InterestSnapshot();
  bool loading = false;
  bool loadFailed = false;
  bool loaded = false;

  /// Members with an action in flight.
  final Set<String> busy = {};

  /// The member whose last action failed, so the right card can say so.
  String? failedFor;

  /// Members hidden by a block; never shown in any list.
  Set<String> hidden = const {};
  bool _disposed = false;

  StreamSubscription<void>? _watch;
  bool _reloadAgain = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Reloads whenever likes or matches change on the server, so new
  /// interest and matches appear while the app is open.
  void watch() {
    _watch ??= service.changes(uid).listen((_) {
      if (loading) {
        _reloadAgain = true;
      } else {
        load();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _watch?.cancel();
    super.dispose();
  }

  List<InterestEntry> _visible(List<InterestEntry> list) =>
      list.where((e) => !hidden.contains(e.card.uid)).toList();
  List<InterestEntry> get received => _visible(snapshot.received);
  List<InterestEntry> get sent => _visible(snapshot.sent);
  List<InterestEntry> get matches => _visible(snapshot.matches);

  InterestState stateOf(String other) => snapshot.stateOf(other);

  Future<void> load() async {
    if (loading) return;
    loading = true;
    loadFailed = false;
    _notify();
    try {
      var result = await service.load(uid);
      // Two members who liked each other at the same moment both saved only
      // their like; complete those matches now.
      final likedBack = result.sent
          .where((s) => result.received.any((r) => r.card.uid == s.card.uid))
          .toList();
      // Pairs where neither has Premium stay unmatched until one upgrades.
      var completed = false;
      for (final entry in likedBack) {
        try {
          await service.completeMatch(uid, entry.card.uid);
          completed = true;
        } catch (_) {}
      }
      if (completed) result = await service.load(uid);
      snapshot = result;
      loaded = true;
    } catch (_) {
      loadFailed = true;
    } finally {
      loading = false;
      _notify();
    }
    if (_reloadAgain && !_disposed) {
      // A change arrived while loading; pick it up too.
      _reloadAgain = false;
      await load();
    }
  }

  Future<bool> _act(String other, Future<void> Function() action) async {
    if (!busy.add(other)) return false;
    failedFor = null;
    _notify();
    try {
      await action();
      return true;
    } catch (_) {
      failedFor = other;
      return false;
    } finally {
      busy.remove(other);
      _notify();
    }
  }

  List<InterestEntry> _without(List<InterestEntry> list, String other) =>
      list.where((e) => e.card.uid != other).toList();

  /// Called when two members like each other but neither has Premium.
  ValueChanged<ProfileCard>? onPremiumNeeded;

  /// Shows interest in [card]; null when it failed.
  Future<LikeResult?> like(ProfileCard card) async {
    LikeResult? result;
    final ok = await _act(card.uid, () async {
      result = await service.like(uid, card.uid);
      final matched = result == LikeResult.matched;
      final entry = InterestEntry(card, DateTime.now());
      snapshot = InterestSnapshot(
        // A mutual like without Premium stays in both lists.
        received: result == LikeResult.mutualNeedsPremium
            ? snapshot.received
            : _without(snapshot.received, card.uid),
        sent: matched
            ? _without(snapshot.sent, card.uid)
            : [entry, ..._without(snapshot.sent, card.uid)],
        matches: matched
            ? [entry, ..._without(snapshot.matches, card.uid)]
            : snapshot.matches,
      );
    });
    return ok ? result : null;
  }

  Future<bool> withdraw(ProfileCard card) => _act(card.uid, () async {
    await service.withdraw(uid, card.uid);
    snapshot = InterestSnapshot(
      received: snapshot.received,
      sent: _without(snapshot.sent, card.uid),
      matches: snapshot.matches,
    );
  });

  Future<bool> decline(ProfileCard card) => _act(card.uid, () async {
    await service.decline(uid, card.uid);
    snapshot = InterestSnapshot(
      received: _without(snapshot.received, card.uid),
      sent: snapshot.sent,
      matches: snapshot.matches,
    );
  });

  Future<bool> unmatch(ProfileCard card) => _act(card.uid, () async {
    await service.unmatch(uid, card.uid);
    snapshot = InterestSnapshot(
      received: _without(snapshot.received, card.uid),
      sent: _without(snapshot.sent, card.uid),
      matches: _without(snapshot.matches, card.uid),
    );
  });

  /// Follows the blocked members known to Discover; the block itself already
  /// removed likes and the match on the server.
  void syncHidden(Set<String> value) {
    if (setEquals(hidden, value)) return;
    hidden = {...value};
    _notify();
  }
}
