import 'package:flutter/material.dart';

import '../application/chat_controller.dart';
import '../application/discovery_controller.dart';
import '../application/interest_controller.dart';
import '../application/wali_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/chat.dart';
import '../models/discovery.dart';
import '../screens/chat_screen.dart';
import '../theme/tokens.dart';
import '../widgets/interest_widgets.dart';
import 'member_page.dart';
import '../widgets/brand/brand.dart';
import '../screens/profile_labels.dart';

/// Chats with new matches on top, so there is no separate Matches tab. Every
/// match action stays reachable: open the match to message, view the
/// profile or unmatch.
class ChatsView extends StatelessWidget {
  const ChatsView({
    super.key,
    required this.chats,
    required this.interests,
    required this.discovery,
    required this.openChat,
    required this.openMember,
    required this.onBrowse,
    this.wali,
    this.today,
  });
  final ChatController chats;
  final InterestController interests;
  final DiscoveryController discovery;
  final WaliController? wali;
  final ValueChanged<ProfileCard> openChat;

  /// Opens the match's profile (message, unmatch, report from there).
  final ValueChanged<ProfileCard> openMember;
  final VoidCallback onBrowse;
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.navChats), automaticallyImplyLeading: false),
      body: ListenableBuilder(
        listenable: Listenable.merge([chats, interests, discovery, ?wali]),
        builder: (context, _) {
          final cards = {for (final e in interests.matches) e.card.uid: e.card};
          final talking = [
            for (final c in chats.conversations)
              if (cards.containsKey(c.otherUid)) (c, cards[c.otherUid]!),
          ];
          final talkingIds = {for (final (c, _) in talking) c.otherUid};
          final fresh = [
            for (final e in interests.matches)
              if (!talkingIds.contains(e.card.uid)) e.card,
          ];
          if (!interests.loaded && interests.loading) {
            return const ListSkeleton();
          }
          if (chats.failed && talking.isEmpty && fresh.isEmpty) {
            return EmptyState(
              icon: Icons.wifi_off,
              title: s.networkErrorTitle,
              message: s.chatsLoadFailed,
              actionLabel: s.retry,
              onAction: chats.retry,
            );
          }
          if (talking.isEmpty && fresh.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline,
              photo: LifestylePhoto.connectionCouple,
              title: s.chatsEmptyTitle,
              message: s.chatsEmptyBody,
              actionLabel: s.browseDiscover,
              onAction: onBrowse,
            );
          }
          Widget heading(String text) => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.l,
              AppSpacing.s,
            ),
            child: Semantics(
              header: true,
              child: Text(text, style: theme.textTheme.titleMedium),
            ),
          );
          return RefreshIndicator(
            onRefresh: interests.load,
            child: ListView(
              children: [
                if (fresh.isNotEmpty) ...[
                  heading(s.chatsNewMatches),
                  SizedBox(
                    // Avatar plus a name line that grows with the text size.
                    height: 104 + MediaQuery.textScalerOf(context).scale(28),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                      ),
                      itemCount: fresh.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.l),
                      itemBuilder: (context, i) => _NewMatch(
                        card: fresh[i],
                        discovery: discovery,
                        blockedReason: messagingBlockedReason(
                          s,
                          wali,
                          fresh[i],
                        ),
                        onTap: () => openMember(fresh[i]),
                      ),
                    ),
                  ),
                ],
                // Matches but nothing written yet: say what to do next.
                if (talking.isEmpty && fresh.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      AppSpacing.xl,
                      AppSpacing.l,
                      0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            Icons.waving_hand_outlined,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Text(
                            s.chatsStartHint,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (talking.isNotEmpty) ...[
                  heading(s.chatsActive),
                  for (final (summary, card) in talking)
                    _ConversationTile(
                      summary: summary,
                      card: card,
                      discovery: discovery,
                      blockedReason: messagingBlockedReason(s, wali, card),
                      now: today ?? DateTime.now(),
                      onTap: () => openChat(card),
                    ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NewMatch extends StatelessWidget {
  const _NewMatch({
    required this.card,
    required this.discovery,
    required this.blockedReason,
    required this.onTap,
  });
  final ProfileCard card;
  final DiscoveryController discovery;
  final String? blockedReason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      label: [displayName(card.profile.name), ?blockedReason].join('. '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: blockedReason == null
                            ? colors.primary
                            : colors.secondary,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: MemberAvatar(
                        card: card,
                        discovery: discovery,
                        size: 68,
                      ),
                    ),
                  ),
                  if (blockedReason != null)
                    PositionedDirectional(
                      end: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLowest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.hourglass_top,
                          size: 16,
                          color: colors.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                displayName(card.profile.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.summary,
    required this.card,
    required this.discovery,
    required this.blockedReason,
    required this.now,
    required this.onTap,
  });
  final ChatSummary summary;
  final ProfileCard card;
  final DiscoveryController discovery;
  final String? blockedReason;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unread = summary.unread;
    final preview =
        blockedReason ??
        (summary.lastFrom == card.uid
            ? summary.lastText
            : s.chatYou(summary.lastText));
    final time = chatTime(context, summary.lastAt, now);
    return Semantics(
      button: true,
      label: [
        displayName(card.profile.name),
        if (unread) s.chatUnread,
        preview,
        time,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.m,
          ),
          child: Row(
            children: [
              ClipOval(
                child: MemberAvatar(card: card, discovery: discovery, size: 56),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName(card.profile.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: unread
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: blockedReason != null
                                  ? colors.secondary
                                  : unread
                                  ? colors.onSurface
                                  : colors.onSurfaceVariant,
                              fontWeight: unread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            margin: const EdgeInsetsDirectional.only(
                              start: AppSpacing.s,
                            ),
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
