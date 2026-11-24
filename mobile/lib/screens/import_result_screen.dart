import 'package:flutter/material.dart';

import '../api/models.dart';
import '../routes.dart';
import '../theme/app_theme.dart';

class ImportDone {
  const ImportDone({required this.result, required this.preview});

  final ImportResult result;
  final ImportPreview preview;
}

class ImportFailure {
  const ImportFailure({required this.message, required this.fileName, required this.platformId, this.row});

  final String message;
  final String fileName;
  final int platformId;
  final int? row;
}

class _ResultLayout extends StatelessWidget {
  const _ResultLayout({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.lines,
    required this.actions,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final List<Widget> lines;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  child: Icon(icon, color: iconColor, size: 36),
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: text.headlineMedium),
              const SizedBox(height: 8),
              ...lines,
              const Spacer(),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

/// S-08 Imports pabeigts.
class ImportDoneScreen extends StatelessWidget {
  const ImportDoneScreen({super.key, required this.result});

  final ImportDone result;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final n = result.result.saved;
    return _ResultLayout(
      icon: Icons.check_rounded,
      iconColor: AppColors.success,
      iconBg: AppColors.primaryWeak,
      title: n == 1 ? 'Saglabāts 1 darījums' : 'Saglabāti $n darījumi',
      lines: [
        Text('${result.preview.platform} dati ir pievienoti. Portfelis un nodoklis ir pārrēķināti.',
            key: const Key('import-done'), style: text.bodyLarge),
      ],
      actions: [
        FilledButton(
          key: const Key('done-home'),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (_) => false),
          child: const Text('Uz portfeli'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          key: const Key('done-another'),
          onPressed: () => Navigator.of(context).pop(), // S-04 paliek zem šī ekrāna
          child: const Text('Importēt vēl vienu izrakstu'),
        ),
      ],
    );
  }
}

/// S-09 Kļūda failā — nekas netiek saglabāts.
class ImportErrorScreen extends StatelessWidget {
  const ImportErrorScreen({super.key, required this.error});

  final ImportFailure error;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return _ResultLayout(
      icon: Icons.error_outline,
      iconColor: AppColors.danger,
      iconBg: AppColors.dangerBg,
      title: 'Failu neizdevās nolasīt',
      lines: [
        Text(error.fileName, style: text.bodyMedium),
        const SizedBox(height: 12),
        Container(
          key: const Key('import-error'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(12)),
          child: Text(error.message, style: text.bodyLarge?.copyWith(color: AppColors.danger)),
        ),
        const SizedBox(height: 12),
        Text('Neviens darījums nav saglabāts.', style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Pārbaudiet, vai izvēlējāties pareizo platformu un vai fails ir neizmainīts CSV izraksts.',
            style: text.bodyMedium),
      ],
      actions: [
        FilledButton(
          key: const Key('error-retry'),
          onPressed: () => Navigator.of(context).pop(), // atpakaļ uz S-05 ar to pašu platformu
          child: const Text('Izvēlēties citu failu'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(Routes.home, (_) => false),
          child: const Text('Uz portfeli'),
        ),
      ],
    );
  }
}
