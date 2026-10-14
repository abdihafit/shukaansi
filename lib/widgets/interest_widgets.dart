import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../application/discovery_controller.dart';
import '../application/interest_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../models/interest.dart';
import '../screens/profile_labels.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'pressable.dart';
import 'shukaansi_ui.dart';
import 'brand/brand.dart';

/// Shows interest after a tap, reports the result and celebrates a match.
Future<void> likeMember(
  BuildContext context,
  ProfileCard card,
  InterestController interests,
  DiscoveryController discovery, {
  VoidCallback? onViewMatches,
}) async {
  final s = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final result = await interests.like(card);
  if (!context.mounted) return;
  switch (result) {
    case null:
      messenger.showSnackBar(SnackBar(content: Text(s.interestFailed)));
    case LikeResult.matched:
      // Matching unlocks her photos; look the permission up again.
      discovery.forgetAccess(card.uid);
      await showMatchCelebration(context, card, onViewMatches: onViewMatches);
    case LikeResult.mutualNeedsPremium:
      interests.onPremiumNeeded?.call(card);
    case LikeResult.liked:
      messenger.showSnackBar(
        SnackBar(content: Text(s.likeSent(displayName(card.profile.name)))),
      );
  }
}

/// The heart on a profile: show interest, withdraw it, or "matched".
class InterestButton extends StatelessWidget {
  const InterestButton({
    super.key,
    required this.card,
    required this.interests,
    required this.discovery,
    this.onViewMatches,
  });
  final ProfileCard card;
  final InterestController interests;
  final DiscoveryController discovery;
  final VoidCallback? onViewMatches;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: interests,
      builder: (context, _) {
        final state = interests.stateOf(card.uid);
        final busy = interests.busy.contains(card.uid);
        final filled =
            state == InterestState.liked ||
            state == InterestState.matched ||
            state == InterestState.mutual;
        final (tooltip, action) = switch (state) {
          InterestState.matched => (s.matchedLabel, null),
          // Both like each other; Premium on either side makes the match.
          InterestState.mutual => (
            s.mutualTitle,
            () => interests.onPremiumNeeded?.call(card),
          ),
          InterestState.liked => (
            s.withdrawInterest,
            () async {
              if (!await interests.withdraw(card) && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(s.interestFailed)));
              }
            },
          ),
          _ => (
            s.likeAction,
            () => likeMember(
              context,
              card,
              interests,
              discovery,
              onViewMatches: onViewMatches,
            ),
          ),
        };
        return Semantics(
          toggled: filled,
          child: Pressable(
            enabled: !busy && action != null,
            child: IconButton.outlined(
              tooltip: tooltip,
              isSelected: filled,
              onPressed: busy ? null : action,
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                side: BorderSide(
                  color: filled ? colors.primary : colors.outlineVariant,
                ),
                disabledForegroundColor: colors.primary,
              ),
              icon: AnimatedSwitcher(
                duration: Motion.of(context, Motion.press),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  filled ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(filled),
                  color: filled ? colors.primary : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "MashaAllah, it's a match!" with what changes now.
Future<void> showMatchCelebration(
  BuildContext context,
  ProfileCard card, {
  VoidCallback? onViewMatches,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) {
      final s = AppLocalizations.of(sheet);
      final theme = Theme.of(sheet);
      final colors = theme.colorScheme;
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
              EnterTransition(
                child: Center(
                  child: ShukaansiIconBadge(
                    icon: Icons.favorite,
                    size: 96,
                    color: colors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  s.matchTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                s.matchBody(displayName(card.profile.name)),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.l),
              ShukaansiFeatureCard(
                icon: Icons.photo_library_outlined,
                title: s.matchPhotosNote,
                body: s.matchMessagingSoon,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (onViewMatches != null)
                Pressable(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(sheet).pop();
                      onViewMatches();
                    },
                    child: Text(s.viewMatches),
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
}

/// A small photo of a member, blurred when she has not shared her photos.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.card,
    required this.discovery,
    this.size = 72,
  });
  final ProfileCard card;
  final DiscoveryController discovery;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: discovery,
      builder: (context, _) {
        discovery.ensureAccess(card);
        final first = card.photoIds.isEmpty ? null : card.photoIds.first;
        if (first != null) discovery.ensureImage(card, first);
        final originals = discovery.showsOriginals(card);
        final bytes = first == null
            ? null
            : discovery.images[DiscoveryController.imageKey(
                card,
                first,
                !originals,
              )];
        Widget image = bytes == null || bytes.isEmpty
            ? ColoredBox(
                color: colors.primary.withValues(alpha: 0.10),
                child: Icon(Icons.person, color: colors.primary),
              )
            : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
        if (!originals && bytes != null && bytes.isNotEmpty) {
          image = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: image,
          );
        }
        return ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: SizedBox.square(dimension: size, child: image),
          ),
        );
      },
    );
  }
}

/// A member in the Likes or Matches lists: photo, name and age, place, and
/// any actions underneath.
class MemberRow extends StatelessWidget {
  const MemberRow({
    super.key,
    required this.card,
    required this.discovery,
    required this.onOpen,
    this.note,
    this.actions = const [],
  });
  final ProfileCard card;
  final DiscoveryController discovery;
  final VoidCallback onOpen;
  final String? note;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final p = card.profile;
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Semantics(
              button: true,
              hint: s.viewProfile,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Row(
                  children: [
                    MemberAvatar(card: card, discovery: discovery),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  s.cardNameAge(
                                    p.name,
                                    card.ageOn(discovery.now),
                                  ),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (card.verified) ...[
                                const SizedBox(width: AppSpacing.xs),
                                const VerifiedBadge(),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.cardLocation(
                              p.city,
                              countryName(context, p.residenceCountry),
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (note != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              note!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ExcludeSemantics(
                      child: Icon(
                        Icons.chevron_right,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                0,
                AppSpacing.m,
                AppSpacing.m,
              ),
              child: Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                alignment: WrapAlignment.end,
                children: actions,
              ),
            ),
        ],
      ),
    );
  }
}
