import 'dart:typed_data';

import '../models/profile_media.dart';

class PhotoException implements Exception {
  const PhotoException();
}

/// Owner photos and verification requests. Implementations never expose
/// public download URLs; images are read through authenticated requests.
abstract interface class PhotoService {
  Future<ProfileMedia> load(String uid);

  Future<Uint8List> download(String uid, String photoId);

  /// Uploads [bytes] and appends it to the photo order; returns the new order.
  Future<List<String>> addPhoto(
    String uid,
    Uint8List bytes, {
    void Function(double progress)? onProgress,
  });

  /// Saves a new order for the same photos (first is the main photo).
  /// A new main photo clears any verification in the same write.
  Future<PhotoUpdate> reorder(String uid, List<String> photoIds);

  /// Removes a photo and deletes its file. Removing the main photo clears any
  /// verification in the same write.
  Future<PhotoUpdate> removePhoto(String uid, String photoId);

  /// Women only: blur photos in Discover until a viewer is approved.
  Future<void> setBlurred(String uid, bool blurred);

  /// Uploads a private selfie and requests review; returns the pending state.
  Future<Verification> submitVerification(
    String uid,
    Uint8List selfie, {
    void Function(double progress)? onProgress,
  });

  /// Deletes every photo, selfie, record, listing and photo permission; used
  /// when deleting the account.
  Future<void> deleteAll(String uid);
}

class UnavailablePhotoService implements PhotoService {
  const UnavailablePhotoService();
  static const _error = PhotoException();
  @override
  Future<ProfileMedia> load(String uid) async => throw _error;
  @override
  Future<Uint8List> download(String uid, String photoId) async => throw _error;
  @override
  Future<List<String>> addPhoto(
    String uid,
    Uint8List bytes, {
    void Function(double progress)? onProgress,
  }) async => throw _error;
  @override
  Future<PhotoUpdate> reorder(String uid, List<String> photoIds) async =>
      throw _error;
  @override
  Future<PhotoUpdate> removePhoto(String uid, String photoId) async =>
      throw _error;
  @override
  Future<void> setBlurred(String uid, bool blurred) async => throw _error;
  @override
  Future<Verification> submitVerification(
    String uid,
    Uint8List selfie, {
    void Function(double progress)? onProgress,
  }) async => throw _error;
  @override
  Future<void> deleteAll(String uid) async => throw _error;
}
