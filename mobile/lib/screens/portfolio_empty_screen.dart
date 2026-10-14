import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// S-03 tukšais stāvoklis pēc pirmās pieteikšanās.
class PortfolioEmptyScreen extends StatelessWidget {
  const PortfolioEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Portfelis', style: text.headlineMedium)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 48),
            const Icon(Icons.description_outlined, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text('Vēl nav neviena darījuma', style: text.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Importējiet izrakstu no Mintos, un šeit būs redzama kopējā portfeļa vērtība.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
