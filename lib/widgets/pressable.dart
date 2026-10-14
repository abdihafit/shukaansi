import 'package:flutter/widgets.dart';

import '../theme/motion.dart';

/// Scales its child down slightly while a pointer is pressed, so touches feel
/// acknowledged. Wrap the tappable surface (it keeps its own ink and semantics).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.enabled ? (_) => _set(true) : null,
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _pressed ? Motion.pressedScale : 1,
      duration: Motion.of(context, Motion.press),
      curve: Motion.easeOut,
      child: widget.child,
    ),
  );
}

/// Fades and scales a child in once, from 95% rather than from nothing.
class EnterTransition extends StatelessWidget {
  const EnterTransition({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.of(context, Motion.enter),
    curve: Motion.easeOut,
    child: child,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.scale(
        scale: Motion.enterScale + (1 - Motion.enterScale) * t,
        child: child,
      ),
    ),
  );
}
