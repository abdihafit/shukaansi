import 'package:flutter/material.dart';

import '../application/discovery_controller.dart';
import '../application/interest_controller.dart';
import '../application/wali_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../models/interest.dart';
import '../models/wali.dart';
import '../theme/tokens.dart';
import '../widgets/interest_widgets.dart';
import '../widgets/safety_actions.dart';
import 'member_profile_view.dart';
import 'photos.dart';
import '../screens/profile_labels.dart';
import '../widgets/brand/brand.dart';

/// Explains, using the real rules, why two matched members cannot message
/// yet; null when they can.
String? messagingBlockedReason(
  AppLocalizations s,
  WaliController? wali,
  ProfileCard card,
) => switch (wali?.approvalFor(
  card.uid,
  otherRequired: waliRequired(card.profile.gender),
)) {
  MatchApproval.needsYourWali => s.approvalNeedsWali,
  MatchApproval.waitingYourWali => s.approvalWaitingYours,
  MatchApproval.waitingTheirWali => s.approvalWaitingTheirs,
  MatchApproval.declined => s.approvalDeclined,
  _ => null,
};

/// One member's full profile from Likes or Chats, with the actions that fit
/// where you stand with them.
class MemberPage extends StatelessWidget {
  const MemberPage({
    super.key,
    required this.card,
    required this.discovery,
    required this.interests,
    required this.onViewMatches,
    this.wali,
    this.onMessage,
    this.concept,
    this.today,
    this.onInviteWali,
  });
  final ProfileCard card;
  final DiscoveryController discovery;
  final InterestController interests;
  final VoidCallback onViewMatches;
  final WaliController? wali;
  final ValueChanged<ProfileCard>? onMessage;
  final ProfileConcept? concept;

  /// Where a member without a Wali can invite one (their profile).
  final VoidCallback? onInviteWali;
  final DateTime? today;

  static Future<void> open(BuildContext context, MemberPage page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  Future<void> _unmatch(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(s.unmatchTitle(displayName(card.profile.name))),
        content: Text(s.unmatchBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(s.profileCancelEdit),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(s.unmatch),
          ),
        ],
      ),
    );
    if (ok == true && await interests.unmatch(card) && context.mounted) {
      discovery.forgetAccess(card.uid);
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([interests, discovery, ?wali]),
      builder: (context, _) {
        final state = interests.stateOf(card.uid);
        final photos = DiscoveryPhotos(discovery, card);
        return Scaffold(
          appBar: AppBar(
            title: Text(displayName(card.profile.name)),
            actions: [
              if (state == InterestState.matched)
                PopupMenuButton<void>(
                  tooltip: s.unmatch,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      onTap: () => _unmatch(context),
                      child: Text(s.unmatch),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.l),
            children: [
              MemberProfileView(
                card: card,
                photos: photos,
                today: today ?? discovery.now,
                concept: concept,
                menu: CardSafetyMenu(card: card, controller: discovery),
              ),
            ],
          ),
          bottomNavigationBar: _ActionBar(
            children: _actions(context, s, state),
          ),
        );
      },
    );
  }

  List<Widget> _actions(
    BuildContext context,
    AppLocalizations s,
    InterestState state,
  ) {
    void like() => likeMember(
      context,
      card,
      interests,
      discovery,
      onViewMatches: onViewMatches,
    );
    final busy = interests.busy.contains(card.uid);
    return switch (state) {
      InterestState.likedYou => [
        OutlinedButton(
          // Declined members leave the list, so go back to it.
          onPressed: busy
              ? null
              : () async {
                  if (await interests.decline(card) && context.mounted) {
                    Navigator.of(context).maybePop();
                  }
                },
          child: Text(s.declineInterest),
        ),
        ElevatedButton.icon(
          onPressed: busy ? null : like,
          icon: const Icon(Icons.favorite),
          label: Text(s.likeBack),
        ),
      ],
      InterestState.liked => [
        OutlinedButton(
          onPressed: busy ? null : () => interests.withdraw(card),
          child: Text(s.withdrawInterest),
        ),
      ],
      InterestState.mutual => [
        ElevatedButton.icon(
          onPressed: () => interests.onPremiumNeeded?.call(card),
          icon: const Icon(Icons.workspace_premium_outlined),
          label: Text(s.viewPlans),
        ),
      ],
      InterestState.matched => [
        if (messagingBlockedReason(s, wali, card) case final reason?)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reason, textAlign: TextAlign.center),
                // The one blocker the member can fix themselves.
                if (onInviteWali != null &&
                    wali?.approvalFor(
                          card.uid,
                          otherRequired: waliRequired(card.profile.gender),
                        ) ==
                        MatchApproval.needsYourWali)
                  TextButton.icon(
                    onPressed: onInviteWali,
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(s.waliInvite),
                  ),
              ],
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: onMessage == null ? null : () => onMessage!(card),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(s.messageAction),
          ),
      ],
      InterestState.none => [
        ElevatedButton.icon(
          onPressed: busy ? null : like,
          icon: const Icon(Icons.favorite),
          label: Text(s.likeAction),
        ),
      ],
    };
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.m),
                child is Expanded ? child : Expanded(child: child),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A photo-led tile for grids (Likes). Name and status sit below the photo.
class PortraitTile extends StatelessWidget {
  const PortraitTile({
    super.key,
    required this.card,
    required this.discovery,
    required this.status,
    required this.onTap,
    this.today,
  });
  final ProfileCard card;
  final DiscoveryController discovery;
  final String status;
  final VoidCallback onTap;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final photos = DiscoveryPhotos(discovery, card);
    final name = s.cardNameAge(
      displayName(card.profile.name),
      card.ageOn(today ?? discovery.now),
    );
    return Semantics(
      button: true,
      label: '$name. $status',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.photoIds.isNotEmpty)
              PortraitPhoto(
                photos: photos,
                id: card.photoIds.first,
                semanticLabel: name,
              ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (card.verified) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: VerifiedBadge.color,
                  ),
                ],
              ],
            ),
            Text(
              status,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
