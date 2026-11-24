import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../widgets/form_parts.dart';

/// S-02a Reģistrācija (API-01) — pēc veiksmīgas reģistrācijas lietotājs uzreiz ir pieteicies.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repeat = TextEditingController();
  String? _emailError;
  String? _passwordError;
  String? _repeatError;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailError = emailProblem(_email.text);
      _passwordError = passwordProblem(_password.text);
      _repeatError = _repeat.text == _password.text ? null : 'Paroles nesakrīt.';
    });
    if (_emailError != null || _passwordError != null || _repeatError != null) return;
    setState(() => _busy = true);
    try {
      await AppScope.apiOf(context).register(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (_) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.field == 'epasts' || e.code == 'EMAIL_TAKEN') {
          _emailError = e.message;
        } else {
          _passwordError = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String? error, [String? helper]) =>
      InputDecoration(error: error == null ? null : FieldError(error), helperText: error == null ? helper : null);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Jauns konts', style: text.headlineMedium)),
      body: SafeArea(
        child: AutofillGroup(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Konts glabā tikai jūsu importētos darījumus. Naudu lietotne nepārskaita.',
                  style: text.bodyMedium),
              const SizedBox(height: 24),
              const FieldLabel('E-pasts'),
              TextField(
                key: const Key('reg-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: _decoration(_emailError),
              ),
              const SizedBox(height: 12),
              const FieldLabel('Parole'),
              TextField(
                key: const Key('reg-password'),
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                decoration: _decoration(_passwordError, 'Vismaz 10 rakstzīmes, mazais un lielais burts, cipars'),
              ),
              const SizedBox(height: 12),
              const FieldLabel('Parole vēlreiz'),
              TextField(
                key: const Key('reg-repeat'),
                controller: _repeat,
                obscureText: true,
                onSubmitted: (_) => _submit(),
                decoration: _decoration(_repeatError),
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('register'),
                onPressed: _busy ? null : _submit,
                child: BusyLabel(busy: _busy, label: 'Izveidot kontu'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.login),
                child: const Text('Jau ir konts? Pieteikties'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
