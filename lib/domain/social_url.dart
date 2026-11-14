/// Video and social post URLs handled by the AI import (AI-1). Pure Dart.
sealed class SocialSource {
  const SocialSource();

  /// The same URL for every shared form, used as the recipe's source URL and
  /// for the duplicate check (AI-14).
  Uri get canonicalUrl;
}

class YouTubeVideo extends SocialSource {
  const YouTubeVideo(this.videoId);

  final String videoId;

  @override
  Uri get canonicalUrl =>
      Uri.https('www.youtube.com', '/watch', {'v': videoId});

  /// Always available for public videos (AI-10).
  Uri get thumbnailUrl =>
      Uri.https('i.ytimg.com', '/vi/$videoId/hqdefault.jpg');

  @override
  bool operator ==(Object other) =>
      other is YouTubeVideo && other.videoId == videoId;

  @override
  int get hashCode => videoId.hashCode;

  @override
  String toString() => 'YouTubeVideo($videoId)';
}

enum InstagramPostKind { post, reel }

class InstagramPost extends SocialSource {
  const InstagramPost(this.kind, this.shortcode);

  final InstagramPostKind kind;
  final String shortcode;

  @override
  Uri get canonicalUrl => Uri.https(
    'www.instagram.com',
    '/${kind == InstagramPostKind.reel ? 'reel' : 'p'}/$shortcode/',
  );

  @override
  bool operator ==(Object other) =>
      other is InstagramPost &&
      other.kind == kind &&
      other.shortcode == shortcode;

  @override
  int get hashCode => Object.hash(kind, shortcode);

  @override
  String toString() => 'InstagramPost(${kind.name}, $shortcode)';
}

final _youTubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');
final _instagramCode = RegExp(r'^[A-Za-z0-9_-]+$');

const _youTubeHosts = {'youtube.com', 'www.youtube.com', 'm.youtube.com'};
const _instagramHosts = {
  'instagram.com',
  'www.instagram.com',
  'm.instagram.com',
};

/// Recognises YouTube videos and Instagram posts or reels, ignoring tracking
/// parameters (AI-1). Returns null for any other URL.
SocialSource? classifySocialUrl(Uri url) {
  if (url.scheme != 'http' && url.scheme != 'https') return null;
  final host = url.host.toLowerCase();
  final segments = url.pathSegments.where((s) => s.isNotEmpty).toList();

  String? videoId;
  if (host == 'youtu.be') {
    videoId = segments.firstOrNull;
  } else if (_youTubeHosts.contains(host)) {
    if (segments.length == 1 && segments[0] == 'watch') {
      videoId = url.queryParameters['v'];
    } else if (segments.length == 2 && segments[0] == 'shorts') {
      videoId = segments[1];
    }
  }
  if (videoId != null) {
    return _youTubeId.hasMatch(videoId) ? YouTubeVideo(videoId) : null;
  }

  if (_instagramHosts.contains(host)) {
    // `/p/<code>`, `/reel/<code>`, `/reels/<code>`, optionally after a
    // username segment.
    for (var i = 0; i + 1 < segments.length && i < 2; i++) {
      final kind = switch (segments[i]) {
        'p' => InstagramPostKind.post,
        'reel' || 'reels' => InstagramPostKind.reel,
        _ => null,
      };
      final code = segments[i + 1];
      if (kind != null && _instagramCode.hasMatch(code)) {
        return InstagramPost(kind, code);
      }
    }
  }
  return null;
}
