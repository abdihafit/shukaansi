import 'package:flutter/widgets.dart';

/// Shared motion tokens. Interface motion enters with a strong ease-out,
/// stays under 300 ms, never grows from zero, and respects reduced motion.
abstract final class Motion {
  /// Strong ease-out for anything entering or responding to a touch.
  static const easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Strong ease-in-out for elements moving while on screen.
  static const easeInOut = Cubic(0.77, 0, 0.175, 1);

  static const press = Duration(milliseconds: 160);
  static const enter = Duration(milliseconds: 220);

  /// Pressed elements shrink slightly to confirm the touch was felt.
  static const pressedScale = 0.97;

  /// Entering elements start nearly full size, never from nothing.
  static const enterScale = 0.95;

  /// AnimatedSwitcher layout that makes both children fill the space, so
  /// cover-fit images are not shown at their intrinsic size while fading.
  static Widget expandedSwitcherLayout(
    Widget? current,
    List<Widget> previous,
  ) => Stack(fit: StackFit.expand, children: [...previous, ?current]);

  /// Zero when the device asks for reduced motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : duration;
}
