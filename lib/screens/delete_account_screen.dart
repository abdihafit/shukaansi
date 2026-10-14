import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/account_service.dart';
import '../services/auth_service.dart';
import '../services/consent_service.dart';
import '../services/interest_service.dart';
import '../services/wali_service.dart';
import '../services/photo_service.dart';
import '../services/profile_service.dart';
import '../widgets/centered_content.dart';
import '../widgets/password_field.dart';
import '../services/device_prefs_store.dart';

/// Permanently deletes the owner's photos and profile records, then the
/// sign-in account.
/// On success the session ends and the app returns to its start screens.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({
    super.key,
    required this.uid,
    required this.account,
    required this.profiles,
    required this.photos,
    this.consents,
    this.interests,
    this.walis,
    this.prefs = const PrefsDevicePrefsStore(),
  });
  final ConsentService? consents;
  final InterestService? interests;
  final WaliService? walis;
  final String uid;
  final AccountService account;
  final ProfileService profiles;
  final PhotoService photos;

  /// Sign-in conveniences on this phone, forgotten with the account.
  final DevicePrefsStore prefs;
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _confirmed = false;
  bool _confirmError = false;
  bool _busy = false;
  // Survive a failed later step, so a retry does not repeat finished work.
  bool _mediaDeleted = false;
  bool _profileDeleted = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  String _authError(AppLocalizations s, Object error) =>
      error is AuthServiceException
      ? switch (error.failure) {
          AuthFailure.rejected => s.accountDeleteWrongPassword,
          AuthFailure.network => s.authNetworkError,
          AuthFailure.throttled => s.authThrottled,
          _ => s.accountDeleteFailed,
        }
      : s.accountDeleteFailed;

  Future<void> _delete() async {
    if (_busy) return;
    final s = AppLocalizations.of(context);
    final valid = _form.currentState!.validate();
    setState(() => _confirmError = !_confirmed);
    if (!valid || !_confirmed) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final password = _password.text;
    _password.clear();
    try {
      // Confirm the password before removing anything.
      await widget.account.reauthenticate(password);
    } catch (error) {
      return _fail(_authError(s, error));
    }
    try {
      // Likes and matches first, while the member can still read them.
      await widget.interests?.deleteAll(widget.uid);
      // Guardian links, invites and match requests, for members and Walis.
      await widget.walis?.deleteAll(widget.uid);
    } catch (_) {
      return _fail(s.accountDeleteFailed);
    }
    if (!_mediaDeleted) {
      try {
        // Photos and selfies first: they are only reachable while signed in.
        await widget.photos.deleteAll(widget.uid);
        _mediaDeleted = true;
      } catch (_) {
        return _fail(s.accountDeleteFailed);
      }
    }
    if (!_profileDeleted) {
      try {
        await widget.profiles.delete(widget.uid);
        _profileDeleted = true;
      } catch (_) {
        return _fail(s.accountDeleteFailed);
      }
    }
    try {
      // The record of accepted terms goes too; deleting twice is harmless.
      await widget.consents?.delete(widget.uid);
    } catch (_) {
      return _fail(s.accountDeleteFailed);
    }
    try {
      await widget.account.deleteAccount();
      await widget.prefs.setRememberedEmail(null);
      await widget.prefs.setAppLock(widget.uid, false);
      // The session stream now signs the user out and resets navigation.
    } catch (_) {
      return _fail(s.accountDeletePartial);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s.accountDeleteTitle)),
      body: CenteredContent(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: colors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(s.accountDeleteBody, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 24),
              PasswordField(
                controller: _password,
                focusNode: _passwordFocus,
                enabled: !_busy,
                label: s.accountDeletePassword,
                autofillHints: const [AutofillHints.password],
                validator: (value) =>
                    (value ?? '').isEmpty ? s.fieldRequired : null,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _confirmed,
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _confirmed = value ?? false;
                        _confirmError = false;
                      }),
                title: Text(s.accountDeleteConfirm),
              ),
              if (_confirmError)
                Text(
                  s.accountDeleteConfirmRequired,
                  style: TextStyle(color: colors.error),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(_error!, style: TextStyle(color: colors.error)),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                onPressed: _busy ? null : _delete,
                child: Text(_busy ? s.authLoading : s.accountDeleteButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
