import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Thrown when the gallery or camera cannot be opened (often a permission).
class PickerException implements Exception {
  const PickerException();
}

abstract interface class PhotoPicker {
  /// A photo from the device gallery, or null if the user cancelled.
  Future<Uint8List?> pickPhoto();

  /// A new photo from the front camera, or null if the user cancelled.
  Future<Uint8List?> takeSelfie();
}

/// Resizes and re-encodes on the device before upload, keeping files small.
class DevicePhotoPicker implements PhotoPicker {
  DevicePhotoPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  Future<Uint8List?> _pick(ImageSource source, CameraDevice camera) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        preferredCameraDevice: camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      return await file?.readAsBytes();
    } catch (_) {
      throw const PickerException();
    }
  }

  @override
  Future<Uint8List?> pickPhoto() =>
      _pick(ImageSource.gallery, CameraDevice.rear);

  @override
  Future<Uint8List?> takeSelfie() =>
      _pick(ImageSource.camera, CameraDevice.front);
}
