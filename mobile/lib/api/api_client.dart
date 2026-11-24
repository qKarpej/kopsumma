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

  /// 'fails.row[47]' → 47
  int? get row {
    final m = RegExp(r'row\[(\d+)\]').firstMatch(field ?? '');
    return m == null ? null : int.parse(m.group(1)!);
  }

  @override
  String toString() => 'ApiException($status, $code)';
}

/// Viens HTTP klients: bāzes adrese, galvenes un kļūdu pārveide vienuviet.
/// Ja piekļuves marķieris beidzies (401), klients vienreiz izsauc [onAuthExpired] un atkārto pieprasījumu.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient, this.timeout = const Duration(seconds: 15)})
      : _http = httpClient ?? http.Client();

  String baseUrl;
  final Duration timeout;
  final http.Client _http;
  String? accessToken;
  Future<bool> Function()? onAuthExpired;

  Map<String, String> _headers({bool json = true, Map<String, String>? extra}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        ...?extra,
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers()));

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
          {Map<String, String>? headers, bool retryAuth = true}) =>
      _send(() => _http.post(_uri(path), headers: _headers(extra: headers), body: jsonEncode(body)),
          retryAuth: retryAuth);

  /// Faila augšupielāde (multipart/form-data).
  Future<Map<String, dynamic>> upload(String path,
          {required Map<String, String> fields,
          required String fileField,
          required String fileName,
          required List<int> bytes}) =>
      _send(() async {
        final req = http.MultipartRequest('POST', _uri(path))
          ..headers.addAll(_headers(json: false))
          ..fields.addAll(fields)
          ..files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: fileName));
        return http.Response.fromStream(await _http.send(req));
      });

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request, {bool retryAuth = true}) async {
    final res = await _raw(request);
    if (res.statusCode == 401 && retryAuth && onAuthExpired != null && accessToken != null) {
      if (await onAuthExpired!()) return _decode(await _raw(request));
    }
    return _decode(res);
  }

  Future<http.Response> _raw(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(0, 'TIMEOUT', 'Serveris neatbild. Mēģiniet vēlreiz.');
    } catch (_) {
      throw const ApiException(0, 'NETWORK', 'Nav savienojuma ar serveri. Pārbaudiet internetu.');
    }
  }

  Map<String, dynamic> _decode(http.Response res) {
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
