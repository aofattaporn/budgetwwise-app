// One-off helper: trim the white border from the source icon and pad it to a
// true square so flutter_launcher_icons doesn't stretch it. Safe to delete.
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const path = 'assets/icon/icon.png';
  final src = img.decodePng(File(path).readAsBytesSync());
  if (src == null) {
    stderr.writeln('Could not decode $path');
    exit(1);
  }

  // Remove the uniform border using the top-left pixel colour (white).
  final trimmed = img.trim(src, mode: img.TrimMode.topLeftColor);

  final size = trimmed.width > trimmed.height ? trimmed.width : trimmed.height;
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255)); // white bg
  img.compositeImage(
    canvas,
    trimmed,
    dstX: (size - trimmed.width) ~/ 2,
    dstY: (size - trimmed.height) ~/ 2,
  );

  File(path).writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln(
    'Squared $path: ${canvas.width}x${canvas.height} '
    '(trimmed content ${trimmed.width}x${trimmed.height})',
  );
}
