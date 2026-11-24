import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Atjaunošanas marķiera glabāšana, lai pēc lietotnes restartēšanas nav jāpiesakās vēlreiz.
abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String refreshToken);
  Future<void> clear();
}

/// Android Keystore / iOS Keychain (web — šifrēts localStorage).
class SecureSessionStore implements SessionStore {
  SecureSessionStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'kopsumma.refresh_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null; // bojāta krātuve → vienkārši jāpiesakās vēlreiz
    }
  }

  @override
  Future<void> write(String refreshToken) => _storage.write(key: _key, value: refreshToken);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

class MemorySessionStore implements SessionStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String refreshToken) async => token = refreshToken;

  @override
  Future<void> clear() async => token = null;
}
