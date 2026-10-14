import 'package:flutter/foundation.dart';

import '../models/profile_media.dart';
import '../services/photo_picker.dart';
import '../services/photo_service.dart';

enum MediaError {
  unsupported,
  uploadFailed,
  updateFailed,
  pickFailed,
  privacyFailed,
}

/// Photo order, cached image bytes, upload progress and verification state for
/// the signed-in owner. One operation runs at a time.
class MediaController extends ChangeNotifier {
  MediaController({
    required this.uid,
    required this.service,
    required this.picker,
  });
  final String uid;
  final PhotoService service;
  final PhotoPicker picker;

  bool loading = true;
  bool loadFailed = false;
  bool busy = false;
  List<String> photoIds = const [];
  Verification verification = Verification.none;

  /// Women only: photos are blurred in Discover until she approves a viewer.
  bool blurred = false;

  /// Increases whenever photos or their privacy change, so Discover knows to
  /// rebuild the owner's listing.
  int revision = 0;
  final Map<String, Uint8List> images = {};
  final Set<String> imageFailed = {};

  /// Local preview and progress (0..1) while a photo uploads.
  Uint8List? uploading;
  double? progress;
  MediaError? error;
  bool _disposed = false;

  bool get canAdd => !busy && !loading && photoIds.length < maxPhotos;
  bool get hasPhoto => photoIds.isNotEmpty;

  /// A pending or approved verification that a main-photo change would reset.
  bool get verificationActive =>
      verification.status == VerificationStatus.pending ||
      verification.status == VerificationStatus.verified;

  /// Whether making [id] main, or removing it, would change the main photo.
  bool changesMain(String id, {required bool removing}) =>
      removing ? mainPhotoOf(photoIds) == id : mainPhotoOf(photoIds) != id;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    loading = true;
    loadFailed = false;
    _notify();
    try {
      final media = await service.load(uid);
      photoIds = media.photoIds;
      verification = media.verification;
      blurred = media.blurred;
    } catch (_) {
      loadFailed = true;
    } finally {
      loading = false;
      _notify();
    }
    for (final id in photoIds) {
      _fetch(id);
    }
  }

  Future<void> _fetch(String id) async {
    if (images.containsKey(id)) return;
    imageFailed.remove(id);
    try {
      images[id] = await service.download(uid, id);
    } catch (_) {
      imageFailed.add(id);
    }
    _notify();
  }

  void retryImage(String id) => _fetch(id);

  Future<void> addPhoto() async {
    if (!canAdd) return;
    error = null;
    final Uint8List? bytes;
    try {
      bytes = await picker.pickPhoto();
    } on PickerException {
      error = MediaError.pickFailed;
      return _notify();
    }
    if (bytes == null) return;
    if (!isAcceptedPhoto(bytes)) {
      error = MediaError.unsupported;
      return _notify();
    }
    busy = true;
    uploading = bytes;
    progress = 0;
    _notify();
    try {
      final next = await service.addPhoto(
        uid,
        bytes,
        onProgress: (value) {
          progress = value;
          _notify();
        },
      );
      // The new photo is the one not already shown; reuse the local bytes.
      for (final id in next) {
        if (!photoIds.contains(id)) images[id] = bytes;
      }
      photoIds = next;
      revision++;
    } catch (_) {
      error = MediaError.uploadFailed;
    } finally {
      busy = false;
      uploading = null;
      progress = null;
      _notify();
    }
  }

  Future<void> _change(Future<PhotoUpdate> Function() action) async {
    if (busy) return;
    final previous = photoIds;
    busy = true;
    error = null;
    _notify();
    try {
      final update = await action();
      photoIds = update.photoIds;
      if (update.verificationReset) verification = Verification.none;
      revision++;
    } catch (_) {
      photoIds = previous;
      error = MediaError.updateFailed;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> makeMain(String id) => _change(
    () => service.reorder(uid, [id, ...photoIds.where((other) => other != id)]),
  );

  Future<void> remove(String id) => _change(() async {
    final update = await service.removePhoto(uid, id);
    images.remove(id);
    return update;
  });

  Future<void> setBlurred(bool value) async {
    if (busy || value == blurred) return;
    busy = true;
    error = null;
    _notify();
    try {
      await service.setBlurred(uid, value);
      blurred = value;
      revision++;
    } catch (_) {
      error = MediaError.privacyFailed;
    } finally {
      busy = false;
      _notify();
    }
  }

  void verificationSubmitted(Verification value) {
    verification = value;
    _notify();
  }
}
