import 'dart:async';

import 'package:shukaansi/models/membership.dart';
import 'package:shukaansi/services/membership_service.dart';

/// A membership that tests can change while the app is running.
class TestMemberships implements MembershipService {
  TestMemberships([this.current = Membership.free]);
  Membership current;
  final _changes = StreamController<Membership>.broadcast();

  void set(Membership value) {
    current = value;
    _changes.add(value);
  }

  @override
  Stream<Membership> watch(String uid) async* {
    yield current;
    yield* _changes.stream;
  }
}
