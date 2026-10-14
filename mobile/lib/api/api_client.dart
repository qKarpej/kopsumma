import 'dart:convert';

import 'package:http/http.dart' as http;

/// Kļūda vienotajā formātā (K3, 3.1).
class ApiException implements Exception {
  ApiException(this.status, this.code, this.message, {this.field});

  final int status;
  final String code;
  final String message;
  final String? field;

  @override
  String toString() => 'ApiException($status, $code)';
}

class LoginResult {
  const LoginResult(this.accessToken, this.refreshToken);

  final String accessToken;
  final String refreshToken;
}

abstract class AuthApi {
  Future<LoginResult> login(String email, String password);
}

class HttpAuthApi implements AuthApi {
  HttpAuthApi({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<LoginResult> login(String email, String password) async {
    final http.Response res;
    try {
      res = await _client.post(
        Uri.parse('$baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'epasts': email, 'parole': password}),
      );
    } catch (_) {
      throw ApiException(0, 'NETWORK', 'Nav savienojuma ar serveri. Pārbaudiet internetu.');
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return LoginResult(body['access_token'] as String, body['refresh_token'] as String);
    }
    final err = (body['error'] ?? const <String, dynamic>{}) as Map<String, dynamic>;
    throw ApiException(
      res.statusCode,
      (err['code'] ?? 'UNKNOWN') as String,
      (err['message'] ?? 'Neizdevās pieteikties.') as String,
      field: err['field'] as String?,
    );
  }
}
