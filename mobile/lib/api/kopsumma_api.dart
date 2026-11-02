import 'api_client.dart';
import 'models.dart';

/// Lietotnes galapunkti (K3 API līgums). Ekrāni zina tikai šo saskarni.
abstract class KopsummaApi {
  Future<void> login(String email, String password);
  void logout();
  Future<Portfolio> portfolio();
  Future<List<Tx>> transactions({String? platform});
  Future<Tx> transaction(String id);
  Future<TaxSummary> tax(String period);
}

class HttpKopsummaApi implements KopsummaApi {
  HttpKopsummaApi(this.client);

  final ApiClient client;

  @override
  Future<void> login(String email, String password) async {
    final body = await client.post('/api/v1/auth/login', {'epasts': email, 'parole': password});
    client.accessToken = body['access_token'] as String;
  }

  @override
  void logout() => client.accessToken = null;

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
}
