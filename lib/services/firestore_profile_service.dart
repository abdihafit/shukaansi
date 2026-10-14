import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/matrimonial_profile.dart';
import 'profile_service.dart';

class FirestoreProfileService implements ProfileService {
  FirestoreProfileService(this._store, this._auth);
  final FirebaseFirestore _store;
  final FirebaseAuth _auth;
  void _checkOwner(String uid) {
    if (uid.isEmpty || _auth.currentUser?.uid != uid) {
      throw const ProfileException();
    }
  }

  static ProfileComplete _complete(
    Map<String, dynamic> profile,
    Map<String, dynamic> account,
  ) {
    final birth = account['birthDate'];
    if (account['schemaVersion'] != profileSchemaVersion ||
        account['adultConfirmed'] != true ||
        birth is! Timestamp) {
      throw const ProfileException();
    }
    final details = PrivateDetails(
      birthDate: PrivateDetails.dateOnly(birth.toDate().toUtc()),
      phoneCountry: account['phoneCountry'] as String,
      phoneNumber: account['phoneNumber'] as String,
    );
    if (!details.isValid(DateTime.now())) throw const ProfileException();
    return ProfileComplete(MatrimonialProfile.fromMap(profile), details);
  }

  static bool _isLegacyPair(
    Map<String, dynamic> profile,
    Map<String, dynamic> account,
  ) =>
      profile['schemaVersion'] == 1 &&
      profile['onboardingComplete'] == true &&
      account['schemaVersion'] == 1 &&
      account['adultConfirmed'] == true;

  @override
  Future<ProfileState> load(String uid) async {
    try {
      _checkOwner(uid);
      // Server-only reads: offline/cache misses never masquerade as new users.
      final profile = await _store
          .collection('profiles')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      final account = await _store
          .collection('privateAccounts')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      _checkOwner(uid);
      if (!profile.exists && !account.exists) return const ProfileMissing();
      if (!profile.exists || !account.exists) throw const ProfileException();
      final p = profile.data()!;
      final a = account.data()!;
      if (_isLegacyPair(p, a)) {
        return ProfileNeedsUpdate(LegacyProfile.fromMap(p));
      }
      return _complete(p, a);
    } catch (_) {
      throw const ProfileException();
    }
  }

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _store.collection('profiles').doc(uid);
  DocumentReference<Map<String, dynamic>> _accountRef(String uid) =>
      _store.collection('privateAccounts').doc(uid);

  /// Writes both documents in one transaction; rules require the pair together.
  void _writePair(
    Transaction tx,
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details, {
    required Object profileCreated,
    required Object accountCreated,
  }) {
    tx.set(_accountRef(uid), {
      'schemaVersion': profileSchemaVersion,
      'adultConfirmed': true,
      'birthDate': Timestamp.fromDate(details.birthDate),
      'phoneCountry': details.phoneCountry,
      'phoneNumber': details.phoneNumber,
      'createdAt': accountCreated,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    tx.set(_profileRef(uid), {
      ...profile.toMap(),
      'createdAt': profileCreated,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Timestamp _createdAt(Map<String, dynamic> data) =>
      data['createdAt'] is Timestamp
      ? data['createdAt'] as Timestamp
      : throw const ProfileException();

  Future<T> _owned<T>(String uid, Future<T> Function() operation) async {
    try {
      _checkOwner(uid);
      final result = await operation();
      _checkOwner(uid);
      return result;
    } catch (_) {
      throw const ProfileException();
    }
  }

  @override
  Future<ProfileComplete> save(
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details, {
    required bool adultConfirmed,
  }) => _owned(uid, () {
    if (!adultConfirmed ||
        !profile.isValid ||
        !details.isValid(DateTime.now())) {
      throw const ProfileException();
    }
    return _store.runTransaction((tx) async {
      _checkOwner(uid);
      final existing = await tx.get(_profileRef(uid));
      final account = await tx.get(_accountRef(uid));
      Object profileCreated = FieldValue.serverTimestamp();
      Object accountCreated = FieldValue.serverTimestamp();
      if (existing.exists || account.exists) {
        final p = existing.data();
        final a = account.data();
        if (p == null || a == null) throw const ProfileException();
        // Deterministic UID documents make retries and concurrent completion safe.
        if (!_isLegacyPair(p, a)) return _complete(p, a);
        // Upgrading keeps the original creation times; rules enforce this.
        profileCreated = _createdAt(p);
        accountCreated = _createdAt(a);
      }
      _writePair(
        tx,
        uid,
        profile,
        details,
        profileCreated: profileCreated,
        accountCreated: accountCreated,
      );
      return ProfileComplete(profile, details);
    });
  });

  @override
  Future<ProfileComplete> update(
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details,
  ) => _owned(uid, () {
    if (!profile.isValid || !details.isValid(DateTime.now())) {
      throw const ProfileException();
    }
    return _store.runTransaction((tx) async {
      _checkOwner(uid);
      final p = (await tx.get(_profileRef(uid))).data();
      final a = (await tx.get(_accountRef(uid))).data();
      if (p == null || a == null) throw const ProfileException();
      final current = _complete(p, a);
      // Locked after creation; rules enforce the same.
      if (current.profile.gender != profile.gender ||
          current.details.birthDate != details.birthDate) {
        throw const ProfileException();
      }
      // The Discover listing is rebuilt from the edited answers.
      tx.delete(_store.collection('publicProfiles').doc(uid));
      _writePair(
        tx,
        uid,
        profile,
        details,
        profileCreated: _createdAt(p),
        accountCreated: _createdAt(a),
      );
      return ProfileComplete(profile, details);
    });
  });

  @override
  Future<void> delete(String uid) => _owned(uid, () async {
    final batch = _store.batch()
      ..delete(_profileRef(uid))
      ..delete(_accountRef(uid))
      // Partner preferences belong to the profile and go with it.
      ..delete(_store.collection('partnerPreferences').doc(uid));
    await batch.commit();
  });
}
