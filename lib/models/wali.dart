import 'dart:math';

import 'matrimonial_profile.dart';

/// Invite codes avoid look-alike characters (0/O, 1/I/L).
const waliCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const waliCodeLength = 8;
const waliInviteValidity = Duration(days: 7);

String newWaliCode([Random? random]) {
  final r = random ?? Random.secure();
  return List.generate(
    waliCodeLength,
    (_) => waliCodeAlphabet[r.nextInt(waliCodeAlphabet.length)],
  ).join();
}

/// Normalises what a guardian typed: upper case, no spaces or dashes.
String cleanWaliCode(String input) =>
    input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

bool isWaliCode(String code) =>
    code.length == waliCodeLength &&
    code.split('').every(waliCodeAlphabet.contains);

/// Sisters must have a Wali; anyone who has one needs his approval.
bool waliRequired(ProfileGender gender) => gender == ProfileGender.female;

/// The member's guardian.
class WaliLink {
  const WaliLink({required this.waliUid, required this.waliName});
  final String waliUid;
  final String waliName;
}

/// An invite the member shared and the guardian has not used yet.
class WaliInvite {
  const WaliInvite({required this.code, required this.expiresAt});
  final String code;
  final DateTime expiresAt;
}

/// A guardian account: limited access, no profile of its own.
class GuardianAccount {
  const GuardianAccount({required this.name, this.members = const []});
  final String name;

  /// Members this guardian looks after.
  final List<GuardedMember> members;
}

class GuardedMember {
  const GuardedMember({required this.uid, required this.name});
  final String uid;
  final String name;
}

enum WaliDecision { pending, approved, declined }

/// The other member's details, copied from their public listing when the
/// match was made, so the guardian can decide without seeing photos.
class MatchCandidate {
  const MatchCandidate({
    required this.name,
    required this.birthYearMonth,
    required this.city,
    required this.residenceCountry,
    required this.profession,
    required this.professionOther,
    required this.education,
    required this.practice,
    required this.maritalStatus,
    required this.about,
    required this.verified,
  });
  final String name;
  final int birthYearMonth;
  final String city;
  final String residenceCountry;
  final Profession profession;
  final String professionOther;
  final EducationLevel education;
  final PracticeLevel practice;
  final MaritalStatus maritalStatus;
  final String about;
  final bool verified;
}

/// A match waiting for (or decided by) one member's guardian.
class WaliRequest {
  const WaliRequest({
    required this.memberUid,
    required this.otherUid,
    required this.waliUid,
    required this.status,
    this.candidate,
  });
  final String memberUid;
  final String otherUid;
  final String waliUid;
  final WaliDecision status;

  /// Present for the guardian's view.
  final MatchCandidate? candidate;

  String get id => '${memberUid}_$otherUid';
}
