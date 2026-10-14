/// Why a member reports a profile. Values are stored verbatim; rules list them.
enum ReportReason {
  fakeProfile,
  inappropriatePhotos,
  harassment,
  scam,
  underage,
  notSerious,
  other,
}

/// Set by moderators. A suspended member sees a locked screen and is removed
/// from Discover.
class AccountStatus {
  const AccountStatus({required this.suspended, this.reason = ''});
  static const active = AccountStatus(suspended: false);
  final bool suspended;
  final String reason;
}

/// Someone the member has blocked; the name is kept so they can unblock
/// without being able to see the blocked profile.
class BlockedMember {
  const BlockedMember({required this.uid, required this.name});
  final String uid;
  final String name;
}

/// Staff roles, created in the Firebase console as admins/{uid}.
enum StaffRole { admin, reviewer, moderator }

class StaffMember {
  const StaffMember({required this.uid, required this.role, this.reviewGender});
  final String uid;
  final StaffRole role;

  /// When set, a reviewer only reviews members of this gender ('female' or
  /// 'male').
  final String? reviewGender;

  bool get canReview => role == StaffRole.admin || role == StaffRole.reviewer;
  bool get canModerate =>
      role == StaffRole.admin || role == StaffRole.moderator;
  bool get isAdmin => role == StaffRole.admin;
}

/// Shown on the suspended screen for appeals. Mail to it is meant to be
/// forwarded to the owner's inbox (configured at the domain, not in the app).
const supportEmail = 'admin@shukaansi.com';
