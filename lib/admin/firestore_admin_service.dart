import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/matrimonial_profile.dart';
import '../models/membership.dart';
import '../models/moderation.dart';
import '../models/profile_media.dart';
import '../services/photo_files.dart';
import 'admin_service.dart';

class FirestoreAdminService implements AdminService {
  FirestoreAdminService(this._store, this._auth, this._files);
  final FirebaseFirestore _store;
  final FirebaseAuth _auth;
  final PhotoFileStore _files;
  static const _server = GetOptions(source: Source.server);

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (_) {
      throw const AdminException();
    }
  }

  static ProfileGender? _gender(Object? value) =>
      ProfileGender.values.where((g) => g.name == value).firstOrNull;

  static DateTime? _time(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  @override
  Stream<String?> get sessions => _auth.authStateChanges().map((u) => u?.uid);

  @override
  Future<void> signIn(String email, String password) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<StaffMember?> staff(String uid) => _guard(() async {
    final data = (await _store.doc('admins/$uid').get(_server)).data();
    final role = StaffRole.values
        .where((r) => r.name == data?['role'])
        .firstOrNull;
    if (role == null) return null;
    final gender = data?['reviewGender'];
    return StaffMember(
      uid: uid,
      role: role,
      reviewGender: gender is String ? gender : null,
    );
  });

  Query<Map<String, dynamic>> _pendingQuery(StaffMember me) {
    var query = _store
        .collection('verifications')
        .where('status', isEqualTo: 'pending');
    // Gender-limited reviewers must filter; the rules require it.
    if (me.role == StaffRole.reviewer && me.reviewGender != null) {
      query = query.where('gender', isEqualTo: me.reviewGender);
    }
    return query;
  }

  Future<int> _count(Query<Map<String, dynamic>> query) async =>
      (await query.count().get()).count ?? 0;

  @override
  Future<AdminCounts> counts(StaffMember me) => _guard(() async {
    final pending = me.canReview ? await _count(_pendingQuery(me)) : null;
    if (!me.canModerate) return AdminCounts(pendingVerifications: pending);
    return AdminCounts(
      members: await _count(_store.collection('profiles')),
      listed: await _count(_store.collection('publicProfiles')),
      pendingVerifications: pending,
      openReports: await _count(
        _store.collection('reports').where('status', isEqualTo: 'open'),
      ),
      suspended: await _count(
        _store
            .collection('accountStatus')
            .where('status', isEqualTo: 'suspended'),
      ),
    );
  });

  @override
  Future<List<VerificationRequest>> pendingVerifications(StaffMember me) =>
      _guard(() async {
        final result = await _pendingQuery(me).get(_server);
        final requests = <VerificationRequest>[];
        for (final doc in result.docs) {
          final data = doc.data();
          final profile = (await _store.doc('profiles/${doc.id}').get(_server))
              .data();
          final photos =
              (await _store.doc('profilePhotos/${doc.id}').get(_server)).data();
          requests.add(
            VerificationRequest(
              uid: doc.id,
              name: profile?['name'] as String? ?? doc.id,
              gender: _gender(profile?['gender'] ?? data['gender']),
              selfieId: data['selfieId'] as String,
              photoIds: (photos?['photoIds'] as List?)?.cast<String>() ?? [],
              submittedAt: _time(data['submittedAt']),
            ),
          );
        }
        requests.sort(
          (a, b) => (a.submittedAt ?? DateTime(0)).compareTo(
            b.submittedAt ?? DateTime(0),
          ),
        );
        return requests;
      });

  @override
  Future<Uint8List> selfie(String uid, String selfieId) =>
      _guard(() => _files.get(PhotoKind.selfie, uid, selfieId));

  @override
  Future<Uint8List> photo(String uid, String photoId) =>
      _guard(() => _files.get(PhotoKind.profile, uid, photoId));

  @override
  Future<void> decideVerification(
    StaffMember me,
    String uid, {
    required bool approve,
    String note = '',
  }) => _guard(() async {
    final batch = _store.batch()
      ..update(_store.doc('verifications/$uid'), {
        'status': approve ? 'verified' : 'rejected',
        'reviewNote': note.trim(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': me.uid,
      });
    // The member's app re-lists them with the new badge on its next visit.
    if (!approve) batch.delete(_store.doc('publicProfiles/$uid'));
    await batch.commit();
  });

  MemberSummary _summary(String uid, Map<String, dynamic> data) =>
      MemberSummary(
        uid: uid,
        name: data['name'] as String? ?? uid,
        gender: _gender(data['gender']),
        city: data['city'] as String? ?? '',
        country: data['residenceCountry'] as String? ?? '',
      );

  @override
  Future<List<MemberSummary>> searchMembers(String query) => _guard(() async {
    final profiles = _store.collection('profiles');
    final text = query.trim();
    if (text.isEmpty) {
      final recent = await profiles
          .orderBy('createdAt', descending: true)
          .limit(25)
          .get(_server);
      return [for (final d in recent.docs) _summary(d.id, d.data())];
    }
    final results = <MemberSummary>[];
    // Firebase user ids are 28 characters without spaces.
    if (!text.contains(' ') && text.length >= 20) {
      final byId = await profiles.doc(text).get(_server);
      if (byId.exists) results.add(_summary(byId.id, byId.data()!));
    }
    // Names are matched by prefix and case as typed, plus a capitalised form.
    final capitalised = text[0].toUpperCase() + text.substring(1);
    for (final prefix in {text, capitalised}) {
      final byName = await profiles
          .orderBy('name')
          .startAt([prefix])
          .endAt(['$prefix'])
          .limit(25)
          .get(_server);
      for (final d in byName.docs) {
        if (results.every((r) => r.uid != d.id)) {
          results.add(_summary(d.id, d.data()));
        }
      }
    }
    return results;
  });

  @override
  Future<MemberDetail> member(StaffMember me, String uid) => _guard(() async {
    final profile = (await _store.doc('profiles/$uid').get(_server)).data();
    if (profile == null) throw const AdminException();
    final photos = (await _store.doc('profilePhotos/$uid').get(_server)).data();
    final verification = (await _store.doc('verifications/$uid').get(_server))
        .data();
    final status = (await _store.doc('accountStatus/$uid').get(_server)).data();
    final listed = (await _store.doc('publicProfiles/$uid').get(_server))
        .exists;
    final membership = Membership.fromMap(
      (await _store.doc('memberships/$uid').get(_server)).data(),
    );
    Map<String, dynamic>? private;
    if (me.isAdmin) {
      private = (await _store.doc('privateAccounts/$uid').get(_server)).data();
    }
    final verificationStatus = VerificationStatus.values
        .where(
          (v) =>
              v != VerificationStatus.none && v.name == verification?['status'],
        )
        .firstOrNull;
    final note = verification?['reviewNote'];
    return MemberDetail(
      uid: uid,
      profile: MatrimonialProfile.fromMap(profile),
      photoIds: (photos?['photoIds'] as List?)?.cast<String>() ?? [],
      verification: verificationStatus == null
          ? Verification.none
          : Verification(
              verificationStatus,
              reviewNote: note is String && note.isNotEmpty ? note : null,
            ),
      status: AccountStatus(
        suspended: status?['status'] == 'suspended',
        reason: status?['reason'] as String? ?? '',
      ),
      listed: listed,
      membership: membership,
      birthDate: _time(private?['birthDate'])?.toUtc(),
      phoneNumber: private?['phoneNumber'] as String?,
    );
  });

  @override
  Future<void> setSuspended(
    StaffMember me,
    String uid, {
    required bool suspended,
    String reason = '',
  }) => _guard(() async {
    final batch = _store.batch()
      ..set(_store.doc('accountStatus/$uid'), {
        'status': suspended ? 'suspended' : 'active',
        'reason': reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': me.uid,
      });
    if (suspended) batch.delete(_store.doc('publicProfiles/$uid'));
    await batch.commit();
  });

  @override
  Future<void> unlist(String uid) =>
      _guard(() => _store.doc('publicProfiles/$uid').delete());

  @override
  Future<void> grantMembership(
    StaffMember me,
    String uid,
    MembershipPlan plan,
    DateTime until,
  ) => _guard(
    () => _store.doc('memberships/$uid').set({
      'plan': plan.name,
      'expiresAt': Timestamp.fromDate(until),
      'grantedBy': me.uid,
      'source': 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> endMembership(String uid) =>
      _guard(() => _store.doc('memberships/$uid').delete());

  @override
  Future<List<MembershipRow>> activeMemberships() => _guard(() async {
    final result = await _store
        .collection('memberships')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .get(_server);
    return [
      for (final doc in result.docs)
        MembershipRow(
          uid: doc.id,
          name: await _name(doc.id),
          membership: Membership.fromMap(doc.data()),
        ),
    ];
  });

  Future<String> _name(String uid) async {
    try {
      final data = (await _store.doc('profiles/$uid').get(_server)).data();
      return data?['name'] as String? ?? uid;
    } catch (_) {
      return uid;
    }
  }

  @override
  Future<List<ReportItem>> openReports() => _guard(() async {
    final result = await _store
        .collection('reports')
        .where('status', isEqualTo: 'open')
        .get(_server);
    final items = <ReportItem>[];
    for (final doc in result.docs) {
      final data = doc.data();
      final reporter = data['reporterUid'] as String;
      final reported = data['reportedUid'] as String;
      items.add(
        ReportItem(
          id: doc.id,
          reporterUid: reporter,
          reporterName: await _name(reporter),
          reportedUid: reported,
          reportedName: await _name(reported),
          reason: ReportReason.values.byName(data['reason'] as String),
          note: data['note'] as String? ?? '',
          createdAt: _time(data['createdAt']),
        ),
      );
    }
    items.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return items;
  });

  @override
  Future<void> resolveReport(
    StaffMember me,
    String reportId,
    ReportOutcome outcome,
    String resolution,
  ) => _guard(
    () => _store.doc('reports/$reportId').update({
      'status': outcome.name,
      'resolution': resolution.trim(),
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': me.uid,
    }),
  );
}
