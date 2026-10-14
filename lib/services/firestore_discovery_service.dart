import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/discovery.dart';
import '../models/interest.dart';
import '../models/membership.dart';
import 'discovery_service.dart';
import 'photo_files.dart';

class FirestoreDiscoveryService implements DiscoveryService {
  FirestoreDiscoveryService(this._store, this._auth, this._files);
  final FirebaseFirestore _store;
  final FirebaseAuth _auth;
  final PhotoFileStore _files;

  static const _pageSize = 20;
  static const _vipFirst = 10;
  static const _server = GetOptions(source: Source.server);

  /// Profile answers copied verbatim into the listing; rules compare them.
  static const _answers = [
    'name', 'gender', 'nationality', 'residenceCountry', 'city', 'ethnicity', //
    'ethnicityOther', 'profession', 'professionOther', 'education',
    'practice', 'marriageTimeline', 'relocation', 'maritalStatus', 'about',
  ];

  CollectionReference<Map<String, dynamic>> get _listings =>
      _store.collection('publicProfiles');
  DocumentReference<Map<String, dynamic>> _request(String owner, String v) =>
      _store.collection('photoRequests').doc(owner).collection('items').doc(v);
  DocumentReference<Map<String, dynamic>> _access(String owner, String v) =>
      _store.collection('photoAccess').doc(owner).collection('items').doc(v);

  void _checkUser(String uid) {
    if (uid.isEmpty || _auth.currentUser?.uid != uid) {
      throw const DiscoveryException();
    }
  }

  Future<T> _guard<T>(String uid, Future<T> Function() operation) async {
    try {
      _checkUser(uid);
      return await operation();
    } catch (_) {
      throw const DiscoveryException();
    }
  }

  @override
  Future<ListingStatus> syncListing(String uid) => _guard(uid, () async {
    final user = _auth.currentUser!;
    // Refresh so a just-verified email reaches the security rules.
    await user.reload();
    final refreshed = _auth.currentUser!;
    await refreshed.getIdToken(true);
    final profile = (await _store.doc('profiles/$uid').get(_server)).data();
    final account = (await _store.doc('privateAccounts/$uid').get(_server))
        .data();
    final photos = (await _store.doc('profilePhotos/$uid').get(_server)).data();
    final verification = (await _store.doc('verifications/$uid').get(_server))
        .data();
    final membership = Membership.fromMap(
      (await _store.doc('memberships/$uid').get(_server)).data(),
    );
    if (profile == null || account == null) throw const DiscoveryException();
    final photoIds = (photos?['photoIds'] as List?)?.cast<String>() ?? [];
    final missing = {
      if (!refreshed.emailVerified) ListingGap.emailNotVerified,
      if (photoIds.isEmpty) ListingGap.noPhoto,
    };
    if (missing.isNotEmpty) {
      await _listings.doc(uid).delete();
      return ListingStatus(missing);
    }
    final birth = (account['birthDate'] as Timestamp).toDate().toUtc();
    await _listings.doc(uid).set({
      'schemaVersion': 1,
      for (final key in _answers) key: profile[key],
      'birthYearMonth': birth.year * 100 + birth.month,
      'photoIds': photoIds,
      'photosBlurred': photos?['blurred'] == true,
      'verified': verification?['status'] == 'verified',
      // When the member joined, for the "New members" feed.
      'joinedAt': profile['createdAt'],
      // VIP members are shown first in "For you" (rules check it is current).
      'vip': membership.planOn(DateTime.now()) == MembershipPlan.vip,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return const ListingStatus({});
  });

  DocumentReference<Map<String, dynamic>> _preferences(String uid) =>
      _store.collection('partnerPreferences').doc(uid);

  @override
  Future<DiscoveryFilter?> loadPreferences(String uid) => _guard(uid, () async {
    final data = (await _preferences(uid).get(_server)).data();
    return data == null ? null : DiscoveryFilter.fromMap(data);
  });

  @override
  Future<void> savePreferences(String uid, DiscoveryFilter preferences) =>
      _guard(
        uid,
        () => _preferences(uid).set({
          'schemaVersion': 1,
          ...preferences.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        }),
      );

  @override
  Future<DiscoveryPage> browse(
    String uid,
    DiscoveryFilter filter, {
    Object? after,
    DiscoverFeed feed = DiscoverFeed.forYou,
  }) => _guard(uid, () async {
    final mine = (await _listings.doc(uid).get(_server)).data();
    if (mine == null) throw const DiscoveryException();
    final newest = feed == DiscoverFeed.newMembers;
    if (newest) filter = const DiscoveryFilter();
    Query<Map<String, dynamic>> base() {
      // The rules only allow queries that filter on the opposite gender.
      var query = _listings.where(
        'gender',
        isEqualTo: mine['gender'] == 'male' ? 'female' : 'male',
      );
      final countries = filter.countries.toList();
      if (countries.length == 1) {
        query = query.where('residenceCountry', isEqualTo: countries.single);
      } else if (countries.isNotEmpty) {
        query = query.where('residenceCountry', whereIn: countries);
      }
      return query;
    }

    // VIP priority placement: the first "For you" page opens with VIPs.
    final vipDocs = !newest && after == null
        ? (await base()
                  .where('vip', isEqualTo: true)
                  .orderBy('updatedAt', descending: true)
                  .limit(_vipFirst)
                  .get(_server))
              .docs
        : const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    // Listings from before join dates were recorded appear in "New members"
    // once their owner's app updates them.
    var query = base()
        .orderBy(newest ? 'joinedAt' : 'updatedAt', descending: true)
        .limit(_pageSize);
    if (after is DocumentSnapshot) query = query.startAfterDocument(after);
    final result = await query.get(_server);
    final today = DateTime.now();
    final cards = <ProfileCard>[];
    final vipIds = {for (final d in vipDocs) d.id};
    for (final doc in [
      ...vipDocs,
      ...result.docs.where((d) => !vipIds.contains(d.id)),
    ]) {
      try {
        final card = ProfileCard.fromMap(doc.id, doc.data());
        if (filter.matches(card, today)) cards.add(card);
      } on Object {
        // Skip malformed listings rather than failing the page.
      }
    }
    return DiscoveryPage(
      cards,
      cursor: result.docs.isEmpty ? after : result.docs.last,
      hasMore: result.docs.length == _pageSize,
    );
  });

  @override
  Future<Uint8List> photo(
    String ownerUid,
    String photoId, {
    bool blurred = false,
  }) => _guard(
    _auth.currentUser?.uid ?? '',
    () => _files.get(
      blurred ? PhotoKind.blurred : PhotoKind.profile,
      ownerUid,
      photoId,
    ),
  );

  @override
  Future<PhotoAccess> photoAccess(String viewerUid, String ownerUid) =>
      _guard(viewerUid, () async {
        if ((await _access(ownerUid, viewerUid).get(_server)).exists) {
          return PhotoAccess.granted;
        }
        // A match also lets both members see each other's photos.
        final match = _store.doc('matches/${matchIdFor(viewerUid, ownerUid)}');
        if ((await match.get(_server)).exists) return PhotoAccess.granted;
        return (await _request(ownerUid, viewerUid).get(_server)).exists
            ? PhotoAccess.requested
            : PhotoAccess.none;
      });

  @override
  Future<void> requestPhotos(String viewerUid, String ownerUid) =>
      _guard(viewerUid, () async {
        await _request(
          ownerUid,
          viewerUid,
        ).set({'createdAt': FieldValue.serverTimestamp()});
      });

  @override
  Future<void> cancelRequest(String viewerUid, String ownerUid) =>
      _guard(viewerUid, () => _request(ownerUid, viewerUid).delete());

  Future<List<ProfileCard>> _members(String ownerUid, String kind) =>
      _guard(ownerUid, () async {
        final items = await _store
            .collection(kind)
            .doc(ownerUid)
            .collection('items')
            .get(_server);
        final cards = <ProfileCard>[];
        for (final item in items.docs) {
          try {
            final data = (await _listings.doc(item.id).get(_server)).data();
            if (data != null) cards.add(ProfileCard.fromMap(item.id, data));
          } on Object {
            // Members who left Discover are not shown.
          }
        }
        return cards;
      });

  @override
  Future<List<ProfileCard>> photoRequests(String ownerUid) =>
      _members(ownerUid, 'photoRequests');

  @override
  Future<List<ProfileCard>> photoViewers(String ownerUid) =>
      _members(ownerUid, 'photoAccess');

  @override
  Future<void> approve(String ownerUid, String viewerUid) =>
      _guard(ownerUid, () async {
        final batch = _store.batch()
          ..set(_access(ownerUid, viewerUid), {
            'grantedAt': FieldValue.serverTimestamp(),
          })
          ..delete(_request(ownerUid, viewerUid));
        await batch.commit();
      });

  @override
  Future<void> decline(String ownerUid, String viewerUid) =>
      _guard(ownerUid, () => _request(ownerUid, viewerUid).delete());

  @override
  Future<void> revoke(String ownerUid, String viewerUid) =>
      _guard(ownerUid, () => _access(ownerUid, viewerUid).delete());
}
