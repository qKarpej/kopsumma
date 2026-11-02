// Ekrānuzņēmumi pārbaudei un K5 kartītei. Palaiž CI darbplūsma screenshots.yml:
// flutter test test_screenshots --update-goldens
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopsumma/app.dart';
import 'package:kopsumma/routes.dart';
import 'package:kopsumma/screens/home_shell.dart';
import 'package:kopsumma/state/app_scope.dart';
import 'package:kopsumma/theme/app_theme.dart';

import '../test/fake_api.dart';

Future<void> loadFonts() async {
  final dir = Directory('${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts');
  final roboto = FontLoader('Roboto');
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (name.startsWith('Roboto-') && name.endsWith('.ttf') && !name.contains('Italic')) {
      roboto.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    if (name.startsWith('MaterialIcons-Regular')) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      await icons.load();
    }
  }
  await roboto.load();
}

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget home(FakeApi api, {int tab = 0}) => AppScope(
      api: api,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(fontFamily: 'Roboto'),
        home: HomeShell(initialTab: tab),
        onGenerateRoute: Routes.generate,
      ),
    );

void main() {
  setUpAll(loadFonts);

  testWidgets('S-01', (t) async {
    phone(t);
    await t.pumpWidget(KopsummaApp(api: FakeApi(), fontFamily: 'Roboto'));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('png/s01_start.png'));
  });

  testWidgets('S-02 kļūda', (t) async {
    phone(t);
    await t.pumpWidget(KopsummaApp(api: FakeApi(), fontFamily: 'Roboto', initialRoute: Routes.login));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('password')), 'nepareiza');
    await t.tap(find.byKey(const Key('login')));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('png/s02_login_error.png'));
  });

  testWidgets('S-03 loading', (t) async {
    phone(t);
    final api = FakeApi()..gate = Completer<void>();
    await t.pumpWidget(home(api));
    await t.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('png/s03_loading.png'));
    api.gate!.complete();
    await t.pumpAndSettle();
  });

  for (final (mode, name) in [(Mode.ready, 'ready'), (Mode.empty, 'empty'), (Mode.error, 'error')]) {
    testWidgets('S-03 $name', (t) async {
      phone(t);
      await t.pumpWidget(home(FakeApi(mode: mode)));
      await t.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('png/s03_$name.png'));
    });
  }

  testWidgets('S-10', (t) async {
    phone(t);
    await t.pumpWidget(home(FakeApi(), tab: 1));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('png/s10_transactions.png'));
  });

  testWidgets('S-11', (t) async {
    phone(t);
    await t.pumpWidget(home(FakeApi(), tab: 1));
    await t.pumpAndSettle();
    await t.tap(find.text('Procentu ienākums').last);
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('png/s11_detail.png'));
  });

  testWidgets('S-12', (t) async {
    phone(t);
    await t.pumpWidget(home(FakeApi(), tab: 2));
    await t.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('png/s12_tax.png'));
  });
}
