import 'dart:math';

import '../state/session_store.dart';
import 'api_client.dart';
import 'models.dart';

/// Lietotnes galapunkti (K3 API līgums). Ekrāni zina tikai šo saskarni.
abstract class KopsummaApi {
  Future<void> login(String email, String password);
  Future<void> register(String email, String password);

  /// Atjauno sesiju no saglabātā marķiera; false — jāpiesakās.
  Future<bool> restoreSession();
  Future<void> logout();
  Future<String> currentEmail();

  String get serverUrl;
  set serverUrl(String url);

  Future<Portfolio> portfolio();
  Future<List<Tx>> transactions({String? platform});
  Future<Tx> transaction(String id);
  Future<TaxSummary> tax(String period);
  Future<Deadlines> deadlines();

  Future<List<PlatformInfo>> platforms();
  Future<ImportPreview> uploadStatement({required int platformId, required String fileName, required List<int> bytes});
  Future<ImportResult> confirmImport(String importId);
  Future<void> cancelImport(String importId);
  Future<List<ImportRecord>> imports();
}

class HttpKopsummaApi implements KopsummaApi {
  HttpKopsummaApi(this.client, {SessionStore? store}) : store = store ?? MemorySessionStore() {
    client.onAuthExpired = _refresh;
  }

  final ApiClient client;
  final SessionStore store;
  String? _refreshToken;
  Future<bool>? _refreshing;
  final _confirmKeys = <String, String>{};

  @override
  String get serverUrl => client.baseUrl;

  @override
  set serverUrl(String url) => client.baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');

  Future<void> _accept(Map<String, dynamic> body) async {
    client.accessToken = body['access_token'] as String;
    _refreshToken = body['refresh_token'] as String?;
    if (_refreshToken != null) await store.write(_refreshToken!);
  }

  @override
  Future<void> login(String email, String password) async {
    await _accept(await client.post('/api/v1/auth/login', {'epasts': email, 'parole': password}));
  }

  @override
  Future<void> register(String email, String password) async {
    await client.post('/api/v1/auth/register', {'epasts': email, 'parole': password});
    await login(email, password);
  }

  /// Viena atjaunošana vienlaicīgi, pat ja vairāki pieprasījumi saņem 401.
  Future<bool> _refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final token = _refreshToken ?? await store.read();
    if (token == null) return false;
    try {
      await _accept(await client.post('/api/v1/auth/refresh', {'refresh_token': token}, retryAuth: false));
      return true;
    } on ApiException catch (e) {
      if (!e.isNetwork) {
        await store.clear();
        _refreshToken = null;
        client.accessToken = null;
      }
      return false;
    }
  }

  @override
  Future<bool> restoreSession() => _refresh();

  @override
  Future<void> logout() async {
    final token = _refreshToken ?? await store.read();
    client.accessToken = null;
    _refreshToken = null;
    await store.clear();
    if (token != null) {
      try {
        await client.post('/api/v1/auth/logout', {'refresh_token': token}, retryAuth: false);
      } on ApiException {
        // marķieris jau izdzēsts ierīcē; servera kļūda iziešanu neaptur
      }
    }
  }

  @override
  Future<String> currentEmail() async => (await client.get('/api/v1/auth/me'))['epasts'] as String;

  @override
  Future<Portfolio> portfolio() async => Portfolio.fromJson(await client.get('/api/v1/portfolio'));

  @override
  Future<List<Tx>> transactions({String? platform}) async {
    final body = await client.get('/api/v1/transactions', query: platform == null ? null : {'platforma': platform});
    return (body['items'] as List<dynamic>).map((t) => Tx.fromJson(t as Map<String, dynamic>)).toList();
  }

  @override
  Future<Tx> transaction(String id) async => Tx.fromJson(await client.get('/api/v1/transactions/$id'));

  @override
  Future<TaxSummary> tax(String period) async =>
      TaxSummary.fromJson(await client.get('/api/v1/tax', query: {'period': period}));

  @override
  Future<Deadlines> deadlines() async => Deadlines.fromJson(await client.get('/api/v1/deadlines'));

  @override
  Future<List<PlatformInfo>> platforms() async {
    final body = await client.get('/api/v1/platforms');
    return (body['items'] as List<dynamic>).map((p) => PlatformInfo.fromJson(p as Map<String, dynamic>)).toList();
  }

  @override
  Future<ImportPreview> uploadStatement(
      {required int platformId, required String fileName, required List<int> bytes}) async {
    final body = await client.upload('/api/v1/imports',
        fields: {'platformas_id': '$platformId'}, fileField: 'fails', fileName: fileName, bytes: bytes);
    return ImportPreview.fromJson(body, fileName: fileName);
  }

  @override
  Future<ImportResult> confirmImport(String importId) async {
    // Viena atslēga katram apstiprinājumam: atkārtots pieprasījums (piem., pēc taimauta) nedublē datus.
    final key = _confirmKeys[importId] ??=
        'k-$importId-${Random.secure().nextInt(0x3fffffff).toRadixString(16)}';
    return ImportResult.fromJson(
        await client.post('/api/v1/imports/$importId/confirm', const {}, headers: {'Idempotency-Key': key}));
  }

  @override
  Future<void> cancelImport(String importId) async {
    await client.post('/api/v1/imports/$importId/cancel', const {});
  }

  @override
  Future<List<ImportRecord>> imports() async {
    final body = await client.get('/api/v1/imports');
    return (body['items'] as List<dynamic>).map((i) => ImportRecord.fromJson(i as Map<String, dynamic>)).toList();
  }
}
