import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kopsumma/api/api_client.dart';
import 'package:kopsumma/api/kopsumma_api.dart';

void main() {
  test('bāzes adrese un galvenes vienā vietā; marķieris pēc pieteikšanās', () async {
    final seen = <http.Request>[];
    final mock = MockClient((req) async {
      seen.add(req);
      if (req.url.path == '/api/v1/auth/login') {
        return http.Response(jsonEncode({'access_token': 'abc'}), 200);
      }
      return http.Response(
        jsonEncode({'valuta': 'EUR', 'kopsumma_centos': 100, 'ienakumi_ceturksni_centos': 0,
            'platformas': [], 'nodoklis': null}),
        200,
      );
    });
    final api = HttpKopsummaApi(ApiClient(baseUrl: 'http://srv:9', httpClient: mock));
    await api.login('a@b.lv', 'x');
    final p = await api.portfolio();
    expect(p.totalCents, 100);
    expect(seen.last.url.toString(), 'http://srv:9/api/v1/portfolio');
    expect(seen.last.headers['Authorization'], 'Bearer abc');
    expect(seen.first.headers.containsKey('Authorization'), isFalse);
  });

  test('servera kļūda pārvēršas vienā ApiException tipā', () async {
    final mock = MockClient((_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'error': {'code': 'X', 'message': 'Ziņa', 'field': 'f', 'request_id': 'r1'}})),
          422,
        ));
    final client = ApiClient(baseUrl: 'http://srv', httpClient: mock);
    await expectLater(
      client.get('/a'),
      throwsA(isA<ApiException>()
          .having((e) => e.status, 'status', 422)
          .having((e) => e.code, 'code', 'X')
          .having((e) => e.message, 'message', 'Ziņa')
          .having((e) => e.requestId, 'requestId', 'r1')),
    );
  });

  test('tīkla kļūda → status 0', () async {
    final mock = MockClient((_) async => throw http.ClientException('down'));
    final client = ApiClient(baseUrl: 'http://srv', httpClient: mock);
    await expectLater(client.get('/a'), throwsA(isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', true)));
  });
}
