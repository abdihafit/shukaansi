import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Records which version of the Terms of Use and Privacy Policy a member
/// accepted, in consents/{uid}.
abstract class ConsentService {
  /// The accepted version, or null if the member never accepted.
  Future<int?> acceptedVersion(String uid);
  Future<void> accept(String uid, int version);
  Future<void> delete(String uid);
}

class ConsentException implements Exception {
  const ConsentException();
}

class UnavailableConsentService implements ConsentService {
  const UnavailableConsentService();
  @override
  Future<int?> acceptedVersion(String uid) async =>
      throw const ConsentException();
  @override
  Future<void> accept(String uid, int version) async =>
      throw const ConsentException();
  @override
  Future<void> delete(String uid) async => throw const ConsentException();
}

class FirestoreConsentService implements ConsentService {
  FirestoreConsentService(this._store, this._auth);
  final FirebaseFirestore _store;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _store.collection('consents').doc(uid);

  Future<T> _owned<T>(String uid, Future<T> Function() operation) async {
    if (_auth.currentUser?.uid != uid) throw const ConsentException();
    try {
      return await operation();
    } catch (_) {
      throw const ConsentException();
    }
  }

  @override
  Future<int?> acceptedVersion(String uid) => _owned(uid, () async {
    final snapshot = await _doc(uid)
        .get(const GetOptions(source: Source.server));
    final version = snapshot.data()?['legalVersion'];
    return version is int ? version : null;
  });

  @override
  Future<void> accept(String uid, int version) => _owned(
    uid,
    () => _doc(uid).set({
      'schemaVersion': 1,
      'legalVersion': version,
      'acceptedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> delete(String uid) => _owned(uid, () => _doc(uid).delete());
}
