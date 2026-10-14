import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen, zoomable view of one of the owner's photos.
class PhotoViewer extends StatelessWidget {
  const PhotoViewer({super.key, required this.heroTag, required this.bytes});
  final String heroTag;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.photoViewer,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.onPhoto,
      leading: const CloseButton(),
    ),
    extendBodyBehindAppBar: true,
    body: Center(
      child: InteractiveViewer(
        maxScale: 4,
        child: Hero(tag: heroTag, child: Image.memory(bytes)),
      ),
    ),
  );
}
