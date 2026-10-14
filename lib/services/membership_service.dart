import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/membership.dart';

/// The member's own plan. Only administrators write it (for now).
abstract interface class MembershipService {
  /// Current membership, updated live (e.g. when an admin grants one).
  Stream<Membership> watch(String uid);
}

class UnavailableMembershipService implements MembershipService {
  const UnavailableMembershipService();
  @override
  Stream<Membership> watch(String uid) => Stream.value(Membership.free);
}

class FirestoreMembershipService implements MembershipService {
  FirestoreMembershipService(this._store, this._auth);
  final FirebaseFirestore _store;
  final FirebaseAuth _auth;

  @override
  Stream<Membership> watch(String uid) {
    if (_auth.currentUser?.uid != uid) return Stream.value(Membership.free);
    return _store
        .doc('memberships/$uid')
        .snapshots()
        .map((s) => Membership.fromMap(s.data()))
        // Unreadable or offline: treat as free; the server decides anyway.
        .handleError((Object _) {});
  }
}
