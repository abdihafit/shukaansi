import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../models/wali.dart';
import '../services/wali_service.dart';
import '../theme/tokens.dart';
import '../widgets/pressable.dart';
import '../widgets/shukaansi_ui.dart';
import '../widgets/brand/brand.dart';
import 'legal_consent_screen.dart';
import 'profile_labels.dart';

/// Shown above profile onboarding: a way in for guardians.
class WaliEntryCard extends StatelessWidget {
  const WaliEntryCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SectionCard(
      tinted: true,
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.xs,
        ),
        leading: ShukaansiIconBadge(
          icon: Icons.family_restroom,
          color: Theme.of(context).colorScheme.secondary,
        ),
        title: Text(s.roleWali),
        subtitle: Text(s.roleWaliBody),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// A guardian joins with their name and the member's invite code.
class WaliSetup extends StatefulWidget {
  const WaliSetup({
    super.key,
    required this.uid,
    required this.service,
    required this.onJoined,
    this.onBack,
    this.knownName,
  });
  final String uid;
  final WaliService service;
  final ValueChanged<GuardianAccount> onJoined;
  final VoidCallback? onBack;

  /// Set when an existing guardian adds another member.
  final String? knownName;
  @override
  State<WaliSetup> createState() => _WaliSetupState();
}

class _WaliSetupState extends State<WaliSetup> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.knownName ?? '');
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (!_form.currentState!.validate()) return;
    final s = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final account = await widget.service.becomeGuardian(
        widget.uid,
        _name.text.trim(),
        _code.text,
      );
      if (mounted) widget.onJoined(account);
    } on WaliCodeException {
      if (mounted) setState(() => _error = s.waliCodeInvalid);
    } catch (_) {
      if (mounted) setState(() => _error = s.interestFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ShukaansiIconBadge(
              icon: Icons.family_restroom,
              size: 88,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Semantics(
            header: true,
            child: Text(
              s.waliSetupTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            s.waliSetupBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (widget.knownName == null) ...[
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              maxLength: 50,
              decoration: InputDecoration(labelText: s.waliYourName),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? s.fieldRequired : null,
            ),
            const SizedBox(height: AppSpacing.m),
          ],
          TextFormField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            decoration: InputDecoration(labelText: s.waliCode),
            validator: (v) =>
                isWaliCode(cleanWaliCode(v ?? '')) ? null : s.waliCodeInvalid,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.m),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Pressable(
            enabled: !_busy,
            child: PrimaryButton(
              onPressed: _join,
              loading: _busy,
              loadingLabel: s.authLoading,
              label: s.waliJoin,
            ),
          ),
          if (widget.onBack != null)
            TextButton(
              onPressed: _busy ? null : widget.onBack,
              child: Text(s.profileBack),
            ),
        ],
      ),
    );
  }
}

/// The guardian's home: whom they look after and the matches to decide.
class WaliHome extends StatefulWidget {
  const WaliHome({
    super.key,
    required this.uid,
    required this.service,
    required this.account,
    required this.onDeleteAccount,
    this.today,
  });
  final String uid;
  final WaliService service;
  final GuardianAccount account;
  final VoidCallback onDeleteAccount;
  final DateTime? today;
  @override
  State<WaliHome> createState() => _WaliHomeState();
}

class _WaliHomeState extends State<WaliHome> {
  late GuardianAccount _account = widget.account;
  late Future<List<WaliRequest>> _requests = widget.service.guardianRequests(
    widget.uid,
  );
  bool _adding = false;
  final Set<String> _busy = {};

  Future<void> _reload() async {
    try {
      final account = await widget.service.guardian(widget.uid);
      if (account != null && mounted) setState(() => _account = account);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _requests = widget.service.guardianRequests(widget.uid);
      });
    }
  }

  Future<void> _decide(WaliRequest request, bool approve) async {
    final s = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!approve) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: Text(s.waliDeclineTitle),
          content: Text(s.waliDeclineBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: Text(s.profileCancelEdit),
            ),
            TextButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: Text(s.waliDecline),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy.add(request.id));
    try {
      await widget.service.decide(widget.uid, request, approve);
      messenger.showSnackBar(
        SnackBar(content: Text(approve ? s.waliApproved : s.waliDeclined)),
      );
      await _reload();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(s.interestFailed)));
    } finally {
      if (mounted) setState(() => _busy.remove(request.id));
    }
  }

  Future<void> _stop(GuardedMember member) async {
    final s = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(s.waliStopTitle(member.name)),
        content: Text(s.waliStopBody(member.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(s.profileCancelEdit),
          ),
          TextButton(
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(s.waliStop(member.name)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await widget.service.stopGuarding(widget.uid, member.uid);
      await _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.interestFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (_adding) {
      return WaliSetup(
        uid: widget.uid,
        service: widget.service,
        knownName: _account.name,
        onBack: () => setState(() => _adding = false),
        onJoined: (account) => setState(() {
          _account = account;
          _adding = false;
          _requests = widget.service.guardianRequests(widget.uid);
        }),
      );
    }
    final members = _account.members;
    final names = {for (final m in members) m.uid: m.name};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShukaansiIconBadge(
                icon: Icons.family_restroom,
                size: 56,
                color: colors.secondary,
              ),
              const SizedBox(height: AppSpacing.m),
              Semantics(
                header: true,
                child: Text(
                  s.waliGreeting(_account.name),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                members.isEmpty
                    ? s.waliNoMembers
                    : s.waliGuarding(members.map((m) => m.name).join(', ')),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.m),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _adding = true),
                    icon: const Icon(Icons.add),
                    label: Text(s.waliAddMember),
                  ),
                  TextButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(s.discoverCheckAgain),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Semantics(
          header: true,
          child: Text(
            s.waliRequestsTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        FutureBuilder<List<WaliRequest>>(
          future: _requests,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(s.waliLoadFailed),
                  TextButton(onPressed: _reload, child: Text(s.retry)),
                ],
              );
            }
            final requests = [...snapshot.data!]
              ..sort(
                (a, b) => (a.status == WaliDecision.pending ? 0 : 1).compareTo(
                  b.status == WaliDecision.pending ? 0 : 1,
                ),
              );
            if (requests.isEmpty) {
              return Text(
                s.waliNoRequests,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in requests) ...[
                  _RequestCard(
                    request: r,
                    memberName: names[r.memberUid] ?? '',
                    busy: _busy.contains(r.id),
                    today: widget.today ?? DateTime.now(),
                    onDecide: (approve) => _decide(r, approve),
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const LegalLinksCard(),
        const SizedBox(height: AppSpacing.m),
        for (final m in members)
          TextButton(
            onPressed: () => _stop(m),
            child: Text(s.waliStop(m.name)),
          ),
        TextButton.icon(
          onPressed: widget.onDeleteAccount,
          style: TextButton.styleFrom(foregroundColor: colors.error),
          icon: const Icon(Icons.delete_outline),
          label: Text(s.accountDelete),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.memberName,
    required this.busy,
    required this.today,
    required this.onDecide,
  });
  final WaliRequest request;
  final String memberName;
  final bool busy;
  final DateTime today;
  final ValueChanged<bool> onDecide;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final c = request.candidate!;
    final facts = [
      c.professionOther.isEmpty
          ? professionLabel(s, c.profession)
          : c.professionOther,
      educationLabel(s, c.education),
      practiceLabel(s, c.practice),
      maritalLabel(s, c.maritalStatus),
    ];
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShukaansiStatusChip(
            label: s.waliRequestFor(memberName),
            icon: Icons.favorite,
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            children: [
              Flexible(
                child: Text(
                  s.cardNameAge(
                    c.name,
                    ageFromYearMonth(c.birthYearMonth, today),
                  ),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (c.verified) ...[
                const SizedBox(width: AppSpacing.xs),
                const VerifiedBadge(),
              ],
            ],
          ),
          Text(
            s.cardLocation(c.city, countryName(context, c.residenceCountry)),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(facts.join(' · '), style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.s),
          Text(c.about, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.s),
          Text(
            s.waliPhotosNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          switch (request.status) {
            WaliDecision.pending => Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : () => onDecide(false),
                  child: Text(s.waliDecline),
                ),
                Pressable(
                  enabled: !busy,
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : () => onDecide(true),
                    icon: const Icon(Icons.check),
                    label: Text(s.waliApprove),
                  ),
                ),
              ],
            ),
            WaliDecision.approved => ShukaansiStatusChip(
              label: s.waliStatusApproved,
              icon: Icons.check_circle,
              tone: StatusTone.positive,
            ),
            WaliDecision.declined => ShukaansiStatusChip(
              label: s.waliStatusDeclined,
              icon: Icons.block,
              tone: StatusTone.attention,
            ),
          },
        ],
      ),
    );
  }
}
