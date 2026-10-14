import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../application/discovery_controller.dart';
import '../application/media_controller.dart';
import '../l10n/generated/app_localizations.dart';
import '../models/discovery.dart';
import '../theme/tokens.dart';
import '../theme/app_theme.dart';

/// Where a profile's photos come from. Other members' photos go through the
/// Discover controller, which only ever loads what this viewer may see; your
/// own come from your photo controller.
abstract interface class MemberPhotos {
  Listenable get changes;
  List<String> get ids;

  /// False while a sister's photos are blurred for this viewer.
  bool get showsOriginals;
  Uint8List? bytes(String id);
  bool failed(String id);
  void ensure(String id);
  void retry(String id);
}

class DiscoveryPhotos implements MemberPhotos {
  DiscoveryPhotos(this.controller, this.card);
  final DiscoveryController controller;
  final ProfileCard card;

  String _key(String id) =>
      DiscoveryController.imageKey(card, id, !controller.showsOriginals(card));

  @override
  Listenable get changes => controller;
  @override
  List<String> get ids => card.photoIds;
  @override
  bool get showsOriginals => controller.showsOriginals(card);
  @override
  Uint8List? bytes(String id) => controller.images[_key(id)];
  @override
  bool failed(String id) => controller.imageFailed.contains(_key(id));
  @override
  void ensure(String id) {
    controller.ensureAccess(card);
    controller.ensureImage(card, id);
  }

  @override
  void retry(String id) => controller.retryImage(card, id);
}

class OwnPhotos implements MemberPhotos {
  OwnPhotos(this.media);
  final MediaController media;
  @override
  Listenable get changes => media;
  @override
  List<String> get ids => media.photoIds;
  @override
  bool get showsOriginals => true;
  @override
  Uint8List? bytes(String id) => media.images[id];
  @override
  bool failed(String id) => media.imageFailed.contains(id);
  @override
  void ensure(String id) {}
  @override
  void retry(String id) => media.retryImage(id);
}

/// A photo in the standard portrait frame. Faces are never covered: no text
/// or buttons sit on top. The image fills the frame without stretching;
/// slightly top-weighted because faces sit in the upper part of portraits
/// (the model stores no focal point yet).
class PortraitPhoto extends StatelessWidget {
  const PortraitPhoto({
    super.key,
    required this.photos,
    required this.id,
    required this.semanticLabel,
    this.onOpen,
    this.aspectRatio = AppSizes.portrait,
    this.radius = AppRadius.card,
  });
  final MemberPhotos photos;
  final String id;
  final String semanticLabel;

  /// Opens the full photo; null when it may not be opened (private photos).
  final VoidCallback? onOpen;

  /// Width / height of the frame; 4:5 portrait unless a short screen needs
  /// a little more of what follows to show.
  final double aspectRatio;

  /// Corner radius; the lead photo of a profile card uses [AppRadius.hero].
  final double radius;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: photos.changes,
      builder: (context, _) {
        photos.ensure(id);
        final bytes = photos.bytes(id);
        final failed = photos.failed(id);
        Widget child;
        if (bytes != null && bytes.isNotEmpty) {
          child = Image.memory(
            bytes,
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.25),
            gaplessPlayback: true,
          );
          if (!photos.showsOriginals) {
            child = ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: child,
            );
          }
        } else if (failed) {
          child = Center(
            child: TextButton.icon(
              onPressed: () => photos.retry(id),
              icon: const Icon(Icons.refresh),
              label: Text(s.retry),
            ),
          );
        } else {
          child = const Center(
            child: SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }
        final open = onOpen != null && bytes != null && photos.showsOriginals;
        // One node for screen readers: the label and the tap together.
        return MergeSemantics(
          child: Semantics(
            image: true,
            button: open,
            label: semanticLabel,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Material(
                  color: colors.surfaceContainerHighest,
                  child: InkWell(
                    onTap: open ? onOpen : null,
                    child: SizedBox.expand(child: child),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen photos: the whole original image (no cropping), pinch to
/// zoom, swipe between photos, a clear close button. Only photos this viewer
/// may see are ever passed in.
class FullPhotoViewer extends StatefulWidget {
  const FullPhotoViewer({
    super.key,
    required this.photos,
    required this.initial,
    required this.name,
  });
  final MemberPhotos photos;
  final int initial;
  final String name;

  static Future<void> open(
    BuildContext context,
    MemberPhotos photos,
    int initial,
    String name,
  ) => Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) =>
          FullPhotoViewer(photos: photos, initial: initial, name: name),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );

  @override
  State<FullPhotoViewer> createState() => _FullPhotoViewerState();
}

class _FullPhotoViewerState extends State<FullPhotoViewer> {
  late int _page = widget.initial;
  late final _pages = PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final ids = widget.photos.ids;
    return Scaffold(
      backgroundColor: AppColors.photoViewer,
      body: SafeArea(
        child: Stack(
          children: [
            ListenableBuilder(
              listenable: widget.photos.changes,
              builder: (context, _) => PageView.builder(
                controller: _pages,
                itemCount: ids.length,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, index) {
                  final id = ids[index];
                  widget.photos.ensure(id);
                  final bytes = widget.photos.bytes(id);
                  return Semantics(
                    image: true,
                    label:
                        '${widget.name}, ${s.photoOf(index + 1, ids.length)}',
                    child: bytes == null
                        ? Center(
                            child: widget.photos.failed(id)
                                ? Text(
                                    s.photoLoadFailed,
                                    style: const TextStyle(
                                      color: AppColors.onPhoto,
                                    ),
                                  )
                                : const CircularProgressIndicator(),
                          )
                        : InteractiveViewer(
                            minScale: 1,
                            maxScale: 4,
                            child: Center(
                              child: Image.memory(
                                bytes,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.s,
              start: AppSpacing.s,
              child: IconButton.filledTonal(
                tooltip: s.closePhoto,
                onPressed: () => Navigator.of(context).maybePop(),
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(AppSizes.touch),
                ),
                icon: const Icon(Icons.close),
              ),
            ),
            if (ids.length > 1)
              Positioned(
                top: AppSpacing.l,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.photoScrim.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(AppRadius.feature),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.xs,
                        ),
                        child: Text(
                          s.photoOf(_page + 1, ids.length),
                          style: const TextStyle(color: AppColors.onPhoto),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
