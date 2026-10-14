import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/theme/app_theme.dart';
import 'package:shukaansi/theme/tokens.dart';
import 'package:shukaansi/widgets/brand/brand.dart';

Widget app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.refinedLight,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: child),
  ),
);

void main() {
  testWidgets('primary button: full width, 52dp, loading disables it', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      app(PrimaryButton(label: 'Continue', onPressed: () => taps++)),
    );
    final size = tester.getSize(find.byType(ElevatedButton));
    expect(size.height, AppSizes.button);
    expect(size.width, tester.getSize(find.byType(Scaffold)).width);
    await tester.tap(find.text('Continue'));
    expect(taps, 1);

    await tester.pumpWidget(
      app(
        PrimaryButton(
          label: 'Continue',
          loadingLabel: 'Please wait',
          loading: true,
          onPressed: () => taps++,
        ),
      ),
    );
    expect(find.text('Please wait'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(taps, 1, reason: 'disabled while loading');
  });

  testWidgets('empty state: mint icon circle, title, message, action', (
    tester,
  ) async {
    var acted = false;
    await tester.pumpWidget(
      app(
        EmptyState(
          icon: Icons.chat_bubble_outline,
          title: 'No conversations yet',
          message: 'InshaAllah, your matches will appear here.',
          actionLabel: 'Browse Discover',
          onAction: () => acted = true,
        ),
      ),
    );
    expect(find.text('No conversations yet'), findsOneWidget);
    expect(find.textContaining('InshaAllah'), findsOneWidget);
    await tester.tap(find.text('Browse Discover'));
    expect(acted, isTrue);
  });

  testWidgets('settings tile shows a chevron only when it opens something', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        Column(
          children: [
            SettingsTile(icon: Icons.tune, title: 'Opens', onTap: () {}),
            const SettingsTile(icon: Icons.info_outline, title: 'Static'),
          ],
        ),
      ),
    );
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('skeletons stay still with reduced motion', (tester) async {
    await tester.pumpWidget(app(const ListSkeleton(), reduceMotion: true));
    // Nothing keeps animating, so the tree settles.
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonBox), findsWidgets);
  });
}
