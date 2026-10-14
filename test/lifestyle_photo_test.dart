import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shukaansi/l10n/framework_localizations.dart';
import 'package:shukaansi/l10n/generated/app_localizations.dart';
import 'package:shukaansi/screens/auth_screen.dart';
import 'package:shukaansi/screens/onboarding_screen.dart';
import 'package:shukaansi/screens/welcome_screen.dart';
import 'package:shukaansi/theme/app_theme.dart';
import 'package:shukaansi/widgets/brand/brand.dart';

import 'app_lock_test.dart' show FakeAuth;

Widget app(
  Widget home, {
  String locale = 'en',
  Brightness brightness = Brightness.light,
  bool reduceMotion = false,
}) => MaterialApp(
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    SomaliMaterialFallback(),
    SomaliCupertinoFallback(),
    ...AppLocalizations.localizationsDelegates,
  ],
  theme: brightness == Brightness.light
      ? AppTheme.refinedLight
      : AppTheme.refinedDark,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
    child: child!,
  ),
  home: home,
);

Finder slide(LifestylePhoto photo) => find.byKey(ValueKey(photo.asset));

/// Records the slideshow's timers so tests can see them start and stop.
List<Timer> recordTimers() {
  final timers = <Timer>[];
  PhotoSlideshow.periodic = (interval, tick) =>
      Timer.periodic(interval, tick)..let(timers.add);
  addTearDown(() => PhotoSlideshow.periodic = Timer.periodic);
  return timers;
}

extension<T> on T {
  void let(void Function(T) f) => f(this);
}

Future<void> setSize(WidgetTester tester, Size size, double scale) async {
  tester.view.devicePixelRatio = 3;
  tester.view.physicalSize = size * 3;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

const sizes = [
  Size(320, 640),
  Size(360, 640),
  Size(430, 932),
  Size(800, 1280), // tablet
  Size(667, 375), // landscape phone
];

void main() {
  const slideshow = SizedBox(
    height: 300,
    child: PhotoSlideshow(photos: LifestylePhoto.signIn),
  );

  test('every photo is bundled', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final photo in [
      ...LifestylePhoto.signIn,
      LifestylePhoto.welcomeMan,
      LifestylePhoto.welcomeWoman,
      LifestylePhoto.connectionCouple,
    ]) {
      final data = await rootBundle.load(photo.asset);
      expect(data.lengthInBytes, greaterThan(0), reason: photo.asset);
      expect(data.lengthInBytes, lessThan(350 * 1024), reason: photo.asset);
    }
  });

  testWidgets('slideshow cross-fades every 5 s and loops', (tester) async {
    await tester.pumpWidget(app(slideshow));
    expect(slide(LifestylePhoto.loginCouple), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(slide(LifestylePhoto.loginWoman), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 400));
    // Mid-fade both photos are on screen.
    expect(slide(LifestylePhoto.loginCouple), findsOneWidget);
    expect(slide(LifestylePhoto.loginWoman), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    expect(slide(LifestylePhoto.loginCouple), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(slide(LifestylePhoto.loginCouple), findsOneWidget);
  });

  testWidgets('reduced motion keeps the first photo, with no timer', (
    tester,
  ) async {
    final timers = recordTimers();
    await tester.pumpWidget(app(slideshow, reduceMotion: true));
    await tester.pump(const Duration(seconds: 30));
    expect(slide(LifestylePhoto.loginCouple), findsOneWidget);
    expect(slide(LifestylePhoto.loginWoman), findsNothing);
    expect(timers, isEmpty);
  });

  testWidgets('timer stops on dispose', (tester) async {
    final timers = recordTimers();
    await tester.pumpWidget(app(slideshow));
    expect(timers.single.isActive, isTrue);
    await tester.pumpWidget(app(const SizedBox()));
    expect(timers.single.isActive, isFalse);
  });

  testWidgets('timer pauses while covered or in the background', (
    tester,
  ) async {
    final timers = recordTimers();
    await tester.pumpWidget(app(slideshow));
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push(MaterialPageRoute<void>(builder: (_) => const Scaffold())),
    );
    await tester.pumpAndSettle();
    expect(timers.every((t) => !t.isActive), isTrue);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(timers.last.isActive, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(timers.every((t) => !t.isActive), isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(timers.last.isActive, isTrue);
  });

  testWidgets('a missing photo falls back to a brand gradient', (tester) async {
    await tester.pumpWidget(
      app(
        const SizedBox(
          height: 200,
          child: LifestyleImage(LifestylePhoto('assets/images/missing.jpg')),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(DecoratedBox), findsWidgets);
  });

  test('page dots and white text are readable on the scrim', () {
    // Worst case: the darkest point of the scrim over a white photo.
    final bottom = Color.alphaBlend(const Color(0xA6000000), Colors.white);
    final x = bottom.computeLuminance();
    expect((1 + 0.05) / (x + 0.05), greaterThanOrEqualTo(4.5));
  });

  for (final locale in ['en', 'so']) {
    testWidgets('$locale: sign-in fields and button are in view on phones '
        'without scrolling', (tester) async {
      for (final size in const [
        Size(360, 640),
        Size(390, 844),
        Size(430, 932),
        Size(800, 1280),
      ]) {
        await setSize(tester, size, 1);
        await tester.pumpWidget(
          app(
            AuthScreen(
              key: ValueKey(size),
              initialMode: AuthMode.login,
              service: FakeAuth(),
            ),
            locale: locale,
          ),
        );
        await tester.pump();
        expect(find.byType(BrandBadge), findsOneWidget);
        for (final finder in [
          find.byKey(const ValueKey('email')),
          find.byKey(ValueKey('password-${AuthMode.login}')),
          find.byType(PrimaryButton),
        ]) {
          expect(
            tester.getRect(finder).bottom,
            lessThanOrEqualTo(size.height),
            reason: '$size',
          );
        }
      }
    });
  }

  for (final locale in ['en', 'so']) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
          '$locale ${brightness.name} ${scale}x: sign-in, welcome and '
          'language fit every size with the form intact',
          (tester) async {
            for (final size in sizes) {
              await setSize(tester, size, scale);
              final hero = size.height >= 480;

              for (final mode in AuthMode.values) {
                await tester.pumpWidget(
                  app(
                    AuthScreen(key: ValueKey(mode), initialMode: mode),
                    locale: locale,
                    brightness: brightness,
                  ),
                );
                await tester.pump();
                expect(tester.takeException(), isNull, reason: '$size');
                final s = AppLocalizations.of(
                  tester.element(find.byType(Form)),
                );
                expect(
                  find.byType(PhotoSlideshow),
                  hero ? findsOneWidget : findsNothing,
                );
                expect(find.byKey(const ValueKey('email')), findsOneWidget);
                expect(find.byKey(ValueKey('password-$mode')), findsOneWidget);
                final label = mode == AuthMode.login
                    ? s.signIn
                    : s.createAccount;
                final submit = find.widgetWithText(PrimaryButton, label);
                expect(submit, findsOneWidget);
                expect(
                  find.text(
                    mode == AuthMode.login
                        ? s.needAccount
                        : s.alreadyHaveAccount,
                  ),
                  findsOneWidget,
                );
                if (mode == AuthMode.login) {
                  expect(find.text(s.forgotPassword), findsOneWidget);
                }

                // Keyboard open: the form still scrolls to its button.
                await tester.ensureVisible(find.byKey(const ValueKey('email')));
                await tester.tap(find.byKey(const ValueKey('email')));
                tester.view.viewInsets = FakeViewPadding(
                  bottom: size.height * 0.4 * 3,
                );
                await tester.pump();
                await tester.ensureVisible(submit);
                await tester.pump();
                expect(submit.hitTestable(), findsOneWidget);
                expect(tester.takeException(), isNull, reason: '$size');
                tester.view.resetViewInsets();
              }

              for (final screen in const [
                WelcomeScreen(),
                OnboardingScreen(),
              ]) {
                await tester.pumpWidget(
                  app(screen, locale: locale, brightness: brightness),
                );
                await tester.pump();
                expect(tester.takeException(), isNull, reason: '$size');
                expect(
                  find.byType(LifestyleImage),
                  hero ? findsOneWidget : findsNothing,
                );
              }

              await tester.pumpWidget(
                app(
                  const Scaffold(
                    body: EmptyState(
                      icon: Icons.chat_bubble_outline,
                      photo: LifestylePhoto.connectionCouple,
                      title: 'No conversations yet',
                      message:
                          'When you both show interest, your match will '
                          'appear here, InshaAllah.',
                      actionLabel: 'Browse Discover',
                    ),
                  ),
                  locale: locale,
                  brightness: brightness,
                ),
              );
              await tester.pump();
              expect(tester.takeException(), isNull, reason: '$size');
            }
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }
}
