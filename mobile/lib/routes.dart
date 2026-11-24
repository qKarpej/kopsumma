import 'package:flutter/material.dart';

import 'api/models.dart';
import 'screens/deadlines_screen.dart';
import 'screens/home_shell.dart';
import 'screens/import_history_screen.dart';
import 'screens/import_preview_screen.dart';
import 'screens/import_result_screen.dart';
import 'screens/import_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/start_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/transactions_screen.dart';

/// Maršruti pēc K2 ekrānu kartes.
abstract final class Routes {
  static const start = '/'; //                    S-01
  static const login = '/login'; //               S-02
  static const register = '/register'; //         S-02a
  static const home = '/home'; //                 S-03, S-10, S-12, S-13 (cilnes)
  static const importStart = '/import'; //        S-04 platforma + S-05 fails
  static const importPreview = '/import/preview'; // S-06 pārbaude
  static const importDone = '/import/done'; //    S-08 saglabāts
  static const importError = '/import/error'; //  S-09 kļūda failā
  static const importHistory = '/import/history';
  static const deadlines = '/deadlines'; //         S-14 termiņi, kalendārs, atgādinājumi
  static const transactions = '/transactions'; // S-10 ar filtru no portfeļa
  static const transaction = '/transaction'; //   S-11

  static Route<dynamic> generate(RouteSettings s) {
    final Widget page = switch (s.name) {
      start => const StartScreen(),
      login => const LoginScreen(),
      register => const RegisterScreen(),
      home => HomeShell(initialTab: (s.arguments as int?) ?? 0),
      importStart => ImportScreen(initialPlatformId: s.arguments as int?),
      importPreview => ImportPreviewScreen(preview: s.arguments! as ImportPreview),
      importDone => ImportDoneScreen(result: s.arguments! as ImportDone),
      importError => ImportErrorScreen(error: s.arguments! as ImportFailure),
      importHistory => const ImportHistoryScreen(),
      deadlines => const DeadlinesScreen(),
      transactions => TransactionsScreen(platform: s.arguments as String?, standalone: true),
      transaction => TransactionScreen(id: s.arguments! as String),
      _ => const StartScreen(),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: s);
  }
}
