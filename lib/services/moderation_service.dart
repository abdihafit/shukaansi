import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/interest.dart';
import 'chat_service.dart';
import '../models/moderation.dart';

class ModerationException implements Exception {
  const ModerationException();
}

/// Member-side safety tools: account status, reporting and blocking.
abstract interface class ModerationService {
  Future<AccountStatus> status(String uid);
  Future<void> report(
    String reporterUid,
    String reportedUid,
    ReportReason reason,
    String note,
  );

  /// Blocks [blockedUid] and withdraws any photo access or requests between
  /// the two members.
  Future<void> block(String blockerUid, String blockedUid, String blockedName);
  Future<void> unblock(String blockerUid, String blockedUid);
  Future<List<BlockedMember>> blocked(String uid);

  /// Everyone this member blocked or was blocked by; hidden from Discover.
  Future<Set<String>> hiddenMembers(String uid);
}

class UnavailableModerationService implements ModerationService {
  const UnavailableModerationService();
  static const _error = ModerationException();
  @override
  Future<AccountStatus> status(String uid) async => throw _error;
  @override
  Future<void> report(
    String reporterUid,
    String reportedUid,
    ReportReason reason,
    String note,
  ) async => throw _error;
  @override
  Future<void> block(
    String blockerUid,
    String blockedUid,
    String blockedName,
  ) async => throw _error;
  @override
  Future<void> unblock(String blockerUid, String blockedUid) async =>
      throw _error;
  @override
  Future<List<BlockedMember>> blocked(String uid) async => throw _error;
  @override
  Future<Set<String>> hiddenMembers(String uid) async => throw _error;
}

class FirestoreModerationService implements ModerationService {
  FirestoreModerationService(this._store, this._auth);
  final FirebaseFirestore _store;
  final FirebaseAuth _auth;
  static const _server = GetOptions(source: Source.server);

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _store.collection('blocks');

  Future<T> _guard<T>(String uid, Future<T> Function() operation) async {
    if (uid.isEmpty || _auth.currentUser?.uid != uid) {
      throw const ModerationException();
    }
    try {
      return await operation();
    } catch (_) {
      throw const ModerationException();
    }
  }

  @override
  Future<AccountStatus> status(String uid) => _guard(uid, () async {
    final data = (await _store.doc('accountStatus/$uid').get(_server)).data();
    if (data?['status'] != 'suspended') return AccountStatus.active;
    final reason = data?['reason'];
    return AccountStatus(
      suspended: true,
      reason: reason is String ? reason : '',
    );
  });

  @override
  Future<void> report(
    String reporterUid,
    String reportedUid,
    ReportReason reason,
    String note,
  ) => _guard(reporterUid, () async {
    await _store.collection('reports').add({
      'reporterUid': reporterUid,
      'reportedUid': reportedUid,
      'reason': reason.name,
      'note': note.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  });

  @override
  Future<void> block(
    String blockerUid,
    String blockedUid,
    String blockedName,
  ) => _guard(blockerUid, () async {
    // Their conversation ends with the block; removed before the match is.
    try {
      await deleteChat(_store, blockerUid, blockedUid);
    } catch (_) {
      // No match or no conversation: nothing to remove.
    }
    DocumentReference<Map<String, dynamic>> item(
      String kind,
      String a,
      String b,
    ) => _store.collection(kind).doc(a).collection('items').doc(b);
    final batch = _store.batch()
      ..set(_blocks.doc('${blockerUid}_$blockedUid'), {
        'blocker': blockerUid,
        'blocked': blockedUid,
        'blockedName': blockedName,
        'createdAt': FieldValue.serverTimestamp(),
      })
      // Photo permissions in either direction end with the block.
      ..delete(item('photoAccess', blockerUid, blockedUid))
      ..delete(item('photoRequests', blockerUid, blockedUid))
      ..delete(item('photoAccess', blockedUid, blockerUid))
      ..delete(item('photoRequests', blockedUid, blockerUid))
      // So do interests and any match.
      ..delete(_store.doc('likes/${blockerUid}_$blockedUid'))
      ..delete(_store.doc('likes/${blockedUid}_$blockerUid'))
      ..delete(_store.doc('matches/${matchIdFor(blockerUid, blockedUid)}'))
      ..delete(_store.doc('waliRequests/${blockerUid}_$blockedUid'))
      ..delete(_store.doc('waliRequests/${blockedUid}_$blockerUid'));
    await batch.commit();
  });

  @override
  Future<void> unblock(String blockerUid, String blockedUid) => _guard(
    blockerUid,
    () => _blocks.doc('${blockerUid}_$blockedUid').delete(),
  );

  @override
  Future<List<BlockedMember>> blocked(String uid) => _guard(uid, () async {
    final result = await _blocks.where('blocker', isEqualTo: uid).get(_server);
    return [
      for (final doc in result.docs)
        BlockedMember(
          uid: doc.data()['blocked'] as String,
          name: doc.data()['blockedName'] as String,
        ),
    ];
  });

  @override
  Future<Set<String>> hiddenMembers(String uid) => _guard(uid, () async {
    final mine = await _blocks.where('blocker', isEqualTo: uid).get(_server);
    final theirs = await _blocks.where('blocked', isEqualTo: uid).get(_server);
    return {
      for (final doc in mine.docs) doc.data()['blocked'] as String,
      for (final doc in theirs.docs) doc.data()['blocker'] as String,
    };
  });
}
