import 'package:flutter/material.dart';

import '../api/models.dart';
import '../money/money_format.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';

/// Importu vēsture (API-07): kas, kad un ar kādu rezultātu importēts.
class ImportHistoryScreen extends StatelessWidget {
  const ImportHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = AppScope.apiOf(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Importu vēsture', style: text.titleLarge)),
      body: SafeArea(
        child: AsyncView<List<ImportRecord>>(
          load: api.imports,
          isEmpty: (l) => l.isEmpty,
          empty: (_) => const EmptyState(
            icon: Icons.history,
            title: 'Vēl nav importu',
            message: 'Importējiet pirmo izrakstu no Mintos vai Twino.',
          ),
          ready: (context, items, reload) => RefreshIndicator(
            onRefresh: reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
              itemBuilder: (context, i) {
                final r = items[i];
                final ok = r.status == 'apstiprinats';
                final color = switch (r.status) {
                  'apstiprinats' => AppColors.success,
                  'kluda' => AppColors.danger,
                  _ => AppColors.muted,
                };
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${r.platform} · ${r.fileName}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text([
                    if (r.created != null) formatDate(r.created!),
                    if (ok) '${r.newCount} darījumi',
                    if (r.errorRow != null) 'kļūda ${r.errorRow}. rindā',
                  ].join(' · ')),
                  trailing: Text(r.statusLabel, style: text.labelLarge?.copyWith(color: color)),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pushNamed(Routes.importStart),
        icon: const Icon(Icons.add),
        label: const Text('Importēt'),
      ),
    );
  }
}
