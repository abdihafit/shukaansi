import 'dart:async';

import 'package:flutter/material.dart';

import '../application/discovery_controller.dart';
import '../application/interest_controller.dart';
import '../application/wali_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/chat.dart';
import '../models/discovery.dart';
import '../models/wali.dart';
import '../services/chat_service.dart';
import '../theme/tokens.dart';
import '../widgets/interest_widgets.dart';
import '../widgets/safety_actions.dart';
import '../widgets/shukaansi_ui.dart';
import '../redesign/member_page.dart';
import 'profile_labels.dart';

/// Whether two matched members may write to each other yet.
bool canMessage(WaliController? wali, ProfileCard card) =>
    wali == null ||
    wali.approvalFor(
          card.uid,
          otherRequired: waliRequired(card.profile.gender),
        ) ==
        MatchApproval.ready;

/// Short time for a message or conversation: the time today, "Yesterday",
/// or the date.
String chatTime(BuildContext context, DateTime time, DateTime now) {
  final m = MaterialLocalizations.of(context);
  final day = DateTime(time.year, time.month, time.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) {
    return m.formatTimeOfDay(
      TimeOfDay.fromDateTime(time),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }
  if (today.difference(day).inDays == 1) {
    return AppLocalizations.of(context).chatYesterday;
  }
  return m.formatShortDate(time);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.uid,
    required this.card,
    required this.chats,
    required this.discovery,
    required this.interests,
    this.wali,
    this.today,
  });
  final String uid;
  final ProfileCard card;
  final ChatService chats;
  final DiscoveryController discovery;
  final InterestController interests;
  final WaliController? wali;
  final DateTime? today;

  static Future<void> open(
    BuildContext context, {
    required String uid,
    required ProfileCard card,
    required ChatService chats,
    required DiscoveryController discovery,
    required InterestController interests,
    WaliController? wali,
    DateTime? today,
  }) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChatScreen(
        uid: uid,
        card: card,
        chats: chats,
        discovery: discovery,
        interests: interests,
        wali: wali,
        today: today,
      ),
    ),
  );

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  late final Stream<List<ChatMessage>> _messages = widget.chats.messages(
    widget.uid,
    widget.card.uid,
  );
  bool _sending = false;
  String? _lastReadId;

  @override
  void initState() {
    super.initState();
    // A block or unmatch from elsewhere closes the conversation.
    widget.discovery.addListener(_closeIfGone);
    widget.interests.addListener(_closeIfGone);
  }

  void _closeIfGone() {
    if (!mounted) return;
    final blocked = widget.discovery.hidden.contains(widget.card.uid);
    final unmatched = !widget.interests.matches.any(
      (e) => e.card.uid == widget.card.uid,
    );
    if (blocked || (widget.interests.loaded && unmatched)) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    widget.discovery.removeListener(_closeIfGone);
    widget.interests.removeListener(_closeIfGone);
    _text.dispose();
    super.dispose();
  }

  void _markRead(List<ChatMessage> messages) {
    if (messages.isEmpty || messages.last.id == _lastReadId) return;
    _lastReadId = messages.last.id;
    unawaited(widget.chats.markRead(widget.uid, widget.card.uid));
  }

  Future<void> _send() async {
    final s = AppLocalizations.of(context);
    final body = _text.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.chats.send(widget.uid, widget.card.uid, body);
      _text.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.messageSendFailed)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final card = widget.card;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => MemberPage.open(
            context,
            MemberPage(
              card: card,
              discovery: widget.discovery,
              interests: widget.interests,
              wali: widget.wali,
              today: widget.today,
              // Already in the conversation: Message returns to it.
              onMessage: (_) => Navigator.of(context).pop(),
              onViewMatches: () => Navigator.of(context).pop(),
            ),
          ),
          child: Semantics(
            button: true,
            hint: s.viewProfile,
            child: Row(
              children: [
                MemberAvatar(card: card, discovery: widget.discovery, size: 40),
                const SizedBox(width: AppSpacing.m),
                Flexible(
                  child: Text(
                    displayName(card.profile.name),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [CardSafetyMenu(card: card, controller: widget.discovery)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _messages,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(s.chatsLoadFailed));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data!;
                  _markRead(messages);
                  if (messages.isEmpty) return _Starter(onSalaam: _salaam);
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(AppSpacing.l),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[messages.length - 1 - index];
                      return _Bubble(
                        message: m,
                        mine: m.from == widget.uid,
                        otherName: displayName(card.profile.name),
                        now: widget.today ?? DateTime.now(),
                      );
                    },
                  );
                },
              ),
            ),
            ListenableBuilder(
              listenable: Listenable.merge([?widget.wali]),
              builder: (context, _) => canMessage(widget.wali, card)
                  ? _composer(context, s)
                  : _locked(context, s, theme),
            ),
          ],
        ),
      ),
    );
  }

  void _salaam() {
    final s = AppLocalizations.of(context);
    _text.text = s.chatStarterSalaam;
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
  }

  Widget _composer(BuildContext context, AppLocalizations s) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.s,
          AppSpacing.s,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                minLines: 1,
                maxLines: 5,
                maxLength: maxMessageLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: s.messageHint,
                  counterText: '',
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            IconButton.filled(
              tooltip: s.messageSend,
              onPressed: _sending ? null : _send,
              style: IconButton.styleFrom(minimumSize: const Size.square(48)),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locked(BuildContext context, AppLocalizations s, ThemeData theme) {
    final wali = widget.wali;
    final card = widget.card;
    final status = wali?.approvalFor(
      card.uid,
      otherRequired: waliRequired(card.profile.gender),
    );
    final reason = switch (status) {
      MatchApproval.needsYourWali => s.approvalNeedsWali,
      MatchApproval.waitingYourWali => s.approvalWaitingYours,
      MatchApproval.waitingTheirWali => s.approvalWaitingTheirs,
      MatchApproval.declined => s.approvalDeclined,
      _ => s.chatLocked,
    };
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: SectionCard(
        tinted: true,
        child: Row(
          children: [
            ShukaansiIconBadge(
              icon: Icons.family_restroom,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(s.chatLocked, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Starter extends StatelessWidget {
  const _Starter({required this.onSalaam});
  final VoidCallback onSalaam;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          ShukaansiIconBadge(
            icon: Icons.waving_hand_outlined,
            size: 72,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            s.chatStarterTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            s.chatStarterBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          ActionChip(
            avatar: const Icon(Icons.edit_outlined),
            label: Text(s.chatStarterSalaam),
            onPressed: onSalaam,
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.otherName,
    required this.now,
  });
  final ChatMessage message;
  final bool mine;
  final String otherName;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final sent = message.sentAt;
    final time = sent == null ? '' : chatTime(context, sent, now);
    final foreground = mine ? colors.onPrimary : colors.onSurface;
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Semantics(
          label:
              '${mine ? s.messageFromYou : s.messageFrom(otherName)}: '
              '${message.text}${time.isEmpty ? '' : ', $time'}',
          excludeSemantics: true,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.s),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.m + 2,
              AppSpacing.s + 2,
              AppSpacing.m + 2,
              AppSpacing.s,
            ),
            decoration: BoxDecoration(
              color: mine ? colors.primary : colors.surfaceContainerHigh,
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(AppRadius.card),
                topEnd: const Radius.circular(AppRadius.card),
                bottomStart: Radius.circular(mine ? AppRadius.card : 4),
                bottomEnd: Radius.circular(mine ? 4 : AppRadius.card),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: foreground.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
