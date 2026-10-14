import 'package:flutter/material.dart';

import '../application/discovery_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../models/moderation.dart';
import '../services/moderation_service.dart';
import 'brand/brand.dart';
import '../screens/profile_labels.dart';

String reportReasonLabel(AppLocalizations s, ReportReason reason) =>
    switch (reason) {
      ReportReason.fakeProfile => s.reportReasonFakeProfile,
      ReportReason.inappropriatePhotos => s.reportReasonInappropriatePhotos,
      ReportReason.harassment => s.reportReasonHarassment,
      ReportReason.scam => s.reportReasonScam,
      ReportReason.underage => s.reportReasonUnderage,
      ReportReason.notSerious => s.reportReasonNotSerious,
      ReportReason.other => s.reportReasonOther,
    };

enum _CardAction { report, block }

/// The ⋮ menu on a Discover card: report or block this member.
class CardSafetyMenu extends StatelessWidget {
  const CardSafetyMenu({
    super.key,
    required this.card,
    required this.controller,
  });
  final ProfileCard card;
  final DiscoveryController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return PopupMenuButton<_CardAction>(
      tooltip: s.cardMoreActions(displayName(card.profile.name)),
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => switch (action) {
        _CardAction.report => _report(context),
        _CardAction.block => _block(context),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _CardAction.report,
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: Text(s.reportAction),
          ),
        ),
        PopupMenuItem(
          value: _CardAction.block,
          child: ListTile(
            leading: const Icon(Icons.block),
            title: Text(s.blockAction),
          ),
        ),
      ],
    );
  }

  Future<void> _report(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = AppLocalizations.of(context);
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ReportSheet(card: card, controller: controller),
    );
    if (sent == true) {
      messenger.showSnackBar(SnackBar(content: Text(s.reportSent)));
    }
  }

  Future<void> _block(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = AppLocalizations.of(context);
    final name = displayName(card.profile.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.blockTitle(name)),
        content: Text(s.blockBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.profileCancelEdit),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(s.blockAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!await controller.block(card)) {
      messenger.showSnackBar(SnackBar(content: Text(s.blockFailed)));
    }
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.card, required this.controller});
  final ProfileCard card;
  final DiscoveryController controller;
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason? _reason;
  final _note = TextEditingController();
  bool _alsoBlock = false;
  bool _busy = false;
  bool _failed = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final ok = await widget.controller.report(
      widget.card,
      _reason!,
      _note.text,
      alsoBlock: _alsoBlock,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = displayName(widget.card.profile.name);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.reportTitle(name), style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(s.reportBody(name)),
            const SizedBox(height: 12),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) {
                if (!_busy) setState(() => _reason = value);
              },
              child: Column(
                children: [
                  for (final reason in ReportReason.values)
                    RadioListTile<ReportReason>(
                      contentPadding: EdgeInsets.zero,
                      value: reason,
                      title: Text(reportReasonLabel(s, reason)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              enabled: !_busy,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: s.reportNote,
                border: const OutlineInputBorder(),
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _alsoBlock,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _alsoBlock = value ?? false),
              title: Text(s.reportAlsoBlock(name)),
            ),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  s.reportFailed,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            PrimaryButton(
              onPressed: _reason == null ? null : _submit,
              loading: _busy,
              loadingLabel: s.authLoading,
              label: s.reportSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Owner list of blocked members with Unblock; hidden when empty.
class BlockedMembersSection extends StatefulWidget {
  const BlockedMembersSection({
    super.key,
    required this.uid,
    required this.moderation,
    this.onChanged,
  });
  final String uid;
  final ModerationService moderation;
  final VoidCallback? onChanged;
  @override
  State<BlockedMembersSection> createState() => _BlockedMembersSectionState();
}

class _BlockedMembersSectionState extends State<BlockedMembersSection> {
  late Future<List<BlockedMember>> _blocked = widget.moderation.blocked(
    widget.uid,
  );
  final Set<String> _busy = {};

  Future<void> _unblock(BlockedMember member) async {
    setState(() => _busy.add(member.uid));
    try {
      await widget.moderation.unblock(widget.uid, member.uid);
      widget.onChanged?.call();
      if (mounted) {
        setState(() => _blocked = widget.moderation.blocked(widget.uid));
      }
    } catch (_) {
      // The list is unchanged; the button becomes available again.
    } finally {
      if (mounted) setState(() => _busy.remove(member.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<List<BlockedMember>>(
      future: _blocked,
      builder: (context, snapshot) {
        final members = snapshot.data ?? const [];
        if (members.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.blockedTitle, style: theme.textTheme.titleMedium),
              for (final member in members)
                Row(
                  children: [
                    Expanded(child: Text(displayName(member.name))),
                    TextButton(
                      onPressed: _busy.contains(member.uid)
                          ? null
                          : () => _unblock(member),
                      child: Text(s.unblockAction),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
