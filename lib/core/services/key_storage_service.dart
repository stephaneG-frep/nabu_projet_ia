import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores AI provider API keys in the platform secure storage
/// (Android Keystore-backed encrypted preferences, iOS Keychain).
class KeyStorageService {
  static const providers = ['openai', 'gemini', 'mistral', 'claude'];
  static const _prefix = 'ai_key_';

  final FlutterSecureStorage _storage;

  KeyStorageService([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  Future<Map<String, String>> load() async {
    final keys = <String, String>{};
    for (final p in providers) {
      final v = await _storage.read(key: '$_prefix$p');
      if (v != null && v.isNotEmpty) keys[p] = v;
    }
    return keys;
  }

  Future<void> save(Map<String, String> keys) async {
    for (final p in providers) {
      final v = keys[p] ?? '';
      if (v.isEmpty) {
        await _storage.delete(key: '$_prefix$p');
      } else {
        await _storage.write(key: '$_prefix$p', value: v);
      }
    }
  }
}
