import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/membership.dart';
import '../services/membership_service.dart';

class MembershipController extends ChangeNotifier {
  MembershipController({required this.uid, required this.service, this.today});
  final String uid;
  final MembershipService service;

  /// Overrides the current date in tests.
  final DateTime? today;

  Membership membership = Membership.free;
  StreamSubscription<Membership>? _subscription;
  bool _disposed = false;

  DateTime get now => today ?? DateTime.now();
  MembershipPlan get plan => membership.planOn(now);
  bool get premium => plan != MembershipPlan.free;

  void start() {
    _subscription ??= service.watch(uid).listen((value) {
      membership = value;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
