import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/auth_validation.dart';
import '../application/auth_controller.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/brand/brand.dart';
import '../widgets/centered_content.dart';
import '../widgets/password_field.dart';
import '../services/device_prefs_store.dart';
import '../services/password_recovery_service.dart';
import 'forgot_password_screen.dart';

enum AuthMode { register, login }

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.initialMode = AuthMode.register,
    this.service = const UnconfiguredAuthService(),
    this.prefs = const PrefsDevicePrefsStore(),
  });

  final AuthMode initialMode;
  final AuthService service;

  /// Remembers the email on this phone. Passwords are never kept by the
  /// app; the phone's own password manager may save them.
  final DevicePrefsStore prefs;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  late AuthMode _mode = widget.initialMode;
  bool _submitted = false;
  late final AuthController _request;

  @override
  void initState() {
    super.initState();
    _request = AuthController(widget.service)..addListener(_requestChanged);
    _fillRememberedEmail();
  }

  Future<void> _fillRememberedEmail() async {
    final email = await widget.prefs.rememberedEmail();
    if (!mounted || email == null || _email.text.isNotEmpty) return;
    // Only when signing in; a new account starts empty.
    if (_mode == AuthMode.login) setState(() => _email.text = email);
  }

  void _requestChanged() {
    if (mounted) setState(() {});
  }

  bool get _registering => _mode == AuthMode.register;

  @override
  void dispose() {
    _request.removeListener(_requestChanged);
    _request.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  String? _message(AuthInputError? error) {
    final strings = AppLocalizations.of(context);
    return switch (error) {
      null => null,
      AuthInputError.required => strings.fieldRequired,
      AuthInputError.invalidEmail => strings.invalidEmail,
      AuthInputError.shortPassword => strings.passwordGuidance,
      AuthInputError.passwordMismatch => strings.passwordMismatch,
    };
  }

  Future<void> _submit() async {
    if (_request.busy) return;
    _request.reset();
    setState(() {
      _submitted = true;
    });
    if (!_form.currentState!.validate()) {
      final focus = AuthValidation.email(_email.text) != null
          ? _emailFocus
          : AuthValidation.password(
                  _password.text,
                  registering: _registering,
                ) !=
                null
          ? _passwordFocus
          : _confirmationFocus;
      focus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    final email = _email.text;
    final password = _password.text;
    // The fields stay filled until the result is known, so the phone's
    // password manager can offer to save them - but only after a
    // successful sign-in, never for a mistyped password.
    await _request.submit(
      registering: _registering,
      email: email,
      password: password,
    );
    if (_request.completed) {
      TextInput.finishAutofillContext();
      await widget.prefs.setRememberedEmail(email.trim());
    } else {
      TextInput.finishAutofillContext(shouldSave: false);
    }
    if (!mounted) return;
    _resetForm();
    setState(() => _submitted = false);
  }

  void _switchMode() {
    if (_request.busy) return;
    _request.reset();
    FocusScope.of(context).unfocus();
    _resetForm();
    setState(() {
      _mode = _registering ? AuthMode.login : AuthMode.register;
      _submitted = false;
    });
  }

  void _resetForm() {
    final email = _email.text;
    _form.currentState!.reset();
    _email.text = email;
    _password.clear();
    _confirmation.clear();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final error = switch (_request.failure) {
      null => null,
      AuthFailure.unavailable => strings.authUnavailable,
      AuthFailure.rejected => strings.authRejected,
      AuthFailure.network => strings.authNetworkError,
      AuthFailure.throttled => strings.authThrottled,
      AuthFailure.unknown => strings.authUnknownError,
    };
    final screen = MediaQuery.sizeOf(context).height;
    // The photos sit above the form; a slim band on short screens, so the
    // sign-in button stays in view, and none in landscape on phones. Sized
    // from the screen, not the space left by the keyboard, so they stay put
    // and the page scrolls instead.
    final heroHeight = screen < 480
        ? 0.0
        : math.min(420.0, screen * (screen < 700 ? 0.22 : 0.32));
    const badge = 64.0;
    final form = AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Form(
        key: _form,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // With photos the logo is a badge on the sheet's edge instead.
            if (heroHeight == 0) ...[
              const BrandHeader(),
              const SizedBox(height: 28),
            ],
            Semantics(
              header: true,
              child: Text(
                strings.authIntroduction,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 12),
            if (!widget.service.isConfigured) Text(strings.authPreviewNotice),
            const SizedBox(height: 24),
            TextFormField(
              key: const ValueKey('email'),
              controller: _email,
              enabled: !_request.busy,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: strings.emailAddress,
                border: const OutlineInputBorder(),
                errorMaxLines: 3,
              ),
              validator: (value) => _message(AuthValidation.email(value ?? '')),
              onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 20),
            PasswordField(
              key: ValueKey('password-$_mode'),
              controller: _password,
              enabled: !_request.busy,
              focusNode: _passwordFocus,
              label: strings.password,
              helperText: _registering ? strings.passwordGuidance : null,
              autofillHints: [
                _registering
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              validator: (value) => _message(
                AuthValidation.password(value ?? '', registering: _registering),
              ),
              textInputAction: _registering
                  ? TextInputAction.next
                  : TextInputAction.done,
              onSubmitted: (_) =>
                  _registering ? _confirmationFocus.requestFocus() : _submit(),
            ),
            if (_registering) ...[
              const SizedBox(height: 20),
              PasswordField(
                key: const ValueKey('confirmation'),
                controller: _confirmation,
                enabled: !_request.busy,
                focusNode: _confirmationFocus,
                label: strings.confirmPassword,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => _message(
                  AuthValidation.confirmation(value ?? '', _password.text),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            if (_request.completed) ...[
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                child: Text(strings.authRequestCompleted),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: _submit,
              loading: _request.busy,
              loadingLabel: strings.authLoading,
              label: _registering ? strings.createAccount : strings.signIn,
            ),
            const SizedBox(height: 12),
            if (!_registering)
              TextButton(
                onPressed: _request.busy
                    ? null
                    : () {
                        FocusScope.of(context).unfocus();
                        _password.clear();
                        _confirmation.clear();
                        TextInput.finishAutofillContext(shouldSave: false);
                        final service = widget.service;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(
                              initialEmail: _email.text,
                              service: service is PasswordRecoveryService
                                  ? service as PasswordRecoveryService
                                  : const UnconfiguredAuthService(),
                            ),
                          ),
                        );
                      },
                child: Text(strings.forgotPassword),
              ),
            TextButton(
              onPressed: _request.busy ? null : _switchMode,
              child: Text(
                _registering ? strings.alreadyHaveAccount : strings.needAccount,
              ),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(_registering ? strings.createAccount : strings.signIn),
      ),
      body: heroHeight == 0
          ? CenteredContent(child: form)
          : SingleChildScrollView(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: heroHeight,
                    child: const PhotoSlideshow(
                      photos: LifestylePhoto.signIn,
                      dotsBottom: AppRadius.hero + AppSpacing.m,
                      dotsAlignment: MainAxisAlignment.end,
                    ),
                  ),
                  // The form on a sheet that overlaps the photos slightly.
                  Padding(
                    padding: EdgeInsets.only(top: heroHeight - AppRadius.hero),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.hero),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl,
                                badge / 2 + AppSpacing.l,
                                AppSpacing.xl,
                                AppSpacing.xl,
                              ),
                              child: form,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: heroHeight - AppRadius.hero - badge / 2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Semantics(
                        image: true,
                        label: '${strings.appTitle}, ${strings.tagline}',
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.photoShadow,
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: BrandBadge(size: badge),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
