import 'package:flutter/material.dart';

import '../routes.dart';
import '../theme/app_theme.dart';

/// S-01 Sākums.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const _Mark(),
              const SizedBox(height: 28),
              Text('Kopsumma', style: text.displaySmall?.copyWith(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                'Ieguldījumi no visām platformām un nodoklis par tiem — vienā skatā.',
                style: text.bodyLarge,
              ),
              const Spacer(),
              FilledButton(
                key: const Key('start-login'),
                onPressed: () => Navigator.of(context).pushNamed(Routes.login),
                child: const Text('Pieteikties'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    Widget bar(double h, Color c) => Container(
          width: 18,
          height: h,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [bar(64, AppColors.primary), bar(40, AppColors.series2), bar(22, AppColors.line)],
    );
  }
}
