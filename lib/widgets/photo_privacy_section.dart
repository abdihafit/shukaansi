import 'package:flutter/material.dart';

import '../application/media_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../services/discovery_service.dart';
import 'brand/brand.dart';
import '../screens/profile_labels.dart';

/// Women only: blur photos in Discover, and decide who may see them.
class PhotoPrivacySection extends StatefulWidget {
  const PhotoPrivacySection({
    super.key,
    required this.uid,
    required this.media,
    required this.discovery,
    this.today,
  });
  final String uid;
  final MediaController media;
  final DiscoveryService discovery;
  final DateTime? today;
  @override
  State<PhotoPrivacySection> createState() => _PhotoPrivacySectionState();
}

class _PhotoPrivacySectionState extends State<PhotoPrivacySection> {
  late Future<(List<ProfileCard>, List<ProfileCard>)> _people = _load();
  final Set<String> _busy = {};
  bool _actionFailed = false;

  Future<(List<ProfileCard>, List<ProfileCard>)> _load() async => (
    await widget.discovery.photoRequests(widget.uid),
    await widget.discovery.photoViewers(widget.uid),
  );

  void _reload() => setState(() => _people = _load());

  Future<void> _act(String viewer, Future<void> Function() action) async {
    setState(() {
      _busy.add(viewer);
      _actionFailed = false;
    });
    try {
      await action();
      if (mounted) _reload();
    } catch (_) {
      if (mounted) setState(() => _actionFailed = true);
    } finally {
      if (mounted) setState(() => _busy.remove(viewer));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final today = widget.today ?? DateTime.now();
    return ListenableBuilder(
      listenable: widget.media,
      builder: (context, _) {
        final media = widget.media;
        Widget person(ProfileCard card, List<Widget> actions) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        s.cardNameAge(
                          displayName(card.profile.name),
                          card.ageOn(today),
                        ),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    if (card.verified) ...[
                      const SizedBox(width: 4),
                      const VerifiedBadge(size: 18),
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: media.blurred,
              onChanged: media.busy || media.loading
                  ? null
                  : (value) => media.setBlurred(value),
              title: Text(s.blurTitle, style: theme.textTheme.titleMedium),
              subtitle: Text(s.blurBody),
            ),
            FutureBuilder(
              future: _people,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError) {
                  // Stacked so a long retry label never overflows.
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.requestsLoadFailed),
                      TextButton(onPressed: _reload, child: Text(s.retry)),
                    ],
                  );
                }
                final (requests, viewers) = snapshot.data!;
                if (!media.blurred && requests.isEmpty && viewers.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text(s.requestsTitle, style: theme.textTheme.titleSmall),
                    if (requests.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          s.requestsEmpty,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ),
                    for (final card in requests)
                      person(card, [
                        TextButton(
                          onPressed: _busy.contains(card.uid)
                              ? null
                              : () => _act(
                                  card.uid,
                                  () => widget.discovery.decline(
                                    widget.uid,
                                    card.uid,
                                  ),
                                ),
                          child: Text(s.requestsDecline),
                        ),
                        FilledButton.tonal(
                          onPressed: _busy.contains(card.uid)
                              ? null
                              : () => _act(
                                  card.uid,
                                  () => widget.discovery.approve(
                                    widget.uid,
                                    card.uid,
                                  ),
                                ),
                          child: Text(s.requestsApprove),
                        ),
                      ]),
                    if (viewers.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(s.viewersTitle, style: theme.textTheme.titleSmall),
                      for (final card in viewers)
                        person(card, [
                          TextButton(
                            onPressed: _busy.contains(card.uid)
                                ? null
                                : () => _act(
                                    card.uid,
                                    () => widget.discovery.revoke(
                                      widget.uid,
                                      card.uid,
                                    ),
                                  ),
                            child: Text(s.viewersRemove),
                          ),
                        ]),
                    ],
                    if (_actionFailed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          s.accountActionFailed,
                          style: TextStyle(color: colors.error),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
