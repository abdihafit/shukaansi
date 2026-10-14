import '../models/matrimonial_profile.dart';

class ProfileException implements Exception {
  const ProfileException();
}

/// What a confirmed server read found for the signed-in owner.
sealed class ProfileState {
  const ProfileState();
}

class ProfileMissing extends ProfileState {
  const ProfileMissing();
}

/// A complete schema v1 profile that must answer the newer questions.
class ProfileNeedsUpdate extends ProfileState {
  const ProfileNeedsUpdate(this.previous);
  final LegacyProfile previous;
}

class ProfileComplete extends ProfileState {
  const ProfileComplete(this.profile, this.details);
  final MatrimonialProfile profile;
  final PrivateDetails details;
}

abstract interface class ProfileService {
  Future<ProfileState> load(String uid);

  /// Creates the profile, or upgrades a v1 profile; retries return the saved pair.
  Future<ProfileComplete> save(
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details, {
    required bool adultConfirmed,
  });

  /// Saves edits to a complete profile. Gender and birth date cannot change.
  Future<ProfileComplete> update(
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details,
  );

  /// Deletes the profile and private details together.
  Future<void> delete(String uid);
}

class UnavailableProfileService implements ProfileService {
  const UnavailableProfileService();
  @override
  Future<ProfileState> load(String uid) async => throw const ProfileException();
  @override
  Future<ProfileComplete> save(
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details, {
    required bool adultConfirmed,
  }) async => throw const ProfileException();
  @override
  Future<ProfileComplete> update(
    String uid,
    MatrimonialProfile profile,
    PrivateDetails details,
  ) async => throw const ProfileException();
  @override
  Future<void> delete(String uid) async => throw const ProfileException();
}
