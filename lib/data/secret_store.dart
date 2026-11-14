/// Platform secure storage (Android Keystore), behind an interface so tests
/// never touch the device keystore. Values stored here are not part of the
/// database and therefore never end up in backups (AI-11).
abstract interface class SecretStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}

abstract final class SecretKeys {
  /// Gemini API key from Google AI Studio (AI-11).
  static const aiApiKey = 'ai_api_key';
}
