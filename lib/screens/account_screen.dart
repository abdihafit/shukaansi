import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/session_service.dart';
import '../widgets/centered_content.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    required this.service,
    this.content,
    this.title,
    this.top = false,
  });
  final SessionService service;
  final Widget? content;

  /// App bar title; the app name when not given.
  final String? title;

  /// Starts long content (forms) at the top of the page.
  final bool top;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _busy = false;
  bool _failed = false;
  Future<void> _signOut() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.service.signOut();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? strings.appTitle),
        automaticallyImplyLeading: false,
      ),
      body: CenteredContent(
        top: widget.top,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.content != null)
              widget.content!
            else ...[
              Icon(
                Icons.lock_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                strings.accountSignedIn,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(strings.accountStageNotice),
            ],
            if (_failed) ...[
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                child: Text(
                  strings.signOutFailed,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Beside a page's own primary action, sign-out stays secondary.
            if (widget.content != null)
              TextButton.icon(
                onPressed: _busy ? null : _signOut,
                icon: const Icon(Icons.logout),
                label: Text(_busy ? strings.authLoading : strings.signOut),
              )
            else
              ElevatedButton(
                onPressed: _busy ? null : _signOut,
                child: Text(_busy ? strings.authLoading : strings.signOut),
              ),
          ],
        ),
      ),
    );
  }
}
