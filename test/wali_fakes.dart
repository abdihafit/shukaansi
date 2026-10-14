import 'dart:async';

import 'package:shukaansi/models/wali.dart';
import 'package:shukaansi/services/wali_service.dart';

/// In-memory Wali links, invites and requests.
class TestWalis implements WaliService {
  TestWalis({
    this.linked,
    this.mine = const {},
    this.theirs = const {},
    this.guardianAccount,
    this.requests = const [],
  });
  WaliLink? linked;
  WaliInvite? pending;
  Map<String, WaliDecision> mine;
  Map<String, WaliDecision> theirs;
  GuardianAccount? guardianAccount;
  List<WaliRequest> requests;

  /// The code that works for [becomeGuardian].
  String validCode = 'ABCD2345';
  GuardedMember joinMember = const GuardedMember(uid: 'her', name: 'Hodan');
  final calls = <String>[];
  final _changes = StreamController<void>.broadcast();

  /// Simulates a server change, e.g. a guardian deciding.
  void emit() => _changes.add(null);

  @override
  Stream<void> changes(String uid) => _changes.stream;

  @override
  Future<WaliLink?> link(String uid) async => linked;
  @override
  Future<WaliInvite?> invite(String uid) async => pending;

  @override
  Future<WaliInvite> createInvite(String uid, String memberName) async {
    calls.add('invite $memberName');
    return pending = WaliInvite(
      code: 'WXYZ6789',
      expiresAt: DateTime(2026, 10, 12),
    );
  }

  @override
  Future<void> removeWali(String uid) async {
    calls.add('remove');
    linked = null;
  }

  @override
  Future<Map<String, WaliDecision>> myDecisions(String uid) async => mine;
  @override
  Future<Map<String, WaliDecision>> theirDecisions(String uid) async => theirs;

  @override
  Future<void> requestApproval(
    String uid,
    String otherUid,
    String waliUid,
  ) async {
    calls.add('request $otherUid');
    mine = {...mine, otherUid: WaliDecision.pending};
  }

  @override
  Future<GuardianAccount?> guardian(String uid) async => guardianAccount;

  @override
  Future<GuardianAccount> becomeGuardian(
    String uid,
    String name,
    String code,
  ) async {
    if (cleanWaliCode(code) != validCode) throw const WaliCodeException();
    calls.add('join $name');
    return guardianAccount = GuardianAccount(
      name: guardianAccount?.name ?? name,
      members: [...?guardianAccount?.members, joinMember],
    );
  }

  @override
  Future<List<WaliRequest>> guardianRequests(String uid) async => requests;

  @override
  Future<void> decide(String uid, WaliRequest request, bool approve) async {
    calls.add('${approve ? 'approve' : 'decline'} ${request.otherUid}');
    requests = [
      for (final r in requests)
        r.id == request.id
            ? WaliRequest(
                memberUid: r.memberUid,
                otherUid: r.otherUid,
                waliUid: r.waliUid,
                status: approve ? WaliDecision.approved : WaliDecision.declined,
                candidate: r.candidate,
              )
            : r,
    ];
  }

  @override
  Future<void> stopGuarding(String uid, String memberUid) async {
    calls.add('stop $memberUid');
    guardianAccount = GuardianAccount(
      name: guardianAccount!.name,
      members: guardianAccount!.members
          .where((m) => m.uid != memberUid)
          .toList(),
    );
  }

  @override
  Future<void> deleteAll(String uid) async => calls.add('deleteAll');
}
