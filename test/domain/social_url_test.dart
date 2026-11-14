import 'package:flutter_test/flutter_test.dart';
import 'package:mirai_cook/domain/social_url.dart';

void main() {
  // Covers: AI-1, AI-14
  group('classifySocialUrl: YouTube', () {
    const canonical = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    for (final url in [
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://youtube.com/watch?v=dQw4w9WgXcQ&t=42s',
      'https://m.youtube.com/watch?feature=share&v=dQw4w9WgXcQ',
      'https://www.youtube.com/shorts/dQw4w9WgXcQ',
      'https://youtube.com/shorts/dQw4w9WgXcQ?si=abc123',
      'https://youtu.be/dQw4w9WgXcQ',
      'https://youtu.be/dQw4w9WgXcQ?si=tracking',
      'http://WWW.YOUTUBE.COM/watch?v=dQw4w9WgXcQ',
    ]) {
      test(url, () {
        final source = classifySocialUrl(Uri.parse(url));
        expect(source, isA<YouTubeVideo>());
        source as YouTubeVideo;
        expect(source.videoId, 'dQw4w9WgXcQ');
        expect(source.canonicalUrl.toString(), canonical);
      });
    }
  });

  // Covers: AI-1, AI-14
  group('classifySocialUrl: Instagram', () {
    for (final (url, kind, canonical) in [
      (
        'https://www.instagram.com/p/C1a2B3c4D5e/',
        InstagramPostKind.post,
        'https://www.instagram.com/p/C1a2B3c4D5e/',
      ),
      (
        'https://instagram.com/p/C1a2B3c4D5e?igsh=xyz',
        InstagramPostKind.post,
        'https://www.instagram.com/p/C1a2B3c4D5e/',
      ),
      (
        'https://www.instagram.com/reel/C1a2B3c4D5e/?utm_source=ig_web',
        InstagramPostKind.reel,
        'https://www.instagram.com/reel/C1a2B3c4D5e/',
      ),
      (
        'https://www.instagram.com/reels/C1a2B3c4D5e/',
        InstagramPostKind.reel,
        'https://www.instagram.com/reel/C1a2B3c4D5e/',
      ),
      (
        'https://m.instagram.com/someuser/reel/C1a2B3c4D5e/',
        InstagramPostKind.reel,
        'https://www.instagram.com/reel/C1a2B3c4D5e/',
      ),
    ]) {
      test(url, () {
        final source = classifySocialUrl(Uri.parse(url));
        expect(source, isA<InstagramPost>());
        source as InstagramPost;
        expect(source.shortcode, 'C1a2B3c4D5e');
        expect(source.kind, kind);
        expect(source.canonicalUrl.toString(), canonical);
      });
    }
  });

  // Covers: AI-1
  group('classifySocialUrl: not a video or post', () {
    for (final url in [
      'https://www.giallozafferano.it/ricetta/carbonara',
      'https://www.youtube.com/',
      'https://www.youtube.com/@canale',
      'https://www.youtube.com/watch',
      'https://www.youtube.com/watch?v=short',
      'https://youtu.be/',
      'https://www.instagram.com/',
      'https://www.instagram.com/someuser/',
      'https://www.instagram.com/p/',
      'https://notyoutube.com/watch?v=dQw4w9WgXcQ',
      'https://youtube.com.evil.example/watch?v=dQw4w9WgXcQ',
    ]) {
      test(url, () {
        expect(classifySocialUrl(Uri.parse(url)), isNull);
      });
    }
  });

  // Covers: AI-10
  test('YouTube thumbnail URL', () {
    const video = YouTubeVideo('dQw4w9WgXcQ');
    expect(
      video.thumbnailUrl.toString(),
      'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
    );
  });
}
