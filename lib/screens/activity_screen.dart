import 'package:flutter/material.dart';

import '../application/activity_controller.dart';
import '../application/discovery_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/interest_widgets.dart';
import '../widgets/shukaansi_ui.dart';
import 'chat_screen.dart';
import 'profile_labels.dart';

/// What a notification says.
String activityText(AppLocalizations s, ActivityItem item) {
  final name = displayName(item.card.profile.name);
  return switch (item.kind) {
    ActivityKind.interest => s.activityLiked(name),
    ActivityKind.match => s.activityMatched(name),
    ActivityKind.yourWaliApproved => s.activityYourWaliApproved(name),
    ActivityKind.yourWaliDeclined => s.activityYourWaliDeclined(name),
    ActivityKind.theirWaliApproved => s.activityTheirWaliApproved(name),
    ActivityKind.theirWaliDeclined => s.activityTheirWaliDeclined(name),
    ActivityKind.message => s.activityMessage(name),
  };
}

IconData activityIcon(ActivityKind kind) => switch (kind) {
  ActivityKind.interest => Icons.favorite,
  ActivityKind.match => Icons.people,
  ActivityKind.yourWaliApproved ||
  ActivityKind.theirWaliApproved => Icons.verified_user,
  ActivityKind.yourWaliDeclined ||
  ActivityKind.theirWaliDeclined => Icons.block,
  ActivityKind.message => Icons.chat_bubble,
};

/// The bell in the app bar, with the number of new notifications.
class ActivityBell extends StatelessWidget {
  const ActivityBell({
    super.key,
    required this.activity,
    required this.onPressed,
  });
  final ActivityController activity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: activity,
      builder: (context, _) {
        final count = activity.newCount;
        return IconButton(
          tooltip: s.activityTitle,
          onPressed: onPressed,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count', semanticsLabel: s.likesNewCount(count)),
            child: Icon(
              count > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none,
            ),
          ),
        );
      },
    );
  }
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({
    super.key,
    required this.activity,
    required this.discovery,
    required this.onOpen,
    this.today,
  });
  final ActivityController activity;
  final DiscoveryController discovery;

  /// Goes to where the item belongs (Likes, Matches or the conversation).
  final ValueChanged<ActivityItem> onOpen;
  final DateTime? today;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  /// New items when the screen opened, so they stay marked while reading.
  late final Set<String> _newWhenOpened;

  @override
  void initState() {
    super.initState();
    _newWhenOpened = {
      for (final i in widget.activity.items)
        if (widget.activity.isNew(i)) i.id,
    };
    // After the first frame: marking notifies listeners such as the bell.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.activity.markAllSeen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.activityTitle)),
      body: ListenableBuilder(
        listenable: widget.activity,
        builder: (context, _) {
          final items = widget.activity.items;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.l),
            children: [
              if (items.isEmpty)
                SectionCard(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    children: [
                      const ShukaansiIconBadge(
                        icon: Icons.notifications_none,
                        size: 72,
                      ),
                      const SizedBox(height: AppSpacing.l),
                      Text(
                        s.activityEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              for (final item in items) ...[
                SectionCard(
                  tinted: _newWhenOpened.contains(item.id),
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.xs,
                    ),
                    leading: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        MemberAvatar(
                          card: item.card,
                          discovery: widget.discovery,
                          size: 48,
                        ),
                        PositionedDirectional(
                          end: -6,
                          bottom: -6,
                          child: ShukaansiIconBadge(
                            icon: activityIcon(item.kind),
                            size: 26,
                            color: colors.secondary,
                          ),
                        ),
                      ],
                    ),
                    title: Text(activityText(s, item)),
                    subtitle: item.at == null
                        ? null
                        : Text(
                            chatTime(
                              context,
                              item.at!,
                              widget.today ?? DateTime.now(),
                            ),
                          ),
                    trailing: _newWhenOpened.contains(item.id)
                        ? ShukaansiStatusChip(
                            label: s.activityNew,
                            icon: Icons.fiber_new_outlined,
                            tone: StatusTone.positive,
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => widget.onOpen(item),
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              const SizedBox(height: AppSpacing.l),
              Text(
                s.activityOpenOnly,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
