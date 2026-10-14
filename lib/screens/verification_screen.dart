import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/profile_media.dart';
import '../services/photo_picker.dart';
import '../services/photo_service.dart';
import '../theme/tokens.dart';
import '../widgets/centered_content.dart';
import '../widgets/pressable.dart';
import '../widgets/shukaansi_ui.dart';
import '../widgets/brand/brand.dart';

/// Takes a private selfie and submits it for manual review, then shows the
/// review timeline. Pops with the new [Verification] once submitted.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({
    super.key,
    required this.uid,
    required this.service,
    required this.picker,
    this.showNiqabTip = false,
  });
  final String uid;
  final PhotoService service;
  final PhotoPicker picker;

  /// Shown on women's profiles: the face must be uncovered for review.
  final bool showNiqabTip;
  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  Uint8List? _selfie;
  bool _busy = false;
  double? _progress;
  String? _error;

  /// Set once the selfie is sent; the screen then shows the review status.
  Verification? _submitted;

  Future<void> _take() async {
    final s = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      final bytes = await widget.picker.takeSelfie();
      if (!mounted || bytes == null) return;
      setState(() {
        if (isAcceptedPhoto(bytes)) {
          _selfie = bytes;
        } else {
          _error = s.photosUnsupported;
        }
      });
    } on PickerException {
      if (mounted) setState(() => _error = s.verifyCameraFailed);
    }
  }

  Future<void> _submit() async {
    if (_busy || _selfie == null) return;
    final s = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _progress = 0;
      _error = null;
    });
    try {
      final result = await widget.service.submitVerification(
        widget.uid,
        _selfie!,
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );
      if (mounted) setState(() => _submitted = result);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = s.verifySubmitFailed;
        });
      }
    }
  }

  void _finish() => Navigator.of(context).pop(_submitted);

  @override
  Widget build(BuildContext context) {
    final submitted = _submitted;
    if (submitted != null) {
      // Leaving by the back button also reports the submission.
      return PopScope<Verification>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _finish();
        },
        child: _InReview(onContinue: _finish),
      );
    }
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final selfie = _selfie;
    Widget tip(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 22, color: colors.primary)),
          const SizedBox(width: AppSpacing.m),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    Widget headline(String title, String body) => Column(
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: Text(s.verifyScreenTitle)),
      // The main action stays in view while the explanation scrolls.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.m,
            AppSpacing.xl,
            AppSpacing.m,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_busy) ...[
                    const SizedBox(height: AppSpacing.l),
                    Semantics(
                      liveRegion: true,
                      label: s.verifySubmitting,
                      child: LinearProgressIndicator(value: _progress),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.m),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                  ],
                  Pressable(
                    enabled: !_busy,
                    child: PrimaryButton(
                      onPressed: selfie == null ? _take : _submit,
                      loading: _busy,
                      loadingLabel: s.authLoading,
                      icon: selfie == null
                          ? Icons.photo_camera_front_outlined
                          : Icons.send,
                      label: selfie == null
                          ? s.verifyTakeSelfie
                          : s.verifySubmit,
                    ),
                  ),
                  if (selfie != null)
                    TextButton(
                      onPressed: _busy ? null : _take,
                      child: Text(s.verifyRetake),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: CenteredContent(
        top: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ShukaansiStepper(
              steps: [
                ProgressStep(s.verifyStepPhoto, ProgressStepState.done),
                ProgressStep(
                  s.verifyStepSelfie,
                  selfie == null
                      ? ProgressStepState.current
                      : ProgressStepState.done,
                ),
                ProgressStep(
                  s.verifyStepReview,
                  selfie == null
                      ? ProgressStepState.upcoming
                      : ProgressStepState.current,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (selfie == null) ...[
              const Center(child: _SelfieFrame()),
              const SizedBox(height: AppSpacing.xl),
              headline(s.verifyHeadline, s.verifyIntro),
              const SizedBox(height: AppSpacing.xl),
              ShukaansiFeatureCard(
                icon: Icons.lock_outline,
                title: s.verifyPrivateTitle,
                body: s.verifyTipPrivate,
              ),
              const SizedBox(height: AppSpacing.m),
              ShukaansiFeatureCard(
                icon: Icons.people_outline,
                iconColor: colors.secondary,
                title: s.verifyCareTitle,
                body: s.verifyCareBody,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                s.verifyTipsIntro,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              tip(Icons.wb_sunny_outlined, s.verifyTipLight),
              tip(Icons.face_outlined, s.verifyTipFace),
              if (widget.showNiqabTip)
                tip(Icons.face_retouching_natural_outlined, s.verifyTipNiqab),
            ] else ...[
              Center(
                child: EnterTransition(
                  child: Semantics(
                    image: true,
                    label: s.verifySelfiePreview,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.feature),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 260),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Image.memory(selfie, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              headline(s.verifyCheckHeadline, s.verifyCheckBody),
              const SizedBox(height: AppSpacing.l),
              ShukaansiFeatureCard(
                icon: Icons.lock_outline,
                title: s.verifyPrivateTitle,
                body: s.verifyTipPrivate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Decorative camera frame: corner brackets around a face, with a tick.
class _SelfieFrame extends StatelessWidget {
  const _SelfieFrame();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const size = 200.0;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _CornerPainter(colors.primary)),
            ),
            Center(
              child: Container(
                width: size * 0.74,
                height: size * 0.74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.face_outlined,
                  size: size * 0.42,
                  color: colors.primary,
                ),
              ),
            ),
            Positioned(
              right: size * 0.08,
              bottom: size * 0.08,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                  border: Border.all(color: colors.surface, width: 4),
                ),
                child: Icon(Icons.check, color: colors.onPrimary, size: 28),
              ),
            ),
            Positioned(
              left: size * 0.12,
              top: size * 0.32,
              child: Icon(
                Icons.auto_awesome,
                color: colors.secondary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final arm = size.width * 0.18;
    const inset = 4.0;
    final w = size.width - inset;
    final h = size.height - inset;
    for (final (x, y, dx, dy) in [
      (inset, inset, 1.0, 1.0),
      (w, inset, -1.0, 1.0),
      (inset, h, 1.0, -1.0),
      (w, h, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(Offset(x, y), Offset(x + dx * arm, y), paint)
        ..drawLine(Offset(x, y), Offset(x, y + dy * arm), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

/// Shown after the selfie is sent: what happens next, honestly stated.
class _InReview extends StatelessWidget {
  const _InReview({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(s.verifyScreenTitle),
      ),
      body: CenteredContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const EnterTransition(
              child: Center(
                child: ShukaansiIconBadge(icon: Icons.verified_user, size: 112),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Center(
              child: ShukaansiStatusChip(
                label: s.verifySubmittedChip,
                icon: Icons.check_circle,
                tone: StatusTone.positive,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                s.verifySubmittedTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              s.verifySubmittedBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SectionCard(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ShukaansiTimeline(
                steps: [
                  ProgressStep(
                    s.reviewStepProfile,
                    ProgressStepState.done,
                    detail: s.reviewStepProfileBody,
                  ),
                  ProgressStep(
                    s.reviewStepReview,
                    ProgressStepState.current,
                    detail: s.reviewStepReviewBody,
                  ),
                  ProgressStep(
                    s.reviewStepBadge,
                    ProgressStepState.upcoming,
                    detail: s.reviewStepBadgeBody,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Pressable(
              child: ElevatedButton(
                onPressed: onContinue,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.verifyContinue,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const ExcludeSemantics(child: Icon(Icons.arrow_forward)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
