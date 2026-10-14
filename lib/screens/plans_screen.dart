import 'package:flutter/material.dart';

import '../application/membership_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../models/membership.dart';
import '../theme/tokens.dart';
import '../widgets/pressable.dart';
import '../widgets/shukaansi_ui.dart';

String planName(AppLocalizations s, MembershipPlan plan) => switch (plan) {
  MembershipPlan.free => s.planFree,
  MembershipPlan.premium => s.planPremium,
  MembershipPlan.vip => s.planVip,
};

List<(IconData, String)> planFeatures(
  AppLocalizations s,
  MembershipPlan plan,
) => switch (plan) {
  MembershipPlan.free => [
    (Icons.verified_user_outlined, s.featureProfile),
    (Icons.favorite_border, s.featureBrowse),
    (Icons.people_outline, s.featureMatchPremium),
  ],
  MembershipPlan.premium => [
    (Icons.favorite, s.featureMatchAnyone),
    (Icons.chat_bubble_outline, s.featureMessage),
  ],
  MembershipPlan.vip => [
    (Icons.workspace_premium_outlined, s.featureEverythingPremium),
    (Icons.trending_up, s.featurePriority),
  ],
};

/// Free, Premium and VIP, with what each includes and its price.
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key, required this.membership});
  final MembershipController membership;

  static Future<void> open(
    BuildContext context,
    MembershipController membership,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlansScreen(membership: membership),
    ),
  );

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  MembershipPlan _shown = MembershipPlan.premium;

  Future<void> _subscribe() async {
    final s = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        icon: const Icon(Icons.schedule),
        title: Text(s.planComingSoonTitle),
        content: Text(s.planComingSoonBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(),
            child: Text(MaterialLocalizations.of(d).okButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _compare() {
    final s = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) {
        final theme = Theme.of(sheet);
        Widget mark(bool yes) => Icon(
          yes ? Icons.check_circle : Icons.remove,
          color: yes ? theme.colorScheme.primary : theme.colorScheme.outline,
          semanticLabel: yes ? '✓' : '–',
        );
        final rows = [
          (s.featureBrowse, true, true, true),
          (s.featureMatchPremium, true, true, true),
          (s.featureMatchAnyone, false, true, true),
          (s.featureMessage, false, true, true),
          (s.featurePriority, false, false, true),
        ];
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              0,
              AppSpacing.l,
              AppSpacing.xl,
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  children: [
                    const SizedBox.shrink(),
                    for (final p in MembershipPlan.values)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.s),
                        child: Text(
                          planName(s, p),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                for (final (label, free, premium, vip) in rows)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.m,
                        ),
                        child: Text(label),
                      ),
                      mark(free),
                      mark(premium),
                      mark(vip),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final current = widget.membership.plan;
    final price = planPrices[_shown];
    final (headline, sub) = switch (_shown) {
      MembershipPlan.free => (s.planHeadlineFree, s.planSubFree),
      MembershipPlan.premium => (s.planHeadlinePremium, s.planSubPremium),
      MembershipPlan.vip => (s.planHeadlineVip, s.planSubVip),
    };
    return Scaffold(
      appBar: AppBar(title: Text(s.plansTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            SegmentedButton<MembershipPlan>(
              showSelectedIcon: false,
              segments: [
                for (final p in MembershipPlan.values)
                  ButtonSegment(value: p, label: Text(planName(s, p))),
              ],
              selected: {_shown},
              onSelectionChanged: (v) => setState(() => _shown = v.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: ShukaansiIconBadge(
                icon: _shown == MembershipPlan.vip
                    ? Icons.workspace_premium
                    : Icons.shield_outlined,
                size: 88,
                color: colors.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Semantics(
              header: true,
              child: Text(
                headline,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // What the plan adds, as a plain list: these are facts, not
            // buttons, so nothing here looks tappable.
            SectionCard(
              child: Column(
                children: [
                  for (final (i, (icon, text)) in planFeatures(
                    s,
                    _shown,
                  ).indexed) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        ExcludeSemantics(
                          child: Icon(icon, color: colors.primary),
                        ),
                        const SizedBox(width: AppSpacing.l),
                        Expanded(
                          child: Text(text, style: theme.textTheme.bodyLarge),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            if (price != null) ...[
              const SizedBox(height: AppSpacing.s),
              SectionCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planName(s, _shown),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: AppSpacing.s,
                      children: [
                        Text(
                          price,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            s.perMonth,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(s.planCancelAnytime),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.l),
            ],
            if (_shown == current)
              Center(
                child: ShukaansiStatusChip(
                  label: s.planCurrent,
                  icon: Icons.check_circle,
                  tone: StatusTone.positive,
                ),
              )
            else if (_shown != MembershipPlan.free) ...[
              // Said before the tap: payments are not open yet.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(Icons.info_outline, color: colors.secondary),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      s.planComingSoonBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              Pressable(
                child: ElevatedButton(
                  onPressed: _subscribe,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.planContinue(planName(s, _shown)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const ExcludeSemantics(child: Icon(Icons.arrow_forward)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s),
            TextButton.icon(
              onPressed: _compare,
              icon: const Icon(Icons.table_chart_outlined),
              label: Text(s.compareAllPlans),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              s.planRenewNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// My profile: the current plan and a way to see the others.
class MembershipCard extends StatelessWidget {
  const MembershipCard({super.key, required this.membership});
  final MembershipController membership;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: membership,
      builder: (context, _) {
        final plan = membership.plan;
        final expires = membership.membership.expiresAt;
        return SectionCard(
          tinted: true,
          child: Row(
            children: [
              ShukaansiIconBadge(
                icon: plan == MembershipPlan.free
                    ? Icons.workspace_premium_outlined
                    : Icons.workspace_premium,
                size: 52,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: AppSpacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.membershipTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      planName(s, plan),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      plan == MembershipPlan.free || expires == null
                          ? s.membershipFreeBody
                          : s.membershipActive(
                              planName(s, plan),
                              MaterialLocalizations.of(context)
                                  .formatMediumDate(expires),
                            ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Pressable(
                      child: ElevatedButton(
                        onPressed: () => PlansScreen.open(context, membership),
                        child: Text(s.viewPlans),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Both like each other but neither has Premium yet.
Future<void> showPremiumNeeded(
  BuildContext context,
  ProfileCard card,
  MembershipController membership,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheet) {
    final s = AppLocalizations.of(sheet);
    final theme = Theme.of(sheet);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ShukaansiIconBadge(
                icon: Icons.favorite,
                size: 88,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                s.mutualTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              s.mutualBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            Pressable(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(sheet).pop();
                  PlansScreen.open(context, membership);
                },
                child: Text(s.viewPlans),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(sheet).pop(),
              child: Text(s.keepBrowsing),
            ),
          ],
        ),
      ),
    );
  },
);
