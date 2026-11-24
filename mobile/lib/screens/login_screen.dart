import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../widgets/form_parts.dart';

/// S-02 Pieteikšanās ar kļūdas stāvokli.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
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
    final emailError = emailProblem(_email.text);
    if (emailError != null || _password.text.isEmpty) {
      setState(() => _error = emailError ?? 'Ievadiet paroli.');
      return;
    }
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
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Ievadiet e-pastu un paroli, ko izmantojāt reģistrējoties.', style: text.bodyMedium),
              const SizedBox(height: 24),
              const FieldLabel('E-pasts'),
              TextField(
                key: const Key('email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              const FieldLabel('Parole'),
              TextField(
                key: const Key('password'),
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(error: _error == null ? null : FieldError(_error!)),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('login'),
                onPressed: _busy ? null : _submit,
                child: BusyLabel(busy: _busy, label: 'Pieteikties'),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('to-register'),
                onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.register),
                child: const Text('Nav konta? Izveidot kontu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
