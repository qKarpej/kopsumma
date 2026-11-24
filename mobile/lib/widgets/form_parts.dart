import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
      );
}

class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

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

class BusyLabel extends StatelessWidget {
  const BusyLabel({super.key, required this.busy, required this.label});

  final bool busy;
  final String label;

  @override
  Widget build(BuildContext context) => busy
      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
      : Text(label);
}

/// Tie paši noteikumi kā serverī (API-01): ≥10 rakstzīmes, mazais un lielais burts, cipars.
String? passwordProblem(String p) {
  if (p.length < 10) return 'Parolei jābūt vismaz 10 rakstzīmēm.';
  if (!RegExp('[a-z]').hasMatch(p) || !RegExp('[A-Z]').hasMatch(p)) {
    return 'Parolē jābūt gan mazajam, gan lielajam burtam.';
  }
  if (!RegExp(r'\d').hasMatch(p)) return 'Parolē jābūt vismaz vienam ciparam.';
  return null;
}

String? emailProblem(String e) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e.trim()) ? null : 'Ievadiet derīgu e-pasta adresi.';
