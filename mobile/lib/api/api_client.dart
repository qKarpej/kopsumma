import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Vienīgais kļūdu tips visai lietotnei (K3, 3.1).
class ApiException implements Exception {
  const ApiException(this.status, this.code, this.message, {this.field, this.requestId});

  /// 0 — nav atbildes no servera (tīkls, taimauts).
  final int status;
  final String code;
  final String message;
  final String? field;
  final String? requestId;

  bool get isNetwork => status == 0;

  @override
  String toString() => 'ApiException($status, $code)';
}

/// Viens HTTP klients: bāzes adrese, galvenes un kļūdu pārveide vienuviet.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient, this.timeout = const Duration(seconds: 10)})
      : _http = httpClient ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final http.Client _http;
  String? accessToken;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers));

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _send(() => _http.post(_uri(path), headers: _headers, body: jsonEncode(body)));

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    final http.Response res;
    try {
      res = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(0, 'TIMEOUT', 'Serveris neatbild. Mēģiniet vēlreiz.');
    } catch (_) {
      throw const ApiException(0, 'NETWORK', 'Nav savienojuma ar serveri. Pārbaudiet internetu.');
    }
    Map<String, dynamic> body;
    try {
      body = res.bodyBytes.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(res.statusCode, 'BAD_RESPONSE', 'Serveris atbildēja nesaprotami.');
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final err = (body['error'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    throw ApiException(
      res.statusCode,
      (err['code'] as String?) ?? 'HTTP_${res.statusCode}',
      (err['message'] as String?) ?? 'Radās kļūda. Mēģiniet vēlreiz.',
      field: err['field'] as String?,
      requestId: err['request_id'] as String?,
    );
  }
}
