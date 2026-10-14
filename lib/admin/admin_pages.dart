import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/matrimonial_profile.dart';
import '../models/membership.dart';
import '../models/moderation.dart';
import '../models/profile_media.dart';
import '../screens/profile_labels.dart';
import '../widgets/safety_actions.dart';
import '../widgets/brand/brand.dart';
import 'admin_service.dart';

// ---- Shared pieces --------------------------------------------------------

String _date(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

String _genderLabel(ProfileGender? gender) => switch (gender) {
  ProfileGender.female => 'Woman',
  ProfileGender.male => 'Man',
  null => '—',
};

/// A page with a title, optional refresh and a constrained readable width.
class _Page extends StatelessWidget {
  const _Page({required this.title, required this.child, this.onRefresh});
  final String title;
  final Widget child;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (onRefresh != null)
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

class _Problem extends StatelessWidget {
  const _Problem({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}

/// Loads an image once and shows it filling its box, with loading/error states.
class _RemoteImage extends StatefulWidget {
  const _RemoteImage({required this.load, required this.label});
  final Future<Uint8List> Function() load;
  final String label;
  @override
  State<_RemoteImage> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<_RemoteImage> {
  late Future<Uint8List> _bytes = widget.load();
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: colors.surfaceContainerHighest,
        child: FutureBuilder<Uint8List>(
          future: _bytes,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: IconButton(
                  tooltip: 'Retry image',
                  onPressed: () => setState(() => _bytes = widget.load()),
                  icon: const Icon(Icons.refresh),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Semantics(
              image: true,
              label: widget.label,
              child: Image.memory(snapshot.data!, fit: BoxFit.cover),
            );
          },
        ),
      ),
    );
  }
}

Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String label,
  required String confirm,
  bool required = false,
  bool destructive = false,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextDialog(
    title: title,
    label: label,
    confirm: confirm,
    required: required,
    destructive: destructive,
  ),
);

/// Owns its controller, so it is disposed only after the closing animation.
class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.label,
    required this.confirm,
    required this.required,
    required this.destructive,
  });
  final String title;
  final String label;
  final String confirm;
  final bool required;
  final bool destructive;
  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: 300,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: widget.destructive
              ? FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                )
              : null,
          onPressed: widget.required && _controller.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.confirm),
        ),
      ],
    );
  }
}

void _toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

// ---- Overview -------------------------------------------------------------

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key, required this.service, required this.me});
  final AdminService service;
  final StaffMember me;
  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late Future<AdminCounts> _counts = widget.service.counts(widget.me);
  void _reload() => setState(() => _counts = widget.service.counts(widget.me));

  @override
  Widget build(BuildContext context) => _Page(
    title: 'Overview',
    onRefresh: _reload,
    child: FutureBuilder<AdminCounts>(
      future: _counts,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Problem(
            message: 'Counts could not be loaded.',
            onRetry: _reload,
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final c = snapshot.data!;
        final tiles = <(IconData, String, int?)>[
          (Icons.people_outline, 'Members with a profile', c.members),
          (Icons.explore_outlined, 'Visible in Discover', c.listed),
          (
            Icons.verified_user_outlined,
            'Verifications waiting',
            c.pendingVerifications,
          ),
          (Icons.flag_outlined, 'Open reports', c.openReports),
          (Icons.block, 'Suspended accounts', c.suspended),
        ].where((t) => t.$3 != null).toList();
        return GridView(
          // Fixed height so labels never overflow on narrow screens.
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 260,
            mainAxisExtent: 140,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          children: [
            for (final (icon, label, value) in tiles)
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: Theme.of(context).colorScheme.primary),
                      Text(
                        '$value',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

// ---- Verifications -----------------------------------------------------------

class VerificationsPage extends StatefulWidget {
  const VerificationsPage({super.key, required this.service, required this.me});
  final AdminService service;
  final StaffMember me;
  @override
  State<VerificationsPage> createState() => _VerificationsPageState();
}

class _VerificationsPageState extends State<VerificationsPage> {
  late Future<List<VerificationRequest>> _queue = widget.service
      .pendingVerifications(widget.me);
  VerificationRequest? _selected;
  bool _busy = false;

  void _reload() => setState(() {
    _selected = null;
    _queue = widget.service.pendingVerifications(widget.me);
  });

  Future<void> _decide(VerificationRequest request, bool approve) async {
    String note = '';
    if (!approve) {
      final reason = await _askText(
        context,
        title: 'Reject verification for ${request.name}?',
        label: 'Reason shown to the member',
        confirm: 'Reject',
        required: true,
        destructive: true,
      );
      if (reason == null) return;
      note = reason;
    }
    setState(() => _busy = true);
    try {
      await widget.service.decideVerification(
        widget.me,
        request.uid,
        approve: approve,
        note: note,
      );
      if (!mounted) return;
      _toast(context, approve ? '${request.name} verified' : 'Rejected');
      _reload();
    } catch (_) {
      if (mounted) _toast(context, 'The decision could not be saved.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final limited =
        widget.me.role == StaffRole.reviewer && widget.me.reviewGender != null;
    return _Page(
      title: limited
          ? 'Verifications · ${widget.me.reviewGender == 'female' ? 'women' : 'men'}'
          : 'Verifications',
      onRefresh: _reload,
      child: FutureBuilder<List<VerificationRequest>>(
        future: _queue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Problem(
              message: 'The queue could not be loaded.',
              onRetry: _reload,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final queue = snapshot.data!;
          if (queue.isEmpty) {
            return const Center(child: Text('No verifications are waiting.'));
          }
          final selected = _selected;
          final list = ListView(
            children: [
              for (final r in queue)
                ListTile(
                  selected: r.uid == selected?.uid,
                  leading: const Icon(Icons.person_outline),
                  title: Text(r.name),
                  subtitle: Text(
                    '${_genderLabel(r.gender)} · submitted ${_date(r.submittedAt)}',
                  ),
                  onTap: () => setState(() => _selected = r),
                ),
            ],
          );
          final detail = selected == null
              ? const Center(child: Text('Select a request to review.'))
              : _VerificationDetail(
                  key: ValueKey(selected.uid),
                  request: selected,
                  service: widget.service,
                  busy: _busy,
                  onDecide: (approve) => _decide(selected, approve),
                );
          if (MediaQuery.sizeOf(context).width < 900) {
            return selected == null
                ? list
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _selected = null),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to queue'),
                      ),
                      Expanded(child: detail),
                    ],
                  );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 320, child: list),
              const VerticalDivider(width: 32),
              Expanded(child: detail),
            ],
          );
        },
      ),
    );
  }
}

class _VerificationDetail extends StatelessWidget {
  const _VerificationDetail({
    super.key,
    required this.request,
    required this.service,
    required this.busy,
    required this.onDecide,
  });
  final VerificationRequest request;
  final AdminService service;
  final bool busy;
  final ValueChanged<bool> onDecide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Text(request.name, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Compare the selfie with the profile photos. Approve only when it is '
          'clearly the same person and the face is fully visible.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selfie (private)', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 6),
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: _RemoteImage(
                      label: 'Verification selfie of ${request.name}',
                      load: () => service.selfie(request.uid, request.selfieId),
                    ),
                  ),
                ],
              ),
            ),
            for (final (i, id) in request.photoIds.indexed)
              SizedBox(
                width: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i == 0 ? 'Main photo' : 'Photo ${i + 1}',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    AspectRatio(
                      aspectRatio: 3 / 4,
                      child: _RemoteImage(
                        label: 'Profile photo ${i + 1} of ${request.name}',
                        load: () => service.photo(request.uid, id),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          children: [
            FilledButton.icon(
              onPressed: busy ? null : () => onDecide(true),
              icon: const Icon(Icons.verified),
              label: const Text('Approve'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => onDecide(false),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
            ),
          ],
        ),
      ],
    );
  }
}

// ---- Members --------------------------------------------------------------

class MembersPage extends StatefulWidget {
  const MembersPage({super.key, required this.service, required this.me});
  final AdminService service;
  final StaffMember me;
  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _query = TextEditingController();
  late Future<List<MemberSummary>> _results = widget.service.searchMembers('');
  String? _open;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search() => setState(() {
    _open = null;
    _results = widget.service.searchMembers(_query.text);
  });

  @override
  Widget build(BuildContext context) {
    final open = _open;
    if (open != null) {
      return _Page(
        title: 'Member',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _open = null),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to members'),
            ),
            Expanded(
              child: _MemberDetailView(
                key: ValueKey(open),
                uid: open,
                service: widget.service,
                me: widget.me,
              ),
            ),
          ],
        ),
      );
    }
    return _Page(
      title: 'Members',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Search by name or member id',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: _search,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<MemberSummary>>(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _Problem(
                    message: 'Members could not be loaded.',
                    onRetry: _search,
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final members = snapshot.data!;
                if (members.isEmpty) {
                  return const Center(child: Text('No members found.'));
                }
                return ListView(
                  children: [
                    for (final m in members)
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(m.name),
                        subtitle: Text(
                          '${_genderLabel(m.gender)} · ${m.city}'
                          '${m.country.isEmpty ? '' : ', ${countryName(context, m.country)}'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => setState(() => _open = m.uid),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberDetailView extends StatefulWidget {
  const _MemberDetailView({
    super.key,
    required this.uid,
    required this.service,
    required this.me,
  });
  final String uid;
  final AdminService service;
  final StaffMember me;
  @override
  State<_MemberDetailView> createState() => _MemberDetailViewState();
}

class _MemberDetailViewState extends State<_MemberDetailView> {
  late Future<MemberDetail> _member = widget.service.member(
    widget.me,
    widget.uid,
  );
  bool _busy = false;

  void _reload() =>
      setState(() => _member = widget.service.member(widget.me, widget.uid));

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      _toast(context, done);
      _reload();
    } catch (_) {
      if (mounted) _toast(context, 'The change could not be saved.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _suspend(MemberDetail m) async {
    final reason = await _askText(
      context,
      title: 'Suspend ${m.profile.name}?',
      label: 'Reason shown to the member',
      confirm: 'Suspend',
      required: true,
      destructive: true,
    );
    if (reason == null) return;
    await _run(
      () => widget.service.setSuspended(
        widget.me,
        m.uid,
        suspended: true,
        reason: reason,
      ),
      'Suspended',
    );
  }

  /// Choose a plan and length; replaces any current plan.
  Future<void> _grant(MemberDetail m) async {
    final choice = await showDialog<(MembershipPlan, int)>(
      context: context,
      builder: (d) => SimpleDialog(
        title: Text('Give ${m.profile.name} a plan'),
        children: [
          for (final plan in [MembershipPlan.premium, MembershipPlan.vip])
            for (final months in [1, 3, 6, 12])
              SimpleDialogOption(
                onPressed: () => Navigator.of(d).pop((plan, months)),
                child: Text(
                  '${_planLabel(plan)} · $months month${months == 1 ? '' : 's'}',
                ),
              ),
        ],
      ),
    );
    if (choice == null) return;
    final (plan, months) = choice;
    final now = DateTime.now();
    await _run(
      () => widget.service.grantMembership(
        widget.me,
        m.uid,
        plan,
        DateTime(now.year, now.month + months, now.day, now.hour, now.minute),
      ),
      '${_planLabel(plan)} given for $months month${months == 1 ? '' : 's'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<MemberDetail>(
      future: _member,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Problem(
            message: 'This member could not be loaded.',
            onRetry: _reload,
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final m = snapshot.data!;
        final p = m.profile;
        final facts = <String, String>{
          'Member id': m.uid,
          'Gender': genderLabel(s, p.gender),
          'Nationality': countryName(context, p.nationality),
          'Lives in': '${p.city}, ${countryName(context, p.residenceCountry)}',
          'Ethnicity':
              ethnicityLabel(s, p.ethnicity) +
              (p.ethnicityOther.isEmpty ? '' : ': ${p.ethnicityOther}'),
          'Profession':
              professionLabel(s, p.profession) +
              (p.professionOther.isEmpty ? '' : ': ${p.professionOther}'),
          'Education': educationLabel(s, p.education),
          'Practice': practiceLabel(s, p.practice),
          'Marital status': maritalLabel(s, p.maritalStatus),
          'Verification': switch (m.verification.status) {
            VerificationStatus.none => 'Not requested',
            VerificationStatus.pending => 'Waiting for review',
            VerificationStatus.verified => 'Verified',
            VerificationStatus.rejected =>
              'Rejected${m.verification.reviewNote == null ? '' : ': ${m.verification.reviewNote}'}',
          },
          'In Discover': m.listed ? 'Yes' : 'No',
          'Membership': m.membership.activeOn(DateTime.now())
              ? '${_planLabel(m.membership.plan)} until '
                    '${_date(m.membership.expiresAt).split(' ').first}'
              : 'Free',
          'Account': m.status.suspended
              ? 'Suspended: ${m.status.reason}'
              : 'Active',
          if (m.birthDate != null)
            'Date of birth': _date(m.birthDate).split(' ').first,
          if (m.phoneNumber != null) 'Phone (private)': m.phoneNumber!,
        };
        // A short page: build it whole so every action is always present.
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(p.name, style: theme.textTheme.headlineSmall),
                  ),
                  if (m.verification.status == VerificationStatus.verified) ...[
                    const SizedBox(width: 6),
                    const VerifiedBadge(),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (m.status.suspended)
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => widget.service.setSuspended(
                                widget.me,
                                m.uid,
                                suspended: false,
                              ),
                              'Reactivated',
                            ),
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Reactivate'),
                    )
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      onPressed: _busy ? null : () => _suspend(m),
                      icon: const Icon(Icons.block),
                      label: const Text('Suspend'),
                    ),
                  if (m.listed)
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => widget.service.unlist(m.uid),
                              'Removed from Discover until their next visit',
                            ),
                      icon: const Icon(Icons.visibility_off_outlined),
                      label: const Text('Remove from Discover'),
                    ),
                  if (widget.me.isAdmin)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _grant(m),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Give Premium or VIP'),
                    ),
                  if (widget.me.isAdmin &&
                      m.membership.activeOn(DateTime.now()))
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                              () => widget.service.endMembership(m.uid),
                              'Membership ended',
                            ),
                      child: const Text('End membership'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (i, id) in m.photoIds.indexed)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: _RemoteImage(
                            label: 'Photo ${i + 1} of ${p.name}',
                            load: () => widget.service.photo(m.uid, id),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final e in facts.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 160,
                        child: Text(
                          e.key,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(child: SelectableText(e.value)),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Text('About', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(p.about),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ---- Reports --------------------------------------------------------------

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.service, required this.me});
  final AdminService service;
  final StaffMember me;
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late Future<List<ReportItem>> _reports = widget.service.openReports();
  final Set<String> _busy = {};

  void _reload() => setState(() => _reports = widget.service.openReports());

  Future<void> _resolve(ReportItem r, ReportOutcome outcome) async {
    final note = await _askText(
      context,
      title: outcome == ReportOutcome.resolved
          ? 'Resolve this report?'
          : 'Dismiss this report?',
      label: 'What was done (internal)',
      confirm: outcome == ReportOutcome.resolved ? 'Resolve' : 'Dismiss',
    );
    if (note == null) return;
    await _act(
      r,
      () => widget.service.resolveReport(widget.me, r.id, outcome, note),
    );
  }

  Future<void> _suspendReported(ReportItem r) async {
    final reason = await _askText(
      context,
      title: 'Suspend ${r.reportedName}?',
      label: 'Reason shown to the member',
      confirm: 'Suspend',
      required: true,
      destructive: true,
    );
    if (reason == null) return;
    await _act(r, () async {
      await widget.service.setSuspended(
        widget.me,
        r.reportedUid,
        suspended: true,
        reason: reason,
      );
      await widget.service.resolveReport(
        widget.me,
        r.id,
        ReportOutcome.resolved,
        'Suspended: $reason',
      );
    });
  }

  Future<void> _act(ReportItem r, Future<void> Function() action) async {
    setState(() => _busy.add(r.id));
    try {
      await action();
      if (mounted) _reload();
    } catch (_) {
      if (mounted) _toast(context, 'The change could not be saved.');
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _Page(
      title: 'Open reports',
      onRefresh: _reload,
      child: FutureBuilder<List<ReportItem>>(
        future: _reports,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Problem(
              message: 'Reports could not be loaded.',
              onRetry: _reload,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data!;
          if (reports.isEmpty) {
            return const Center(child: Text('No open reports.'));
          }
          return ListView.separated(
            itemCount: reports.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = reports[index];
              final busy = _busy.contains(r.id);
              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportReasonLabel(s, r.reason),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${r.reporterName} reported ${r.reportedName} · ${_date(r.createdAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (r.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('“${r.note}”'),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.tonal(
                            onPressed: busy
                                ? null
                                : () => _resolve(r, ReportOutcome.resolved),
                            child: const Text('Resolve'),
                          ),
                          OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => _resolve(r, ReportOutcome.dismissed),
                            child: const Text('Dismiss'),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            onPressed: busy ? null : () => _suspendReported(r),
                            icon: const Icon(Icons.block),
                            label: Text('Suspend ${r.reportedName}'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---- Memberships ----------------------------------------------------------

String _planLabel(MembershipPlan plan) => switch (plan) {
  MembershipPlan.free => 'Free',
  MembershipPlan.premium => 'Premium (£4.99/month)',
  MembershipPlan.vip => 'VIP (£14.99/month)',
};

/// Active Premium and VIP members. Plans are granted from a member's page
/// until Google Play billing is connected.
class MembershipsPage extends StatefulWidget {
  const MembershipsPage({super.key, required this.service, required this.me});
  final AdminService service;
  final StaffMember me;
  @override
  State<MembershipsPage> createState() => _MembershipsPageState();
}

class _MembershipsPageState extends State<MembershipsPage> {
  late Future<List<MembershipRow>> _rows = widget.service.activeMemberships();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Page(
      title: 'Memberships',
      child: FutureBuilder<List<MembershipRow>>(
        future: _rows,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Problem(
              message: 'Memberships could not be loaded.',
              onRetry: () => setState(() {
                _rows = widget.service.activeMemberships();
              }),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data!;
          int count(MembershipPlan p) =>
              rows.where((r) => r.membership.plan == p).length;
          return ListView(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Chip(
                    label: Text('Premium: ${count(MembershipPlan.premium)}'),
                  ),
                  Chip(label: Text('VIP: ${count(MembershipPlan.vip)}')),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Plans are granted from a member\'s page (Members). Google Play '
                'billing will be connected after the Blaze upgrade.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (rows.isEmpty) const Text('No active memberships yet.'),
              for (final r in rows)
                ListTile(
                  leading: Icon(
                    r.membership.plan == MembershipPlan.vip
                        ? Icons.workspace_premium
                        : Icons.star_outline,
                  ),
                  title: Text(r.name),
                  subtitle: Text(
                    '${_planLabel(r.membership.plan)} · until '
                    '${_date(r.membership.expiresAt).split(' ').first}\n${r.uid}',
                  ),
                  isThreeLine: true,
                ),
            ],
          );
        },
      ),
    );
  }
}
