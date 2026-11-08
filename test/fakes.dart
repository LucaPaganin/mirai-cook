import 'dart:async';

import 'package:mirai_cook/data/http_client.dart';
import 'package:mirai_cook/data/share_intent.dart';
import 'package:mirai_cook/data/thumbnailer.dart';
import 'package:mirai_cook/domain/clock.dart';

class FixedClock implements Clock {
  FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}

class FakeHttpClient implements HttpClient {
  FakeHttpClient([Map<String, HttpResponse>? responses])
    : responses = responses ?? {};

  final Map<String, HttpResponse> responses;
  final requested = <Uri>[];
  Object? throwOnGet;

  @override
  Future<HttpResponse> get(Uri url) async {
    requested.add(url);
    if (throwOnGet != null) throw throwOnGet!;
    return responses[url.toString()] ?? const HttpResponse(404, []);
  }
}

class FakeThumbnailer implements Thumbnailer {
  final inputs = <List<int>>[];

  @override
  Future<List<int>?> makeThumbnail(
    List<int> bytes, {
    int maxBytes = 50 * 1024,
  }) async {
    inputs.add(bytes);
    return [9, 9, 9];
  }
}

class FakeShareIntentSource implements ShareIntentSource {
  String? initialText;
  final controller = StreamController<String>.broadcast();

  @override
  Future<String?> takeInitialText() async {
    final t = initialText;
    initialText = null;
    return t;
  }

  @override
  Stream<String> get sharedTexts => controller.stream;
}
