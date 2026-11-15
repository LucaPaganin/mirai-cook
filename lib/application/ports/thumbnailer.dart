abstract interface class Thumbnailer {
  /// Returns a compressed JPEG of at most [maxBytes], or null if the image
  /// cannot be decoded (IMP-7).
  Future<List<int>?> makeThumbnail(List<int> bytes, {int maxBytes = 50 * 1024});
}
