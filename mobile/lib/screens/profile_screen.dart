import 'package:flutter/material.dart';

import '../config.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';

/// S-13 Profils.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Profils', style: text.headlineMedium),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)),
          child: Text('Serveris: $apiBaseUrl', style: text.bodyMedium),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          key: const Key('logout'),
          onPressed: () {
            AppScope.apiOf(context).logout();
            Navigator.of(context).pushNamedAndRemoveUntil(Routes.start, (_) => false);
          },
          child: const Text('Iziet'),
        ),
      ],
    );
  }
}
