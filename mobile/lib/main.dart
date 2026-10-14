import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

void main() => runApp(const KopsummaApp());

class KopsummaApp extends StatelessWidget {
  const KopsummaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kopsumma',
      theme: buildTheme(),
      home: const Scaffold(body: Center(child: Text('Kopsumma'))),
    );
  }
}
