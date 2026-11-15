import 'dart:async';

import 'package:flutter/services.dart';

import '../../application/ports/share_intent.dart';

/// [ShareIntentSource] adapter: Android ACTION_SEND via a method channel.
class MethodChannelShareIntentSource implements ShareIntentSource {
  MethodChannelShareIntentSource() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'sharedText' && call.arguments is String) {
        _controller.add(call.arguments as String);
      }
    });
  }

  static const _channel = MethodChannel('mirai_cook/share');
  final _controller = StreamController<String>.broadcast();

  @override
  Future<String?> takeInitialText() async {
    try {
      return await _channel.invokeMethod<String>('takeInitialText');
    } on MissingPluginException {
      return null; // Not on Android.
    }
  }

  @override
  Stream<String> get sharedTexts => _controller.stream;
}
