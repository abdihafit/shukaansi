import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/application/locale_scope.dart';
import 'package:shukaansi/main.dart';

void main() {
  test('Somali resources cover every English message', () {
    final english = jsonDecode(
      File('lib/l10n/app_en.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final somali = jsonDecode(
      File('lib/l10n/app_so.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final keys = english.keys.where((key) => !key.startsWith('@'));
    expect(
      somali.keys.where((key) => !key.startsWith('@')),
      unorderedEquals(keys),
    );
    for (final key in keys) {
      expect((somali[key] as String).trim(), isNotEmpty, reason: key);
    }
  });

  for (final deviceLocale in [
    const Locale('so', 'SO'),
    const Locale('fr', 'FR'),
  ]) {
    testWidgets('device locale $deviceLocale resolves and can be overridden', (
      tester,
    ) async {
      tester.platformDispatcher.localesTestValue = [deviceLocale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(const ShukaansiApp());
      await tester.pumpAndSettle();
      final somali = deviceLocale.languageCode == 'so';
      expect(
        find.bySemanticsLabel(
          somali
              ? 'Shukaansi, Xalaal • Dhab ah • Wadajir'
              : 'Shukaansi, Halal • Serious • Together',
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.text(somali ? 'English' : 'Soomaali'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          somali
              ? 'Assalamu alaikum, welcome to Shukaansi'
              : 'Assalaamu calaykum, ku soo dhawoow Shukaansi',
        ),
        findsOneWidget,
      );
      final context = tester.element(find.byType(Scaffold));
      expect(MaterialLocalizations.of(context).backButtonTooltip, 'Back');
      // Changing app locale rebuilds the current route without resetting navigation.
      LocaleScope.of(context).selectLocale(const Locale('so'));
      await tester.pumpAndSettle();
      expect(
        find.text('Assalaamu calaykum, ku soo dhawoow Shukaansi'),
        findsOneWidget,
      );
      expect(find.text('Choose your language'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Somali flow remains reachable in landscape with large text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(667, 375));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ShukaansiApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Soomaali'));
    await tester.tap(find.text('Soomaali'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Bilow'));
    await tester.tap(find.text('Bilow'));
    await tester.pumpAndSettle();
    expect(find.text('Samee akoon'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}
