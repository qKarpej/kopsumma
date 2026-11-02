import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/start_screen.dart';
import 'screens/transaction_screen.dart';
import 'screens/transactions_screen.dart';

/// Maršruti pēc K2 ekrānu kartes.
abstract final class Routes {
  static const start = '/'; //                S-01
  static const login = '/login'; //           S-02
  static const home = '/home'; //             S-03, S-10, S-12, S-13 (cilnes)
  static const transactions = '/transactions'; // S-10 ar filtru no portfeļa
  static const transaction = '/transaction'; //   S-11

  static Route<dynamic> generate(RouteSettings s) {
    final Widget page = switch (s.name) {
      start => const StartScreen(),
      login => const LoginScreen(),
      home => const HomeShell(),
      transactions => TransactionsScreen(platform: s.arguments as String?, standalone: true),
      transaction => TransactionScreen(id: s.arguments! as String),
      _ => const StartScreen(),
    };
    return MaterialPageRoute<void>(builder: (_) => page, settings: s);
  }
}
