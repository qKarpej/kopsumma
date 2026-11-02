import 'package:flutter/material.dart';

import 'portfolio_screen.dart';
import 'profile_screen.dart';
import 'tax_screen.dart';
import 'transactions_screen.dart';

/// Apakšējā cilņu josla: S-03 Portfelis, S-10 Darījumi, S-12 Nodoklis, S-13 Profils.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PortfolioScreen(onOpenTax: () => setState(() => _tab = 2)),
      const TransactionsScreen(),
      const TaxScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(key: Key('tab-portfolio'), icon: Icon(Icons.pie_chart_outline), label: 'Portfelis'),
          NavigationDestination(key: Key('tab-transactions'), icon: Icon(Icons.list), label: 'Darījumi'),
          NavigationDestination(key: Key('tab-tax'), icon: Icon(Icons.percent), label: 'Nodoklis'),
          NavigationDestination(key: Key('tab-profile'), icon: Icon(Icons.person_outline), label: 'Profils'),
        ],
      ),
    );
  }
}
