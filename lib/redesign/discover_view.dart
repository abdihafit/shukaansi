import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/discovery_controller.dart';
import '../application/interest_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../models/interest.dart';
import '../theme/tokens.dart';
import '../widgets/interest_widgets.dart';
import '../widgets/partner_preferences_sheet.dart';
import '../widgets/safety_actions.dart';
import 'member_profile_view.dart';
import 'photos.dart';
import '../widgets/brand/brand.dart';
import '../screens/profile_labels.dart';

/// Discover, one member at a time. People come first: a compact header with
/// one filter entry point, the profile filling the screen, and Pass / Like
/// below the content so nothing covers it.
class DiscoverView extends StatefulWidget {
  const DiscoverView({
    super.key,
    required this.discovery,
    required this.interests,
    required this.onOpenProfile,
    required this.onViewMatches,
    this.notifications,
    this.conceptFor,
    this.today,
  });
  final DiscoveryController discovery;
  final InterestController interests;

  /// Opens My profile (to finish setup).
  final VoidCallback onOpenProfile;
  final VoidCallback onViewMatches;
  final Widget? notifications;

  /// Preview only: proposed profile content per member.
  final ProfileConcept? Function(String uid)? conceptFor;
  final DateTime? today;

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  /// Members passed or liked this session; the next one is shown instead.
  /// Passing is local for now (no server-side "hide" exists yet).
  final Set<String> _dismissed = {};
  bool _promptClosed = false;

  DiscoveryController get _d => widget.discovery;

  ProfileCard? _current() {
    for (final card in _d.cards) {
      if (_dismissed.contains(card.uid)) continue;
      final state = widget.interests.stateOf(card.uid);
      // Already liked, mutual or matched: nothing more to decide here.
      if (state == InterestState.none || state == InterestState.likedYou) {
        return card;
      }
    }
    return null;
  }

  void _pass(ProfileCard card) {
    final s = AppLocalizations.of(context);
    setState(() => _dismissed.add(card.uid));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(s.passedName(displayName(card.profile.name))),
          // Floats above the Pass / Like bar instead of covering it.
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            0,
            AppSpacing.l,
            AppSizes.likeButton + AppSpacing.m * 2 + AppSpacing.s,
          ),
          action: SnackBarAction(
            label: s.undoAction,
            onPressed: () => setState(() => _dismissed.remove(card.uid)),
          ),
        ),
      );
    _maybeLoadMore();
  }

  Future<void> _like(ProfileCard card) async {
    await likeMember(
      context,
      card,
      widget.interests,
      _d,
      onViewMatches: widget.onViewMatches,
    );
    if (!mounted) return;
    if (widget.interests.stateOf(card.uid) != InterestState.none) {
      setState(() => _dismissed.add(card.uid));
      _maybeLoadMore();
    }
  }

  void _maybeLoadMore() {
    if (_current() == null && _d.hasMore) _d.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_d, widget.interests]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: _FeedMenu(discovery: _d),
          actions: [
            if (_d.listed && _d.feed == DiscoverFeed.forYou)
              IconButton(
                tooltip: s.partnerPreferences,
                onPressed: () => editPartnerPreferences(context, _d),
                icon: Badge(
                  isLabelVisible: !_d.filter.isDefault,
                  smallSize: 8,
                  child: const Icon(Icons.tune),
                ),
              ),
            ?widget.notifications,
            const SizedBox(width: AppSpacing.xs),
          ],
        ),
        body: _body(context, s),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations s) {
    if (_d.status == null) {
      if (_d.syncFailed) return _networkError(s);
      return const ProfileSkeleton();
    }
    if (!_d.listed) {
      final missing = _d.status!.missing;
      return EmptyState(
        icon: Icons.visibility_outlined,
        title: s.discoverNotListedTitle,
        message: s.discoverNotListedBody,
        actionLabel: s.discoverGoToProfile,
        onAction: widget.onOpenProfile,
        secondaryLabel: s.discoverCheckAgain,
        onSecondary: _d.refresh,
        children: [
          const SizedBox(height: AppSpacing.l),
          for (final (gap, label) in [
            (ListingGap.emailNotVerified, s.discoverNeedEmail),
            (ListingGap.noPhoto, s.discoverNeedPhoto),
          ])
            _Check(done: !missing.contains(gap), label: label),
        ],
      );
    }
    final card = _current();
    if (card == null) {
      if (_d.loadingPage) return const ProfileSkeleton();
      if (_d.pageFailed) return _networkError(s, retry: _d.loadMore);
      if (_d.cards.isEmpty) {
        if (_d.feed == DiscoverFeed.newMembers) {
          return EmptyState(
            icon: Icons.group_outlined,
            title: s.discoverNewMembers,
            message: s.newMembersEmpty,
            actionLabel: s.discoverCheckAgain,
            onAction: _d.refresh,
          );
        }
        if (!_d.hasPreferences) {
          return EmptyState(
            icon: Icons.tune,
            title: s.forYouSetupTitle,
            message: s.forYouSetupBody,
            actionLabel: s.setPreferences,
            onAction: () => editPartnerPreferences(context, _d),
          );
        }
        return EmptyState(
          icon: Icons.search_off,
          title: s.noMatchesTitle,
          message: s.noMatchesBody,
          actionLabel: s.adjustPreferences,
          onAction: () => editPartnerPreferences(context, _d),
        );
      }
      return EmptyState(
        icon: Icons.done_all,
        title: s.seenEveryoneTitle,
        message: s.seenEveryoneBody,
        actionLabel: s.discoverCheckAgain,
        onAction: () {
          setState(_dismissed.clear);
          _d.refresh();
        },
      );
    }
    final photos = DiscoveryPhotos(_d, card);
    // Actions sit in their own bar below the profile, so they never cover a
    // face, a name or text, whatever the screen or text size.
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, viewport) => RefreshIndicator(
              onRefresh: _d.refresh,
              child: ListView(
                key: ValueKey(card.uid),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.xs,
                  AppSpacing.l,
                  0,
                ),
                children: [
                  // A gentle, dismissible nudge; people stay first on screen.
                  if (!_d.hasPreferences &&
                      _d.feed == DiscoverFeed.forYou &&
                      !_promptClosed)
                    _PreferencesPrompt(
                      onSet: () => editPartnerPreferences(context, _d),
                      onClose: () => setState(() => _promptClosed = true),
                    ),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: MemberProfileView(
                        card: card,
                        photos: photos,
                        today: _d.now,
                        concept: widget.conceptFor?.call(card.uid),
                        menu: CardSafetyMenu(card: card, controller: _d),
                        privatePhotos: photos.showsOriginals
                            ? null
                            : _PrivatePhotosNote(card: card, discovery: _d),
                        bottomPadding: AppSpacing.xl,
                        // Leave room for the name line under the photo.
                        // The card fills the visible area above the actions.
                        leadPhotoMaxHeight:
                            viewport.maxHeight - AppSpacing.l * 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _Actions(
          busy: widget.interests.busy.contains(card.uid),
          onPass: () {
            HapticFeedback.lightImpact();
            _pass(card);
          },
          onLike: () {
            HapticFeedback.mediumImpact();
            _like(card);
          },
        ),
      ],
    );
  }

  Widget _networkError(AppLocalizations s, {VoidCallback? retry}) => EmptyState(
    icon: Icons.wifi_off,
    title: s.networkErrorTitle,
    message: s.networkErrorBody,
    actionLabel: s.retry,
    onAction: retry ?? _d.refresh,
  );
}

class _FeedMenu extends StatelessWidget {
  const _FeedMenu({required this.discovery});
  final DiscoveryController discovery;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final label = discovery.feed == DiscoverFeed.forYou
        ? s.discoverForYou
        : s.discoverNewMembers;
    return PopupMenuButton<DiscoverFeed>(
      tooltip: s.navDiscover,
      initialValue: discovery.feed,
      onSelected: discovery.showFeed,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: DiscoverFeed.forYou,
          child: Text(s.discoverForYou),
        ),
        PopupMenuItem(
          value: DiscoverFeed.newMembers,
          child: Text(s.discoverNewMembers),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.touch),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.busy,
    required this.onPass,
    required this.onLike,
  });
  final bool busy;
  final VoidCallback onPass;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Material(
              color: colors.surfaceContainerLowest,
              shape: CircleBorder(
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: IconButton(
                tooltip: s.passAction,
                onPressed: busy ? null : onPass,
                iconSize: 28,
                constraints: const BoxConstraints.tightFor(
                  width: AppSizes.passButton,
                  height: AppSizes.passButton,
                ),
                icon: Icon(Icons.close, color: colors.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: AppSpacing.xxl),
            Material(
              color: colors.primary,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: s.likeAction,
                onPressed: busy ? null : onLike,
                iconSize: 30,
                constraints: const BoxConstraints.tightFor(
                  width: AppSizes.likeButton,
                  height: AppSizes.likeButton,
                ),
                icon: Icon(Icons.favorite, color: colors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivatePhotosNote extends StatelessWidget {
  const _PrivatePhotosNote({required this.card, required this.discovery});
  final ProfileCard card;
  final DiscoveryController discovery;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = discovery.access[card.uid];
    final busy = discovery.accessBusy.contains(card.uid);
    final requested = state == PhotoAccess.requested;
    final colors = theme.colorScheme;
    // Under the photo, never over it: what is private, why, and the one
    // thing the viewer can do about it.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.m),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(Icons.lock_outline, color: colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.photosPrivateTitle,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.photosPrivateBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (state != null) ...[
                const SizedBox(height: AppSpacing.m),
                Wrap(
                  spacing: AppSpacing.s,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (requested) ...[
                      // A status, not an action; cancelling sits beside it.
                      OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check),
                        label: Text(s.photosRequested),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => discovery.cancelRequest(card),
                        child: Text(s.photosCancelRequest),
                      ),
                    ] else
                      ElevatedButton.icon(
                        onPressed: busy
                            ? null
                            : () => discovery.requestPhotos(card),
                        icon: const Icon(Icons.visibility_outlined),
                        label: Text(s.photosRequest),
                      ),
                  ],
                ),
              ],
              if (discovery.requestFailedFor == card.uid) ...[
                const SizedBox(height: AppSpacing.s),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    s.photosRequestFailed,
                    style: TextStyle(color: colors.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferencesPrompt extends StatelessWidget {
  const _PreferencesPrompt({required this.onSet, required this.onClose});
  final VoidCallback onSet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.l,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          // The action sits on its own line so long labels and large text
          // never push it off screen.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, color: theme.colorScheme.secondary),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      s.forYouSetupTitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xxl,
                ),
                child: TextButton(
                  onPressed: onSet,
                  child: Text(s.setPreferences),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.done, required this.label});
  final bool done;
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      checked: done,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? colors.primary : colors.outline,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
