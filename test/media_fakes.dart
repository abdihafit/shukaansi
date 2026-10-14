import 'dart:async';
import 'dart:typed_data';

import 'package:shukaansi/models/profile_media.dart';
import 'package:shukaansi/services/photo_picker.dart';
import 'package:shukaansi/services/photo_service.dart';

/// A valid 1x1 transparent PNG, so widget tests can decode it.
final png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

String photoId(int n) => 'Photo${'$n'.padLeft(15, '0')}';

class TestPhotos implements PhotoService {
  List<String> ids = [];
  Verification verification = Verification.none;
  bool failLoad = false;
  bool failUpload = false;
  bool failUpdate = false;
  bool failSubmit = false;
  bool failDeleteAll = false;
  bool blurred = false;
  bool failBlur = false;
  int uploads = 0;
  int submissions = 0;
  int deleteAlls = 0;
  List<String>? reordered;
  final calls = <String>[];

  @override
  Future<ProfileMedia> load(String uid) async {
    if (failLoad) throw const PhotoException();
    return ProfileMedia(
      photoIds: [...ids],
      verification: verification,
      blurred: blurred,
    );
  }

  @override
  Future<Uint8List> download(String uid, String id) async => png;

  @override
  Future<List<String>> addPhoto(
    String uid,
    Uint8List bytes, {
    void Function(double progress)? onProgress,
  }) async {
    uploads++;
    onProgress?.call(0.5);
    if (failUpload) throw const PhotoException();
    onProgress?.call(1);
    return ids = [...ids, photoId(ids.length + 1)];
  }

  /// Mirrors the service: a new main photo clears any verification.
  PhotoUpdate _save(List<String> next) {
    final reset =
        mainPhotoOf(ids) != mainPhotoOf(next) &&
        verification.status != VerificationStatus.none;
    ids = next;
    if (reset) verification = Verification.none;
    return PhotoUpdate([...next], verificationReset: reset);
  }

  @override
  Future<PhotoUpdate> reorder(String uid, List<String> photoIds) async {
    if (failUpdate) throw const PhotoException();
    reordered = photoIds;
    return _save([...photoIds]);
  }

  @override
  Future<PhotoUpdate> removePhoto(String uid, String id) async {
    if (failUpdate) throw const PhotoException();
    return _save([...ids]..remove(id));
  }

  @override
  Future<void> setBlurred(String uid, bool value) async {
    if (failBlur) throw const PhotoException();
    blurred = value;
  }

  @override
  Future<Verification> submitVerification(
    String uid,
    Uint8List selfie, {
    void Function(double progress)? onProgress,
  }) async {
    submissions++;
    onProgress?.call(0.5);
    if (failSubmit) throw const PhotoException();
    return verification = const Verification(VerificationStatus.pending);
  }

  @override
  Future<void> deleteAll(String uid) async {
    deleteAlls++;
    calls.add('photos.deleteAll');
    if (failDeleteAll) throw const PhotoException();
    ids = [];
  }
}

class TestPicker implements PhotoPicker {
  Uint8List? photo;
  Uint8List? selfie;
  bool fail = false;

  @override
  Future<Uint8List?> pickPhoto() async {
    if (fail) throw const PickerException();
    return photo;
  }

  @override
  Future<Uint8List?> takeSelfie() async {
    if (fail) throw const PickerException();
    return selfie;
  }
}
