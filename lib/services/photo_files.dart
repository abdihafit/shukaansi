import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/profile_media.dart';

/// Profile photos, private verification selfies, and tiny blurred copies of
/// profile photos for viewers who may not see the originals.
enum PhotoKind { profile, selfie, blurred }

/// Where image bytes live. Photo order and verification state are separate;
/// switching stores does not change them.
abstract interface class PhotoFileStore {
  /// Writes a new file; existing files are never overwritten.
  Future<void> put(
    PhotoKind kind,
    String uid,
    String id,
    Uint8List bytes,
    String contentType, {
    void Function(double progress)? onProgress,
  });

  /// Reads a profile photo or blurred copy. Selfies are never readable.
  Future<Uint8List> get(PhotoKind kind, String uid, String id);

  Future<void> delete(PhotoKind kind, String uid, String id);
}

/// Free-plan store: each image is one owner-only Firestore document, so it
/// must stay under [maxPhotoBytes] (Firestore documents are capped at 1 MiB).
class FirestorePhotoFiles implements PhotoFileStore {
  FirestorePhotoFiles(this._store);
  final FirebaseFirestore _store;

  DocumentReference<Map<String, dynamic>> _doc(
    PhotoKind kind,
    String uid,
    String id,
  ) => _store
      .collection(switch (kind) {
        PhotoKind.profile => 'profilePhotoFiles',
        PhotoKind.selfie => 'verificationSelfieFiles',
        PhotoKind.blurred => 'profilePhotoBlurFiles',
      })
      .doc(uid)
      .collection('items')
      .doc(id);

  @override
  Future<void> put(
    PhotoKind kind,
    String uid,
    String id,
    Uint8List bytes,
    String contentType, {
    void Function(double progress)? onProgress,
  }) async {
    // A single document write has no partial progress to report.
    onProgress?.call(0);
    await _doc(kind, uid, id).set({
      'schemaVersion': 1,
      'contentType': contentType,
      'data': Blob(bytes),
      'createdAt': FieldValue.serverTimestamp(),
    });
    onProgress?.call(1);
  }

  @override
  Future<Uint8List> get(PhotoKind kind, String uid, String id) async {
    final data = (await _doc(
      kind,
      uid,
      id,
    ).get(const GetOptions(source: Source.server))).data();
    final blob = data?['data'];
    if (blob is! Blob) throw StateError('Missing photo');
    return blob.bytes;
  }

  @override
  Future<void> delete(PhotoKind kind, String uid, String id) =>
      _doc(kind, uid, id).delete();
}

/// Firebase Storage store (requires the Blaze plan and a default bucket).
class StoragePhotoFiles implements PhotoFileStore {
  StoragePhotoFiles(this._storage);
  final FirebaseStorage _storage;

  Reference _ref(PhotoKind kind, String uid, String id) =>
      _storage.ref(switch (kind) {
        PhotoKind.profile => 'profilePhotos/$uid/$id',
        PhotoKind.selfie => 'verificationSelfies/$uid/$id',
        PhotoKind.blurred => 'profilePhotoBlurred/$uid/$id',
      });

  @override
  Future<void> put(
    PhotoKind kind,
    String uid,
    String id,
    Uint8List bytes,
    String contentType, {
    void Function(double progress)? onProgress,
  }) async {
    final task = _ref(
      kind,
      uid,
      id,
    ).putData(bytes, SettableMetadata(contentType: contentType));
    final progress = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    }, onError: (_) {});
    try {
      await task;
    } finally {
      await progress.cancel();
    }
  }

  @override
  Future<Uint8List> get(PhotoKind kind, String uid, String id) async =>
      await _ref(kind, uid, id).getData(maxPhotoBytes) ??
      (throw StateError('Missing photo'));

  @override
  Future<void> delete(PhotoKind kind, String uid, String id) =>
      _ref(kind, uid, id).delete();
}
