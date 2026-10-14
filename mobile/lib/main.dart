import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'api/token_store.dart';
import 'screens/login_screen.dart';
import 'screens/portfolio_empty_screen.dart';
import 'theme/app_theme.dart';

const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');

void main() {
  runApp(KopsummaApp(api: HttpAuthApi(baseUrl: apiBaseUrl), tokens: const SecureTokenStore()));
}

class KopsummaApp extends StatelessWidget {
  const KopsummaApp({super.key, required this.api, required this.tokens});

  final AuthApi api;
  final TokenStore tokens;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kopsumma',
      theme: buildTheme(),
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => LoginScreen(
          api: api,
          tokens: tokens,
          onLoggedIn: (_) => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const PortfolioEmptyScreen()),
          ),
        ),
      ),
    );
  }
}
