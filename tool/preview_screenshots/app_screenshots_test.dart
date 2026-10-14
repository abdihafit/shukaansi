// Renders the real app shell (ProfileGate with the test fakes) with real
// fonts and saves PNGs to build/app_screenshots/ for design review. Not part
// of the normal test suite; run it explicitly:
//
//   flutter test tool/preview_screenshots/app_screenshots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/main.dart';
import 'package:shukaansi/theme/app_theme.dart';
import 'package:shukaansi/widgets/brand_loading.dart';
import 'package:shukaansi/services/profile_service.dart';

import '../../test/account_test.dart' as a;
import '../../test/discovery_fakes.dart';
import '../../test/interest_fakes.dart';
import '../../test/media_fakes.dart';
import '../../test/profile_test.dart' as p;

final _out = Directory('build/app_screenshots');
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

Future<void> _shot(
  WidgetTester tester,
  String name, {
  bool settle = true,
}) async {
  // Settle, decode images for real (the test clock can't), settle again.
  // Endless animations (spinners) can't settle: pump a frame instead.
  Future<void> calm() => settle
      ? tester.pumpAndSettle()
      : tester.pump(const Duration(milliseconds: 300));
  await calm();
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      await precacheImage((element.widget as Image).image, element);
    }
  });
  await tester.pump();
  await calm();
  await tester.runAsync(() async {
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    _out.createSync(recursive: true);
    File('${_out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void _shots(String description, Future<void> Function(WidgetTester) body) =>
    testWidgets(description, (tester) async {
      debugDisableShadows = false;
      try {
        await body(tester);
      } finally {
        debugDisableShadows = true;
      }
    });

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  Size size = const Size(412, 915),
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool emailVerified = true,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  final hodan = testCard('hodan', name: 'Hodan', verified: true);
  final amina = testCard('amina', name: 'Amina');
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: p.harness(
        p.TestProfiles()..stored = ProfileComplete(p.sample, p.details),
        'en',
        brightness,
        account: a.TestAccount()..verified = emailVerified,
        photos: TestPhotos()..ids = [photoId(1), photoId(2)],
        discovery: TestDiscovery()..cards = [hodan, amina],
        interests: TestInterests(received: [amina], matches: [hodan]),
        picker: TestPicker(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return AppLocalizations.of(tester.element(find.byType(Scaffold).first));
}

void main() {
  setUpAll(_loadFonts);

  _shots('loading page, then slow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.refinedLight,
          home: BrandLoadingPage(onSignOut: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await _shot(tester, 'brand-05-loading', settle: false);
    await tester.pump(const Duration(seconds: 9));
    await _shot(tester, 'brand-06-loading-slow', settle: false);
  });

  for (final dark in [false, true]) {
    _shots('brand screens ${dark ? 'dark' : 'light'}', (tester) async {
      final mode = dark ? 'dark' : 'light';
      await tester.binding.setSurfaceSize(const Size(412, 915));
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      });
      await tester.pumpWidget(
        RepaintBoundary(key: _boundary, child: const ShukaansiApp()),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await _shot(tester, 'brand-01-splash-$mode');
      await tester.pump(const Duration(seconds: 2));
      await _shot(tester, 'brand-02-language-$mode');
      await tester.tap(find.text('English'));
      await _shot(tester, 'brand-03-welcome-$mode');
      await tester.tap(find.byType(ElevatedButton));
      await _shot(tester, 'brand-04-sign-up-$mode');
    });
  }

  _shots('app screens', (tester) async {
    final s = await _pump(tester, emailVerified: false);
    await _shot(tester, '01-discover');
    await p.openProfileTab(tester);
    await _shot(tester, '02-profile');
    await p.tap(tester, s.managePhotos);
    await _shot(tester, '03-manage-photos');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -900));
    await _shot(tester, '04-manage-photos-verification');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await p.tap(tester, s.profileEdit);
    await _shot(tester, '05-edit-profile');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await p.tap(tester, s.progressAccount);
    await _shot(tester, '06-verify-email');
    await tester.pageBack();
    await tester.pumpAndSettle();
    final plans = find.text(s.viewPlans).first;
    await tester.ensureVisible(plans);
    await tester.pumpAndSettle();
    await tester.tap(plans);
    await tester.pumpAndSettle();
    await tester.tap(find.text(s.planPremium).first);
    await _shot(tester, '07-plans');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(s.navChats),
      ),
    );
    await _shot(tester, '08-chats');
  });

  _shots('verification screen', (tester) async {
    final s = await _pump(tester);
    await p.openProfileTab(tester);
    await p.tap(tester, s.managePhotos);
    final start = find.text(s.verifyStart);
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await _shot(tester, '09-verification');
  });

  _shots('small phone, large text', (tester) async {
    await _pump(
      tester,
      size: const Size(360, 690),
      textScale: 1.4,
      brightness: Brightness.dark,
    );
    await p.openProfileTab(tester);
    await _shot(tester, '10-profile-large-text-dark');
  });
}
