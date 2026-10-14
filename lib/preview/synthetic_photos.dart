import 'dart:typed_data';

/// Clearly synthetic sample portraits for the development preview: a soft
/// arch, a faceless head-and-shoulders silhouette, a head covering for
/// sisters. Drawn and PNG-encoded in pure Dart (deterministic, no assets, no
/// real people's photographs).
class PortraitSpec {
  const PortraitSpec({
    required this.background,
    required this.arch,
    required this.cloth,
    required this.skin,
    this.covered = false,
    this.width = 360,
    this.height = 450,
  });
  final int background;
  final int arch;
  final int cloth;
  final int skin;

  /// Head covering (hijab silhouette).
  final bool covered;
  final int width;
  final int height;
}

final _cache = <PortraitSpec, Uint8List>{};

Uint8List syntheticPortrait(PortraitSpec spec) =>
    _cache.putIfAbsent(spec, () => _encodePng(spec));

int _colourAt(PortraitSpec s, double x, double y) {
  final w = s.width.toDouble();
  final h = s.height.toDouble();
  bool inEllipse(double cx, double cy, double rx, double ry) {
    final dx = (x - cx) / rx;
    final dy = (y - cy) / ry;
    return dx * dx + dy * dy <= 1;
  }

  // Shoulders, then head (covering first, face inside it).
  if (inEllipse(w / 2, h * 1.04, w * 0.44, h * 0.30)) return s.cloth;
  if (s.covered) {
    if (inEllipse(w / 2, h * 0.47, w * 0.115, h * 0.125)) return s.skin;
    if (inEllipse(w / 2, h * 0.50, w * 0.21, h * 0.21)) return s.cloth;
  } else {
    if (inEllipse(w / 2, h * 0.66, w * 0.07, h * 0.08)) return s.skin;
    if (inEllipse(w / 2, h * 0.46, w * 0.15, h * 0.15)) return s.skin;
  }
  // The arch behind: a column with a rounded top.
  final archLeft = w * 0.16;
  final archRight = w * 0.84;
  final radius = (archRight - archLeft) / 2;
  final archTop = h * 0.10;
  if (x >= archLeft && x <= archRight) {
    if (y >= archTop + radius) return s.arch;
    if (inEllipse(w / 2, archTop + radius, radius, radius)) return s.arch;
  }
  return s.background;
}

/// 2x2 supersampling softens the edges.
List<int> _pixel(PortraitSpec s, int px, int py) {
  var r = 0, g = 0, b = 0;
  for (final ox in const [0.25, 0.75]) {
    for (final oy in const [0.25, 0.75]) {
      final c = _colourAt(s, px + ox, py + oy);
      r += (c >> 16) & 0xFF;
      g += (c >> 8) & 0xFF;
      b += c & 0xFF;
    }
  }
  return [r ~/ 4, g ~/ 4, b ~/ 4];
}

Uint8List _encodePng(PortraitSpec s) {
  final rowBytes = s.width * 3 + 1;
  final raw = Uint8List(rowBytes * s.height);
  var i = 0;
  for (var y = 0; y < s.height; y++) {
    raw[i++] = 0; // filter: none
    for (var x = 0; x < s.width; x++) {
      final p = _pixel(s, x, y);
      raw[i++] = p[0];
      raw[i++] = p[1];
      raw[i++] = p[2];
    }
  }
  final out = BytesBuilder();
  out.add(const [137, 80, 78, 71, 13, 10, 26, 10]);
  final header = ByteData(13)
    ..setUint32(0, s.width)
    ..setUint32(4, s.height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // colour type: RGB
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  _chunk(out, 'IHDR', header.buffer.asUint8List());
  _chunk(out, 'IDAT', _zlibStored(raw));
  _chunk(out, 'IEND', Uint8List(0));
  return out.toBytes();
}

/// zlib stream with uncompressed ("stored") deflate blocks: valid PNG data
/// without needing a compressor (works on every platform, including web).
Uint8List _zlibStored(Uint8List data) {
  final out = BytesBuilder()..add(const [0x78, 0x01]);
  const max = 65535;
  for (var offset = 0; offset < data.length; offset += max) {
    final end = (offset + max).clamp(0, data.length);
    final len = end - offset;
    final last = end == data.length;
    out
      ..addByte(last ? 1 : 0)
      ..addByte(len & 0xFF)
      ..addByte((len >> 8) & 0xFF)
      ..addByte(~len & 0xFF)
      ..addByte((~len >> 8) & 0xFF)
      ..add(Uint8List.sublistView(data, offset, end));
  }
  var a = 1, b = 0;
  for (final byte in data) {
    a = (a + byte) % 65521;
    b = (b + a) % 65521;
  }
  final adler = (b << 16) | a;
  out.add([
    (adler >> 24) & 0xFF,
    (adler >> 16) & 0xFF,
    (adler >> 8) & 0xFF,
    adler & 0xFF,
  ]);
  return out.toBytes();
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

void _chunk(BytesBuilder out, String type, Uint8List data) {
  final typeBytes = Uint8List.fromList(type.codeUnits);
  final length = ByteData(4)..setUint32(0, data.length);
  out
    ..add(length.buffer.asUint8List())
    ..add(typeBytes)
    ..add(data);
  var crc = 0xFFFFFFFF;
  for (final byte in [...typeBytes, ...data]) {
    crc = _crcTable[(crc ^ byte) & 0xFF] ^ (crc >> 8);
  }
  crc ^= 0xFFFFFFFF;
  out.add((ByteData(4)..setUint32(0, crc)).buffer.asUint8List());
}
