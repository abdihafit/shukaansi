// Renders the development preview with real fonts and saves PNGs to
// build/preview_screenshots/ for design review. Not part of the normal test
// suite; run it explicitly:
//
//   flutter test tool/preview_screenshots/screenshots_test.dart
//
// Uses the Roboto and Material Icons fonts shipped in the Flutter SDK cache.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/preview/fixtures.dart';
import 'package:shukaansi/preview/preview_app.dart';

final _out = Directory('build/preview_screenshots');
final _boundary = GlobalKey();

Future<void> _loadFonts() async {
  final sdk =
      Platform.environment['FLUTTER_ROOT'] ?? r'C:\Users\ADMIN\flutter\flutter';
  final dir = '$sdk/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('$dir/$name').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final w in ['regular', 'medium', 'bold', 'italic']) {
    roboto.addFont(read('roboto-$w.ttf'));
  }
  await roboto.load();
  final jakarta = FontLoader('PlusJakartaSans');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    jakarta.addFont(
      File('assets/fonts/plus_jakarta_sans/PlusJakartaSans-$w.ttf')
          .readAsBytes()
          .then(ByteData.sublistView),
    );
  }
  await jakarta.load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('materialicons-regular.otf'))).load();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
  await tester.pumpAndSettle();
}

/// Decodes every visible image for real (fake async can't), then saves.
Future<void> _shot(
  WidgetTester tester,
  String name, {
  bool settle = true,
}) async {
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = (element.widget as Image).image;
      await precacheImage(image, element);
    }
  });
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await tester.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    _out.createSync(recursive: true);
    File('${_out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<PreviewWorld> _pump(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  PreviewScenario scenario = PreviewScenario.populated,
  bool dark = false,
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  tester.platformDispatcher.platformBrightnessTestValue = dark
      ? Brightness.dark
      : Brightness.light;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
  });
  final world = PreviewWorld()..scenario = scenario;
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: PreviewApp(world: world),
    ),
  );
  if (scenario == PreviewScenario.loading) {
    await tester.pump(const Duration(seconds: 1));
  } else {
    await _settle(tester);
  }
  return world;
}

AppLocalizations _s(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(NavigationBar)));

Future<void> _tab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await _settle(tester);
}

/// A screenshot test drawn with real shadows (the test default draws them as
/// solid black outlines). Restored before the framework's end-of-test check.
void _shots(String description, Future<void> Function(WidgetTester) body) =>
    testWidgets(description, (tester) async {
      debugDisableShadows = false;
      try {
        await body(tester);
      } finally {
        debugDisableShadows = true;
      }
    });

void main() {
  setUpAll(_loadFonts);

  for (final (label, size) in [
    ('small', const Size(360, 690)),
    ('large', const Size(412, 915)),
  ]) {
    _shots('$label: main screens', (tester) async {
      await _pump(tester, size: size);
      final s = _s(tester);
      await _shot(tester, '$label-01-discover');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await _settle(tester);
      await _shot(tester, '$label-02-discover-details');
      await _tab(tester, s.navLikes);
      await _shot(tester, '$label-03-likes-received');
      await tester.tap(find.textContaining(s.likesSentTab));
      await _settle(tester);
      await _shot(tester, '$label-04-likes-sent');
      await _tab(tester, s.navChats);
      await _shot(tester, '$label-05-chats');
      await _tab(tester, s.navProfile);
      await _shot(tester, '$label-06-profile');
    });
  }

  _shots('large dark: main screens', (tester) async {
    await _pump(tester, dark: true);
    final s = _s(tester);
    await _shot(tester, 'dark-01-discover');
    await _tab(tester, s.navChats);
    await _shot(tester, 'dark-02-chats');
    await _tab(tester, s.navProfile);
    await _shot(tester, 'dark-03-profile');
  });

  _shots('large text 1.4 on a small phone', (tester) async {
    await _pump(tester, size: const Size(360, 690), textScale: 1.4);
    final s = _s(tester);
    await _shot(tester, 'text14-01-discover');
    await _tab(tester, s.navLikes);
    await _shot(tester, 'text14-02-likes');
    await _tab(tester, s.navChats);
    await _shot(tester, 'text14-03-chats');
    await _tab(tester, s.navProfile);
    await _shot(tester, 'text14-04-profile');
  });

  _shots('tablet', (tester) async {
    await _pump(tester, size: const Size(834, 1112));
    await _shot(tester, 'tablet-01-discover');
  });

  _shots('flows: match, Wali pending, chat, photo viewer', (tester) async {
    await _pump(tester);
    final s = _s(tester);
    await tester.tap(find.bySemanticsLabel(s.openPhoto(1, 3)).first);
    await _settle(tester);
    await _shot(tester, 'flow-01-photo-viewer');
    await tester.tap(find.byTooltip(s.closePhoto));
    await _settle(tester);
    await tester.tap(find.byTooltip(s.passAction));
    await _settle(tester);
    await _shot(tester, 'flow-02-passed-undo');
    await tester.tap(find.byTooltip(s.likeAction));
    await _settle(tester);
    await _shot(tester, 'flow-03-match');
    Navigator.of(tester.element(find.text(s.matchTitle))).pop();
    await _settle(tester);
    await _tab(tester, s.navChats);
    await tester.tap(find.text('Hodan'));
    await _settle(tester);
    await _shot(tester, 'flow-04-wali-pending');
    await tester.pageBack();
    await _settle(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^Amina')));
    await _settle(tester);
    await _shot(tester, 'flow-05-chat');
  });

  for (final scenario in [
    PreviewScenario.loading,
    PreviewScenario.networkError,
    PreviewScenario.incompleteProfile,
    PreviewScenario.noMatches,
    PreviewScenario.preferencesNotSet,
  ]) {
    _shots('state: ${scenario.name}', (tester) async {
      await _pump(tester, size: const Size(360, 690), scenario: scenario);
      await _shot(
        tester,
        'state-${scenario.name}',
        settle: scenario != PreviewScenario.loading,
      );
    });
  }

  _shots('state: empty activity', (tester) async {
    await _pump(
      tester,
      size: const Size(360, 690),
      scenario: PreviewScenario.emptyActivity,
    );
    final s = _s(tester);
    await _tab(tester, s.navLikes);
    await _shot(tester, 'state-empty-likes');
    await _tab(tester, s.navChats);
    await _shot(tester, 'state-empty-chats');
  });

  _shots('audit: onboarding form, verification, plans', (tester) async {
    await _pump(tester, scenario: PreviewScenario.incompleteProfile);
    final s = _s(tester);
    await _tab(tester, s.navProfile);
    await tester.tap(find.text(s.profileEdit));
    await _settle(tester);
    await _shot(tester, 'audit-01-onboarding-form');
    await tester.pageBack();
    await _settle(tester);
    await tester.tap(find.text(s.progressVerification));
    await _settle(tester);
    await _shot(tester, 'audit-02-verification');
    await tester.pageBack();
    await _settle(tester);
    final plans = find.text(s.viewPlans);
    await tester.scrollUntilVisible(
      plans,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    // Bring it clear of the navigation bar before tapping.
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await _settle(tester);
    await tester.tap(plans);
    await _settle(tester);
    await _shot(tester, 'audit-03-plans');
  });

  _shots('screens: preview own profile, profile, likes, chats', (tester) async {
    await _pump(tester);
    final s = _s(tester);
    await _tab(tester, s.navProfile);
    await _shot(tester, 'screen-03-my-profile');
    await tester.tap(find.text(s.previewProfile));
    await _settle(tester);
    await _shot(tester, 'screen-02-preview-profile');
    await tester.pageBack();
    await _settle(tester);
    await _tab(tester, s.navLikes);
    await _shot(tester, 'screen-05-likes');
    await _tab(tester, s.navChats);
    await _shot(tester, 'screen-04-chats');
  });
}
