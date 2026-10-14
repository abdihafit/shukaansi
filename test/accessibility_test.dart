import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/preview/fixtures.dart';
import 'package:shukaansi/preview/preview_app.dart';
import 'package:shukaansi/theme/app_theme.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.pumpAndSettle();
}

void main() {
  for (final (mode, theme) in [
    ('light', AppTheme.refinedLight),
    ('dark', AppTheme.refinedDark),
  ]) {
    test('$mode: text colours meet WCAG AA (4.5:1)', () {
      final c = theme.colorScheme;
      final pairs = {
        'text on page': (c.onSurface, c.surface),
        'text on card': (c.onSurface, c.surfaceContainerLowest),
        'secondary text on page': (c.onSurfaceVariant, c.surface),
        'secondary text on card': (
          c.onSurfaceVariant,
          c.surfaceContainerLowest,
        ),
        'teal links on page': (c.primary, c.surface),
        'teal links on card': (c.primary, c.surfaceContainerLowest),
        'button text': (c.onPrimary, c.primary),
        'chip text': (c.onPrimaryContainer, c.primaryContainer),
        'gold text on card': (c.secondary, c.surfaceContainerLowest),
        'errors on page': (c.error, c.surface),
      };
      for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: name);
      }
    });
  }

  test('white text on the photo scrim is readable', () {
    // Worst case: the scrim over a white photo.
    final scrim = Color.alphaBlend(AppColors.photoScrim, Colors.white);
    expect(contrast(AppColors.onPhoto, scrim), greaterThanOrEqualTo(4.5));
  });

  for (final (label, size, scale) in [
    ('360px phone', const Size(360, 740), 1.0),
    ('360px phone, large text', const Size(360, 740), 1.3),
    ('large phone', const Size(430, 932), 1.0),
  ]) {
    testWidgets('$label: tap targets, labels and contrast on every tab', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(PreviewApp(world: PreviewWorld()));
      await settle(tester);
      final s = AppLocalizations.of(tester.element(find.byType(NavigationBar)));
      for (final tab in [s.navDiscover, s.navLikes, s.navChats, s.navProfile]) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(tab),
          ),
        );
        await settle(tester);
        expect(tester.takeException(), isNull, reason: tab);
        await expectLater(
          tester,
          meetsGuideline(androidTapTargetGuideline),
          reason: tab,
        );
        await expectLater(
          tester,
          meetsGuideline(labeledTapTargetGuideline),
          reason: tab,
        );
        if (scale == 1.0) {
          await expectLater(
            tester,
            meetsGuideline(textContrastGuideline),
            reason: tab,
          );
        }
      }
      handle.dispose();
    });
  }
}
