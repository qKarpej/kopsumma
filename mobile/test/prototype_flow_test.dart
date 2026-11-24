import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopsumma/app.dart';
import 'package:kopsumma/platform/file_source.dart';
import 'package:kopsumma/routes.dart';
import 'package:kopsumma/screens/home_shell.dart';
import 'package:kopsumma/state/app_scope.dart';
import 'package:kopsumma/state/settings.dart';
import 'package:kopsumma/theme/app_theme.dart';

import 'fake_api.dart';
import 'fake_services.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget shell(AppServices s, {int tab = 0}) => AppScope(
      services: s,
      child: MaterialApp(theme: buildTheme(), home: HomeShell(initialTab: tab), onGenerateRoute: Routes.generate),
    );

void main() {
  group('Sesija un konts', () {
    testWidgets('saglabāta sesija → sākuma ekrāns uzreiz atver portfeli', (tester) async {
      phone(tester);
      await tester.pumpWidget(KopsummaApp(api: FakeApi(hasSession: true)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('total')), findsOneWidget);
    });

    testWidgets('reģistrācija: pārbaude ierīcē, aizņemts e-pasts, veiksmīgs konts', (tester) async {
      phone(tester);
      final api = FakeApi(mode: Mode.empty);
      await tester.pumpWidget(KopsummaApp(api: api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start-register')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('reg-email')), 'juris@inbox.lv');
      await tester.enterText(find.byKey(const Key('reg-password')), 'isa');
      await tester.tap(find.byKey(const Key('register')));
      await tester.pumpAndSettle();
      expect(find.text('Parolei jābūt vismaz 10 rakstzīmēm.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('reg-email')), 'anna@inbox.lv');
      await tester.enterText(find.byKey(const Key('reg-password')), 'Kopsumma2026');
      await tester.enterText(find.byKey(const Key('reg-repeat')), 'Kopsumma2026');
      await tester.tap(find.byKey(const Key('register')));
      await tester.pumpAndSettle();
      expect(find.text('Šis e-pasts jau ir reģistrēts.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('reg-email')), 'juris@inbox.lv');
      await tester.tap(find.byKey(const Key('register')));
      await tester.pumpAndSettle();
      expect(api.registered, 'juris@inbox.lv');
      expect(find.byKey(const Key('empty-import')), findsOneWidget); // jauns konts → tukšais stāvoklis ar importu
    });

    testWidgets('iziet: sesija tiek dzēsta, atgādinājumi atcelti', (tester) async {
      phone(tester);
      final api = FakeApi();
      final reminders = FakeReminders();
      await tester.pumpWidget(shell(AppServices(api: api, reminders: reminders), tab: 3));
      await tester.pumpAndSettle();
      expect(find.text('anna@inbox.lv'), findsOneWidget);
      await tester.tap(find.byKey(const Key('logout')));
      await tester.pumpAndSettle();
      expect(api.loggedOut, isTrue);
      expect(reminders.cancelled, isTrue);
      expect(find.byKey(const Key('start-login')), findsOneWidget);
    });
  });

  group('Imports S-04…S-09', () {
    testWidgets('Twino: fails → pārbaude → saglabāt → pabeigts; atgādinājumi atjaunoti', (tester) async {
      phone(tester);
      final api = FakeApi();
      final reminders = FakeReminders();
      final settings = MemorySettingsStore()..reminders = true;
      final files = FakeFiles(const PickedFile('twino_2026-10-11.csv', [1, 2, 3]));
      await tester.pumpWidget(shell(AppServices(api: api, files: files, reminders: reminders, settings: settings)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('portfolio-import')));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(find.byKey(const Key('pick-file'))).onPressed, isNull); // vispirms platforma
      await tester.tap(find.byKey(const Key('platform-Twino')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Twino tīmekļa vietnē'), findsOneWidget);
      await tester.tap(find.byKey(const Key('pick-file')));
      await tester.pumpAndSettle();

      expect(find.text('83 jauni darījumi'), findsOneWidget);
      expect(find.text('94,28 €'), findsOneWidget);
      expect(api.confirmed, isEmpty); // nekas nav saglabāts pirms apstiprinājuma
      await tester.tap(find.byKey(const Key('preview-save')));
      await tester.pumpAndSettle();

      expect(api.confirmed, ['imp-1']);
      expect(find.text('Saglabāti 83 darījumi'), findsOneWidget);
      expect(reminders.scheduled.single.date, DateTime(2099, 1, 15));
      await tester.tap(find.byKey(const Key('done-home')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('total')), findsOneWidget);
    });

    testWidgets('bojāts fails → S-09 ar rindas numuru; atpakaļ uz faila izvēli', (tester) async {
      phone(tester);
      final api = FakeApi();
      final files = FakeFiles(const PickedFile('mintos_bojats.csv', [1]));
      await tester.pumpWidget(shell(AppServices(api: api, files: files)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('portfolio-import')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('platform-Mintos')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pick-file')));
      await tester.pumpAndSettle();

      expect(find.text('Failu neizdevās nolasīt'), findsOneWidget);
      expect(find.text("47. rindā: Summa 'abc' nav skaitlis."), findsOneWidget);
      expect(find.text('Neviens darījums nav saglabāts.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('error-retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('pick-file')), findsOneWidget);
      expect(api.confirmed, isEmpty);
    });

    testWidgets('atkārtots fails → nav jaunu darījumu, nekas netiek saglabāts', (tester) async {
      phone(tester);
      final api = FakeApi();
      final files = FakeFiles(const PickedFile('twino_atkartots.csv', [1]));
      await tester.pumpWidget(shell(AppServices(api: api, files: files)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('portfolio-import')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('platform-Twino')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pick-file')));
      await tester.pumpAndSettle();
      expect(find.text('Nav jaunu darījumu'), findsOneWidget);
      expect(find.byKey(const Key('preview-save')), findsNothing);
      await tester.tap(find.byKey(const Key('preview-home')));
      await tester.pumpAndSettle();
      expect(api.cancelled, ['imp-1']);
      expect(api.confirmed, isEmpty);
    });

    testWidgets('tukšs portfelis piedāvā importu', (tester) async {
      phone(tester);
      await tester.pumpWidget(shell(AppServices(api: FakeApi(mode: Mode.empty))));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('empty-import')));
      await tester.pumpAndSettle();
      expect(find.text('1. Izvēlieties platformu'), findsOneWidget);
    });

    testWidgets('importu vēsture', (tester) async {
      phone(tester);
      await tester.pumpWidget(shell(AppServices(api: FakeApi()), tab: 3));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('profile-imports')));
      await tester.pumpAndSettle();
      expect(find.text('Saglabāts'), findsOneWidget);
      expect(find.textContaining('kļūda 47. rindā'), findsOneWidget);
    });
  });

  group('Termiņi S-14', () {
    testWidgets('portfelī nākamais termiņš → termiņu ekrāns → ieslēgt atgādinājumus', (tester) async {
      phone(tester);
      final reminders = FakeReminders();
      final settings = MemorySettingsStore();
      await tester.pumpWidget(shell(AppServices(api: FakeApi(), reminders: reminders, settings: settings)));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nākamais termiņš · 15.01.2099.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('next-deadline')));
      await tester.pumpAndSettle();

      expect(find.text('Deklarēt un samaksāt nodokli'), findsOneWidget);
      expect(find.text('Pagājušie'), findsOneWidget);
      await tester.tap(find.byKey(const Key('reminders-switch')));
      await tester.pumpAndSettle();
      expect(settings.reminders, isTrue);
      expect(reminders.scheduled, hasLength(1));
      expect(find.byKey(const Key('reminders-test')), findsOneWidget);
    });

    testWidgets('nav datu → termiņu tukšais stāvoklis', (tester) async {
      phone(tester);
      await tester.pumpWidget(shell(AppServices(api: FakeApi(mode: Mode.empty)), tab: 2));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tax-deadlines')));
      await tester.pumpAndSettle();
      expect(find.text('Termiņu vēl nav'), findsOneWidget);
    });
  });
}
