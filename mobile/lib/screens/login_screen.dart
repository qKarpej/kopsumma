import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';

/// S-02 Pieteikšanās ar kļūdas stāvokli.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController(text: 'anna@inbox.lv');
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.apiOf(context).login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (_) => false);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Pieteikšanās', style: text.headlineMedium)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Ievadiet e-pastu un paroli, ko izmantojāt reģistrējoties.', style: text.bodyMedium),
            const SizedBox(height: 24),
            const _Label('E-pasts'),
            TextField(key: const Key('email'), controller: _email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            const _Label('Parole'),
            TextField(
              key: const Key('password'),
              controller: _password,
              obscureText: true,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(error: _error == null ? null : _ErrorText(_error!)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('login'),
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Pieteikties'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
      );
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
          const SizedBox(width: 4),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14, color: AppColors.danger))),
        ],
      );
}
