import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

// SectionCard moved to the brand widgets; kept available from here.
export 'brand/section_card.dart';
import 'brand/section_card.dart';

/// Decorative icon in a soft circle; hidden from screen readers.
class ShukaansiIconBadge extends StatelessWidget {
  const ShukaansiIconBadge({
    super.key,
    required this.icon,
    this.size = 40,
    this.color,
  });
  final IconData icon;
  final double size;

  /// Defaults to the brand green.
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size * 0.5, color: tint),
      ),
    );
  }
}

enum StatusTone { positive, neutral, attention }

/// Small pill describing a state. The icon and text carry the meaning, so it
/// never depends on colour alone.
class ShukaansiStatusChip extends StatelessWidget {
  const ShukaansiStatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.tone = StatusTone.neutral,
  });
  final String label;
  final IconData icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (background, foreground) = switch (tone) {
      StatusTone.positive => (
        colors.primary.withValues(alpha: 0.12),
        colors.primary,
      ),
      StatusTone.attention => (colors.errorContainer, colors.onErrorContainer),
      StatusTone.neutral => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.feature),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs + 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 18, color: foreground)),
            const SizedBox(width: AppSpacing.s - 2),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular progress with content in the middle. [value] is 0..1 and must be
/// real progress; the label describes it for screen readers.
class ShukaansiProgressRing extends StatelessWidget {
  const ShukaansiProgressRing({
    super.key,
    required this.value,
    required this.semanticsLabel,
    required this.child,
    this.size = 120,
    this.stroke = 8,
  });
  final double value;
  final String semanticsLabel;
  final Widget child;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0, 1)),
              duration: Motion.of(context, const Duration(milliseconds: 600)),
              curve: Motion.easeOut,
              builder: (context, progress, _) => CircularProgressIndicator(
                value: progress,
                strokeWidth: stroke,
                strokeCap: StrokeCap.round,
                color: colors.primary,
                backgroundColor: colors.primary.withValues(alpha: 0.15),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(stroke + AppSpacing.xs),
              child: Center(child: child),
            ),
          ],
        ),
      ),
    );
  }
}

enum ProgressStepState { done, current, upcoming }

/// One step in a [ShukaansiStepper] or [ShukaansiTimeline].
class ProgressStep {
  const ProgressStep(this.label, this.state, {this.detail});
  final String label;
  final ProgressStepState state;
  final String? detail;
}

String _stateLabel(BuildContext context, ProgressStepState state) {
  final s = AppLocalizations.of(context);
  return switch (state) {
    ProgressStepState.done => s.stepStateDone,
    ProgressStepState.current => s.stepStateCurrent,
    ProgressStepState.upcoming => s.stepStateUpcoming,
  };
}

/// The circle marking a step: filled with a tick when done, a ring with a
/// dot when current, an empty ring when still to come.
class _StepDot extends StatelessWidget {
  const _StepDot(this.state, {this.accent});
  final ProgressStepState state;
  final Color? accent;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = accent ?? colors.primary;
    const size = 28.0;
    return AnimatedContainer(
      duration: Motion.of(context, const Duration(milliseconds: 220)),
      curve: Motion.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: state == ProgressStepState.done
            ? colors.primary
            : colors.surface,
        border: Border.all(
          width: 2.5,
          color: switch (state) {
            ProgressStepState.done => colors.primary,
            ProgressStepState.current => color,
            ProgressStepState.upcoming => colors.outlineVariant,
          },
        ),
      ),
      child: switch (state) {
        ProgressStepState.done => Icon(
          Icons.check,
          size: 16,
          color: colors.onPrimary,
        ),
        ProgressStepState.current => Center(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        ProgressStepState.upcoming => null,
      },
    );
  }
}

/// Horizontal steps with connecting lines, e.g. Photo → Selfie → Review.
class ShukaansiStepper extends StatelessWidget {
  const ShukaansiStepper({super.key, required this.steps});
  final List<ProgressStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    Widget line(bool reached, bool visible) => Expanded(
      child: Container(
        height: 2.5,
        color: !visible
            ? Colors.transparent
            : reached
            ? colors.primary
            : colors.outlineVariant,
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Semantics(
              container: true,
              label:
                  '${steps[i].label}, ${_stateLabel(context, steps[i].state)}',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Row(
                      children: [
                        line(
                          steps[i].state != ProgressStepState.upcoming,
                          i > 0,
                        ),
                        _StepDot(steps[i].state),
                        line(
                          steps[i].state == ProgressStepState.done,
                          i < steps.length - 1,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      steps[i].label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: steps[i].state == ProgressStepState.upcoming
                            ? colors.onSurfaceVariant
                            : colors.onSurface,
                        fontWeight: steps[i].state == ProgressStepState.current
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Vertical timeline with a title and detail per step. The current step uses
/// the gold accent so it stands apart from finished ones.
class ShukaansiTimeline extends StatelessWidget {
  const ShukaansiTimeline({super.key, required this.steps});
  final List<ProgressStep> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          Semantics(
            container: true,
            label: '${steps[i].label}, ${_stateLabel(context, steps[i].state)}',
            child: ExcludeSemantics(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        _StepDot(steps[i].state, accent: colors.secondary),
                        if (i < steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2.5,
                              margin: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              color: steps[i].state == ProgressStepState.done
                                  ? colors.primary
                                  : colors.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 2,
                          bottom: i < steps.length - 1 ? AppSpacing.l : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[i].label,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color:
                                    steps[i].state == ProgressStepState.upcoming
                                    ? colors.onSurfaceVariant
                                    : colors.onSurface,
                              ),
                            ),
                            if (steps[i].detail != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                steps[i].detail!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A tinted card with a large icon, a bold title and a short explanation,
/// used for reassurances such as "Private and secure".
class ShukaansiFeatureCard extends StatelessWidget {
  const ShukaansiFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.iconColor,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      tinted: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShukaansiIconBadge(icon: icon, size: 52, color: iconColor),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A read-only label and value. Labels are quieter than values.
class ShukaansiProfileField extends StatelessWidget {
  const ShukaansiProfileField({
    super.key,
    required this.label,
    required this.value,
  });
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Fields separated by subtle dividers, for use inside a section card.
class ShukaansiFieldList extends StatelessWidget {
  const ShukaansiFieldList({super.key, required this.fields});
  final Map<String, String> fields;
  @override
  Widget build(BuildContext context) {
    final entries = fields.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ShukaansiProfileField(label: entries[i].key, value: entries[i].value),
        ],
      ],
    );
  }
}
