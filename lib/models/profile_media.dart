import 'dart:typed_data';

const maxPhotos = 6;

/// Fits one Firestore document (1 MiB cap) with room for metadata; the rules
/// enforce the same limit. Photos are resized on the device to stay under it.
const maxPhotoBytes = 900 * 1024;

enum VerificationStatus { none, pending, verified, rejected }

class Verification {
  const Verification(this.status, {this.reviewNote});
  static const none = Verification(VerificationStatus.none);
  final VerificationStatus status;

  /// Optional explanation an administrator adds when rejecting.
  final String? reviewNote;
}

/// Result of reordering or removing photos.
class PhotoUpdate {
  const PhotoUpdate(this.photoIds, {this.verificationReset = false});
  final List<String> photoIds;

  /// True when the main photo changed and the verification was cleared.
  final bool verificationReset;
}

/// The main (first) photo, or null when there are none.
String? mainPhotoOf(List<String> photoIds) => photoIds.firstOrNull;

/// The owner's photo order (first is the main photo) and verification state.
class ProfileMedia {
  const ProfileMedia({
    required this.photoIds,
    required this.verification,
    this.blurred = false,
  });
  final List<String> photoIds;
  final Verification verification;

  /// Women only: Discover shows blurred copies until she approves a viewer.
  final bool blurred;
}

/// Content type from the file's leading bytes, or null if not an accepted image.
/// Trusting signatures rather than names keeps renamed files out.
String? imageContentType(Uint8List bytes) {
  bool startsWith(List<int> signature, [int offset = 0]) =>
      bytes.length >= offset + signature.length &&
      [
        for (var i = 0; i < signature.length; i++)
          bytes[offset + i] == signature[i],
      ].every((match) => match);
  if (startsWith([0xFF, 0xD8, 0xFF])) return 'image/jpeg';
  if (startsWith([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
    return 'image/png';
  }
  if (startsWith([0x52, 0x49, 0x46, 0x46]) &&
      startsWith([0x57, 0x45, 0x42, 0x50], 8)) {
    return 'image/webp';
  }
  return null;
}

bool isAcceptedPhoto(Uint8List bytes) =>
    bytes.isNotEmpty &&
    bytes.length < maxPhotoBytes &&
    imageContentType(bytes) != null;
