import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/wali.dart';
import '../services/wali_service.dart';

/// Where a match stands with the guardians, from the viewer's side.
enum MatchApproval {
  /// Nobody needs to approve, or everyone has.
  ready,

  /// A sister without a guardian yet; she must add one first.
  needsYourWali,

  /// Waiting for the viewer's guardian.
  waitingYourWali,

  /// Waiting for the other member's guardian.
  waitingTheirWali,

  /// A guardian declined.
  declined,
}

/// The member's guardian, their invite and approvals for their matches.
class WaliController extends ChangeNotifier {
  WaliController({
    required this.uid,
    required this.service,
    required this.required,
  });
  final String uid;
  final WaliService service;

  /// Sisters must have a guardian.
  final bool required;

  WaliLink? link;
  WaliInvite? invite;
  Map<String, WaliDecision> mine = const {};
  Map<String, WaliDecision> theirs = const {};
  bool loading = false;
  bool loaded = false;
  bool loadFailed = false;
  bool busy = false;
  bool _disposed = false;

  StreamSubscription<void>? _watch;
  bool _reloadAgain = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Reloads when the guardian link or an approval changes on the server.
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

  Future<void> load() async {
    if (loading) return;
    loading = true;
    loadFailed = false;
    _notify();
    try {
      link = await service.link(uid);
      invite = link == null ? await service.invite(uid) : null;
      mine = await service.myDecisions(uid);
      theirs = await service.theirDecisions(uid);
      loaded = true;
    } catch (_) {
      loadFailed = true;
    } finally {
      loading = false;
      _notify();
    }
    if (_reloadAgain && !_disposed) {
      _reloadAgain = false;
      await load();
    }
  }

  /// Makes sure the guardian is asked about every current match.
  Future<void> syncRequests(Iterable<String> matchedUids) async {
    final wali = link;
    if (wali == null) return;
    final missing = matchedUids.where((u) => !mine.containsKey(u)).toList();
    if (missing.isEmpty) return;
    for (final other in missing) {
      try {
        await service.requestApproval(uid, other, wali.waliUid);
        mine = {...mine, other: WaliDecision.pending};
      } catch (_) {
        // Retried on the next load.
      }
    }
    _notify();
  }

  /// [otherRequired]: the other member must have a guardian too (a sister),
  /// so a missing request still means waiting.
  MatchApproval approvalFor(String other, {bool otherRequired = false}) {
    final my = mine[other];
    final their = theirs[other];
    if (my == WaliDecision.declined || their == WaliDecision.declined) {
      return MatchApproval.declined;
    }
    if (link == null && required) return MatchApproval.needsYourWali;
    if (link != null && my != WaliDecision.approved) {
      return MatchApproval.waitingYourWali;
    }
    if (their == WaliDecision.pending || (their == null && otherRequired)) {
      return MatchApproval.waitingTheirWali;
    }
    return MatchApproval.ready;
  }

  Future<bool> _act(Future<void> Function() action) async {
    if (busy) return false;
    busy = true;
    _notify();
    try {
      await action();
      return true;
    } catch (_) {
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<bool> createInvite(String memberName) => _act(() async {
    invite = await service.createInvite(uid, memberName);
  });

  Future<bool> removeWali() => _act(() async {
    await service.removeWali(uid);
    link = null;
    mine = const {};
  });
}
