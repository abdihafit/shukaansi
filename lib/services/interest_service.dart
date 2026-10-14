import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/discovery.dart';
import '../models/interest.dart';
import 'chat_service.dart';
import 'live_changes.dart';

class InterestException implements Exception {
  const InterestException();
}

/// Likes and mutual matches. Security rules decide what is allowed: a like
/// needs a member the liker may see, a match needs both likes.
abstract interface class InterestService {
  Future<InterestSnapshot> load(String uid);

  /// Fires when likes or matches involving [uid] change on the server.
  Stream<void> changes(String uid);

  /// Shows interest in [other]: a match when they already like the viewer
  /// and either has Premium; otherwise the like alone.
  Future<LikeResult> like(String uid, String other);

  /// Takes back the viewer's own interest.
  Future<void> withdraw(String uid, String other);

  /// Removes another member's interest in the viewer.
  Future<void> decline(String uid, String other);

  /// Ends a match and both interests behind it.
  Future<void> unmatch(String uid, String other);

  /// Creates a match whose likes already exist, e.g. after two members liked
  /// each other at the same moment.
  Future<void> completeMatch(String uid, String other);

  /// Removes every like and match involving [uid]; used on account deletion.
  Future<void> deleteAll(String uid);
}

class UnavailableInterestService implements InterestService {
  const UnavailableInterestService();
  static const _error = InterestException();
  @override
  Future<InterestSnapshot> load(String uid) async => throw _error;
  @override
  Stream<void> changes(String uid) => const Stream.empty();
  @override
  Future<LikeResult> like(String uid, String other) async => throw _error;
  @override
  Future<void> withdraw(String uid, String other) async => throw _error;
  @override
  Future<void> decline(String uid, String other) async => throw _error;
  @override
  Future<void> unmatch(String uid, String other) async => throw _error;
  @override
  Future<void> completeMatch(String uid, String other) async => throw _error;
  @override
  Future<void> deleteAll(String uid) async => throw _error;
}

class FirestoreInterestService implements InterestService {
  FirestoreInterestService(this._store, this._auth);
  final FirebaseFirestore _store;
  final FirebaseAuth _auth;
  static const _server = GetOptions(source: Source.server);

  CollectionReference<Map<String, dynamic>> get _likes =>
      _store.collection('likes');
  CollectionReference<Map<String, dynamic>> get _matches =>
      _store.collection('matches');
  DocumentReference<Map<String, dynamic>> _like(String from, String to) =>
      _likes.doc('${from}_$to');
  DocumentReference<Map<String, dynamic>> _match(String a, String b) =>
      _matches.doc(matchIdFor(a, b));

  Future<T> _guard<T>(String uid, Future<T> Function() operation) async {
    if (uid.isEmpty || _auth.currentUser?.uid != uid) {
      throw const InterestException();
    }
    try {
      return await operation();
    } catch (_) {
      throw const InterestException();
    }
  }

  Map<String, Object> _matchData(String a, String b) {
    final users = [a, b]..sort();
    return {'users': users, 'createdAt': FieldValue.serverTimestamp()};
  }

  DateTime _time(Map<String, dynamic> data) =>
      (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

  /// Listings the viewer may read; anyone else is left out.
  Future<Map<String, ProfileCard>> _cards(Iterable<String> uids) async {
    final cards = <String, ProfileCard>{};
    for (final uid in uids.toSet()) {
      try {
        final data = (await _store.doc('publicProfiles/$uid').get(_server))
            .data();
        if (data != null) cards[uid] = ProfileCard.fromMap(uid, data);
      } on Object {
        // Unlisted, blocked or suspended members are not shown.
      }
    }
    return cards;
  }

  @override
  Future<InterestSnapshot> load(String uid) => _guard(uid, () async {
    final sent = await _likes.where('from', isEqualTo: uid).get(_server);
    final received = await _likes.where('to', isEqualTo: uid).get(_server);
    final matches = await _matches
        .where('users', arrayContains: uid)
        .get(_server);
    final matched = {
      for (final m in matches.docs)
        (m.data()['users'] as List).cast<String>().firstWhere((u) => u != uid):
            _time(m.data()),
    };
    final sentTimes = {
      for (final d in sent.docs) d.data()['to'] as String: _time(d.data()),
    };
    final receivedTimes = {
      for (final d in received.docs)
        d.data()['from'] as String: _time(d.data()),
    };
    final cards = await _cards([
      ...matched.keys,
      ...sentTimes.keys,
      ...receivedTimes.keys,
    ]);
    List<InterestEntry> entries(Map<String, DateTime> times) => [
      for (final MapEntry(:key, :value) in times.entries)
        if (cards[key] != null) InterestEntry(cards[key]!, value),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return InterestSnapshot(
      matches: entries(matched),
      sent: entries({
        for (final e in sentTimes.entries)
          if (!matched.containsKey(e.key)) e.key: e.value,
      }),
      received: entries({
        for (final e in receivedTimes.entries)
          if (!matched.containsKey(e.key)) e.key: e.value,
      }),
    );
  });

  @override
  Stream<void> changes(String uid) => mergeChanges([
    _likes.where('to', isEqualTo: uid).snapshots(),
    _likes.where('from', isEqualTo: uid).snapshots(),
    _matches.where('users', arrayContains: uid).snapshots(),
  ]);

  @override
  Future<LikeResult> like(String uid, String other) => _guard(uid, () async {
    Map<String, Object> like() => {
      'from': uid,
      'to': other,
      'createdAt': FieldValue.serverTimestamp(),
    };
    try {
      final matched = await _store.runTransaction((tx) async {
        final reverse = await tx.get(_like(other, uid));
        tx.set(_like(uid, other), like());
        if (reverse.exists) {
          tx.set(_match(uid, other), _matchData(uid, other));
        }
        return reverse.exists;
      });
      return matched ? LikeResult.matched : LikeResult.liked;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
    // They like each other but neither has Premium: the rules refuse the
    // match, so keep the like on its own. It completes when either upgrades.
    await _like(uid, other).set(like());
    return LikeResult.mutualNeedsPremium;
  });

  @override
  Future<void> withdraw(String uid, String other) =>
      _guard(uid, () => _like(uid, other).delete());

  @override
  Future<void> decline(String uid, String other) =>
      _guard(uid, () => _like(other, uid).delete());

  @override
  Future<void> unmatch(String uid, String other) => _guard(uid, () async {
    // Messages first, while the match still lets the members reach them.
    await deleteChat(_store, uid, other);
    final batch = _store.batch()
      ..delete(_match(uid, other))
      ..delete(_like(uid, other))
      ..delete(_like(other, uid))
      // Any guardian approvals for this match end with it.
      ..delete(_store.doc('waliRequests/${uid}_$other'))
      ..delete(_store.doc('waliRequests/${other}_$uid'));
    await batch.commit();
  });

  @override
  Future<void> completeMatch(String uid, String other) =>
      _guard(uid, () => _match(uid, other).set(_matchData(uid, other)));

  @override
  Future<void> deleteAll(String uid) => _guard(uid, () async {
    final matches = await _matches
        .where('users', arrayContains: uid)
        .get(_server);
    for (final m in matches.docs) {
      final users = (m.data()['users'] as List).cast<String>();
      await deleteChat(_store, users[0], users[1]);
    }
    final batch = _store.batch();
    for (final query in [
      _likes.where('from', isEqualTo: uid),
      _likes.where('to', isEqualTo: uid),
      _matches.where('users', arrayContains: uid),
    ]) {
      for (final doc in (await query.get(_server)).docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  });
}
