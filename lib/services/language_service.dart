import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LanguageService {
  static const _storage = FlutterSecureStorage();
  static const String _languageKey = 'selected_language';
  static const String defaultLanguage = 'en';

  static Future<String> getLanguage() async {
    try {
      final language = await _storage.read(key: _languageKey);
      return language ?? defaultLanguage;
    } catch (e) {
      return defaultLanguage;
    }
  }

  static Future<void> setLanguage(String languageCode) async {
    try {
      await _storage.write(key: _languageKey, value: languageCode);
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> clearLanguage() async {
    try {
      await _storage.delete(key: _languageKey);
    } catch (e) {
      // Handle error silently
    }
  }
}

