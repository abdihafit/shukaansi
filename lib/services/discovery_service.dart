import 'dart:typed_data';

import '../models/discovery.dart';

class DiscoveryException implements Exception {
  const DiscoveryException();
}

/// Discover listings, browsing and photo permissions. Security rules decide
/// who may see what; this interface only expresses the user's intent.
abstract interface class DiscoveryService {
  /// Re-creates the owner's listing from their current records, or removes it
  /// when they are not yet eligible. Returns what is still missing.
  Future<ListingStatus> syncListing(String uid);

  /// Opposite-gender listings: for [DiscoverFeed.forYou] those matching
  /// [filter], most recently active first; for [DiscoverFeed.newMembers]
  /// everyone, newest members first ([filter] is ignored).
  Future<DiscoveryPage> browse(
    String uid,
    DiscoveryFilter filter, {
    Object? after,
    DiscoverFeed feed = DiscoverFeed.forYou,
  });

  /// The member's saved partner preferences, or null if never set.
  Future<DiscoveryFilter?> loadPreferences(String uid);
  Future<void> savePreferences(String uid, DiscoveryFilter preferences);

  /// A photo of another member: the original, or the tiny blurred copy.
  Future<Uint8List> photo(String ownerUid, String photoId, {bool blurred});

  Future<PhotoAccess> photoAccess(String viewerUid, String ownerUid);
  Future<void> requestPhotos(String viewerUid, String ownerUid);
  Future<void> cancelRequest(String viewerUid, String ownerUid);

  /// Members asking the owner to see her photos.
  Future<List<ProfileCard>> photoRequests(String ownerUid);

  /// Members the owner has allowed to see her photos.
  Future<List<ProfileCard>> photoViewers(String ownerUid);
  Future<void> approve(String ownerUid, String viewerUid);
  Future<void> decline(String ownerUid, String viewerUid);
  Future<void> revoke(String ownerUid, String viewerUid);
}

class UnavailableDiscoveryService implements DiscoveryService {
  const UnavailableDiscoveryService();
  static const _error = DiscoveryException();
  @override
  Future<ListingStatus> syncListing(String uid) async => throw _error;
  @override
  Future<DiscoveryPage> browse(
    String uid,
    DiscoveryFilter filter, {
    Object? after,
    DiscoverFeed feed = DiscoverFeed.forYou,
  }) async => throw _error;
  @override
  Future<DiscoveryFilter?> loadPreferences(String uid) async => throw _error;
  @override
  Future<void> savePreferences(String uid, DiscoveryFilter preferences) async =>
      throw _error;
  @override
  Future<Uint8List> photo(
    String ownerUid,
    String photoId, {
    bool blurred = false,
  }) async => throw _error;
  @override
  Future<PhotoAccess> photoAccess(String viewerUid, String ownerUid) async =>
      throw _error;
  @override
  Future<void> requestPhotos(String viewerUid, String ownerUid) async =>
      throw _error;
  @override
  Future<void> cancelRequest(String viewerUid, String ownerUid) async =>
      throw _error;
  @override
  Future<List<ProfileCard>> photoRequests(String ownerUid) async =>
      throw _error;
  @override
  Future<List<ProfileCard>> photoViewers(String ownerUid) async => throw _error;
  @override
  Future<void> approve(String ownerUid, String viewerUid) async => throw _error;
  @override
  Future<void> decline(String ownerUid, String viewerUid) async => throw _error;
  @override
  Future<void> revoke(String ownerUid, String viewerUid) async => throw _error;
}
