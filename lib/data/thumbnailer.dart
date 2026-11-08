import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

abstract interface class Thumbnailer {
  /// Returns a compressed JPEG of at most [maxBytes], or null if the image
  /// cannot be decoded (IMP-7).
  Future<List<int>?> makeThumbnail(List<int> bytes, {int maxBytes = 50 * 1024});
}

class ImageThumbnailer implements Thumbnailer {
  const ImageThumbnailer({this.runInIsolate = true});

  final bool runInIsolate;

  @override
  Future<List<int>?> makeThumbnail(
    List<int> bytes, {
    int maxBytes = 50 * 1024,
  }) {
    final input = Uint8List.fromList(bytes);
    return runInIsolate
        ? Isolate.run(() => compress(input, maxBytes))
        : Future.value(compress(input, maxBytes));
  }

  static List<int>? compress(Uint8List bytes, int maxBytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    var side = 480;
    while (side >= 64) {
      final resized = decoded.width >= decoded.height
          ? img.copyResize(
              decoded,
              width: decoded.width > side ? side : decoded.width,
            )
          : img.copyResize(
              decoded,
              height: decoded.height > side ? side : decoded.height,
            );
      for (var quality = 80; quality >= 40; quality -= 10) {
        final jpg = img.encodeJpg(resized, quality: quality);
        if (jpg.length <= maxBytes) return jpg;
      }
      side = (side * 0.75).round();
    }
    return null;
  }
}
