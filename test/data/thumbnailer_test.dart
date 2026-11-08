import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mirai_cook/data/thumbnailer.dart';

void main() {
  // Covers: IMP-7
  test('compresses a large noisy image to at most 50 KB', () async {
    final big = img.Image(width: 2000, height: 1500);
    for (var y = 0; y < big.height; y++) {
      for (var x = 0; x < big.width; x++) {
        big.setPixelRgb(x, y, (x * 7 + y) % 256, (x ^ y) % 256, (x * y) % 256);
      }
    }
    final png = img.encodePng(big);
    expect(png.length, greaterThan(50 * 1024));
    final thumb = await const ImageThumbnailer(runInIsolate: false)
        .makeThumbnail(png);
    expect(thumb, isNotNull);
    expect(thumb!.length, lessThanOrEqualTo(50 * 1024));
    final decoded = img.decodeJpg(Uint8List.fromList(thumb))!;
    expect(decoded.width, lessThanOrEqualTo(480));
  });

  // Covers: IMP-7
  test('returns null for bytes that are not an image', () async {
    expect(
      await const ImageThumbnailer(runInIsolate: false)
          .makeThumbnail([1, 2, 3, 4]),
      isNull,
    );
  });
}
