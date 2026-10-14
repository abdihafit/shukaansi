import 'package:flutter/material.dart';

import '../widgets/brand/brand.dart';

import 'onboarding_screen.dart';

/// Continues the native splash: the full logo in exactly the same place,
/// then a short fade to the language choice.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final still = MediaQuery.disableAnimationsOf(context);
      Navigator.pushReplacement(
        context,
        PageRouteBuilder<void>(
          transitionDuration: still
              ? Duration.zero
              : const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: BrandSurface(
      child: Center(child: ShukaansiLogo(height: ShukaansiLogo.launchHeight)),
    ),
  );
}
