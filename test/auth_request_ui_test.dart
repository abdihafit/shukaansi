import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/framework_localizations.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/screens/auth_screen.dart';
import 'package:shukaansi/services/auth_service.dart';
import 'package:shukaansi/theme/app_theme.dart';

class PendingTestService implements AuthService {
  final result = Completer<void>();
  int calls = 0;
  @override
  bool get isConfigured => true;
  @override
  Future<void> register({required String email, required String password}) {
    calls++;
    return result.future;
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      register(email: email, password: password);
}

void main() {
  for (final locale in ['en', 'so']) {
    testWidgets(
      '$locale pending request disables editing and shows safe error',
      (tester) async {
        final service = PendingTestService();
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              SomaliMaterialFallback(),
              SomaliCupertinoFallback(),
              ...AppLocalizations.localizationsDelegates,
            ],
            theme: AppTheme.dark,
            home: AuthScreen(service: service),
          ),
        );
        await tester.pumpAndSettle();
        final strings = AppLocalizations.of(tester.element(find.byType(Form)));
        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'test@example.com');
        await tester.enterText(fields.at(1), 'a long test passphrase');
        await tester.enterText(fields.at(2), 'a long test passphrase');
        final submit = find.byType(ElevatedButton);
        await tester.ensureVisible(submit);
        await tester.tap(submit);
        await tester.pump();
        expect(find.text(strings.authLoading), findsOneWidget);
        expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
        expect(
          tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNull,
        );
        for (final field in tester.widgetList<TextField>(
          find.byType(TextField),
        )) {
          expect(field.enabled, isFalse);
        }
        // Kept (hidden, disabled) until the result, so the phone's password
        // manager can save it after a successful sign-in.
        expect(
          tester.widget<TextFormField>(fields.at(1)).controller!.text,
          'a long test passphrase',
        );
        expect(service.calls, 1);
        service.result.completeError(
          const AuthServiceException(AuthFailure.network),
        );
        await tester.pumpAndSettle();
        expect(find.text(strings.authNetworkError), findsOneWidget);
        // A failed attempt clears the password, as before.
        expect(
          tester.widget<TextFormField>(fields.at(1)).controller!.text,
          isEmpty,
        );
        expect(tester.widget<ElevatedButton>(submit).onPressed, isNotNull);
        expect(find.text(strings.authRequestCompleted), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
