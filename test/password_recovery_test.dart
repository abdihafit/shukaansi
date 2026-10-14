import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/framework_localizations.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/screens/forgot_password_screen.dart';
import 'package:shukaansi/screens/auth_screen.dart';
import 'package:shukaansi/services/auth_service.dart';
import 'package:shukaansi/services/password_recovery_service.dart';
import 'package:shukaansi/theme/app_theme.dart';

class TestRecovery implements PasswordRecoveryService {
  final result = Completer<void>();
  int calls = 0;
  @override
  bool get isConfigured => true;
  @override
  Future<void> sendPasswordReset({required String email}) {
    calls++;
    return result.future;
  }
}

Widget app(
  PasswordRecoveryService service,
  String locale,
  Brightness brightness,
) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    SomaliMaterialFallback(),
    SomaliCupertinoFallback(),
    ...AppLocalizations.localizationsDelegates,
  ],
  theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
  home: ForgotPasswordScreen(service: service),
);

void main() {
  testWidgets(
    'sign-in opens recovery with email and clears password before returning',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthScreen(initialMode: AuthMode.login),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'test@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'temporary');
      await tester.ensureVisible(find.text('Forgot password?'));
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'test@example.com',
      );
      await tester.tap(find.text('Back to sign in'));
      await tester.pumpAndSettle();
      expect(find.byType(ForgotPasswordScreen), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        isEmpty,
      );
    },
  );
  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale ${brightness.name} reset validates, suppresses duplicates and confirms safely',
        (tester) async {
          final service = TestRecovery();
          await tester.pumpWidget(app(service, locale, brightness));
          final strings = AppLocalizations.of(
            tester.element(find.byType(Form)),
          );
          await tester.tap(find.byType(ElevatedButton));
          await tester.pump();
          expect(find.text(strings.fieldRequired), findsOneWidget);
          expect(service.calls, 0);
          await tester.enterText(
            find.byType(TextFormField),
            'test@example.com',
          );
          await tester.tap(find.byType(ElevatedButton));
          await tester.pump();
          expect(
            tester
                .widget<ElevatedButton>(find.byType(ElevatedButton))
                .onPressed,
            isNull,
          );
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump();
          expect(service.calls, 1);
          service.result.complete();
          await tester.pumpAndSettle();
          expect(find.text(strings.resetPasswordConfirmation), findsOneWidget);
          expect(find.byType(TextFormField), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('reset failure is safe and leaving during a request is safe', (
    tester,
  ) async {
    final service = TestRecovery();
    await tester.pumpWidget(app(service, 'en', Brightness.light));
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    service.result.completeError(
      const AuthServiceException(AuthFailure.network),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Connection unavailable. Check your internet and try again.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    final pending = TestRecovery();
    await tester.pumpWidget(app(pending, 'en', Brightness.light));
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.result.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('unconfigured reset fails closed', (tester) async {
    await tester.pumpWidget(
      app(const UnconfiguredAuthService(), 'en', Brightness.light),
    );
    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(
      find.text('Account services are unavailable. Please try again later.'),
      findsOneWidget,
    );
  });
}
