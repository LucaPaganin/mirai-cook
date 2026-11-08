import 'dart:async';

import 'package:flutter/services.dart';

/// Text shared to the app from other Android apps (IMP-1).
abstract interface class ShareIntentSource {
  /// Text that launched the app, if any (consumed once).
  Future<String?> takeInitialText();

  /// Text shared while the app is running.
  Stream<String> get sharedTexts;
}

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
