import 'package:flutter/material.dart';

import '../api/models.dart';
import '../money/money_format.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/async_view.dart';
import 'transactions_screen.dart';

/// S-11 Darījuma detaļas.
class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final api = AppScope.apiOf(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text('Darījums', style: text.headlineMedium)),
      body: SafeArea(
        child: AsyncView<Tx>(
          load: () => api.transaction(id),
          isEmpty: (_) => false,
          empty: (_) => const SizedBox.shrink(),
          ready: (context, t, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${t.typeLabel} · ${t.platform}', style: text.bodyMedium),
              Text(
                formatCents(t.cents, currency: t.currency, signed: true),
                style: text.displaySmall?.copyWith(color: t.cents > 0 ? AppColors.success : AppColors.ink),
              ),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerLeft, child: StatusBadge(needsReview: t.needsReview)),
              if (t.needsReview) ...[
                const SizedBox(height: 12),
                const _Note('Summa nav EUR. Kamēr tā nav pārrēķināta, darījums netiek iekļauts nodokļa aprēķinā.'),
              ],
              const SizedBox(height: 12),
              _Kv('Datums', formatDate(t.date)),
              _Kv('Platforma', t.platform),
              _Kv('Veids', t.typeLabel),
              _Kv('Nodokļa aprēķinā', t.needsReview
                  ? 'Nav iekļauts'
                  : (const {'procenti', 'kapitala_pieaugums'}.contains(t.type) ? 'Iekļauts' : 'Nav apliekams')),
              _Kv('Darījuma ID', t.externalId),
            ],
          ),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.warnBg, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.warn)),
      );
}

class _Kv extends StatelessWidget {
  const _Kv(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line))),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyLarge?.copyWith(color: AppColors.muted))),
          Text(value, style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
