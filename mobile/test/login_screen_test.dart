import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopsumma/api/api_client.dart';
import 'package:kopsumma/api/token_store.dart';
import 'package:kopsumma/main.dart';

class FakeAuthApi implements AuthApi {
  @override
  Future<LoginResult> login(String email, String password) async {
    if (password == 'Kopsumma2026') return const LoginResult('access', 'refresh');
    throw ApiException(401, 'INVALID_CREDENTIALS', 'E-pasts vai parole nav pareiza.');
  }
}

class MemoryTokenStore implements TokenStore {
  String? saved;

  @override
  Future<void> saveRefreshToken(String token) async => saved = token;
}

void main() {
  testWidgets('nepareiza parole rāda kļūdu zem lauka', (tester) async {
    final store = MemoryTokenStore();
    await tester.pumpWidget(KopsummaApp(api: FakeAuthApi(), tokens: store));

    await tester.enterText(find.byKey(const Key('email')), 'anna@inbox.lv');
    await tester.enterText(find.byKey(const Key('password')), 'parole1');
    await tester.tap(find.byKey(const Key('login')));
    await tester.pumpAndSettle();

    expect(find.text('E-pasts vai parole nav pareiza.'), findsOneWidget);
    expect(find.text('Pieteikšanās'), findsOneWidget);
    expect(store.saved, isNull);
  });

  testWidgets('pareiza parole atver tukšo portfeli un saglabā marķieri', (tester) async {
    final store = MemoryTokenStore();
    await tester.pumpWidget(KopsummaApp(api: FakeAuthApi(), tokens: store));

    await tester.enterText(find.byKey(const Key('email')), 'anna@inbox.lv');
    await tester.enterText(find.byKey(const Key('password')), 'Kopsumma2026');
    await tester.tap(find.byKey(const Key('login')));
    await tester.pumpAndSettle();

    expect(find.text('Vēl nav neviena darījuma'), findsOneWidget);
    expect(store.saved, 'refresh');
  });
}
