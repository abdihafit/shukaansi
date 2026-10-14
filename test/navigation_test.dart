import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/application/locale_scope.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/main.dart';
import 'package:shukaansi/services/locale_store.dart';
import 'package:shukaansi/services/profile_service.dart';

import 'discovery_fakes.dart';
import 'media_fakes.dart';
import 'profile_test.dart' as p;

AppLocalizations strings(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold).first));

Widget app({String locale = 'en', Brightness brightness = Brightness.light}) =>
    p.harness(
      p.TestProfiles()..stored = ProfileComplete(p.sample, p.details),
      locale,
      brightness,
      photos: TestPhotos(),
      discovery: TestDiscovery(),
      picker: TestPicker(),
    );

/// The harness plus a LocaleScope, so the language switcher can be used.
class _SwitchableApp extends StatefulWidget {
  const _SwitchableApp();
  @override
  State<_SwitchableApp> createState() => _SwitchableAppState();
}

class _SwitchableAppState extends State<_SwitchableApp> {
  Locale _locale = const Locale('en');
  @override
  Widget build(BuildContext context) => LocaleScope(
    locale: _locale,
    selectLocale: (locale) => setState(() => _locale = locale),
    child: app(locale: _locale.languageCode),
  );
}

void main() {
  testWidgets('home has four tabs; empty tabs lead back to Discover', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final s = strings(tester);
    // Matches have no tab of their own: new matches open Chats.
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text(s.navMatches), findsNothing);
    for (final (tab, title) in [
      (s.navLikes, s.likesReceivedEmpty),
      (s.navChats, s.chatsEmptyTitle),
    ]) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: tab);
    }
    // An empty Chats tab leads to Discover.
    await tester.tap(find.text(s.browseDiscover));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('language can be switched from My profile', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const _SwitchableApp());
    await tester.pumpAndSettle();
    await p.openProfileTab(tester);
    final en = strings(tester);
    expect(find.text(en.settingsLanguage), findsOneWidget);
    await p.tap(tester, en.settingsLanguage);
    await p.tap(tester, en.somaliLanguage);
    final so = strings(tester);
    expect(so.localeName, 'so');
    expect(find.text(so.settingsLanguage), findsOneWidget);
    expect(find.text(so.navDiscover), findsOneWidget);
  });

  testWidgets('the saved language is used at start and choices are saved', (
    tester,
  ) async {
    final store = MemoryLocaleStore('so');
    await tester.pumpWidget(
      ShukaansiApp(localeStore: store, initialLocale: const Locale('so')),
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('so'),
    );
    // The splash moves on to the language screen.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text(strings(tester).englishLanguage));
    await tester.pumpAndSettle();
    expect(store.value, 'en');
  });

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        '$locale ${brightness.name}: tabs fit a small screen with large text',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await tester.pumpWidget(app(locale: locale, brightness: brightness));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final s = strings(tester);
          for (final tab in [s.navLikes, s.navChats, s.navProfile]) {
            await tester.tap(
              find.descendant(
                of: find.byType(NavigationBar),
                matching: find.text(tab),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: tab);
          }
        },
      );
    }
  }
}
