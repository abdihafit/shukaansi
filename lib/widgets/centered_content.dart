import 'dart:math' as math;

import 'package:flutter/material.dart';

class CenteredContent extends StatelessWidget {
  const CenteredContent({super.key, required this.child, this.top = false});

  final Widget child;

  /// Long content such as forms starts at the top instead of the middle.
  final bool top;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 48),
            ),
            child: Align(
              alignment: top ? Alignment.topCenter : Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
