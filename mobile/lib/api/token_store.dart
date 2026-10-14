import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Atjaunošanas marķieris glabājas Keychain / Keystore (NFR-06).
/// Piekļuves marķieris tiek turēts tikai atmiņā.
abstract class TokenStore {
  Future<void> saveRefreshToken(String token);
}

class SecureTokenStore implements TokenStore {
  const SecureTokenStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: 'refresh_token', value: token);
}
