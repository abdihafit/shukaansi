import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/theme/app_theme.dart';
import 'package:shukaansi/widgets/brand_loading.dart';
import 'package:shukaansi/widgets/brand/brand.dart';

Widget app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.refinedLight,
  home: home,
);

void main() {
  testWidgets('loading shows only the logo and a spinner at first', (
    tester,
  ) async {
    var signedOut = 0;
    await tester.pumpWidget(
      app(BrandLoadingPage(onSignOut: () => signedOut++)),
    );
    final s = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(ShukaansiLogo), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(s.signOut), findsNothing);

    // The way out appears only when loading takes unusually long.
    await tester.pump(const Duration(seconds: 7));
    expect(find.text(s.signOut), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(s.loadingSlow), findsOneWidget);
    await tester.tap(find.text(s.signOut));
    expect(signedOut, 1);
  });

  testWidgets('without a sign-out action nothing extra appears', (
    tester,
  ) async {
    await tester.pumpWidget(app(const BrandLoadingPage()));
    await tester.pump(const Duration(seconds: 20));
    final s = AppLocalizations.of(tester.element(find.byType(Scaffold)));
    expect(find.text(s.loadingSlow), findsNothing);
    expect(find.text(s.signOut), findsNothing);
  });

  testWidgets('the logo sits in the centre, where the native splash draws it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(const BrandLoadingPage()));
    final logo = tester.getRect(find.byType(ShukaansiLogo));
    expect(logo.center, const Offset(200, 400));
    expect(logo.height, closeTo(ShukaansiLogo.launchHeight, 0.5));
  });
}
