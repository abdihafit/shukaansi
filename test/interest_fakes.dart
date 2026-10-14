import 'dart:async';

import 'package:shukaansi/models/discovery.dart';
import 'package:shukaansi/models/interest.dart';
import 'package:shukaansi/services/interest_service.dart';

/// In-memory likes and matches. [pool] supplies the cards for members the
/// viewer likes from Discover.
class TestInterests implements InterestService {
  TestInterests({
    this.received = const [],
    this.sent = const [],
    this.matches = const [],
    this.pool = const [],
  });
  List<ProfileCard> received;
  List<ProfileCard> sent;
  List<ProfileCard> matches;
  List<ProfileCard> pool;
  bool fail = false;
  int loads = 0;
  final calls = <String>[];
  final _changes = StreamController<void>.broadcast();

  /// Simulates a server change, e.g. someone else's like arriving.
  void emit() => _changes.add(null);

  @override
  Stream<void> changes(String uid) => _changes.stream;

  static final _at = DateTime(2026, 9, 29);
  List<InterestEntry> _entries(List<ProfileCard> cards) => [
    for (final c in cards) InterestEntry(c, _at),
  ];
  ProfileCard _card(String uid) => [
    ...pool,
    ...received,
    ...sent,
    ...matches,
  ].firstWhere((c) => c.uid == uid);
  List<ProfileCard> _without(List<ProfileCard> list, String uid) =>
      list.where((c) => c.uid != uid).toList();

  void _check() {
    if (fail) throw const InterestException();
  }

  @override
  Future<InterestSnapshot> load(String uid) async {
    loads++;
    _check();
    return InterestSnapshot(
      received: _entries(received),
      sent: _entries(sent),
      matches: _entries(matches),
    );
  }

  /// Either member has Premium, so a mutual like becomes a match.
  bool canMatch = true;

  @override
  Future<LikeResult> like(String uid, String other) async {
    _check();
    calls.add('like $other');
    final card = _card(other);
    if (received.any((c) => c.uid == other)) {
      if (!canMatch) {
        sent = [card, ..._without(sent, other)];
        return LikeResult.mutualNeedsPremium;
      }
      received = _without(received, other);
      matches = [card, ...matches];
      return LikeResult.matched;
    }
    sent = [card, ..._without(sent, other)];
    return LikeResult.liked;
  }

  @override
  Future<void> withdraw(String uid, String other) async {
    _check();
    calls.add('withdraw $other');
    sent = _without(sent, other);
  }

  @override
  Future<void> decline(String uid, String other) async {
    _check();
    calls.add('decline $other');
    received = _without(received, other);
  }

  @override
  Future<void> unmatch(String uid, String other) async {
    _check();
    calls.add('unmatch $other');
    matches = _without(matches, other);
  }

  @override
  Future<void> completeMatch(String uid, String other) async {
    _check();
    if (!canMatch) throw const InterestException();
    calls.add('complete $other');
    final card = _card(other);
    sent = _without(sent, other);
    received = _without(received, other);
    matches = [card, ...matches];
  }

  @override
  Future<void> deleteAll(String uid) async {
    _check();
    calls.add('deleteAll');
  }
}
