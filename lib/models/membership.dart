enum MembershipPlan { free, premium, vip }

/// Launch prices (proposal 3.6). Shown as written until Google Play billing
/// supplies local prices.
const planPrices = {
  MembershipPlan.premium: '£4.99',
  MembershipPlan.vip: '£14.99',
};

/// A member's paid plan. Granted by an administrator until Google Play
/// billing is connected (needs the Blaze plan for server verification).
class Membership {
  const Membership(this.plan, {this.expiresAt});
  static const free = Membership(MembershipPlan.free);

  final MembershipPlan plan;
  final DateTime? expiresAt;

  bool activeOn(DateTime now) =>
      plan != MembershipPlan.free &&
      expiresAt != null &&
      expiresAt!.isAfter(now);

  /// The plan in force now: free once it has expired.
  MembershipPlan planOn(DateTime now) =>
      activeOn(now) ? plan : MembershipPlan.free;

  factory Membership.fromMap(Map<String, dynamic>? data) {
    if (data == null) return free;
    final plan = MembershipPlan.values
        .where((p) => p.name == data['plan'] && p != MembershipPlan.free)
        .firstOrNull;
    final expires = data['expiresAt'];
    if (plan == null) return free;
    return Membership(
      plan,
      expiresAt: expires is DateTime ? expires : _toDate(expires),
    );
  }

  static DateTime? _toDate(Object? value) {
    try {
      // Firestore Timestamp, without importing Firestore into the model.
      return (value as dynamic)?.toDate() as DateTime?;
    } catch (_) {
      return null;
    }
  }
}
