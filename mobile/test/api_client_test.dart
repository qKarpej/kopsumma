import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kopsumma/api/api_client.dart';
import 'package:kopsumma/api/kopsumma_api.dart';
import 'package:kopsumma/state/session_store.dart';

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

  test('beidzies marķieris: viena atjaunošana un pieprasījuma atkārtojums; jaunais marķieris saglabāts', () async {
    var refreshes = 0;
    final mock = MockClient((req) async {
      if (req.url.path == '/api/v1/auth/refresh') {
        refreshes++;
        expect(jsonDecode(req.body)['refresh_token'], 'old-refresh');
        return http.Response(jsonEncode({'access_token': 'new', 'refresh_token': 'new-refresh'}), 200);
      }
      if (req.headers['Authorization'] != 'Bearer new') {
        return http.Response(jsonEncode({'error': {'code': 'AUTH_INVALID', 'message': 'Sesija beigusies.'}}), 401);
      }
      return http.Response(jsonEncode({'epasts': 'a@b.lv'}), 200);
    });
    final store = MemorySessionStore()..token = 'old-refresh';
    final client = ApiClient(baseUrl: 'http://srv', httpClient: mock)..accessToken = 'expired';
    final api = HttpKopsummaApi(client, store: store);
    final results = await Future.wait([api.currentEmail(), api.currentEmail()]);
    expect(results, ['a@b.lv', 'a@b.lv']);
    expect(refreshes, 1);
    expect(store.token, 'new-refresh');
  });

  test('sesijas atjaunošana bez saglabāta marķiera → false; nederīgs marķieris tiek dzēsts', () async {
    final mock = MockClient((_) async =>
        http.Response(jsonEncode({'error': {'code': 'AUTH_INVALID', 'message': 'x'}}), 401));
    expect(await HttpKopsummaApi(ApiClient(baseUrl: 'http://s', httpClient: mock)).restoreSession(), isFalse);
    final store = MemorySessionStore()..token = 'bad';
    expect(await HttpKopsummaApi(ApiClient(baseUrl: 'http://s', httpClient: mock), store: store).restoreSession(),
        isFalse);
    expect(store.token, isNull);
  });

  test('augšupielāde: multipart ar platformu; apstiprinājums atkārto to pašu Idempotency-Key', () async {
    final keys = <String?>[];
    final mock = MockClient((req) async {
      if (req.url.path == '/api/v1/imports') {
        expect(req.headers['content-type'], startsWith('multipart/form-data'));
        final body = utf8.decode(req.bodyBytes);
        expect(body, contains('name="platformas_id"'));
        expect(body, contains('filename="twino.csv"'));
        return http.Response(jsonEncode({'importa_id': 'abc', 'jauni': 2, 'dublikati': 0, 'platforma': 'Twino'}), 201);
      }
      keys.add(req.headers['Idempotency-Key']);
      if (keys.length == 1) throw http.ClientException('pazuda tīkls');
      return http.Response(jsonEncode({'saglabati': 2, 'dublikati': 0}), 200);
    });
    final api = HttpKopsummaApi(ApiClient(baseUrl: 'http://s', httpClient: mock));
    final preview = await api.uploadStatement(platformId: 2, fileName: 'twino.csv', bytes: utf8.encode('a;b'));
    expect(preview.newCount, 2);
    await expectLater(api.confirmImport(preview.id), throwsA(isA<ApiException>()));
    expect((await api.confirmImport(preview.id)).saved, 2);
    expect(keys[0], isNotNull);
    expect(keys[0], keys[1]);
  });

  test('kļūdas rindas numurs no lauka', () {
    expect(const ApiException(422, 'X', 'm', field: 'fails.row[47]').row, 47);
    expect(const ApiException(422, 'X', 'm').row, isNull);
  });
}
