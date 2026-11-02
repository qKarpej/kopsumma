import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopsumma/app.dart';
import 'package:kopsumma/routes.dart';
import 'package:kopsumma/screens/home_shell.dart';
import 'package:kopsumma/state/app_scope.dart';
import 'package:kopsumma/theme/app_theme.dart';

import 'fake_api.dart';

Widget home(FakeApi api) => AppScope(
      api: api,
      child: MaterialApp(theme: buildTheme(), home: const HomeShell(), onGenerateRoute: Routes.generate),
    );

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  group('Portfelis: četri stāvokļi', () {
    testWidgets('loading → ready', (tester) async {
      phone(tester);
      final api = FakeApi()..gate = Completer<void>();
      await tester.pumpWidget(home(api));
      expect(find.byKey(const Key('state-loading')), findsOneWidget);
      api.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('state-ready')), findsOneWidget);
      expect(find.text('19 380,00 €'), findsOneWidget);
      expect(find.text('Mintos'), findsOneWidget);
    });

    testWidgets('empty', (tester) async {
      phone(tester);
      await tester.pumpWidget(home(FakeApi(mode: Mode.empty)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('state-empty')), findsOneWidget);
      expect(find.text('Vēl nav neviena darījuma'), findsOneWidget);
    });

    testWidgets('error → mēģināt vēlreiz → ready', (tester) async {
      phone(tester);
      final api = FakeApi(mode: Mode.error);
      await tester.pumpWidget(home(api));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('state-error')), findsOneWidget);
      expect(find.textContaining('Nav savienojuma'), findsOneWidget);
      api.mode = Mode.ready;
      await tester.tap(find.text('Mēģināt vēlreiz'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('state-ready')), findsOneWidget);
      expect(api.portfolioCalls, 2);
    });
  });

  testWidgets('pilns scenārijs: sākums → pieteikšanās → portfelis → darījums → nodoklis', (tester) async {
      phone(tester);
    await tester.pumpWidget(KopsummaApp(api: FakeApi()));
    await tester.tap(find.byKey(const Key('start-login')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('password')), 'nepareiza');
    await tester.tap(find.byKey(const Key('login')));
    await tester.pumpAndSettle();
    expect(find.text('E-pasts vai parole nav pareiza.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('password')), 'Kopsumma2026');
    await tester.tap(find.byKey(const Key('login')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('total')), findsOneWidget);

    await tester.tap(find.text('Mintos'));
    await tester.pumpAndSettle();
    expect(find.text('Procentu ienākums'), findsOneWidget);
    await tester.tap(find.text('Procentu ienākums'));
    await tester.pumpAndSettle();
    expect(find.text('MT-88412301'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tax-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tax-total')), findsOneWidget);
    expect(find.text('312,40 €'), findsOneWidget);
  });

  testWidgets('darījumi: filtrs un "jāpārbauda" atzīme', (tester) async {
      phone(tester);
    await tester.pumpWidget(home(FakeApi()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tab-transactions')));
    await tester.pumpAndSettle();
    expect(find.text('3 darījumi · 1 jāpārbauda'), findsOneWidget);
    await tester.tap(find.text('Twino'));
    await tester.pumpAndSettle();
    expect(find.text('Jāpārbauda'), findsOneWidget);
    expect(find.text('Ieguldījums'), findsNothing);
  });
}
