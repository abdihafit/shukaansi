import 'dart:typed_data';
import 'dart:ui' as ui;

/// A 24-pixel-wide PNG of [bytes]. Viewers who may not see a photo receive only
/// this copy, which the app enlarges and blurs; the original never leaves the
/// owner's account.
Future<Uint8List> blurThumbnail(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes, targetWidth: 24);
  try {
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    if (data == null) throw StateError('Could not encode thumbnail');
    return data.buffer.asUint8List();
  } finally {
    codec.dispose();
  }
}
