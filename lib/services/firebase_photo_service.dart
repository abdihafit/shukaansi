import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/profile_media.dart';
import 'blur_thumbnail.dart';
import 'photo_files.dart';
import 'photo_service.dart';

/// Photo order and verification records in Firestore; image bytes in a
/// [PhotoFileStore] (Firestore documents now, Firebase Storage once enabled).
class FirebasePhotoService implements PhotoService {
  FirebasePhotoService(this._store, this._files, this._auth);
  final FirebaseFirestore _store;
  final PhotoFileStore _files;
  final FirebaseAuth _auth;

  void _checkOwner(String uid) {
    if (uid.isEmpty || _auth.currentUser?.uid != uid) {
      throw const PhotoException();
    }
  }

  Future<T> _owned<T>(String uid, Future<T> Function() operation) async {
    try {
      _checkOwner(uid);
      final result = await operation();
      _checkOwner(uid);
      return result;
    } catch (_) {
      throw const PhotoException();
    }
  }

  DocumentReference<Map<String, dynamic>> _photosDoc(String uid) =>
      _store.collection('profilePhotos').doc(uid);
  DocumentReference<Map<String, dynamic>> _verificationDoc(String uid) =>
      _store.collection('verifications').doc(uid);

  /// The public Discover listing. Any photo change removes it in the same
  /// write (the rules require this); Discover re-creates it from fresh data.
  DocumentReference<Map<String, dynamic>> _listingDoc(String uid) =>
      _store.collection('publicProfiles').doc(uid);

  Map<String, Object> _order(List<String> ids, Map<String, dynamic>? current) =>
      {
        'schemaVersion': 1,
        'photoIds': ids,
        if (current?['blurred'] == true) 'blurred': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Future<void> _uploadBlurCopy(String uid, String id, Uint8List bytes) async {
    final thumbnail = await blurThumbnail(bytes);
    await _files.put(PhotoKind.blurred, uid, id, thumbnail, 'image/png');
  }

  /// Firestore auto-IDs: 20 alphanumeric characters, as the rules require.
  String _newId() => _store.collection('profilePhotos').doc().id;

  static List<String> _ids(Map<String, dynamic>? data) =>
      (data?['photoIds'] as List?)?.cast<String>() ?? const [];

  static Verification _verification(Map<String, dynamic>? data) {
    final status = VerificationStatus.values
        .where((s) => s != VerificationStatus.none && s.name == data?['status'])
        .firstOrNull;
    final note = data?['reviewNote'];
    return status == null
        ? Verification.none
        : Verification(
            status,
            reviewNote: note is String && note.trim().isNotEmpty
                ? note.trim()
                : null,
          );
  }

  Future<void> _upload(
    PhotoKind kind,
    String uid,
    String id,
    Uint8List bytes,
    void Function(double progress)? onProgress,
  ) async {
    final contentType = imageContentType(bytes);
    if (contentType == null || !isAcceptedPhoto(bytes)) {
      throw const PhotoException();
    }
    await _files.put(kind, uid, id, bytes, contentType, onProgress: onProgress);
  }

  Future<void> _quietDelete(PhotoKind kind, String uid, String id) async {
    try {
      await _files.delete(kind, uid, id);
    } catch (_) {
      // Already gone or unreachable; an orphaned private file is harmless.
    }
  }

  @override
  Future<ProfileMedia> load(String uid) => _owned(uid, () async {
    // Server reads: a cache miss must not look like "no photos".
    const server = GetOptions(source: Source.server);
    final photos = await _photosDoc(uid).get(server);
    final verification = await _verificationDoc(uid).get(server);
    return ProfileMedia(
      photoIds: _ids(photos.data()),
      verification: _verification(verification.data()),
      blurred: photos.data()?['blurred'] == true,
    );
  });

  @override
  Future<Uint8List> download(String uid, String photoId) =>
      _owned(uid, () => _files.get(PhotoKind.profile, uid, photoId));

  @override
  Future<List<String>> addPhoto(
    String uid,
    Uint8List bytes, {
    void Function(double progress)? onProgress,
  }) => _owned(uid, () async {
    final id = _newId();
    await _upload(PhotoKind.profile, uid, id, bytes, onProgress);
    try {
      // Every photo gets a blurred copy, ready if she turns blurring on.
      await _uploadBlurCopy(uid, id, bytes);
      return await _store.runTransaction((tx) async {
        final current = (await tx.get(_photosDoc(uid))).data();
        final ids = _ids(current);
        if (ids.length >= maxPhotos) throw const PhotoException();
        final next = [...ids, id];
        tx.set(_photosDoc(uid), _order(next, current));
        tx.delete(_listingDoc(uid));
        return next;
      });
    } catch (_) {
      await _quietDelete(PhotoKind.profile, uid, id);
      await _quietDelete(PhotoKind.blurred, uid, id);
      rethrow;
    }
  });

  /// Writes a new order inside [tx]. Verification is tied to the main photo,
  /// so when the main photo changes the verification record is deleted in the
  /// same write (the rules require this). Returns the update and any selfie to
  /// clean up afterwards.
  Future<(PhotoUpdate, String?)> _saveOrder(
    Transaction tx,
    String uid,
    Map<String, dynamic>? photos,
    List<String> next,
  ) async {
    final current = _ids(photos);
    // Transactions must finish every read before writing.
    final verification = await tx.get(_verificationDoc(uid));
    final reset =
        mainPhotoOf(current) != mainPhotoOf(next) && verification.exists;
    tx.set(_photosDoc(uid), _order(next, photos));
    tx.delete(_listingDoc(uid));
    if (reset) tx.delete(_verificationDoc(uid));
    final selfie = verification.data()?['selfieId'];
    return (
      PhotoUpdate(next, verificationReset: reset),
      reset && selfie is String ? selfie : null,
    );
  }

  @override
  Future<PhotoUpdate> reorder(String uid, List<String> photoIds) =>
      _owned(uid, () async {
        final (update, selfie) = await _store.runTransaction((tx) async {
          final photos = (await tx.get(_photosDoc(uid))).data();
          final ids = _ids(photos);
          // Only a reordering of the same photos is accepted here.
          if (ids.length != photoIds.length ||
              !ids.toSet().containsAll(photoIds)) {
            throw const PhotoException();
          }
          return _saveOrder(tx, uid, photos, photoIds);
        });
        if (selfie != null) await _quietDelete(PhotoKind.selfie, uid, selfie);
        return update;
      });

  @override
  Future<PhotoUpdate> removePhoto(String uid, String photoId) => _owned(
    uid,
    () async {
      final (update, selfie) = await _store.runTransaction((tx) async {
        final photos = (await tx.get(_photosDoc(uid))).data();
        return _saveOrder(tx, uid, photos, [..._ids(photos)]..remove(photoId));
      });
      await _quietDelete(PhotoKind.profile, uid, photoId);
      await _quietDelete(PhotoKind.blurred, uid, photoId);
      if (selfie != null) await _quietDelete(PhotoKind.selfie, uid, selfie);
      return update;
    },
  );

  @override
  Future<void> setBlurred(String uid, bool blurred) => _owned(uid, () async {
    if (blurred) {
      // Photos added before blurring existed may lack a blurred copy.
      for (final id in _ids((await _photosDoc(uid).get()).data())) {
        try {
          await _files.get(PhotoKind.blurred, uid, id);
        } catch (_) {
          await _uploadBlurCopy(
            uid,
            id,
            await _files.get(PhotoKind.profile, uid, id),
          );
        }
      }
    }
    await _store.runTransaction((tx) async {
      final current = (await tx.get(_photosDoc(uid))).data();
      tx.set(_photosDoc(uid), {
        ..._order(_ids(current), current),
        'blurred': blurred,
      });
      tx.delete(_listingDoc(uid));
    });
  });

  @override
  Future<Verification> submitVerification(
    String uid,
    Uint8List selfie, {
    void Function(double progress)? onProgress,
  }) => _owned(uid, () async {
    final previous = (await _verificationDoc(uid).get()).data();
    // The gender routes the request to a matching reviewer; rules check it.
    final gender = (await _store.doc('profiles/$uid').get()).data()?['gender'];
    if (gender is! String) throw const PhotoException();
    final id = _newId();
    await _upload(PhotoKind.selfie, uid, id, selfie, onProgress);
    try {
      await _verificationDoc(uid).set({
        'schemaVersion': 1,
        'status': 'pending',
        'selfieId': id,
        'gender': gender,
        'submittedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      await _quietDelete(PhotoKind.selfie, uid, id);
      rethrow;
    }
    final old = previous?['selfieId'];
    if (old is String && old != id) {
      await _quietDelete(PhotoKind.selfie, uid, old);
    }
    return const Verification(VerificationStatus.pending);
  });

  @override
  Future<void> deleteAll(String uid) => _owned(uid, () async {
    final photos = await _photosDoc(uid).get();
    final verification = await _verificationDoc(uid).get();
    // Leave Discover first so nobody can load photos mid-deletion.
    await _listingDoc(uid).delete();
    for (final id in _ids(photos.data())) {
      await _quietDelete(PhotoKind.profile, uid, id);
      await _quietDelete(PhotoKind.blurred, uid, id);
    }
    final selfie = verification.data()?['selfieId'];
    if (selfie is String) await _quietDelete(PhotoKind.selfie, uid, selfie);
    final batch = _store.batch()
      ..delete(_photosDoc(uid))
      ..delete(_verificationDoc(uid));
    for (final kind in ['photoRequests', 'photoAccess']) {
      final items = await _store
          .collection(kind)
          .doc(uid)
          .collection('items')
          .get();
      for (final item in items.docs) {
        batch.delete(item.reference);
      }
    }
    await batch.commit();
  });
}
