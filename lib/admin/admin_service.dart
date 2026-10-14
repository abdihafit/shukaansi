import 'dart:typed_data';

import '../models/matrimonial_profile.dart';
import '../models/membership.dart';
import '../models/moderation.dart';
import '../models/profile_media.dart';

class AdminException implements Exception {
  const AdminException();
}

/// Headline numbers; null when the signed-in role may not see that figure.
class AdminCounts {
  const AdminCounts({
    this.members,
    this.listed,
    this.pendingVerifications,
    this.openReports,
    this.suspended,
  });
  final int? members;
  final int? listed;
  final int? pendingVerifications;
  final int? openReports;
  final int? suspended;
}

class VerificationRequest {
  const VerificationRequest({
    required this.uid,
    required this.name,
    required this.gender,
    required this.selfieId,
    required this.photoIds,
    this.submittedAt,
  });
  final String uid;
  final String name;
  final ProfileGender? gender;
  final String selfieId;
  final List<String> photoIds;
  final DateTime? submittedAt;
}

class MemberSummary {
  const MemberSummary({
    required this.uid,
    required this.name,
    required this.gender,
    required this.city,
    required this.country,
  });
  final String uid;
  final String name;
  final ProfileGender? gender;
  final String city;
  final String country;
}

class MemberDetail {
  const MemberDetail({
    required this.uid,
    required this.profile,
    required this.photoIds,
    required this.verification,
    required this.status,
    required this.listed,
    this.membership = Membership.free,
    this.birthDate,
    this.phoneNumber,
  });
  final String uid;
  final MatrimonialProfile profile;
  final List<String> photoIds;
  final Verification verification;
  final AccountStatus status;
  final bool listed;
  final Membership membership;

  /// Admins only.
  final DateTime? birthDate;
  final String? phoneNumber;
}

/// A member with an active Premium or VIP plan.
class MembershipRow {
  const MembershipRow({
    required this.uid,
    required this.name,
    required this.membership,
  });
  final String uid;
  final String name;
  final Membership membership;
}

enum ReportOutcome { resolved, dismissed }

class ReportItem {
  const ReportItem({
    required this.id,
    required this.reporterUid,
    required this.reporterName,
    required this.reportedUid,
    required this.reportedName,
    required this.reason,
    required this.note,
    this.createdAt,
  });
  final String id;
  final String reporterUid;
  final String reporterName;
  final String reportedUid;
  final String reportedName;
  final ReportReason reason;
  final String note;
  final DateTime? createdAt;
}

/// Everything the dashboard reads or changes. Every call is also checked by
/// the security rules, so a role can never exceed its permissions.
abstract interface class AdminService {
  /// The signed-in user id, or null when signed out.
  Stream<String?> get sessions;
  Future<void> signIn(String email, String password);
  Future<void> signOut();

  /// The staff record for [uid], or null when they are not staff.
  Future<StaffMember?> staff(String uid);

  Future<AdminCounts> counts(StaffMember me);

  /// Pending requests this reviewer may decide, oldest first.
  Future<List<VerificationRequest>> pendingVerifications(StaffMember me);
  Future<Uint8List> selfie(String uid, String selfieId);
  Future<Uint8List> photo(String uid, String photoId);

  /// Records the decision. Rejection also removes the member from Discover so
  /// a stale blue check can never remain.
  Future<void> decideVerification(
    StaffMember me,
    String uid, {
    required bool approve,
    String note,
  });

  /// By exact member id, or by name prefix; recent members when empty.
  Future<List<MemberSummary>> searchMembers(String query);
  Future<MemberDetail> member(StaffMember me, String uid);

  /// Suspending also removes the member from Discover.
  Future<void> setSuspended(
    StaffMember me,
    String uid, {
    required bool suspended,
    String reason,
  });
  Future<void> unlist(String uid);

  /// Administrators only: gives Premium or VIP until [until] (replacing any
  /// current plan), or ends it.
  Future<void> grantMembership(
    StaffMember me,
    String uid,
    MembershipPlan plan,
    DateTime until,
  );
  Future<void> endMembership(String uid);

  /// Active plans, soonest to expire first. Administrators only.
  Future<List<MembershipRow>> activeMemberships();

  Future<List<ReportItem>> openReports();
  Future<void> resolveReport(
    StaffMember me,
    String reportId,
    ReportOutcome outcome,
    String resolution,
  );
}
