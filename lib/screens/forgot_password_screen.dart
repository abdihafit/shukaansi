import 'package:flutter/material.dart';

import '../application/auth_validation.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/password_recovery_service.dart';
import '../widgets/centered_content.dart';
import '../widgets/brand/brand.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.service,
    this.initialEmail = '',
  });
  final PasswordRecoveryService service;
  final String initialEmail;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  bool _busy = false;
  bool _completed = false;
  AuthFailure? _failure;

  Future<void> _submit() async {
    if (_busy || _completed || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      if (!widget.service.isConfigured) {
        throw const AuthServiceException(AuthFailure.unavailable);
      }
      await widget.service.sendPasswordReset(email: _email.text.trim());
      if (mounted) setState(() => _completed = true);
    } on AuthServiceException catch (error) {
      if (mounted) setState(() => _failure = error.failure);
    } catch (_) {
      if (mounted) setState(() => _failure = AuthFailure.unknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final error = switch (_failure) {
      null => null,
      AuthFailure.unavailable => strings.authUnavailable,
      AuthFailure.network => strings.authNetworkError,
      AuthFailure.throttled => strings.authThrottled,
      AuthFailure.rejected || AuthFailure.unknown => strings.authUnknownError,
    };
    return Scaffold(
      appBar: AppBar(title: Text(strings.forgotPassword)),
      body: CenteredContent(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrandHeader(height: 104),
              const SizedBox(height: 24),
              Text(
                strings.resetPasswordIntroduction,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              if (!_completed) ...[
                TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: strings.emailAddress,
                    border: const OutlineInputBorder(),
                    errorMaxLines: 3,
                  ),
                  validator: (value) =>
                      switch (AuthValidation.email(value ?? '')) {
                        null => null,
                        AuthInputError.required => strings.fieldRequired,
                        _ => strings.invalidEmail,
                      },
                  onFieldSubmitted: (_) => _submit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 20),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  onPressed: _submit,
                  loading: _busy,
                  loadingLabel: strings.authLoading,
                  label: strings.sendResetLink,
                ),
              ] else
                Semantics(
                  liveRegion: true,
                  child: Text(strings.resetPasswordConfirmation),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.backToSignIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
