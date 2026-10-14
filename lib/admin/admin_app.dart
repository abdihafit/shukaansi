import 'package:flutter/material.dart';

import '../l10n/framework_localizations.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/moderation.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_loading.dart';
import '../widgets/brand/brand.dart';
import 'admin_pages.dart';
import 'admin_service.dart';

/// Shukaansi staff dashboard. English only: it is an internal tool.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.service});
  final AdminService service;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Shukaansi Admin',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.refinedLight,
    darkTheme: AppTheme.refinedDark,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      SomaliMaterialFallback(),
      SomaliCupertinoFallback(),
      ...AppLocalizations.localizationsDelegates,
    ],
    home: _AdminGate(service: service),
  );
}

class _AdminGate extends StatelessWidget {
  const _AdminGate({required this.service});
  final AdminService service;

  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
    stream: service.sessions,
    builder: (context, session) {
      if (session.connectionState == ConnectionState.waiting) {
        return const BrandLoadingPage();
      }
      final uid = session.data;
      if (uid == null) return _LoginPage(service: service);
      return FutureBuilder<StaffMember?>(
        key: ValueKey(uid),
        future: service.staff(uid),
        builder: (context, staff) {
          if (staff.connectionState != ConnectionState.done) {
            return const BrandLoadingPage();
          }
          final me = staff.data;
          if (me == null) return _NotAuthorized(service: service);
          return AdminShell(service: service, me: me);
        },
      );
    },
  );
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: child,
        ),
      ),
    ),
  );
}

class _LoginPage extends StatefulWidget {
  const _LoginPage({required this.service});
  final AdminService service;
  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _failed = false;
  bool _obscured = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.service.signIn(_email.text, _password.text);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      _password.clear();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? required(String? v) =>
        (v ?? '').trim().isEmpty ? 'This field is required.' : null;
    return _Centered(
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ExcludeSemantics(child: ShukaansiLogo(height: 180)),
              const SizedBox(height: 24),
              Text(
                'Staff sign in',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For Shukaansi administrators, reviewers and moderators.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  border: OutlineInputBorder(),
                ),
                validator: required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                obscureText: _obscured,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _obscured ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: required,
              ),
              if (_failed) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Sign in failed. Check your email and password.',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Please wait…' : 'Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotAuthorized extends StatelessWidget {
  const _NotAuthorized({required this.service});
  final AdminService service;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Centered(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('No staff access', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'This account is not a Shukaansi staff member. Ask an '
            'administrator to add your account in the Firebase console.',
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: service.signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

/// Role-aware navigation: a side rail on wide screens, a bottom bar on phones.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.service, required this.me});
  final AdminService service;
  final StaffMember me;
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final pages = <(IconData, IconData, String, Widget)>[
      (
        Icons.dashboard_outlined,
        Icons.dashboard,
        'Overview',
        OverviewPage(service: widget.service, me: me),
      ),
      if (me.canReview)
        (
          Icons.verified_user_outlined,
          Icons.verified_user,
          'Verifications',
          VerificationsPage(service: widget.service, me: me),
        ),
      if (me.canModerate)
        (
          Icons.people_outline,
          Icons.people,
          'Members',
          MembersPage(service: widget.service, me: me),
        ),
      if (me.canModerate)
        (
          Icons.flag_outlined,
          Icons.flag,
          'Reports',
          ReportsPage(service: widget.service, me: me),
        ),
      if (me.isAdmin)
        (
          Icons.workspace_premium_outlined,
          Icons.workspace_premium,
          'Memberships',
          MembershipsPage(service: widget.service, me: me),
        ),
    ];
    final index = _index.clamp(0, pages.length - 1);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final role = switch (me.role) {
      StaffRole.admin => 'Administrator',
      StaffRole.reviewer =>
        me.reviewGender == null
            ? 'Reviewer'
            : 'Reviewer · ${me.reviewGender == 'female' ? 'women' : 'men'}',
      StaffRole.moderator => 'Moderator',
    };
    final body = pages[index].$4;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shukaansi Admin'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(label: Text(role)),
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.service.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final (icon, selected, label, _) in pages)
                      NavigationRailDestination(
                        icon: Icon(icon),
                        selectedIcon: Icon(selected),
                        label: Text(label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
      bottomNavigationBar: wide || pages.length < 2
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final (icon, selected, label, _) in pages)
                  NavigationDestination(
                    icon: Icon(icon),
                    selectedIcon: Icon(selected),
                    label: label,
                  ),
              ],
            ),
    );
  }
}
