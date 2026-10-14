import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/matrimonial_profile.dart';
import '../models/wali.dart';
import 'live_changes.dart';

class WaliException implements Exception {
  const WaliException();
}

/// The code is unknown, used or older than [waliInviteValidity].
class WaliCodeException extends WaliException {
  const WaliCodeException();
}

/// Wali (guardian) links, invites and match approvals. Security rules decide
/// what is allowed; see firestore.rules "Wali".
abstract interface class WaliService {
  // Member side.
  Future<WaliLink?> link(String uid);
  Future<WaliInvite?> invite(String uid);

  /// Replaces any earlier invite with a new code.
  Future<WaliInvite> createInvite(String uid, String memberName);

  /// Ends the link; the member's pending and decided requests go too, so a
  /// new guardian decides afresh.
  Future<void> removeWali(String uid);

  /// The member's own requests, by the other member's uid.
  Future<Map<String, WaliDecision>> myDecisions(String uid);

  /// Requests other members' guardians hold about this member, by their uid.
  Future<Map<String, WaliDecision>> theirDecisions(String uid);

  /// Asks the member's guardian about the match with [otherUid].
  Future<void> requestApproval(String uid, String otherUid, String waliUid);

  /// Fires when the member's guardian link or any approval about them
  /// changes on the server.
  Stream<void> changes(String uid);

  // Guardian side.
  Future<GuardianAccount?> guardian(String uid);
  Future<GuardianAccount> becomeGuardian(String uid, String name, String code);
  Future<List<WaliRequest>> guardianRequests(String uid);
  Future<void> decide(String uid, WaliRequest request, bool approve);
  Future<void> stopGuarding(String uid, String memberUid);

  /// Removes everything Wali-related for a member or guardian account.
  Future<void> deleteAll(String uid);
}

class UnavailableWaliService implements WaliService {
  const UnavailableWaliService();
  static const _e = WaliException();
  @override
  Future<WaliLink?> link(String uid) async => throw _e;
  @override
  Future<WaliInvite?> invite(String uid) async => throw _e;
  @override
  Future<WaliInvite> createInvite(String uid, String memberName) async =>
      throw _e;
  @override
  Future<void> removeWali(String uid) async => throw _e;
  @override
  Future<Map<String, WaliDecision>> myDecisions(String uid) async => throw _e;
  @override
  Future<Map<String, WaliDecision>> theirDecisions(String uid) async =>
      throw _e;
  @override
  Future<void> requestApproval(
    String uid,
    String otherUid,
    String waliUid,
  ) async => throw _e;
  @override
  Stream<void> changes(String uid) => const Stream.empty();
  @override
  Future<GuardianAccount?> guardian(String uid) async => throw _e;
  @override
  Future<GuardianAccount> becomeGuardian(
    String uid,
    String name,
    String code,
  ) async => throw _e;
  @override
  Future<List<WaliRequest>> guardianRequests(String uid) async => throw _e;
  @override
  Future<void> decide(String uid, WaliRequest request, bool approve) async =>
      throw _e;
  @override
  Future<void> stopGuarding(String uid, String memberUid) async => throw _e;
  @override
  Future<void> deleteAll(String uid) async => throw _e;
}

class FirestoreWaliService implements WaliService {
  FirestoreWaliService(this._store, this._auth);
  final FirebaseFirestore _store;
  final FirebaseAuth _auth;
  static const _server = GetOptions(source: Source.server);

  CollectionReference<Map<String, dynamic>> get _walis =>
      _store.collection('walis');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _store.collection('waliInvites');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _store.collection('waliRequests');
  DocumentReference<Map<String, dynamic>> _guardian(String uid) =>
      _store.collection('guardians').doc(uid);

  Future<T> _guard<T>(String uid, Future<T> Function() operation) async {
    if (uid.isEmpty || _auth.currentUser?.uid != uid) {
      throw const WaliException();
    }
    try {
      return await operation();
    } on WaliException {
      rethrow;
    } catch (_) {
      throw const WaliException();
    }
  }

  static WaliDecision _status(Object? value) => WaliDecision.values.firstWhere(
    (d) => d.name == value,
    orElse: () => WaliDecision.pending,
  );

  @override
  Future<WaliLink?> link(String uid) => _guard(uid, () async {
    final data = (await _walis.doc(uid).get(_server)).data();
    return data == null
        ? null
        : WaliLink(
            waliUid: data['waliUid'] as String,
            waliName: data['waliName'] as String,
          );
  });

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _myInvites(
    String uid,
  ) async =>
      (await _invites.where('memberUid', isEqualTo: uid).get(_server)).docs;

  @override
  Future<WaliInvite?> invite(String uid) => _guard(uid, () async {
    WaliInvite? latest;
    for (final doc in await _myInvites(uid)) {
      final created = (doc.data()['createdAt'] as Timestamp?)?.toDate();
      if (created == null) continue;
      final expires = created.add(waliInviteValidity);
      if (expires.isAfter(DateTime.now()) &&
          (latest == null || expires.isAfter(latest.expiresAt))) {
        latest = WaliInvite(code: doc.id, expiresAt: expires);
      }
    }
    return latest;
  });

  @override
  Future<WaliInvite> createInvite(String uid, String memberName) =>
      _guard(uid, () async {
        final batch = _store.batch();
        for (final old in await _myInvites(uid)) {
          batch.delete(old.reference);
        }
        final code = newWaliCode();
        batch.set(_invites.doc(code), {
          'memberUid': uid,
          'memberName': memberName,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
        return WaliInvite(
          code: code,
          expiresAt: DateTime.now().add(waliInviteValidity),
        );
      });

  @override
  Future<void> removeWali(String uid) => _guard(uid, () async {
    final mine = await _requests
        .where('memberUid', isEqualTo: uid)
        .get(_server);
    final batch = _store.batch()..delete(_walis.doc(uid));
    for (final doc in mine.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  });

  Future<Map<String, WaliDecision>> _decisions(
    String uid,
    String field,
    String key,
  ) => _guard(uid, () async {
    final result = await _requests.where(field, isEqualTo: uid).get(_server);
    return {
      for (final doc in result.docs)
        doc.data()[key] as String: _status(doc.data()['status']),
    };
  });

  @override
  Future<Map<String, WaliDecision>> myDecisions(String uid) =>
      _decisions(uid, 'memberUid', 'otherUid');

  @override
  Future<Map<String, WaliDecision>> theirDecisions(String uid) =>
      _decisions(uid, 'otherUid', 'memberUid');

  @override
  Future<void> requestApproval(String uid, String otherUid, String waliUid) =>
      _guard(uid, () async {
        final l = (await _store.doc('publicProfiles/$otherUid').get(_server))
            .data();
        if (l == null) throw const WaliException();
        await _requests.doc('${uid}_$otherUid').set({
          'memberUid': uid,
          'otherUid': otherUid,
          'waliUid': waliUid,
          'status': 'pending',
          // Rules check every field against the listing.
          'candidate': {for (final key in _candidateKeys) key: l[key]},
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

  @override
  Stream<void> changes(String uid) => mergeChanges([
    _walis.doc(uid).snapshots(),
    _requests.where('memberUid', isEqualTo: uid).snapshots(),
    _requests.where('otherUid', isEqualTo: uid).snapshots(),
  ]);

  static const _candidateKeys = [
    'name', 'birthYearMonth', 'city', 'residenceCountry', 'profession', //
    'professionOther', 'education', 'practice', 'maritalStatus', 'about',
    'verified',
  ];

  @override
  Future<GuardianAccount?> guardian(String uid) => _guard(uid, () async {
    final data = (await _guardian(uid).get(_server)).data();
    if (data == null) return null;
    final linked = await _walis.where('waliUid', isEqualTo: uid).get(_server);
    return GuardianAccount(
      name: data['name'] as String,
      members: [
        for (final doc in linked.docs)
          GuardedMember(uid: doc.id, name: doc.data()['memberName'] as String),
      ],
    );
  });

  @override
  Future<GuardianAccount> becomeGuardian(
    String uid,
    String name,
    String code,
  ) => _guard(uid, () async {
    final clean = cleanWaliCode(code);
    if (!isWaliCode(clean)) throw const WaliCodeException();
    final DocumentSnapshot<Map<String, dynamic>> invite;
    try {
      invite = await _invites.doc(clean).get(_server);
    } catch (_) {
      throw const WaliCodeException();
    }
    final data = invite.data();
    final created = (data?['createdAt'] as Timestamp?)?.toDate();
    if (data == null ||
        created == null ||
        created.add(waliInviteValidity).isBefore(DateTime.now())) {
      throw const WaliCodeException();
    }
    final memberUid = data['memberUid'] as String;
    if (memberUid == uid) throw const WaliCodeException();
    final existing = (await _guardian(uid).get(_server)).data();
    final waliName = (existing?['name'] as String?) ?? name.trim();
    final batch = _store.batch();
    if (existing == null) {
      batch.set(_guardian(uid), {
        'name': waliName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    batch
      ..set(_walis.doc(memberUid), {
        'waliUid': uid,
        'waliName': waliName,
        'memberName': data['memberName'],
        'inviteCode': clean,
        'linkedAt': FieldValue.serverTimestamp(),
      })
      ..delete(invite.reference);
    try {
      await batch.commit();
    } catch (_) {
      // Already has a guardian, or the code was just used.
      throw const WaliCodeException();
    }
    return (await guardian(uid))!;
  });

  @override
  Future<List<WaliRequest>> guardianRequests(String uid) => _guard(
    uid,
    () async {
      final result = await _requests
          .where('waliUid', isEqualTo: uid)
          .get(_server);
      final requests = <WaliRequest>[];
      for (final doc in result.docs) {
        try {
          final d = doc.data();
          final c = (d['candidate'] as Map).cast<String, dynamic>();
          requests.add(
            WaliRequest(
              memberUid: d['memberUid'] as String,
              otherUid: d['otherUid'] as String,
              waliUid: uid,
              status: _status(d['status']),
              candidate: MatchCandidate(
                name: c['name'] as String,
                birthYearMonth: c['birthYearMonth'] as int,
                city: c['city'] as String,
                residenceCountry: c['residenceCountry'] as String,
                profession: Profession.values.byName(c['profession']),
                professionOther: c['professionOther'] as String,
                education: EducationLevel.values.byName(c['education']),
                practice: PracticeLevel.values.byName(c['practice']),
                maritalStatus: MaritalStatus.values.byName(c['maritalStatus']),
                about: c['about'] as String,
                verified: c['verified'] == true,
              ),
            ),
          );
        } on Object {
          // Skip a malformed request rather than hiding all of them.
        }
      }
      return requests;
    },
  );

  @override
  Future<void> decide(String uid, WaliRequest request, bool approve) => _guard(
    uid,
    () => _requests.doc(request.id).update({
      'status': approve ? 'approved' : 'declined',
      'decidedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> stopGuarding(String uid, String memberUid) =>
      _guard(uid, () => _walis.doc(memberUid).delete());

  @override
  Future<void> deleteAll(String uid) => _guard(uid, () async {
    final batch = _store.batch()
      ..delete(_walis.doc(uid))
      ..delete(_guardian(uid));
    for (final query in [
      _invites.where('memberUid', isEqualTo: uid),
      _requests.where('memberUid', isEqualTo: uid),
      _requests.where('otherUid', isEqualTo: uid),
      _walis.where('waliUid', isEqualTo: uid),
    ]) {
      for (final doc in (await query.get(_server)).docs) {
        batch.delete(doc.reference);
      }
    }
    await batch.commit();
  });
}
