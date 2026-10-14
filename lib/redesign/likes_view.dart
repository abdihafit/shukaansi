import 'package:flutter/material.dart';

import '../application/discovery_controller.dart';
import '../application/interest_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../models/interest.dart';
import '../theme/tokens.dart';
import 'member_page.dart';
import '../widgets/brand/brand.dart';

/// Likes: who showed interest in you, and whom you showed interest in, as
/// photo-led tiles. States follow the real rules (e.g. Premium for a match).
class LikesView extends StatefulWidget {
  const LikesView({
    super.key,
    required this.interests,
    required this.discovery,
    required this.openMember,
    required this.onBrowse,
  });
  final InterestController interests;
  final DiscoveryController discovery;
  final ValueChanged<ProfileCard> openMember;
  final VoidCallback onBrowse;

  @override
  State<LikesView> createState() => _LikesViewState();
}

class _LikesViewState extends State<LikesView> {
  bool _sent = false;

  String _status(AppLocalizations s, ProfileCard card) =>
      switch (widget.interests.stateOf(card.uid)) {
        InterestState.mutual => s.likeStatusMutual,
        InterestState.likedYou => s.likeStatusLikesYou,
        InterestState.matched => s.matchedLabel,
        _ => s.likeStatusWaiting,
      };

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final interests = widget.interests;
    return Scaffold(
      appBar: AppBar(title: Text(s.navLikes), automaticallyImplyLeading: false),
      body: ListenableBuilder(
        listenable: Listenable.merge([interests, widget.discovery]),
        builder: (context, _) {
          final entries = _sent ? interests.sent : interests.received;
          final Widget content;
          if (!interests.loaded && interests.loading) {
            content = const PortraitGridSkeleton();
          } else if (interests.loadFailed && !interests.loaded) {
            content = EmptyState(
              icon: Icons.wifi_off,
              title: s.networkErrorTitle,
              message: s.likesLoadFailed,
              actionLabel: s.retry,
              onAction: interests.load,
            );
          } else if (entries.isEmpty) {
            content = EmptyState(
              icon: _sent ? Icons.favorite_border : Icons.favorite,
              title: _sent ? s.likesSentTab : s.likesReceivedTab,
              message: _sent ? s.likesSentEmpty : s.likesReceivedEmpty,
              actionLabel: s.browseDiscover,
              onAction: widget.onBrowse,
            );
          } else {
            content = RefreshIndicator(
              onRefresh: interests.load,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Tile height follows the portrait width plus the text
                  // below it at the current text size, so large text and
                  // longer translations never clip.
                  const maxTile = 240.0;
                  const gap = AppSpacing.m;
                  final width = constraints.maxWidth - AppSpacing.l * 2;
                  final columns = ((width + gap) / (maxTile + gap)).ceil();
                  final tileWidth = (width - gap * (columns - 1)) / columns;
                  final theme = Theme.of(context);
                  final scaler = MediaQuery.textScalerOf(context);
                  double line(TextStyle? style) => scaler.scale(
                    (style?.fontSize ?? 14) * (style?.height ?? 1.4),
                  );
                  final extent =
                      tileWidth / AppSizes.portrait +
                      AppSpacing.s +
                      line(theme.textTheme.titleMedium) +
                      line(theme.textTheme.bodySmall) * 2 +
                      AppSpacing.xs;
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.l,
                      crossAxisSpacing: gap,
                      mainAxisExtent: extent,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, i) => PortraitTile(
                      card: entries[i].card,
                      discovery: widget.discovery,
                      status: _status(s, entries[i].card),
                      onTap: () => widget.openMember(entries[i].card),
                    ),
                  );
                },
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  0,
                  AppSpacing.l,
                  AppSpacing.s,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(
                          '${s.likesReceivedTab} (${interests.received.length})',
                        ),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(
                          '${s.likesSentTab} (${interests.sent.length})',
                        ),
                      ),
                    ],
                    selected: {_sent},
                    onSelectionChanged: (v) => setState(() => _sent = v.first),
                  ),
                ),
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}
