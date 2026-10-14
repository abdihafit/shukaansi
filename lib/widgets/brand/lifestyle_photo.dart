import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/motion.dart';

/// A decorative lifestyle photo from assets/images/lifestyle. These are
/// generated, promotional images: never show them as members, matches,
/// testimonials or success stories.
class LifestylePhoto {
  const LifestylePhoto(this.asset, {this.focus = Alignment.center});
  final String asset;

  /// Where `BoxFit.cover` keeps the picture when it crops, so faces stay in
  /// view on wide or short frames.
  final Alignment focus;

  static const _dir = 'assets/images/lifestyle';
  static const loginCouple = LifestylePhoto(
    '$_dir/login_couple.jpg',
    focus: Alignment(0, -0.44),
  );
  static const loginWoman = LifestylePhoto(
    '$_dir/login_woman.jpg',
    focus: Alignment(0, -0.4),
  );
  static const welcomeMan = LifestylePhoto(
    '$_dir/welcome_man.jpg',
    focus: Alignment(0, -0.3),
  );
  static const welcomeWoman = LifestylePhoto(
    '$_dir/welcome_woman.jpg',
    focus: Alignment(0, -0.55),
  );
  static const connectionCouple = LifestylePhoto(
    '$_dir/connection_couple.jpg',
    focus: Alignment(0, -0.3),
  );

  /// The sign-in slideshow.
  static const signIn = [loginCouple, loginWoman];

  AssetImage get image => AssetImage(asset);
}

/// A [LifestylePhoto] filling its box. Hidden from screen readers (it is
/// decorative); a soft brand gradient stands in if it cannot be loaded.
class LifestyleImage extends StatelessWidget {
  const LifestyleImage(this.photo, {super.key});
  final LifestylePhoto photo;

  @override
  Widget build(BuildContext context) => Image(
    image: photo.image,
    fit: BoxFit.cover,
    alignment: photo.focus,
    width: double.infinity,
    height: double.infinity,
    gaplessPlayback: true,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryLight, AppColors.teal],
        ),
      ),
      child: SizedBox.expand(),
    ),
  );
}

/// Darkens the bottom of a photo (transparent to 65% black) so white text,
/// page dots and the logo stay readable on any picture.
class PhotoScrim extends StatelessWidget {
  const PhotoScrim({super.key, this.from = 0.45});

  /// Fraction of the height where the darkening starts.
  final double from;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [from, 1],
          colors: const [Color(0x00000000), Color(0xA6000000)],
        ),
      ),
      child: const SizedBox.expand(),
    ),
  );
}

/// Photos that cross-fade every [interval], with small page dots. Advancing
/// stops while the page is covered, the app is in the background or the
/// device asks for reduced motion (then the first photo simply stays).
class PhotoSlideshow extends StatefulWidget {
  const PhotoSlideshow({
    super.key,
    required this.photos,
    this.interval = const Duration(seconds: 5),
    this.fade = const Duration(milliseconds: 800),
    this.dotsBottom = 16,
    this.dotsAlignment = MainAxisAlignment.center,
  });
  final List<LifestylePhoto> photos;
  final Duration interval;
  final Duration fade;

  /// Distance of the page dots from the bottom edge.
  final double dotsBottom;
  final MainAxisAlignment dotsAlignment;

  /// Lets tests see the advance timer start and stop.
  @visibleForTesting
  static Timer Function(Duration, void Function(Timer)) periodic =
      Timer.periodic;

  @override
  State<PhotoSlideshow> createState() => _PhotoSlideshowState();
}

class _PhotoSlideshowState extends State<PhotoSlideshow>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _index = 0;
  bool _foreground = true;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final photo in widget.photos) {
        // A missing photo falls back in LifestyleImage; nothing to do here.
        precacheImage(photo.image, context, onError: (_, _) {});
      }
    }
    _sync();
  }

  @override
  void didUpdateWidget(PhotoSlideshow old) {
    super.didUpdateWidget(old);
    if (_index >= widget.photos.length) _index = 0;
    if (old.interval != widget.interval) {
      _timer?.cancel();
      _timer = null;
    }
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  bool get _reducedMotion => MediaQuery.disableAnimationsOf(context);

  /// Runs the timer only while it is useful: several photos, visible page,
  /// app in front and motion allowed.
  void _sync() {
    final run =
        widget.photos.length > 1 &&
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !_reducedMotion;
    if (!run) {
      _timer?.cancel();
      _timer = null;
      // Reduced motion shows the first photo; a rebuild follows this call.
      if (_reducedMotion) _index = 0;
    } else {
      _timer ??= PhotoSlideshow.periodic(widget.interval, (_) {
        if (mounted) {
          setState(() => _index = (_index + 1) % widget.photos.length);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.photos.length;
    if (count == 0) return const SizedBox.expand();
    final photo = widget.photos[_index];
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: Motion.of(context, widget.fade),
          layoutBuilder: Motion.expandedSwitcherLayout,
          child: LifestyleImage(photo, key: ValueKey(photo.asset)),
        ),
        const PhotoScrim(),
        if (count > 1)
          Positioned(
            left: 24,
            right: 24,
            bottom: widget.dotsBottom,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: widget.dotsAlignment,
                  children: [
                    for (var i = 0; i < count; i++)
                      AnimatedContainer(
                        duration: Motion.of(context, Motion.enter),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _index ? 18 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppColors.onPhoto
                              : AppColors.onPhoto.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.photoShadow,
                              blurRadius: 4,
                            ),
                          ],
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
