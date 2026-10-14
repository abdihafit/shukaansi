import 'package:flutter/material.dart';

import '../application/media_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/profile_media.dart';
import '../screens/photo_viewer.dart';
import '../theme/motion.dart';
import 'pressable.dart';
import 'shukaansi_ui.dart';
import '../theme/tokens.dart';

String mediaErrorText(AppLocalizations s, MediaError error) => switch (error) {
  MediaError.unsupported => s.photosUnsupported,
  MediaError.uploadFailed => s.photosUploadFailed,
  MediaError.updateFailed => s.photosUpdateFailed,
  MediaError.pickFailed => s.photosPickFailed,
  MediaError.privacyFailed => s.blurFailed,
};

enum _PhotoAction { view, makeMain, remove }

/// Owner photo grid: up to six portrait tiles, the first marked as main.
class PhotosSection extends StatelessWidget {
  const PhotosSection({super.key, required this.controller});
  final MediaController controller;

  Future<void> _openActions(BuildContext context, String id, int index) async {
    final s = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final action = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.images.containsKey(id))
              ListTile(
                leading: const Icon(Icons.zoom_out_map),
                title: Text(s.photosView),
                onTap: () => Navigator.pop(context, _PhotoAction.view),
              ),
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(s.photosMakeMain),
                onTap: () => Navigator.pop(context, _PhotoAction.makeMain),
              ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colors.error),
              title: Text(
                s.photosRemove,
                style: TextStyle(color: colors.error),
              ),
              onTap: () => Navigator.pop(context, _PhotoAction.remove),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    final changesMain =
        action != _PhotoAction.view &&
        controller.changesMain(id, removing: action == _PhotoAction.remove);
    if (changesMain && controller.verificationActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.photosResetTitle),
          content: Text(s.photosResetBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.profileCancelEdit),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.photosResetConfirm),
            ),
          ],
        ),
      );
      if (!context.mounted || confirmed != true) return;
    }
    switch (action) {
      case _PhotoAction.view:
        await Navigator.of(context).push(
          PageRouteBuilder<void>(
            opaque: false,
            transitionDuration: Motion.of(context, Motion.enter),
            reverseTransitionDuration: Motion.of(context, Motion.press),
            pageBuilder: (_, _, _) => PhotoViewer(
              heroTag: 'photo-$id',
              bytes: controller.images[id]!,
            ),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Motion.easeOut,
              ),
              child: child,
            ),
          ),
        );
      case _PhotoAction.makeMain:
        await controller.makeMain(id);
      case _PhotoAction.remove:
        await controller.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final ids = controller.photoIds;
        final tiles = <Widget>[
          if (controller.loading)
            for (var i = 0; i < 3; i++) const _Skeleton()
          else ...[
            for (final (index, id) in ids.indexed)
              EnterTransition(
                key: ValueKey(id),
                child: _PhotoTile(
                  id: id,
                  index: index,
                  controller: controller,
                  onTap: () => _openActions(context, id, index),
                ),
              ),
            if (controller.uploading != null)
              _UploadingTile(controller: controller),
            if (ids.length + (controller.uploading == null ? 0 : 1) < maxPhotos)
              _AddTile(enabled: controller.canAdd, onTap: controller.addPhoto),
          ],
        ];
        // Every slot is always visible, numbered, so the limit is clear.
        if (!controller.loading) {
          for (var slot = tiles.length + 1; slot <= maxPhotos; slot++) {
            tiles.add(_EmptySlot(number: slot));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      s.photosTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (!controller.loading && !controller.loadFailed) ...[
                  const SizedBox(width: AppSpacing.s),
                  // Wraps rather than overflowing with long text.
                  Flexible(
                    child: Text(
                      s.photosCount(ids.length, maxPhotos),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.photosHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (controller.loadFailed)
              Row(
                children: [
                  Expanded(child: Text(s.photosLoadFailed)),
                  TextButton(onPressed: controller.load, child: Text(s.retry)),
                ],
              )
            else
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3 / 4,
                children: tiles,
              ),
            if (controller.error != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  mediaErrorText(s, controller.error!),
                  style: TextStyle(color: colors.error),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

const _tileRadius = BorderRadius.all(Radius.circular(12));

/// A not-yet-used photo slot. Decorative: the Add photo tile is the action.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.number});
  final int number;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: _tileRadius,
          border: Border.all(color: colors.outlineVariant),
        ),
        // Scales down inside small tiles or with very large text.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, color: colors.outline),
              const SizedBox(height: AppSpacing.s),
              CircleAvatar(
                radius: 11,
                backgroundColor: colors.surfaceContainerHighest,
                child: Text(
                  '$number',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: _tileRadius,
    ),
  );
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.id,
    required this.index,
    required this.controller,
    required this.onTap,
  });
  final String id;
  final int index;
  final MediaController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final bytes = controller.images[id];
    final failed = controller.imageFailed.contains(id);
    final label = index == 0
        ? '${s.photosSlot(index + 1)}, ${s.photosMain}'
        : s.photosSlot(index + 1);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        enabled: !controller.busy,
        child: Material(
          color: colors.surfaceContainerHighest,
          borderRadius: _tileRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: controller.busy
                ? null
                : failed
                ? () => controller.retryImage(id)
                : onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedSwitcher(
                  duration: Motion.of(context, Motion.enter),
                  switchInCurve: Motion.easeOut,
                  layoutBuilder: Motion.expandedSwitcherLayout,
                  child: bytes != null
                      ? Hero(
                          key: const ValueKey('image'),
                          tag: 'photo-$id',
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        )
                      : Center(
                          key: const ValueKey('placeholder'),
                          child: Icon(
                            failed ? Icons.refresh : Icons.image_outlined,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                ),
                if (index == 0)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          s.photosMain,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onPrimary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadingTile extends StatelessWidget {
  const _UploadingTile({required this.controller});
  final MediaController controller;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Semantics(
      label: s.photosUploading,
      liveRegion: true,
      child: ClipRRect(
        borderRadius: _tileRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.45,
              child: Image.memory(controller.uploading!, fit: BoxFit.cover),
            ),
            Center(
              child: CircularProgressIndicator(value: controller.progress),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: s.photosAdd,
      excludeSemantics: true,
      child: Pressable(
        enabled: enabled,
        child: Material(
          color: colors.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: _tileRadius,
            side: BorderSide(color: colors.outlineVariant, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            // Scales down inside small tiles or with very large text.
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: enabled ? colors.primary : colors.outline,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        s.photosAdd,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: enabled ? colors.primary : colors.outline,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile verification status with the next action for each state. The
/// status chip shows the real backend state; nothing claims verification
/// unless the reviewer approved it.
class VerificationCard extends StatelessWidget {
  const VerificationCard({
    super.key,
    required this.controller,
    required this.onStart,
  });
  final MediaController controller;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.loading || controller.loadFailed) {
          return const SizedBox.shrink();
        }
        final verification = controller.verification;
        if (verification.status == VerificationStatus.verified) {
          return SectionCard(
            tinted: true,
            child: Row(
              children: [
                const ShukaansiIconBadge(icon: Icons.verified),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    s.verifyVerified,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final (icon, title, body, chip) = switch (verification.status) {
          VerificationStatus.pending => (
            Icons.hourglass_top_rounded,
            s.verifyPendingTitle,
            s.verifyPendingBody,
            ShukaansiStatusChip(
              label: s.verifyStatusPending,
              icon: Icons.schedule,
            ),
          ),
          VerificationStatus.rejected => (
            Icons.error_outline,
            s.verifyRejectedTitle,
            s.verifyRejectedBody,
            ShukaansiStatusChip(
              label: s.verifyStatusRejected,
              icon: Icons.error_outline,
              tone: StatusTone.attention,
            ),
          ),
          _ => (
            Icons.verified_user_outlined,
            s.verifyTitle,
            s.verifyBody,
            ShukaansiStatusChip(
              label: s.verifyStatusNotStarted,
              icon: Icons.radio_button_unchecked,
            ),
          ),
        };
        final canStart = verification.status != VerificationStatus.pending;
        final enabled = controller.hasPhoto && !controller.busy;
        return SectionCard(
          tinted: true,
          padding: const EdgeInsets.all(AppSpacing.l + AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShukaansiIconBadge(icon: icon, size: 52),
                  const SizedBox(width: AppSpacing.l),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        chip,
                      ],
                    ),
                  ),
                ],
              ),
              if (verification.reviewNote != null) ...[
                const SizedBox(height: AppSpacing.m),
                Text(
                  s.verifyReviewNote(verification.reviewNote!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
              if (canStart) ...[
                const SizedBox(height: AppSpacing.l),
                Pressable(
                  enabled: enabled,
                  child: OutlinedButton(
                    onPressed: enabled ? onStart : null,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            verification.status == VerificationStatus.rejected
                                ? s.retry
                                : s.verifyStart,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const ExcludeSemantics(
                          child: Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!controller.hasPhoto) ...[
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    s.verifyNeedsPhoto,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
