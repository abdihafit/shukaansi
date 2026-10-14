import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// The main action on a screen: full width, teal, 52dp. While [loading] it
/// is disabled and shows a small spinner beside [loadingLabel] (or [label]),
/// so people can see something is happening.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: _ButtonContent(
        label: loading ? (loadingLabel ?? label) : label,
        icon: icon,
        loading: loading,
      ),
    ),
  );
}

/// A secondary action: full width, teal outline, 52dp, same loading state.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.loadingLabel,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: loading ? null : onPressed,
      child: _ButtonContent(
        label: loading ? (loadingLabel ?? label) : label,
        icon: icon,
        loading: loading,
      ),
    ),
  );
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.loading,
  });
  final String label;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final lead = loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : icon == null
        ? null
        : Icon(icon, size: 20);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lead != null) ...[
          ExcludeSemantics(child: lead),
          const SizedBox(width: AppSpacing.s),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}
