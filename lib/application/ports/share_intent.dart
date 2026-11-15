/// Text shared to the app from other Android apps (IMP-1).
abstract interface class ShareIntentSource {
  /// Text that launched the app, if any (consumed once).
  Future<String?> takeInitialText();

  /// Text shared while the app is running.
  Stream<String> get sharedTexts;
}
