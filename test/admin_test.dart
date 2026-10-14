import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/admin/admin_app.dart';
import 'package:shukaansi/admin/admin_service.dart';
import 'package:shukaansi/models/matrimonial_profile.dart';
import 'package:shukaansi/models/membership.dart';
import 'package:shukaansi/models/moderation.dart';
import 'package:shukaansi/models/profile_media.dart';

import 'media_fakes.dart';
import 'profile_test.dart' as p;

class FakeAdmin implements AdminService {
  final _sessions = StreamController<String?>.broadcast();
  String? current;
  StaffMember? me;
  bool failSignIn = false;
  List<VerificationRequest> queue = [];
  final decisions = <(String, bool, String)>[];
  List<MemberSummary> members = [];
  final suspensions = <(String, bool, String)>[];
  final unlisted = <String>[];
  List<ReportItem> reports = [];
  final resolutions = <(String, ReportOutcome, String)>[];
  AccountStatus status = AccountStatus.active;

  void emit(String? uid) {
    current = uid;
    _sessions.add(uid);
  }

  @override
  Stream<String?> get sessions async* {
    yield current;
    yield* _sessions.stream;
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (failSignIn) throw const AdminException();
    emit('staff');
  }

  @override
  Future<void> signOut() async => emit(null);

  @override
  Future<StaffMember?> staff(String uid) async => me;

  @override
  Future<AdminCounts> counts(StaffMember me) async => me.canModerate
      ? const AdminCounts(
          members: 12,
          listed: 9,
          pendingVerifications: 2,
          openReports: 1,
          suspended: 0,
        )
      : const AdminCounts(pendingVerifications: 2);

  @override
  Future<List<VerificationRequest>> pendingVerifications(
    StaffMember me,
  ) async => queue;

  @override
  Future<Uint8List> selfie(String uid, String selfieId) async => png;

  @override
  Future<Uint8List> photo(String uid, String photoId) async => png;

  @override
  Future<void> decideVerification(
    StaffMember me,
    String uid, {
    required bool approve,
    String note = '',
  }) async {
    decisions.add((uid, approve, note));
    queue = queue.where((r) => r.uid != uid).toList();
  }

  @override
  Future<List<MemberSummary>> searchMembers(String query) async => members
      .where((m) => m.name.toLowerCase().startsWith(query.toLowerCase()))
      .toList();

  @override
  Future<MemberDetail> member(StaffMember me, String uid) async => MemberDetail(
    uid: uid,
    profile: p.sample,
    photoIds: [photoId(1)],
    verification: const Verification(VerificationStatus.verified),
    status: status,
    listed: !status.suspended,
    phoneNumber: me.isAdmin ? '+447700900123' : null,
    birthDate: me.isAdmin ? DateTime.utc(2001, 1, 15) : null,
  );

  @override
  Future<void> setSuspended(
    StaffMember me,
    String uid, {
    required bool suspended,
    String reason = '',
  }) async {
    suspensions.add((uid, suspended, reason));
    status = AccountStatus(suspended: suspended, reason: reason);
  }

  @override
  Future<void> unlist(String uid) async => unlisted.add(uid);

  final grants = <String>[];
  List<MembershipRow> memberships = [];

  @override
  Future<void> grantMembership(
    StaffMember me,
    String uid,
    MembershipPlan plan,
    DateTime until,
  ) async => grants.add('$uid ${plan.name}');

  @override
  Future<void> endMembership(String uid) async => grants.add('end $uid');

  @override
  Future<List<MembershipRow>> activeMemberships() async => memberships;

  @override
  Future<List<ReportItem>> openReports() async => reports;

  @override
  Future<void> resolveReport(
    StaffMember me,
    String reportId,
    ReportOutcome outcome,
    String resolution,
  ) async {
    resolutions.add((reportId, outcome, resolution));
    reports = reports.where((r) => r.id != reportId).toList();
  }
}

Future<void> pumpAdmin(
  WidgetTester tester,
  FakeAdmin admin, {
  Size size = const Size(1280, 900),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(AdminApp(service: admin));
  await tester.pumpAndSettle();
}

Future<void> go(WidgetTester tester, String section) async {
  await tester.tap(find.text(section).first);
  await tester.pumpAndSettle();
}

const request = VerificationRequest(
  uid: 'her',
  name: 'Hodan',
  gender: ProfileGender.female,
  selfieId: 'Selfie00000000000001',
  photoIds: ['Photo000000000000001'],
);

void main() {
  testWidgets('sign in; non-staff accounts get no access', (tester) async {
    final admin = FakeAdmin()..failSignIn = true;
    await pumpAdmin(tester, admin);
    expect(find.text('Staff sign in'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await p.tap(tester, 'Sign in');
    expect(
      find.text('Sign in failed. Check your email and password.'),
      findsOneWidget,
    );
    admin.failSignIn = false;
    await tester.enterText(find.byType(TextFormField).last, 'secret1');
    await p.tap(tester, 'Sign in');
    expect(find.text('No staff access'), findsOneWidget);
    await p.tap(tester, 'Sign out');
    expect(find.text('Staff sign in'), findsOneWidget);
  });

  testWidgets('each role sees only its sections', (tester) async {
    final admin = FakeAdmin()
      ..current = 'staff'
      ..me = const StaffMember(
        uid: 'staff',
        role: StaffRole.reviewer,
        reviewGender: 'female',
      );
    await pumpAdmin(tester, admin);
    expect(find.text('Reviewer · women'), findsOneWidget);
    expect(find.text('Verifications'), findsOneWidget);
    expect(find.text('Members'), findsNothing);
    expect(find.text('Reports'), findsNothing);
    expect(find.text('Verifications waiting'), findsOneWidget);
    expect(find.text('Open reports'), findsNothing);

    admin.me = const StaffMember(uid: 'staff', role: StaffRole.admin);
    admin.emit('staff2');
    await tester.pumpAndSettle();
    for (final section in [
      'Overview',
      'Verifications',
      'Members',
      'Reports',
      'Memberships',
    ]) {
      expect(find.text(section), findsWidgets);
    }
    expect(find.text('12'), findsOneWidget);

    admin.me = const StaffMember(uid: 'staff', role: StaffRole.moderator);
    admin.emit('staff3');
    await tester.pumpAndSettle();
    expect(find.text('Verifications'), findsNothing);
    expect(find.text('Memberships'), findsNothing);
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets('reviewers approve, and reject only with a reason', (
    tester,
  ) async {
    final admin = FakeAdmin()
      ..current = 'staff'
      ..me = const StaffMember(uid: 'staff', role: StaffRole.reviewer)
      ..queue = [
        request,
        const VerificationRequest(
          uid: 'him',
          name: 'Ahmed',
          gender: ProfileGender.male,
          selfieId: 'Selfie00000000000002',
          photoIds: [],
        ),
      ];
    await pumpAdmin(tester, admin);
    await go(tester, 'Verifications');
    await p.tap(tester, 'Hodan');
    expect(
      find.bySemanticsLabel('Verification selfie of Hodan'),
      findsOneWidget,
    );
    await p.tap(tester, 'Approve');
    expect(admin.decisions.single, ('her', true, ''));
    expect(find.text('Hodan'), findsNothing);

    await p.tap(tester, 'Ahmed');
    await p.tap(tester, 'Reject');
    final confirm = find.widgetWithText(FilledButton, 'Reject');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.enterText(find.byType(TextField).last, 'Face not visible');
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(admin.decisions.last, ('him', false, 'Face not visible'));
    expect(find.text('No verifications are waiting.'), findsOneWidget);
  });

  testWidgets('moderators search, suspend with a reason, and reactivate', (
    tester,
  ) async {
    final admin = FakeAdmin()
      ..current = 'staff'
      ..me = const StaffMember(uid: 'staff', role: StaffRole.moderator)
      ..members = [
        const MemberSummary(
          uid: 'her',
          name: 'Test Person',
          gender: ProfileGender.female,
          city: 'London',
          country: 'GB',
        ),
      ];
    await pumpAdmin(tester, admin);
    await go(tester, 'Members');
    await tester.enterText(find.byType(TextField), 'zz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('No members found.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'test');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await p.tap(tester, 'Test Person');
    expect(find.text('Phone (private)'), findsNothing);
    await p.tap(tester, 'Suspend');
    await tester.enterText(find.byType(TextField).last, 'Fake profile');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Suspend').last);
    await tester.pumpAndSettle();
    expect(admin.suspensions.single, ('her', true, 'Fake profile'));
    expect(find.text('Suspended: Fake profile'), findsOneWidget);
    await p.tap(tester, 'Reactivate');
    expect(admin.suspensions.last, ('her', false, ''));
  });

  testWidgets('admins see private details', (tester) async {
    final admin = FakeAdmin()
      ..current = 'staff'
      ..me = const StaffMember(uid: 'staff', role: StaffRole.admin)
      ..members = [
        const MemberSummary(
          uid: 'her',
          name: 'Test Person',
          gender: ProfileGender.female,
          city: 'London',
          country: 'GB',
        ),
      ];
    await pumpAdmin(tester, admin);
    await go(tester, 'Members');
    await p.tap(tester, 'Test Person');
    expect(find.text('+447700900123', findRichText: true), findsOneWidget);
    expect(find.text('Phone (private)'), findsOneWidget);
  });

  testWidgets('admins give and end memberships; the page lists them', (
    tester,
  ) async {
    final admin = FakeAdmin()
      ..current = 'staff'
      ..me = const StaffMember(uid: 'staff', role: StaffRole.admin)
      ..members = [
        const MemberSummary(
          uid: 'her',
          name: 'Test Person',
          gender: ProfileGender.female,
          city: 'London',
          country: 'GB',
        ),
      ]
      ..memberships = [
        MembershipRow(
          uid: 'him',
          name: 'Ahmed',
          membership: Membership(
            MembershipPlan.vip,
            expiresAt: DateTime(2030, 1, 1),
          ),
        ),
      ];
    await pumpAdmin(tester, admin);
    await go(tester, 'Members');
    await p.tap(tester, 'Test Person');
    expect(find.text('Membership'), findsOneWidget);
    await p.tap(tester, 'Give Premium or VIP');
    await p.tap(tester, 'VIP (£14.99/month) · 3 months');
    expect(admin.grants, ['her vip']);
    await go(tester, 'Memberships');
    expect(find.text('VIP: 1'), findsOneWidget);
    expect(find.text('Ahmed'), findsOneWidget);
  });

  testWidgets('moderators cannot give memberships', (tester) async {
    final admin = FakeAdmin()
      ..current = 'staff'
      ..me = const StaffMember(uid: 'staff', role: StaffRole.moderator)
      ..members = [
        const MemberSummary(
          uid: 'her',
          name: 'Test Person',
          gender: ProfileGender.female,
          city: 'London',
          country: 'GB',
        ),
      ];
    await pumpAdmin(tester, admin);
    await go(tester, 'Members');
    await p.tap(tester, 'Test Person');
    expect(find.text('Give Premium or VIP'), findsNothing);
  });

  testWidgets('reports can be resolved, dismissed, or end in suspension', (
    tester,
  ) async {
    ReportItem report(String id, String name) => ReportItem(
      id: id,
      reporterUid: 'a',
      reporterName: 'Amina',
      reportedUid: 'r$id',
      reportedName: name,
      reason: ReportReason.scam,
      note: 'Asked for money',
    );
    final admin = FakeAdmin()
      ..current = 'staff'
      ..me = const StaffMember(uid: 'staff', role: StaffRole.moderator)
      ..reports = [report('1', 'Ahmed'), report('2', 'Yusuf')];
    await pumpAdmin(tester, admin);
    await go(tester, 'Reports');
    expect(find.text('Amina reported Ahmed · —'), findsOneWidget);
    await tester.tap(find.text('Dismiss').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Dismiss'));
    await tester.pumpAndSettle();
    expect(admin.resolutions.single.$2, ReportOutcome.dismissed);
    await p.tap(tester, 'Suspend Yusuf');
    await tester.enterText(find.byType(TextField).last, 'Scam');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Suspend'));
    await tester.pumpAndSettle();
    expect(admin.suspensions.single, ('r2', true, 'Scam'));
    expect(admin.resolutions.last, (
      '2',
      ReportOutcome.resolved,
      'Suspended: Scam',
    ));
    expect(find.text('No open reports.'), findsOneWidget);
  });

  testWidgets('phones get a bottom navigation bar', (tester) async {
    final admin = FakeAdmin()
      ..current = 'staff'
      ..me = const StaffMember(uid: 'staff', role: StaffRole.admin);
    await pumpAdmin(tester, admin, size: const Size(400, 800));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
